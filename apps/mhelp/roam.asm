org 0x8000
use16
mov ah,0x0B
int 0x61
mov dx,helpstr
mov ah,0x03
int 0x61
ret
helpstr:
db "Roam command lets you browse"
db " through dirs until you choose a file or app.",0
times (512)-($-$$) db 0