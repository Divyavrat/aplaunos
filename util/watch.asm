org 0x6000
use16

mov ax,0x0003
int 0x10
mov ax,0x0500
int 10h
mov ch,0x20
mov ah,0x01
int 0x10
watch:
mov byte [color],0x11
call getpos
mov dx,0x0301
call setpos
call time
call space
call newline
call space
call date
call space
call newline
call space
call timer
mov ax,0x0E20
int 0x10
int 0x10

;mov bx,0x0F38
;add bl,dl
;sub bl,dh
;add bh,bl

mov ah,0x02
int 0x1a
mov al,ch
call bcd2hex
mov ch,al
call convert
add bh,0x14
push bx
mov dx,0x320D
;push dx
call line

mov ah,0x02
int 0x1a
mov al,cl
call bcd2hex
xor ah,ah
mov cl,0x05
div cl
mov ch,al
call convert
add bh,0x14
push bx
mov dx,0x320D
mov byte [color],0x45
call line

mov ah,0x02
int 0x1a
mov al,dh
call bcd2hex
xor ah,ah
mov cl,0x05
div cl
mov ch,al
call convert
add bh,0x14
push bx
mov dx,0x320D
mov byte [color],0x34
call line

xor cx,cx
mov byte [color],0x0f
.board:
push cx
mov ch,cl
call convert
add bh,0x14
xchg bh,bl
mov dx,bx
call setpos
pop cx
;push cx
mov ax,cx
add al,0x30
call printc
;pop cx
inc cx
cmp cx,12
jl .board

call delay
mov byte [color],0x00
mov dx,0x320D
pop bx
call line
mov dx,0x320D
pop bx
call line
mov dx,0x320D
pop bx
call line

mov ah,0x01
int 0x16
jz watch
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
mov ah,0x0E
int 0x10
popa
ret

printc:
;mov al,0x20
;printf:
pusha
xor bh,bh
mov ah,0x09
mov bl,[color]
mov cx,0x0001
int 0x10
;call getpos
;inc dl
;call setpos
popa
ret

colon:
mov al,':'
call printf
ret

space:
mov al,' '
call printf
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

newline:
mov al,0x0D
call printf
mov al,0x0A
call printf
ret

date:
mov ah,0x04
int 0x1a
mov al,dl
call printh
call colon
mov al,dh
call printh
call colon
mov al,ch
call printh
;call colon
mov al,cl
call printh
ret

time:
mov ah,0x02
int 0x1a
mov al,ch
call printh
call colon
mov al,cl
call printh
call colon
mov al,dh
call printh
ret

timer:
;mov ah,0x00
xor ah,ah
int 0x1a
mov al,ch
call printh
call colon
mov al,cl
call printh
call colon
mov al,dh
call printh
call colon
mov al,dl
call printh
ret

getpos:
mov ah,0x03
xor bh,bh
int 10h
ret

setpos:

mov ah,0x02
xor bh,bh

int 10h
ret

delay:
xor ah,ah
int 1ah
mov [wx],dl
.delay_loop:
xor ah,ah
int 1ah
cmp [wx],dl
je .delay_loop
ret

line:
mov [x],bh
mov [y],bl
;mov [x1],bh
;mov [y1],bl
mov [x2],dh
mov [y2],dl

mov ch,0
mov cl,bh
mov dh,0
mov dl,bl

mov ah,0
mov al,[x2]
mov si,ax
mov ah,0
mov al,[y2]
mov di,ax
mov bl,[color]
call os_draw_line
;call delay
ret

; Change the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved

os_set_pixel:
pusha
mov dl,al
mov dh,cl
mov [color],bl
call setpos
mov al,0x20
call printc
popa
ret

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
	ret
	
	
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

convert:
cmp ch,0x00
je .h12
cmp ch,0x01
je .h1
cmp ch,0x02
je .h2
cmp ch,0x03
je .h3
cmp ch,0x04
je .h4
cmp ch,0x05
je .h5
cmp ch,0x06
je .h6
cmp ch,0x07
je .h7
cmp ch,0x08
je .h8
cmp ch,0x09
je .h9
cmp ch,0x0A
je .h10
cmp ch,0x0B
je .h11
mov byte [color],0x23
sub ch,12
jmp convert
.h1:
mov bx,0x2106
ret
.h2:
mov bx,0x250A
ret
.h3:
mov bx,0x280D
ret
.h4:
mov bx,0x2510
ret
.h5:
mov bx,0x2114
ret
.h6:
mov bx,0x1E17
ret
.h7:
mov bx,0x1B14
ret
.h8:
mov bx,0x1710
ret
.h9:
mov bx,0x140D
ret
.h10:
mov bx,0x170A
ret
.h11:
mov bx,0x1B06
ret
.h12:
mov bx,0x1E03
ret

bcd2hex:
mov bl,al
and al,0xF0
ror al,4

mov cl,0x0A
mul cl
and bl,0x0F
add al,bl
ret

x:
db 0x00
y:
db 0x00
;x1:
;db 0x00
;y1:
;db 0x00
x2:
db 0x00
y2:
db 0x00
wx:
db 0x00
wy:
db 0x00
eps:
db 0x00
color:
db 0x31

times (512*3)-($-$$) db 0x90