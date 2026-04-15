org 0x6000
use16

mov si,reloadstr
call prnstr
mov ah,0x00
int 0x16

mov bx,ds
mov es,bx
mov ax,0x0201
mov cx,0x0001
mov dx,0x0000
mov bx,0x7C00
stc
int 0x13
jnc .done
mov dl,0x80
stc
int 0x13
.done:
jmp 0x7C00

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

reloadstr:
db 0x0D,0x0A,' Press any key to reload the OS :: ',0

times 512-($-$$) db 0x90