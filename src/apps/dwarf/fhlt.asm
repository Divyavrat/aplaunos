org 0x6000
use16

mov si,haltstr
call prnstr

mainloop:
cli
hlt
jmp mainloop

mov si,failedstr
call prnstr

ret

printf:
pusha
mov ah,0x0E
int 0x10
popa
ret

prnstr:
lodsb
cmp al,0
je .end
call printf
jmp prnstr
.end:
ret

haltstr:
db 0x0D,0x0A,'System is Halted. Safe to turn off your computer. ',0
failedstr:
db 0x0D,0x0A,'Failed , Could not halt.',0

times 512-($-$$) db 0x90