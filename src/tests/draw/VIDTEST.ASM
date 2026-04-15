org 0x6000
use16
pop ax
mov [return_loc],ax
mov ax , 0x0013
int 0x10
mov ah , 0x0c
mov cx,0x0000
mov dx,0x0000
mov bl,0
vstart:
mov al,cl
add al,bl
mov ah,0x0c
int 0x10
inc cl
cmp cl ,0xfd
jbe vstart
mov ch,0
mov cl,0
mov al,0
inc dl
cmp dl,198
jbe vstart
mov dl,0
mov dh,0
inc bl
cmp bl,60
jbe vstart
mov ax,0x0003
int 10h
jmp word [return_loc]

return_loc:
dw 0x0000
times (512*1)-($-$$) db 0