org 0x6000
use16
main:
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,start
int 0x61
.main_skipnewline:
mov ah,0x07
int 0x21
cmp al,'q'
je .quit
cmp al,'w'
je .play
cmp al,'i'
je .char
mov dl,al
mov ah,0x0e
int 0x61
jmp main
.quit:
pop ax
mov ah,0x0B
int 0x61
mov ax,0x4c00
int 0x21
.play:
mov ah,0x0D
mov dx,playstr
int 0x61
ret
.char:
mov ah,0x07
int 0x21
mov dl,al
mov ah,0x02
int 0x21
jmp .main_skipnewline
start:
db 'Press q-quit, w-play and any mint:',0
playstr:
db 'play ',0
times 512-($-$$) db 0