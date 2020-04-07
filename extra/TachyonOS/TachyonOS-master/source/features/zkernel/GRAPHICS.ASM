; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; GRAPHICS ROUTINES
; ==================================================================

os_text_mode:
	; Put the operating system in text mode (mode 03h)
	pusha
	
	mov ax, 3			; Back to text mode
	mov bx, 0
	int 10h
	mov ax, 1003h			; No blinking text!
	int 10h

	inc byte [gs:internal_call]
	call os_add_custom_icons
	dec byte [gs:internal_call]
	
	popa
	jmp os_return
	

os_add_custom_icons:
	pusha
	push es

	mov ax, 1000h
	mov es, ax

	mov ax, 1110h
	mov bh, 10h
	mov bl, 0
	mov cx, 7
	mov dx, 128
	mov bp, icon_start
	int 10h

	pop es
	popa
	jmp os_return
		

os_graphics_mode:
	; Put the operating system in graphical mode (mode 13h)
	push ax
	mov ah, 0			; Switch to graphics mode
	mov al, 13h
	int 10h
	pop ax
	jmp os_return
	
; Change the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved

os_set_pixel:
	pusha

	cmp ax, 320
	jge .out_of_range
	
	cmp cx, 200
	jge .out_of_range
	
	mov dx, cx
	mov cx, ax
	mov ah, 0Ch
	mov al, bl
	xor bx, bx
	int 10h
.out_of_range:
	popa
	jmp os_return
	
	
; Get the the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved
os_get_pixel:
	pusha
	
	push 1000h
	pop ds
	
	mov dx, cx
	mov cx, ax
	mov ah, 0Dh
	xor bx, bx
	int 10h
	mov byte [.pixel], al
	popa
	mov bl, [.pixel]
	jmp os_return
	
	.pixel				db 0
	
	
; Implementation of Bresenham's line algorithm. Translated from an implementation in C (http://www.edepot.com/linebresenham.html)
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour
; OUT: None, registers preserved
os_draw_line:
	pusha				; Save parameters
	
	mov ax, 1000h
	mov ds, ax
	mov es, ax
	inc byte [internal_call]
	
	xor ax, ax			; Clear variables
	mov di, .x1
	mov cx, 11
	rep stosw
	
	popa				; Restore and save parameters
	pusha
	
	mov [.x1], cx			; Save points
	mov [.x], cx
	mov [.y1], dx
	mov [.y], dx
	mov [.x2], si
	mov [.y2], di
	
	mov [.colour], bl		; Save the colour
	
	mov bx, [.x2]
	mov ax, [.x1]
	cmp bx, ax
	jl .x1gtx2
	
	sub bx, ax
	mov [.dx], bx
	mov ax, 1
	mov [.incx], ax
	jmp .test2
	
.x1gtx2:
	sub ax, bx
	mov [.dx], ax
	mov ax, -1
	mov [.incx], ax
	
.test2:
	mov bx, [.y2]
	mov ax, [.y1]
	cmp bx, ax
	jl .y1gty2
	
	sub bx, ax
	mov [.dy], bx
	mov ax, 1
	mov [.incy], ax
	jmp .test3
	
.y1gty2:
	sub ax, bx
	mov [.dy], ax
	mov ax, -1
	mov [.incy], ax
	
.test3:
	mov bx, [.dx]
	mov ax, [.dy]
	cmp bx, ax
	jl .dygtdx
	
	mov ax, [.dy]
	shl ax, 1
	mov [.dy], ax
	
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dx], bx
	
.xloop:
	mov ax, [.x]
	mov bx, [.x2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .xloop1
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	mov ax, [.balance]
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
.xloop1:
	mov ax, [.balance]
	mov bx, [.dy]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	jmp .xloop
	
.dygtdx:
	mov ax, [.dx]
	shl ax, 1
	mov [.dx], ax
	
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dy], bx
	
.yloop:
	mov ax, [.y]
	mov bx, [.y2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .yloop1
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	mov ax, [.balance]
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
.yloop1:
	mov ax, [.balance]
	mov bx, [.dx]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	jmp .yloop
	
.done:
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	popa
	dec byte [internal_call]
	jmp os_return
	
	
	.x1 dw 0
	.y1 dw 0
	.x2 dw 0
	.y2 dw 0
	
	.x dw 0
	.y dw 0
	.dx dw 0
	.dy dw 0
	.incx dw 0
	.incy dw 0
	.balance dw 0
	.colour db 0
	.pad db 0
	
; Draw (straight) rectangle
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour, CF = set if filled or clear if not
; OUT: None, registers preserved
os_draw_rectangle:
	pusha
	pushf
	
	mov ax, 1000h
	mov ds, ax
	mov es, ax
	
	inc byte [internal_call]
	
	mov word [.x1], cx
	mov word [.y1], dx
	mov word [.x2], si
	mov word [.y2], di
	
	; top line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y1]
	call os_draw_line
	
	; left line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x1]
	mov di, [.y2]
	call os_draw_line
	
	; right line
	mov cx, [.x2]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line

	; bottom line
	mov cx, [.x1]
	mov dx, [.y2]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line
	
	popf
	jnc .finished_fill
	
.fill_shape:
	inc word [.y1]
	
	mov ax, [.y1]
	cmp ax, [.y2]
	jge .finished_fill
	
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y1]
	call os_draw_line
	
	jmp .fill_shape
	
.finished_fill:
	popa
	dec byte [internal_call]
	jmp os_return
	
	.x1				dw 0
	.x2				dw 0
	.y1				dw 0
	.y2				dw 0

; Draw freeform shape
; IN: BH = number of points, BL = colour, SI = location of shape points data
; OUT: None, registers preserved
; DATA FORMAT: x1, y1, x2, y2, x3, y3, etc
os_draw_polygon:
	pusha
	
	mov ax, 1000h
	mov ds, ax
	mov es, ax
	
	inc byte [internal_call]
	
	dec bh
	mov byte [.points], bh
	
	mov word ax, [fs:si]
	add si, 2
	mov word [.xi], ax
	mov word [.xl], ax
	
	mov word ax, [fs:si]
	add si, 2
	mov word [.yi], ax
	mov word [.yl], ax
	
	.draw_points:
		mov cx, [.xl]
		mov dx, [.yl]
		
		mov word ax, [fs:si]
		add si, 2
		mov word [.xl], ax
		
		mov word ax, [fs:si]
		add si, 2
		mov word [.yl], ax
		
		push si
		
		mov si, [.xl]
		mov di, [.yl]
		
		call os_draw_line
		
		pop si
		
		dec byte [.points]
		cmp byte [.points], 0
		jne .draw_points
		
	mov cx, [.xl]
	mov dx, [.yl]
	mov si, [.xi]
	mov di, [.yi]
	call os_draw_line
	
	popa
	dec byte [internal_call]
	jmp os_return
	
	.xi				dw 0
	.yi				dw 0
	.xl				dw 0
	.yl				dw 0
	.points				db 0
	

; Clear the screen by setting all pixels to a single colour
; BL = colour to set
os_clear_graphics:
	pusha
	
	mov ax, 0xA000
	mov es, ax

	mov al, bl
	mov di, 0
	mov cx, 64000
	rep stosb

	popa
	jmp os_return
	
	
; ----------------------------------------
; os_draw_circle -- draw a circular shape
; IN: AL = colour, BX = radius, CX = middle X, DX = middle y

os_draw_circle:
	pusha

	push gs
	pop ds
	
	inc byte [internal_call]

	mov [.colour], al
	mov [.radius], bx
	mov [.x0], cx
	mov [.y0], dx

	mov [.x], bx
	mov word [.y], 0
	mov ax, 1
	shl bx, 1
	sub ax, bx
	mov [.xChange], ax
	mov word [.yChange], 0
	mov word [.radiusError], 0

.next_point:
	mov cx, [.x]
	mov dx, [.y]
	cmp cx, dx
	jl .finish

	;ax bx - function points
	;cx = x 
	;dx = y
	;si = -x
	;di = -y

	mov si, cx
	xor si, 0xFFFF
	inc si
	mov di, dx
	xor di, 0xFFFF
	inc di

	; (x + x0, y + y0)
	mov ax, cx
	mov bx, dx
	call .draw_point

	; (y + x0, x + y0)
	xchg ax, bx
	call .draw_point

	; (-x + x0, y + y0)
	mov ax, si
	mov bx, dx
	call .draw_point

	; (-y + x0, x + y0)
	mov ax, di
	mov bx, cx
	call .draw_point

	; (-x + x0, -y + y0)
	mov ax, si
	mov bx, di
	call .draw_point

	; (-y + x0, -x + y0)
	xchg ax, bx
	call .draw_point

	; (x + x0, -y + y0)
	mov ax, cx
	mov bx, di
	call .draw_point

	; (y + x0, -x + y0)
	mov ax, dx
	mov bx, si
	call .draw_point
	
	inc word [.y]
	mov ax, [.yChange]
	add [.radiusError], ax
	add word [.yChange], 2
	
	mov ax, [.radiusError]
	shl ax, 1
	add ax, [.xChange]
	
	cmp ax, 0
	jle .next_point
	
	dec word [.x]
	mov ax, [.xChange]
	add [.radiusError], ax
	add word [.xChange], 2

	jmp .next_point

.draw_point:
	; AX = X, BX = Y
	pusha
	add ax, [.x0]
	add bx, [.y0]
	mov cx, bx
	mov bl, [.colour]
	call os_set_pixel
	popa
	ret
	
.finish:
	popa
	dec byte [internal_call]
	jmp os_return
	


.colour				db 0
.x0				dw 0
.y0				dw 0
.radius				dw 0
.x				dw 0
.y				dw 0
.xChange			dw 0
.yChange			dw 0
.radiusError			dw 0
