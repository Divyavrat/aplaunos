[BITS 16]
[ORG 100h]

section .text
global _start
	_start:

	call load_bmp
	call parse_header
	; call read_palette
	push es
	call vga_init
	; call load_palette
	call display_bmp2

	; mov ax, 0 ; 0 puts the pixel in the top left corner
	; mov di, ax
	; mov dl, 2 ; grey color
	; mov [es:di], dl ; put a pixel on the screen
	pop es

	@exitloop:
		mov ah, 1h ; wait for keypress
		int 21h
		cmp al, 27 ; if 'ESC'
		jne @exitloop

	@exit:
		call exit


; initialized data
section .data
	invalid_bmp_error: db "Image is not a valid bitmap file",13,10,'$'
	file_close_error: db "Error closing file",13,10,'$'
	file_open_error: db "Error opening file",13,10,'$'
	file_read_error: db "Error reading file",13,10,'$'
	file_success: db "File successfully opened",13,10,'$'
	file: db "C:\IMAGE3.BMP",0

	; load the BMP palette into a variable that will serve as a buffer
	read_palette:
		mov ah,3fh
		mov cx, [palette_size] ; number of colors in palette
		shl cx, 2
		; mov dx, palette_buffer
		mov dx, palette_buffer ; read the palette into the buffer
		int 21h
		ret

	; color values in BMP files are saved as 'BGR' instead of 'RGB'
	load_palette:
		mov si, palette_buffer
		lea cx, [palette_size]
		mov dx, 3c8h
		mov al, 0 ; out port 3c8h
		out dx, al
		inc dx ; so that dx = 3c9h

		; @palette_loop:
		; 	mov al, [si+2] ; get red value
		; 	shr al, 2 ; since the max is 255, but DOS only allows values 
		; 			  ; of up to 63, dividing by 4 gives a proper value
		; 	out dx, al
		; 	mov al,[si+1]	; get green value
		; 	shr al,2
		; 	out dx,al
		; 	mov al,[si] ; get blue value
		; 	shr al, 2
		; 	out dx, al

		; 	add si, 4 ; point to next color (compensate for null character after every color)
		; 	loop @palette_loop
		ret

	; load the bitmap file
	load_bmp:
		; file loading sequence
		lea dx, [file]
		mov ah,3dh ; call DOS interrupt 'OPEN'
		int 21h
		jnc @load ; check carry flag
			lea dx, [file_open_error]
			call print
			jmp @to_exit
		@load: ; file is open, now continue reading the file
			mov [filehndl], ax
			mov bx, ax
			mov ah, 3fh ; call DOS interrupt 'READ'
			mov cx, 15h 
			mov dx, buf
			int 21h
			jnc @file ; check carry flag
				lea dx, [file_read_error]
				call print
				jmp @to_exit
		@file: ; the file has been read successfully
			lea dx, [file_success]
			call print

			xor ebx, ebx
			mov bx, [filehndl]
			mov ah, 3Eh ; call DOS interrupt 'CLOSE'
			int 21h
			jnc @to_return ; check carry flag
				lea dx, [file_close_error]
				call print
				jmp @to_exit

		@to_exit:
			call exit

		@to_return:
			ret

	; extract important data from the header
	parse_header:
		; validate the BMP file
		mov dl, [buf]
		cmp dl, 'B'
		jne invalid_bmp
		mov dl, [buf+1]
		cmp dl, 'M'
		jne invalid_bmp
		mov ebx, dword[buf+0Ah] ; the offset of the start of the image data (as 4 bytes at offset 000Ah)
		mov dword[bmp_offset], ebx
		sub bx, 54 ; substract the length of the header (54?)
		shr bx, 2
		mov word[palette_size], ax

		mov eax, [buf+ebx]
		mov dword[bmp_img_start], eax

		; read heigth and width from the DIB header
		mov ebx, dword[buf+12h] ; image width (as 4 bytes at offset 012h)
		mov dword[bmp_width], ebx

		mov eax, dword[buf+16h] ; image height (as 4 bytes at offset 016h)
		mov dword[bmp_height], eax
		ret

	display_bmp2:
		mov cx, bmp_height
		mov bx, filehndl
		@nextline:
			push cx

			mov cx, bmp_width


			mov al, 27h
			rep stosb ; store al at [es:edi]

			; ; read a line
			; mov ah, 3fh
			; mov cx, bmp_width
			; mov dx, [bmp_line]
			; int 21h 

			; cld
			; mov si, bmp_line
			; rep movsb ; movbyte in [ds:esi] at [es:edi]

			pop cx
		loop @nextline
		ret

	invalid_bmp:
		mov dx, invalid_bmp_error
		call print
		ret

	; print the contents of edx
	print:
		mov ah, 9h
		int 21h  ; call DOS interrupt 'WRITE STR'
		ret

	; initialize the graphics mode
	vga_init:
		mov ax, 13h ; change video mode to VGA (320x200, 8bit color)
		int 10h
		mov ax, 0A000h ; move offset to video memory into es
		mov es, ax
		ret

	; return control of the program to DOS
	exit:
		mov ax, 03h ; reset video to mode 3
		int 10h
		mov ah,4ch ; back to DOS
		int 21h
		ret

; uninitialized data
section .bss
	filehndl: resw 1h
	bmp_offset: resd 1h
	bmp_file_size: resd 1h
	bmp_raw_size: resd 1h
	bmp_img_size: resd 1h
	bmp_img_start: resd 1h
	bmp_width: resd 1h
	bmp_height: resd 1h
	buf: resb 15
	bmp_line: resb 320
	palette_size: resw 1h
	palette_buffer: resd 1024
