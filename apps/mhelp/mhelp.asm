org 0x6000
use16
start:
mov word [pos],0
call newline
mov dx,helpstr
call prnstr
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
mov dx,c_file
int 0x61
mov [strlen],dx
mov bx,c_file
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundfile

mov ah,0x33
mov dx,c_app
int 0x61
mov [strlen],dx
mov bx,c_app
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundapp

mov ah,0x33
mov dx,c_batch
int 0x61
mov [strlen],dx
mov bx,c_batch
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .foundbatch

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
call prnstr
jmp start
.key:
cmp ah,0x01
je .foundexit
jmp start
.foundfile:
call newline
mov dx,filestr
call prnstr
jmp start
.foundbatch:
call newline
mov dx,batchstr
call prnstr
jmp .foundmicro
.foundapp:
call newline
mov dx,appstr
call prnstr
.foundmicro:
call newline
mov dx,microhelp
call prnstr
jmp start
.foundexit:
ret
newline:
mov ah,0x0B
int 0x61
ret
prnstr:
mov ah,0x03
int 0x61
ret

helpstr:
db 'file, app, batch, bye,close,quit,exit, clock, alarm, roam, pipe :',0
filestr:
db 'Define a file name using - fname and then search'
db ' the current directory using - q command .'
db ' This will load the file at current location (loc).',0
appstr:
db 'Just load an app like any other file and run it.',0
batchstr:
db 'Just load a batch file like any other file and run it.',0
microhelp:
db ' Or you can just mention its name like - pwd and'
db ' this will search the current directory for a COM or a BAT file'
db ' named pwd and accordingly run it or batch it.',0
notfoundstr:
db 'NotFound',0
c_file:
db 'file',0
c_app:
db 'app',0
c_batch:
db 'batch',0
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
times (512*2)-($-$$) db 0