org 0x6000
use16

mov ax,0x0003
int 10h
mov ah,0x02
int 0x64
mov [.tempcolor],dl
mov dl,0x0f
mov ah,0x01
int 61h
mov ch,0x20
mov ah,0x01
int 0x10
.loop:

call getcount
.loopstar:
push cx
call star
pop cx
loop .loopstar

mov ah,0x01
int 0x16
jnz .done

call getcount
.loopantistar:
push cx
call antistar
pop cx
loop .loopantistar

mov ah,0x01
int 0x16
jnz .done

jmp .loop
.done:
mov cx,0x0506
mov ah,0x01
int 0x10
mov dl,[.tempcolor]
mov ah,0x01
int 61h
ret
.tempcolor: db 0x31

reset:
mov ah,0x17
mov dx,1
mov bx,80
int 0x61
push cx
mov ah,0x17
mov dx,1
mov bx,23
int 0x61
mov dh,cl
pop cx
mov dl,cl
mov ah,0x31
int 0x61
ret

printf:
pusha
mov ah,0x09
xor bh,bh
mov cx,1
mov bl,0x0F
int 10h
popa
ret

delay:
pusha
mov ah,0x09
int 61h
mov ah,0x09
int 61h
mov ah,0x09
int 61h
popa
ret

star:
call reset
mov si,starlist
mov cx,6
cld
.loop:
lodsb
call printf
call delay
loop .loop
ret

antistar:
call reset
mov si,antistarlist
mov cx,6
.loop:
dec si
mov al,[si]
call printf
call delay
loop .loop
ret

getcount:
mov ah,0x17
mov dx,1
mov bx,4
int 0x61
ret

starlist:
db 0,0xFA,0xF9,0x07,0x2A,0x0F
antistarlist:

times 512-($-$$) db 0