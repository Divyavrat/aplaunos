;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; define start address of program assembly (.com mode)
	org 0x6000

	; program is started here

	; prepare data access, set data segment identical to code segment
	mov AX, CS
	mov DS, AX

	; jump to main program
	jmp start


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; define data

	; some text strings, with line ends, 
	; terminated with '$' for output with DOS function 9
hello	db 'Hello',13,10,'$'
bye	db 'Bye',13,10,'$'
newline	db 13,10,'$'

	; data for some calculation
a	db 23h
b	db 85h
w	dw 89ABh

	; buffer for decimal conversion
	db 0,0,0,0,0	; reserve digits for word conversion (16 bits)
bufend	db '$'	; string terminator for DOS function 9


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; main program
start:
	; print Hello
	mov DX, hello
	call outstring

	; perform some simple example operations and output
	mov AX, 1234h
	call outhexAX
	call outnewline

	mov AX, [w]
	call outhexAX
	call outnewline

	mov AL, [a]
	add AL, [b]
	call outhexAL
	call outnewline

	mov AL, 135
	call outdecAL0
	call outnewline
	mov AL, 135
	call outdecAL1
	call outnewline
	mov AL, 135
	call outdecAL1
	call outnewline

	; print Bye
	mov DX, bye
	call outstring

finish:	; terminate program
	mov AH, 4Ch
	int 21h


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; text output routines

; outnewline: output line end (CR and LF)
outnewline:
	mov DX, newline
	; fall-through to outstring
	; v
	; v
; outstring: output string, terminated with '$'
; DX: string address
outstring:
	mov AH, 9	; DOS function 9: print a '$'-terminated string
	int 21h		; invoke DOS function
	ret

; outcharDL: output character
; DL: character
outcharDL:
	mov AH, 2	; DOS function 2: print a character from DL
	int 21h		; invoke DOS function
	ret


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; numeric output routines

; outhexAX: output word with 4 hex digits
; AX: word value for hex output
outhexAX:
	push AX		; save parameter for second byte
	mov AL, AH	; get first byte for output
	call outhexAL
	pop AX		; restore parameter
	; fall-through to outhexAL
	; v
	; v
; outhexAL: output byte with 2 hex digits
; AL: byte value for hex output
outhexAL:
	push AX		; save parameter
	mov DL, AL	; get parameter
	shr DL, 4	; extract higher 4 bits, move to lower bits
	call outhexDL4	; output them as a hexadecimal digit
	pop AX		; restore parameter
	mov DL, AL	; get parameter again, use lower 4 bits
	; fall-through to outhexDL4
	; v
	; v
; outhexDL4: output hex digit
; DL (bits 3..0): value for hex output
outhexDL4:
	and DL, 0Fh	; mask lower nibble; clear higher 4 bits to 0000
	cmp DL, 10	; check if decimal digit or hexadecimal (>= 10)
	jl outhexDL4_1	; if < 10, jump to skip the following
	add DL, 'A'-10-'0'	; add additional offset for hex. digits
outhexDL4_1:
	add DL, '0'	; add offset for ASCII digit characters
	jmp outcharDL	; continue with outcharDL, return from there


; outdecAL: output byte decimal, 3 versions
; AL: byte value for output
outdecAL0:
	mov AH, 0	; clear upper byte for division
	mov BL, 10	; prepare for division by 10
	div BL
	push AX
	mov DL,AH
	call outhexDL4
	pop AX
	cmp AL, 0
	jnz outdecAL0
	ret

outdecAL1:
	mov DI, bufend
outdecAL1loop:
	mov AH, 0	; clear upper byte for division
	mov BL, 10	; prepare for division by 10
	div BL
	mov DL,AH
	dec DI
	add DL, '0'
	mov [DI], DL
	cmp AL, 0
	jnz outdecAL1loop
	mov DX, DI
	jmp outstring


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; end of program assembly
	end
