org 0x6000
use16

mov si,helpstr
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

helpstr:
db ' Help - {head,track},{load,save},{size,drive,loc},run,type,cls',0

times 512-($-$$) db 0x90