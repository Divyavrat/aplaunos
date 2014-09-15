org 0x6000
use16
mov ah,0x11
int 0x61
ret
times 512-($-$$) db 0