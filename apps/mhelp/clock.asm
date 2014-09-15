org 0x8000
use16
mov ah,0x0B
int 0x61
mov dx,helpstr
mov ah,0x03
int 0x61
ret
helpstr:
db "Clock doesn't stop until you press a key.",0
times (512)-($-$$) db 0