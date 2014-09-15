org 0x6000
use16

mov si,restartstr
call prnstr
mov al,'1'
call printf

start:
in al,0x64
cmp al,0x02
je start
mov al,0xfe
out 0x64,al

mov si,restart2str
call prnstr
mov al,'2'
call printf

mov word [472h],1234h
jmp 0FFFFh:0

mov si,restart3str
call prnstr
mov al,'3'
call printf

int 0x19

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

restartstr:
db 0x0D,0x0A,'Restart by Normal Method ',0
restart2str:
db 0x0D,0x0A,'Restart by Forcible Restart Method ',0
restart3str:
db 0x0D,0x0A,'Restart by Soft Reset Method ',0
failedstr:
db 0x0D,0x0A,'Failed , APX not supported',0

times 512-($-$$) db 0x90