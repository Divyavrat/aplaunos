org 0x6000
use16
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,currentstr
int 0x61
mov ah,0x13
int 0x61
push dx
mov ah,0x24
int 0x61
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,currentitemstr
int 0x61
pop bx
push bx
dec bx
mov dl,[bx]
push dx
mov ah,0x22
int 0x61
mov ah,0x02
mov dl,':'
int 0x21
pop dx
mov ah,0x02
int 0x21
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,enterstr
int 0x61
mov ah,0x23
int 0x61
pop bx
mov [bx],dl
inc bx
mov ah,0x12
mov dx,bx
int 0x61
ret
stackloc:
dw 0x8000
currentstr:
db 'Current stack location : ',0
currentitemstr:
db 'Currently this is on top : ',0
enterstr:
db 'Enter byte of hexadecimal number to push ( e.g. D5 ) : ',0
times 512-($-$$) db 0