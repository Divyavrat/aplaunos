org 0x6000
use16

mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,textstr
int 0x61

mov cx,0xffff
.loop:
push cx
;mov ah,0x0B
;int 0x61
mov dx,cx
mov ah,0x19
int 0x61
mov ah,0x24
int 0x61
pop cx
mov ah,0x01
int 0x16
jnz .closeloop
loop .loop
.closeloop:
ret

textstr:
db "Sounds :",0

times 512-($-$$) db 0x90