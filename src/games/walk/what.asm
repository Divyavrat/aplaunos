org 0x8000
use16
mov ah,0x0B
int 0x61
mov dx,showstr
mov ah,0x03
int 0x61
ret
showstr:
db " A Cow is a four legged animal"
db " that roams the common land"
db " eating grass, leaves, etc.",0
times (512)-($-$$) db 0