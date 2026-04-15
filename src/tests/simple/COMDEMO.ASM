
; fasm example of writing 16-bit COM program

	org	0x6000			; code starts at offset 100h
	use16				; use 16-bit code

	;push cs
	;pop ds
	
	mov	ah,9;display_text
	mov	dx,hello
	int	0x21

	mov ah,7
	int 0x21
	
	int	0x20
	
;display_text = 9
hello db 'Hello world!',24h