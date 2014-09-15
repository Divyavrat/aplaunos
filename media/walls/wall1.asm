org 0x6000
use16

mov ah,0x06
int 0x61
xor dx,dx
mov ah,0x31
int 0x61

mov si,design
mov bx,0xB800
mov es,bx
xor bx,bx
mov cx,0x07D0
.loop:
lodsw
mov [es:bx],ax
add bx,2
loop .loop
xor bx,bx
mov es,bx
mov ah,0x50
int 0x61
ret

design:
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x2F20
times 80 dw 0x3F20
times 80 dw 0x4F20
times 80 dw 0x4F20
times 80 dw 0x4F20
times 80 dw 0x4F20
times 80 dw 0x2F20
times 80 dw 0x2F20
times 80 dw 0x2F20
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x3120
times 80 dw 0x4F20
times 80 dw 0x2F20
times 80 dw 0x4F20
times 80 dw 0x2F20
times 80 dw 0x4F20
times 80 dw 0x2F20

times (512*8)-($-$$) db 0