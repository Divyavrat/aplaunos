org 0x6000
use16
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,currentstr
int 0x61
mov ah,0x13
int 0x61
mov ah,0x24
int 0x61
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,stackstr
int 0x61
mov ah,0x23
int 0x61
mov [stackloc+1],dl
mov ah,0x23
int 0x61
mov [stackloc],dl
mov ah,0x12
mov dx,[stackloc]
int 0x61
ret
stackloc:
dw 0x8000
currentstr:
db 'Current stack location : ',0
stackstr:
db 'Where your stack should be located (e.g. 7000)  : ',0
times 512-($-$$) db 0