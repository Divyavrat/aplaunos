org 0x6000
use16

main:
cmp si,0
je .exit_q
push si
mov ax,si
mov bx,0x6000
call os_write_file
jnc .true
mov ah,0x0E
mov al,'F'
int 0x10
pop si
.exit_q:
ret
.true:
mov ah,0x0E
mov al,'T'
int 0x10
pop si
ret

%include "mikedev.inc"

times (512*1)-($-$$) db 0