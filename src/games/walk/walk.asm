org 0x6000
use16
start:
mov word [pos],0
call newline
mov dx,helpstr
mov ah,0x03
int 0x61
mov dx,[loc]
mov ah,0x04
int 0x61
mov ah,0x33
mov dx,[loc]
int 0x61
mov [strlen],dx
mov di,[loc]
add di,[strlen]
mov cx,0x0200
.clearbuffer:
xor al,al
stosb
loop .clearbuffer
.cmploop:
mov ah,0x06
mov dl,0xff
int 0x21
cmp dl,0x0f
jne .key

mov ah,0x33
mov dx,c_hy
int 0x61
mov [strlen],dx
mov bx,c_hy
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundhy

mov ah,0x33
mov dx,c_bye
int 0x61
mov [strlen],dx
mov bx,c_bye
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundexit

mov ah,0x33
mov dx,c_close
int 0x61
mov [strlen],dx
mov bx,c_close
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundexit

mov ah,0x33
mov dx,c_quit
int 0x61
mov [strlen],dx
mov bx,c_quit
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundexit

mov ah,0x33
mov dx,c_exit
int 0x61
mov [strlen],dx
mov bx,c_exit
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundexit

inc word [pos]
cmp word [pos],0x0200
jl .cmploop

mov ah,0x33
mov dx,[loc]
int 0x61
mov [strlen],dx

mov di,[loc]
add di,[strlen]
dec di
mov al,'.'
stosb
mov al,'C'
stosb
mov al,'O'
stosb
mov al,'M'
stosb

mov dx,[loc]
mov ah,0x3d
int 0x21

cmp dx,0xf0f0
jne .notfound
call ax
jmp start
.notfound:
mov dx,notfoundstr
mov ah,0x03
int 0x61
jmp start
.key:
cmp ah,0x01
je .foundexit
jmp start
.foundhy:
call newline
mov dx,hystr
mov ah,0x03
int 0x61
jmp start
.foundexit:
ret
newline:
mov ah,0x0B
int 0x61
ret
helpstr:
db ' Talk to me : ',0
hystr:
db " Hy , Greetings , Wha'sup!! ",0
notfoundstr:
db "I didn't understand that.",0
c_hy:
db 'hy',0
c_bye:
db 'bye',0
c_close:
db 'close',0
c_quit:
db 'quit',0
c_exit:
db 'exit',0
loc:
dw 0x7000
pos:
dw 0
strlen:
dw 0
times (512)-($-$$) db 0