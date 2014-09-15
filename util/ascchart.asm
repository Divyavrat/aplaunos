; ----------------------------------------------------------------------------
; FILE: Main.Asm
; DATE: May 24, 2002
; DESCRIPTION: Scrollable symbol chart for DOS.
; ----------------------------------------------------------------------------

;.386
use16
org 0x6000

jmp Main

GotoXY :
; ----------------------------------------------------------------------------
; INPUT:
;	DH <- row in [1..25]
;	DL <- column in [1..80]
; OUTPUT:
;	ES:DI -> VGA RAM address at that [row, column]
; ----------------------------------------------------------------------------
; Here is the theory of DOS text mode: Buffer starts at 0B800h:0000h.
; Every symbol on screen takes 2 bytes in video RAM: symbol code byte +
; color byte. When you put ASCII in AL and color in AH and then store
; whole AX at the video address you get the symbol painted with that color.
; So, every row takes 80*2 = 160 bytes, that means a formula for
; address is:
;	OFS=(row * 160) + 2*column
; where 'row' and 'column' are zero based.
; ----------------------------------------------------------------------------

	dec	dh		; We need both zero-based
	dec	dl

	mov	al, dh		; AL <- row in [0..24]
	cbw			; full AX now is row

	mov	cx, 160
	push	dx		; DX needed (we have DL as column there)
	mul	cx		; DX:AX is now (row*160)
	mov	di, ax		; DI = (row*160)
	pop	dx

	mov	al, dl		; AL <- column in [0..79]
	cbw
	shl	ax, 1		; AX = 2*column
	add	di, ax		; Final DI = (row * 160) + 2*column

	mov	ax, 0B800h	; Prepare segment
	mov	es, ax

	ret
;GotoXY EndP

TextOut:
; ----------------------------------------------------------------------------
; INPUT:
;	ES:DI <- address of VGA RAM where to put text string
;	SI <- address of text string
;	CX <- number of symbols in the string
;	AH <- color to paint text with
; ----------------------------------------------------------------------------
	cld	; Direction flag = 0 means SI and DI will be incremented by LODSB, STOSW

@_PrintChar:
	lodsb	; AL <- [SI], increment SI
	stosw	; AX -> ES:[DI], Move DI forward by 2 bytes
	loop	@_PrintChar

	ret
;TextOut EndP

Bar:
; ----------------------------------------------------------------------------
; INPUT:
;	DH <- row in [1..25]
;	AH <- color to fill all 80 columns of that row
; ----------------------------------------------------------------------------
	mov	dl, 1
	push	ax		; Save color, AH will be killed by 'GotoXY'
	call	GotoXY		; This one makes ES:DI

	;mov	si, offset [strBlankLine]
	mov	si, strBlankLine
	mov	cx, 80
	pop	ax		; Restore color
	call	TextOut	; This one uses ES:DI
	ret
;Bar EndP

ConvertAL2HexDigit:
; Proc Near
; ----------------------------------------------------------------------------
; INPUT:
;	AL <- only last 4 bits will be used
; OUTPUT:
;	DL -> HEX digit for last 4 bits in AL
; ----------------------------------------------------------------------------
	push	ax		; We need AL back after this
	and	al, 0Fh		; Leave only 4 last digits
	cmp	al, 9
	ja	@_A_to_F	; If AL above 9 then we have ['A'..'F']

	add	al, '0'		; Here we have ['0'..'9']
	jmp	@_Exit_Convert

@_A_to_F:
	sub	al, 10
	add	al, 'A'

@_Exit_Convert:
	mov	dl, al		; DL returns it
	pop	ax		; We have AL back
	ret
;ConvertAL2HexDigit EndP

Format_AL_to_DEC:
; ----------------------------------------------------------------------------
; INPUT:
;	AL <- ASCII symbol to format
;	DI <- address of 3 symbols area where to store it [0..255]
; ----------------------------------------------------------------------------
	xor	ah, ah	; Clean up the AH, so we can use AX as the full 16-bit value
	push	ax	; Save ASCII, because it will be destroyed, but we need it later

	; --- Before we start - clean up the area with blanks, because
	; --- we do it on the same memory, so we must erase previous formatting
	mov	dx, 2020h	; Both DH <- ' ' and DL <- ' '
	mov	[di], dx		; Clean first 2 bytes
	mov	[di+2], dl	; Clean 3-rd byte

	; --- Prepare for dividing
	add	di, 3		; Move pointer beyond the last symbol in buffer
	mov	cx, 10		; Our denominator

@_Div10:
	xor	dx, dx		; Clear DX, because we divide DX:AX as a whole
	div	cx		; AX is a result, DX is a remainder
	add	dl, '0'		; Make remainder a digit in ['0'..'9']

	; --- Save the digit
	dec	di
	mov	[di], dl

	; --- See, if more to divide
	test	ax, ax
	jnz	@_Div10

	pop	ax	; Restore ASCII
	ret
;Format_AL_to_DEC EndP

Format_AL_to_HEX:
; Proc Near
; ----------------------------------------------------------------------------
; INPUT:
;	AL <- ASCII symbol to format
;	DI <- address of 2 symbols area where to store it [00..FF]
; ----------------------------------------------------------------------------
	push	ax	; Again, need it all the time

	; --- We do not clear the area here as in 'Format_AL_to_DEC', because
	; --- we write both HEX digits all the time, so they erase previous data

	; --- Last 4 bits
	call	ConvertAL2HexDigit
	mov	[di+1], dl

	; --- First 4 bits, that is why we need to save/restore AL inside 'ConvertAL2HexDigit'
	; --- we need its first 4 digits...

	shr	al, 4
	call	ConvertAL2HexDigit
	mov	[di], dl

	pop	ax	; Got it back!
	ret
;Format_AL_to_HEX EndP

Format_AL_to_BIN:
; Proc Near
; ----------------------------------------------------------------------------
; INPUT:
;	AL <- ASCII symbol to format
;	DI <- address of 9 symbols area where to store it [0000 0000..1111 1111]
; ----------------------------------------------------------------------------
	; --- Prepare for loop
	mov	cx, 8		; 8 bits to check
	mov	dl, 80h		; Mask now is 10000000 binary
	xor	bx, bx		; BX <- 0 - counts how many symbols stored at DI

@_CheckBit:
	mov	dh, '0'		; Prepare '0' all the time
	test	al, dl		; Check it!
	jz	@_SaveBinDigit

	inc	dh		; Now DH is '1' (was '0')

@_SaveBinDigit:
	mov	[di], dh	; Write digit into buffer at DI
	inc	bx		; Count symbols

	; --- This is why we need BX - to skip a symbol AFTER 4 symbols
	; --- saved, so we will get [xxxx xxxx] format and not [xxxxxxxx]
	cmp	bx, 4
	jne	@_ContinueLoop

	inc	di		; Skip the address

@_ContinueLoop:
	shr	dl, 1		; Shift our testing mask, so we can test next bit in AL
	inc	di		; Next buffer symbol to store
	loop	@_CheckBit

	; --- No need to push/pop AX, because we only test it and TEST
	; --- instruction is not modifying the register, so AL left as is...
	ret
;Format_AL_to_BIN EndP

Format_AL_All:
; Proc Near
; ----------------------------------------------------------------------------
; INPUT:
;	AL <- ASCII symbol to format
; OUTPUT:
;	'strFormatted' must be done for printing - all fields are set.
; ----------------------------------------------------------------------------
	; --- Save it as a symbol - you see the letter on screen
	mov	di, strFormatted+1
	mov	[di], al

	; --- Decimal
	mov	di, strFormatted+6
	call	Format_AL_to_DEC

	; --- Hexa-Decimal
	mov	di, strFormatted+12
	call	Format_AL_to_HEX

	; --- Binary
	mov	di, strFormatted+17
	call	Format_AL_to_BIN

	; --- We need AL not modified in all sequence of calls, that is why
	; --- all Format_xxx functions are saving/restoring AX if it is destroyed
	; --- by the function.

	ret
;Format_AL_All EndP

DrawSingleRow:
; Proc Near
; ----------------------------------------------------------------------------
; INPUT:
;	AL <- first ASCII symbol to format
;	DH <- row in [1..25] where to paint
; ----------------------------------------------------------------------------
	;local	iRow:Word, iCol:Word, iAscii:Word=VarSize	; That is how you declare local vars
	;enter	VarSize, 0	; Allocate local vars

	; --- Save parameters, because these registers are killed
	mov	[iAscii], ax
	mov	[iRow], dx
	mov	[iCol], 2		; We start at column 2

	; --- Sub-row #1
	call	Format_AL_All

	mov	dx, [iRow]
	mov	ax, [iCol]
	mov	dl, al
	call	GotoXY

	mov	si, strFormatted
	mov	cx, 26
	mov	ah, 07h	; LIGHTGRAY text on BLACK back
	call	TextOut

	; --- Next ASCII
	mov	ax, [iAscii]
	add	ax, [wASCIIofs]
	cmp	ax, 255
	ja	@_Exit_DrawSingleRow	; AX is above 255 - done

	mov	[iAscii], ax	; For next time
	add	[iCol], 31	; Skip 26 written + 5 for divider

	; --- Sub-row #2
	call	Format_AL_All

	mov	dx, [iRow]
	mov	ax, [iCol]
	mov	dl, al
	call	GotoXY

	mov	si, strFormatted
	mov	cx, 26
	mov	ah, 07h
	call	TextOut

@_Exit_DrawSingleRow:
	;leave	; Release local vars
	ret
;DrawSingleRow EndP

DrawPage:
; ----------------------------------------------------------------------------
; INPUT:
;	'wPageTop' <- ASCII code at the top of the page
; ----------------------------------------------------------------------------
	mov	cx, 23		; 23 rows from 25 (top & bottom are taken)
	mov	ax, [wPageTop]	; Page starting point
	mov	dh, 2		; Starting row index

@_AllPageRows:
	push	cx

	push	ax
	push	dx
	call	DrawSingleRow
	pop	dx
	pop	ax

	inc	ax	; Both incremented: row and ASCII code
	inc	dh

	pop	cx
	loop	@_AllPageRows

	ret
;DrawPage EndP

PaintFrame:
; ----------------------------------------------------------------------------
; Just paint the surrounding areas, which never will change...
; ----------------------------------------------------------------------------

	; --- Bar at the bottom
	mov	dh, 25
	mov	ah, 70h	; BLACK text on LIGHTGRAY back
	call	Bar

	; --- Program name
	mov	dh, 25
	mov	dl, 2
	call	GotoXY

	mov	si, strAppName
	mov	cx, 11
	mov	ah, 70h
	call	TextOut

	; --- Navigation info
	mov	dh, 25
	mov	dl, 44
	call	GotoXY

	mov	si, strNavigation
	mov	cx, 36
	mov	ah, 74h	; RED text on LIGHTGRAY back
	call	TextOut

	; --- Bar at the top
	mov	dh, 1
	mov	ah, 1Eh	; YELLOW (0Eh) text on BLUE (10h) back
	call	Bar

	; --- Header #1
	mov	dh, 1
	mov	dl, 2
	call	GotoXY

	mov	si, strHeader
	mov	cx, 20
	mov	ah, 1Eh
	call	TextOut

	; --- Header #2
	mov	dh, 1
	mov	dl, 33
	call	GotoXY

	mov	si, strHeader
	mov	cx, 20
	mov	ah, 1Eh
	call	TextOut

	ret
;PaintFrame EndP

KeyboardHandler:
; ----------------------------------------------------------------------------
; Here we work out all the navigation. It is very easy - all you have
; to do is set up the 'wPageTop' correctly and call 'DrawPage' to refresh whole
; thing. Also, the code takes care of max. possible index for 'wPageTop'.
; It is done as:
;	1. last visible page index is 'wPageTop' + 22 (23 lines in all)
;	2. last possible 'wPageTop' is 127-22 = 105.
; ----------------------------------------------------------------------------

@_ReadKeyboard:
	xor	ah, ah
	int	0x16		; AH is a scan code of a key (AL is ASCII, but we do not use it here...)

	; --- Analyser
	cmp	ah, 1
	je	@_OnEsc
	cmp	ah, 72
	je	@_OnUp
	cmp	ah, 80
	je	@_OnDown
	cmp	ah, 73
	je	@_OnPageUp
	cmp	ah, 81
	je	@_OnPageDown
	cmp	ah, 71
	je	@_OnHome
	cmp	ah, 79
	je	@_OnEnd
	jmp	@_ReadKeyboard	; No luck!

@_OnEsc:
	ret	; Only here we leave this function and the program

@_OnUp:
	mov	ax, -1		; Offset from current page top index
	jmp	@_Navigate

@_OnDown:
	mov	ax, 1		; Offset from current page top index
	jmp	@_Navigate

@_OnPageUp:
	mov	ax, -20		; Offset from current page top index
	jmp	@_Navigate

@_OnPageDown:
	mov	ax, 20		; Offset from current page top index
	jmp	@_Navigate

@_OnHome:
	mov	[wPageTop], 0
	call	DrawPage
	jmp	@_ReadKeyboard

@_OnEnd:
	mov	[wPageTop], 105
	call	DrawPage
	jmp	@_ReadKeyboard

@_Navigate:
	; --- Add offset in AX to 'wPageTop'
	mov	dx, [wPageTop]
	add	dx, ax
	js	@_OnHome	; Negative, so go home

	cmp	dx, 105
	ja	@_OnEnd	; More than needed

	mov	[wPageTop], dx
	call	DrawPage
	jmp	@_ReadKeyboard
;KeyboardHandler EndP

; ----------------------------------------------------------------------------
; Program starts here...
; ----------------------------------------------------------------------------
Main:
	;mov	ax, Data	; Set up DS to access the variables
	xor ax,ax
	mov	ds, ax

	mov	ax, 3		; Set text mode 80x25x16 colors
	int	10h		; We got clear screen now!

	mov	ah, 1		; No visible cursor
	mov	cx, 2000h
	int	10h

	call	PaintFrame
	call	DrawPage
	call	KeyboardHandler

	mov	ah, 1		; DOS visible cursor
	mov	cx, 0D0Eh
	int	10h

	mov	ax, 4C00h	; Back to DOS
	int	21h
;Code EndS
;End Main

; --- Macros:

; ----------------------------------------------------------------------------
;Vars Segment Use16 Stack 'STACK'
;	Db 512 Dup (0)
;Vars EndS

; ----------------------------------------------------------------------------
;Data Segment Use16 Dword Public 'DATA'	;BM
;Assume Ds:Data

	strFormatted	Db '[x] - xxx - xx - xxxx xxxx'
	strHeader	Db 'Asc   Dec   Hex  Bin'
	strBlankLine	Db 80 Dup (20h)
	strAppName	Db 'ASCII Table'
	strNavigation	Db 'Up, Down, PgUp, PgDn, Home, End, Esc'

	; Every row contains 2 instances of 'strFormatted', so this
	; value needed to shift our ASCII code to format all 2.
	wASCIIofs	Dw 128	; 256/2
	wPageTop	Dw 0
	iRow dw 0
	iCol dw 0
	iAscii dw 0
	
;Data EndS

; ----------------------------------------------------------------------------
;Code Segment Use16 Dword Public 'CODE'
	;Assume Cs:Code
