org 0x6000
use16
mov ah,0x80
mov dx,[loc]
int 0x61
mov ah,0x0B
int 0x61
;add word [loc],0x0075

hexloop:
mov bx,[loc]
add bx,[current]
add word [current],0x0002
;inc word [current]
mov dx,[bx]
;xchg dh,dl
push dx
shl dh,4
mov bl,dh
call printc
call printc
pop dx
push dx
or dh,0x0F
mov bl,dh
call printc
call printc
pop dx
push dx

shl dl,4
mov bl,dl
call printc
call printc
pop dx
;push dx
or dl,0x0F
mov bl,dl
call printc
call printc

;mov ah,0x24
;int 0x61
;cmp word [current],0x011F
cmp word [current],0x0194
;cmp word [current],0x023E
jle hexloop

mov ah,0x07
int 0x21


ret

printc:
pusha
mov cx,bx
push cx
mov ah,0x05
int 0x64
mov bh,dl
;xor bh,bh
pop cx
mov bl,cl
mov ah,0x09
mov al,' '
mov cx,0x0001
int 0x10
call getpos
inc dl
call setpos
popa
ret

getpos:
mov ah,0x30
int 0x61
ret

setpos:
;cmp dl,23
cmp dl,46
jge .col_g
jmp .done
.col_g:
xor dl,dl
inc dh
.done:
mov ah,0x31
int 0x61
ret

loc:
dw 0x7000
current:
dw 0x0076
;118 to 405
;0x76 to 0x0194 works
times 512-($-$$) db 0