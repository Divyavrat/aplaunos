; -----------------------------------------------------------------
; Program to display PCX images (320x200, 8-bit only)
; -----------------------------------------------------------------

os_print_splash:
	mov ax, splash_name
	mov cx, 1000h			; Load PCX at 1000h
	call os_load_file


	mov ah, 0			; Switch to graphics mode
	mov al, 13h
	int 10h


	mov ax, 0A000h			; ES = video memory
	mov es, ax


	mov si, 1080h			; Move source to start of image data
					; (First 80h bytes is header)

	xor di, di			; Start our loop at top of video RAM

.decode:
	mov cx, 1
	lodsb
	cmp al, 192			; Single pixel or string?
	jb .single
	and al, 63			; String, so 'mod 64' it
	mov cl, al			; Result in CL for following 'rep'
	lodsb				; Get byte to put on screen
.single:
	rep stosb			; And show it (or all of them)
	cmp di, 64001
	jb .decode


	mov dx, 3c8h			; Palette index register
	xor al, al			; Start at color 0
	out dx, al			; Tell VGA controller that...
	inc dx				; ...3c9h = palette data register

	mov cx, 768			; 256 colours, 3 bytes each
.setpal:
	lodsb				; Grab the next byte.
	shr al, 2			; Palettes divided by 4, so undo
	out dx, al			; Send to VGA controller
	loop .setpal

	mov ax, 20			; Pause for splash
	call os_pause

	mov ah, 0			; Back to text video mode
	mov al, 03h
	int 10h
	mov ax, 1003h			; No blinking text!
	int 10h

	mov ax, 2000h			; Reset ES back to original value
	mov es, ax

	call os_clear_screen
ret



; -----------------------------------------------------------------

	splash_name	db 'SPLASH  PCX', 0

; -----------------------------------------------------------------