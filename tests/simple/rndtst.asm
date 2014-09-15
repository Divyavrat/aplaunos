org 0x6000
use16

mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,textstr
int 0x61

mov cx,10
.loop:
push cx
mov ah,0x0B
int 0x61
mov dx,0
mov bx,0x0fff
mov ah,0x17
int 0x61
push dx
mov ah,0x24
int 0x61
mov ah,0x02
mov dl,':'
int 0x21
pop dx
mov ah,0x20
int 0x61
pop cx
loop .loop
ret

textstr:
db "Ten random numbers :",0

times 512-($-$$) db 0x90