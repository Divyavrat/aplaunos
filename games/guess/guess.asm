; guess.asm: Guessing game program. 
; User is asked to guess which letter the program 'knows'
; Author: Joe Carthy
; Date: March 1994

		;.model small
		;.stack 100h

		CR equ 13d
		LF equ 10d

		;.data

		;.code
		org 0x6000

start:

		;mov ax, @data
		;mov ds, ax

		mov ax,prompt
		call puts ; prompt for input

		call getc ; read character 

		cmp al, 'A'
		jne is_not_an_a ; if (al != 'A') skip action

		mov ax, yes_msg ; if action
		call puts ; display correct guess 
		jmp end_else1 ; skip else action

is_not_an_a: 					; else action

		mov ax, no_msg
		call puts ; display wrong guess 

end_else1:

finish: 	
		mov ax, 4c00h
		int 21h

; User defined subprograms

puts: 		; display a string terminated by $
			; dx contains address of string

		push ax ; save ax
		push bx ; save bx 
		push cx ; save cx
		push dx ; save dx

		mov dx, ax
		mov ah, 9h
		int 21h ; call ms-dos to output string

		pop dx ; restore dx
		pop cx ; restore cx
		pop bx ; restore bx
		pop ax ; restore ax

		ret

putc: ; display character in al

		push ax ; save ax
		push bx ; save bx 
		push cx ; save cx
		push dx ; save dx

		mov dl, al
		mov ah, 2h
		int 21h

		pop dx ; restore dx
		pop cx ; restore cx
		pop bx ; restore bx
		pop ax ; restore ax
		ret

getc: 	; read character into al

		push bx ; save bx 
		push cx ; save cx
		push dx ; save dx

		mov ah, 1h
		int 21h

		pop dx ; restore dx
		pop cx ; restore cx
		pop bx ; restore bx
		ret


		;end start

prompt db "Guessing game: Enter a letter (A to Z): $"
yes_msg db CR, LF, "You guessed correctly !! $" 
no_msg db CR, LF,  "Sorry incorrect guess $" 