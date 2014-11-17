org 0x6000
use16

;======================
; LOGO
; ----

; Draw lines and circles
; on a 320x200 playground.
; Check out lots of colours too.
;======================

mov byte [color],0x4a

start:
mov ax,0x0013
int 0x10
mov ax,0x0500
int 10h
mov ch,0x20
mov ah,0x01
int 0x10

logo:
xor dx,dx
call setpos
mov cx,40
mov al,0x20
.loop:
call printf
loop .loop

xor dx,dx
call setpos
mov al,'>'
call printf
mov di,command
call getarg

mov si,command
mov di,c_exit
call cmpstr
jc exit_f

mov si,command
mov di,c_quit
call cmpstr
jc exit_f

mov si,command
mov di,c_bye
call cmpstr
jc exit_f

mov si,command
mov di,c_circle
call cmpstr
jc c_circle_f

mov si,command
mov di,c_cls
call cmpstr
jc start

mov si,command
mov di,c_help
call cmpstr
jc c_help_f

mov si,command
mov di,c_clear
call cmpstr
jc c_clear_f

mov si,command
mov di,c_color
call cmpstr
jc c_color_f

mov si,command
mov di,c_dot
call cmpstr
jc c_dot_f

mov si,command
mov di,c_line
call cmpstr
jc c_line_f

mov si,command
mov di,c_bar
call cmpstr
jc c_bar_f

mov si,command
mov di,c_rect
call cmpstr
jc c_rect_f

mov si,command
mov di,c_poly
call cmpstr
jc c_polygon_f

mov si,command
mov di,c_polygon
call cmpstr
jc c_polygon_f

jmp logo
;mov ah,0x01
;int 0x16
;jz logo
exit_f:
mov ax,0x0003
int 0x10
mov ax,0x0500
int 10h
mov dx,0x0a00
call setpos
mov cx,0x0506
mov ah,0x01
int 0x10
xor bx,bx
mov es,bx
ret

printf:
pusha
xor bh,bh
mov bl,[color]
mov ah,0x0E
int 0x10
popa
ret

printh:
push ax
shr al,4
cmp al,10
sbb al,69h
das
call printf
pop ax
ror al,4
shr al,4
cmp al,10
sbb al,69h
das
call printf
ret

getpos:
mov ah,0x03
xor bh,bh
int 0x10
ret

setpos:

mov ah,0x02
xor bh,bh

int 0x10
ret

getkey:
xor ah,ah
int 0x16
ret

getarg:
call getkey
call printf
cmp al,0x20
je .argf
cmp al,0x0d
je .argf
cmp ah,0x0e
je .argb
stosb
jmp getarg
.argb:
dec di
call getpos
inc dl
call setpos
call eraseback
call eraseback
call getpos
dec dl
call setpos
jmp getarg
.argf:
mov ax,0x0000
stosb
ret

cmpstr:
lodsb
mov bl,[di]
cmp al,bl
jne .nequal
;cmp al,dh
;je .cmpend
cmp al,0
je .cmpend
inc di
jmp cmpstr
.nequal:
clc
ret
.cmpend:
stc
ret

eraseback:
call getpos
dec dl
call setpos
mov al,0x20
call printf
ret

getno:
push bx
push cx
push dx
xor bx,bx
.getno_loop:
call getkey
call printf
cmp al,0x0D
je .getno2e
cmp al,0x20
je .getno2e
sub al,0x30
mov cl,al
mov ax,bx
mov dx,0x000a
mul dx
mov bx,ax
xor ch,ch
add bx,cx
jmp .getno_loop
.getno2e:
xor eax,eax
mov ax,bx
pop dx
pop cx
pop bx
ret

; delay:
; xor ah,ah
; int 1ah
; mov [wx],dl
; .delay_loop:
; xor ah,ah
; int 1ah
; cmp [wx],dl
; je .delay_loop
; ret

os_set_pixel:
pusha
mov dx,cx
mov cx,ax
mov al,bl
;mov ah,0x0c
;int 10h
mov bx,0xA000
mov es,bx
;mov bx,320
push ax
push cx
mov ax,320
mov cx,dx
xor dx,dx
mul cx
pop cx
mov bx,ax
add bx,cx
pop ax
mov [es:bx],al
xor dx,dx
mov es,dx
popa
jmp os_return

; Change the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved

; os_set_pixel:
	; pusha

	; cmp ax, 320
	; jge .out_of_range
	
	; cmp cx, 200
	; jge .out_of_range
	
	; mov dx, cx
	; mov cx, ax
	; mov ah, 0Ch
	; mov al, bl
	; xor bx, bx
	; int 10h
; .out_of_range:
	; popa
	; jmp os_return
	
	
; Get the the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved
; os_get_pixel:
	; pusha
	
	; ;push 1000h
	; ;pop ds
	
	; mov dx, cx
	; mov cx, ax
	; mov ah, 0Dh
	; xor bx, bx
	; int 10h
	; mov byte [.pixel], al
	; popa
	; mov bl, [.pixel]
	; jmp os_return
	
	; .pixel				db 0
	
	
; Implementation of Bresenham's line algorithm. Translated from an implementation in C (http://www.edepot.com/linebresenham.html)
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour
; OUT: None, registers preserved
os_draw_line:
	pusha				; Save parameters
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	;inc byte [internal_call]
	
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
	;dec byte [internal_call]
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
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	
	;inc byte [internal_call]
	
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
	;dec byte [internal_call]
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
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	
	;inc byte [internal_call]
	
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
	;dec byte [internal_call]
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

	;push gs
	;pop ds
	
	;inc byte [internal_call]

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
	cmp cx, dx
	jl .finish

	;ax bx - function points
	;cx = x 
	;dx = y
	;si = -x
	;di = -y

	mov cx, [.x]
	mov dx, [.y]
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
	
	mov cx, [.x]
	mov dx, [.y]
	
	cmp ax, 0
	jle .next_point
	
	dec word [.x]
	mov ax, [.xChange]
	add [.radiusError], ax
	add word [.xChange], 2

	mov cx, [.x]
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
	;dec byte [internal_call]
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

os_return:
xor ax,ax
mov ds,ax
mov es,ax
ret

gethex:
call getkey
call printf
call atohex
shl al,4
mov byte [var_a],al

call getkey
call printf
call atohex
mov byte ah,[var_a]
add al,ah
ret

atohex:
cmp al,0x3a
jle hex_num_found
cmp al,0x5a
jg hex_small_found
add al,0x20
hex_small_found:
sbb al,0x28
hex_num_found:
sbb al,0x2f
ret

c_circle_f:
call getno
mov ecx,eax
call getno
mov edx,eax
call getno
mov ebx,eax
mov al,[color]

call os_draw_circle
jmp logo

c_clear_f:
call getno
mov ebx,eax
call os_clear_graphics
jmp logo

c_color_f:
call gethex
mov [color],al
jmp logo

c_help_f:
mov dx,0
call setpos
mov si,help_str
call prnstr
call getkey
jmp logo

prnstr:
lodsb
cmp al,0
je prnstr_quit
call printf
jmp prnstr
prnstr_quit:
ret

c_dot_f:
call getno
;mov cx,ax
push ax
call getno
mov cx,ax
pop ax
mov bl,[color]
call os_set_pixel
jmp logo

c_line_f:
call getno
;mov [x1],eax
mov ecx,eax
call getno
;mov [y1],eax
mov edx,eax
call getno
;mov [x2],eax
mov esi,eax
call getno
;mov [y2],eax
mov edi,eax

mov bl,[color]
call os_draw_line
jmp logo

c_bar_f:
call getno
;mov [x1],eax
mov ecx,eax
call getno
;mov [y1],eax
mov edx,eax
call getno
;mov [x2],eax
mov esi,eax
call getno
;mov [y2],eax
mov edi,eax
;call getno
;mov [var_a],ax
stc
mov bl,[color]

;call bar
call os_draw_rectangle
jmp logo

c_rect_f:
call getno
mov ecx,eax
call getno
mov edx,eax
call getno
mov esi,eax
call getno
mov edi,eax
clc
mov bl,[color]
call os_draw_rectangle
jmp logo

c_polygon_f:
call getno
mov bh,al
mov bl,al
mov di,command
pusha
mov bh,0
mov cx,bx
.loop:
call getno
stosw
call getno
stosw
loop .loop
popa
mov si,command
mov bl,[color]
call os_draw_polygon
jmp logo

; x1      dd  0
; y1      dd  0
; x2      dd  0
; y2      dd  0
; x       dd  ?
; y       dd  ?
; ddx     dd  ?
; ddy     dd  ?
; e       dd  ?

var_a:
db 0
color:
db 0x31

c_exit:
db 'exit',0
c_quit:
db 'quit',0
c_bye:
db 'bye',0
c_cls:
db 'cls',0
c_help:
db 'help',0

c_clear:
db 'clear',0
c_color:
db 'color',0
c_dot:
db 'dot',0
c_line:
db 'line',0
c_circle:
db 'circle',0
c_bar:
db 'bar',0
c_rect:
db 'rect',0
c_poly:
db 'poly',0
c_polygon:
db 'polygon',0

help_str:
db "dot,line,circle,rect,poly,color,cls",0

command:
times 10 db 0

times (512*4)-($-$$) db 0x90