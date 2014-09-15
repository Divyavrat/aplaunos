org 0x6000
use16
mov ah,0x0D
mov dx,autorun
int 61h
ret
autorun:
db 't e fhlt ',0
times 512-($-$$) db 0