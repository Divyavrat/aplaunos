org 0x6000
use16
main:
mov ah,0x03
mov dx,message
int 0x61
mov ah,0x21
int 0x61
cmp dx,7
jg main
mov [command],dl
call kbd_wait
mov al,0xED
out 0x60,al
call kbd_wait
mov al,[command]
out 0x60,al
call kbd_wait
ret

kbd_wait:
jmp $+2
in al,64h
test al,1
jz .ok
jmp $+2
in al,60h
jmp kbd_wait
.ok:
test al,2
jnz kbd_wait
ret

command db 0
message:
db " Enter the keyboard command : ",0
times 512-($-$$) db 0