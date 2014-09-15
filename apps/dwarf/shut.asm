org 0x6000
use16

mov si,shuttingstr
call prnstr
mov al,'1'
call printf

xor bx,bx
mov cx,0x0102
mov ax,0x530e
int 0x15
mov cx,0x0003
mov bx,0x0001
mov ax,0x5307
int 0x15

mov si,shuttingstr
call prnstr
mov al,'2'
call printf

xor bx,bx
mov ax,0x5301
int 0x15
xor bx,bx
mov cx,0x0102
mov ax,0x530e
int 0x15
mov cx,0x0003
mov bx,0x0001
mov ax,0x5307
int 0x15

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

shuttingstr:
db 0x0D,0x0A,'Shutting down by Method ',0
failedstr:
db 0x0D,0x0A,'Failed , APX not supported',0

times 512-($-$$) db 0x90