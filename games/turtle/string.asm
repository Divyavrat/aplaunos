	; String library
	; NAMESPACE: "string"
	string:

; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "putChar"
	; Places a character at the current cursor position and advances the cursor
	;
	; param:
	;	al = character to display at current position
	; destroyed:
	;	ah
macro string.putChar
{
	mov		ah, 0x0E
	int		0x10
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### PROC: "teletype"
	; Prints the string using the TTY interrupt feature, scrolling and advancing the cursor as needed.
	;
	; param:
	;	si = pointer to string, null terminated
macro string.teletype {
	.teletype:
		push	ax
		push	si
		
		mov		ah, 0x0E			; 0x10 - teletype output
	
	.teletype.nextChar:
		mov		al, [si]
		cmp		al, 0				; if char==0 then return
		jz		.teletype.return
		int		0x10				; write to screen
		inc		si					; next character
		jmp		.teletype.nextChar
	
	.teletype.return:
		pop		si
		pop		ax
		ret
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### PROC: "match"
	; Determines if the two strings are identical.
	;
	; param:
	;	si = pointer to primary string to be compared against, null terminated
	;	di = pointer to secondary string to be compared, null terminated
	; return:
	;	(flag) carry = set if match, clear if not.
macro string.match {
	.match:
		push	ax
		push	si
		push	di
		
	.match.nextChar:
		mov		ah, [si]
		mov		al, [di]
		cmp		ah, al				; if char1 != char2 then goto notEqual
		jne		.match.notEqual
		cmp		al, 0				; elseif char2==0 then goto equal (end of strings)
		je		.match.equal
		inc		si					; else next character
		inc		di					; ...
		jmp		.match.nextChar
		
	.match.notEqual:
		clc
		jmp		.match.return
		
	.match.equal:
		stc
		jmp		.match.return
		
	.match.return:
		pop		di
		pop		si
		pop		ax
		ret
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### PROC: "getLength"
	; Determines the length of the string in number of characters, excluding the null termination character
	;
	; param:
	;	si = pointer to string, null terminated
	; return:
	;	al = number of characters
macro string.getLength {
	.getLength:
		push	si
		mov		al, 0
		
	.getLength.nextChar:
		mov		ah, [si]
		cmp		ah, 0				; if char==0 then goto return
		je		.getLength.return
		inc		al					; else charCount++
		inc		si					; next character
		jmp		.getLength.nextChar
		
	.getLength.return:
		pop		si
		ret
}
	
	
; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### PROC: "reverse"
	; Reverses the string, so that the last character is first and vice versa.
	;
	; param:
	;	si = pointer to string, null terminated
	;	di = pointer to new string destination
	; return
	;	di = pointer to new string, null terminated
macro string.reverse {
	.reverse:
		push	ax
		push	cx
		push	si
		push	di
		
		xor		cx, cx				; clear cx for use as for-loop counter
		
	.reverse.gotoEnd:				; count number of characters in source string, excluding null terminator
		mov		al, [si]
		cmp		al, 0
		je		.reverse.nextChar.setup
		inc		si
		inc		cl
		jmp		.reverse.gotoEnd
	
	.reverse.nextChar.setup:
		dec		si					; character before null terminator
		
	.reverse.nextChar:				; for (i=getLength(si); i>0; i--)
		mov		al, [si]			; [di] <== [si]
		mov		[di], al
		dec		si					; next character
		inc		di
		loop	.reverse.nextChar
		
	.reverse.appendTerminator:
		mov		[di], byte 0		; add null terminator to the end
		
	.reverse.return:
		pop		di
		pop		si
		pop		cx
		pop		ax
		ret
}
	
	
; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### PROC: "numberToString"
	; Translates a number into a null terminated string value
	;
	; param:
	;	ax = number
	;	di = pointer to new string destination
	; return:
	;	di = pointer to new string, null terminated
macro string.numberToString {
	.numberToString:
		push	ax
		push	bx
		push	dx
		push	si
		push	di
		
		mov		bx, 10				; constant used to divide by
		mov		si, .numberToString.rawString
									; sandbox area for reversing string before returning it
		xor		dx, dx				; clear dx for doubleword division
		
		cmp		ax, 0				; if (number==0) then goto numberIsZero
		jz		.numberToString.numberIsZero
		jmp		.numberToString.extractLeastSignificant
									; else goto extractLeastSignificant
		
	.numberToString.numberIsZero:
		mov		[di], byte '0'		; set string to '0'
		inc		di
		mov		[di], byte 0		; append null terminator ... and return
		jmp		.numberToString.return
	
	.numberToString.extractLeastSignificant:
		div		bx					; ax=ax/10, dx=remainder -- remainder will be the least significant number off the rest of it
		
		add		dl, 48				; convert single digit remainder into ASCII code
		mov		[si], dl			; write character to string
		inc		si
		mov		dl, 0				; sanitize dl before dividing again
		
		cmp		ax, 0				; a quotient of 0 means that there are no more numbers to extract
		jz		.numberToString.flipString
		jmp		.numberToString.extractLeastSignificant
	
	.numberToString.flipString:
		mov		[si], byte 0		; append null terminator
		mov		si, .numberToString.rawString
									; si = pointer to sandbox area, di = destination passed by program
		call	.reverse			; reverse it!
	
	.numberToString.return:
		pop		di
		pop		si
		pop		dx
		pop		bx
		pop		ax
		ret
	
	.numberToString.rawString:
		db		6 dup (0)
}
	
