org 0x6000
use16
mov ah,0x80
mov dx,[loc]
int 0x61
;mov dx,0x8000
;mov cx,0x0200
;mov ah,0x14
;int 0x61

read:
mov ah,0x32
int 0x61
mov [var_x],al
cmp al,0x0f
je .set_tele_skip
mov ah,0x08
int 0x61
.set_tele_skip:
mov ah,0x0B
int 0x61
call getpos
dec dh
call setpos
mov ah,0x01
int 0x64
xor ax,ax
mov al,dl
xor dx,dx
mov [var_a],dx
mov bx,0x200
mul bx
mov [var_b],ax
.read_loop:
mov si,[loc]
add si,[var_a]
.loop:
lodsb
cmp al,0x09
je .tab
call printf
inc word [var_a]
mov dx,[var_a]
cmp dx,[var_b]
jge .filedone
call getpos
cmp dh,24
jge .bottom
jmp .loop
.bottom:
call getpos
push dx
xor dl,dl
call setpos
call space
mov si,posstr
call prnstr
mov al,':'
call printf

mov ax,[var_a]
call printwordh
mov al,'/'
call printf
mov ax,[var_b]
call printwordh
call space
call space
mov ax,[var_a]
xor dx,dx
mov bx,100
mul bx
mov bx,[var_b]
div bx
mov dx,ax
mov ah,0x20
int 0x61
mov al,'%'
call printf
call space
pop dx
.control:
mov ah,0x07
int 0x21
cmp ah,0x01
je .filedone
cmp ah,0x29
je .filedone
cmp ah,0x1C
je .pagedown
cmp ah,0x51
je .pagedown
cmp ah,0x47
je .pageup
cmp ah,0x49
je .pageup
cmp ah,0x3C
je .jump
cmp ah,0x3D
je .jump
cmp ah,0x3B
je .help
push dx
call getpos
xor dl,dl
call setpos

mov al,0x20
mov cx,0x4f
.clloop:
call printf
dec cx
cmp cx,0
jge .clloop
call color_switch
mov dx,var_p
mov cx,1
mov ah,0x14
int 0x61
call color_switch
call getpos
sub dl,0x50
call setpos

mov ah,0x16
int 0x61

mov ah,0x04
int 0x64
mov bl,dl
pop dx
mov dh,0x16
sub dl,bl
inc dl
call setpos
jmp .read_loop
.filedone:
mov al,[var_x]
cmp al,0x0f
je .set_tele_back
mov ah,0x08
int 0x61
.set_tele_back:
ret
.help:
mov dx,read_helpstr
xor ah,ah
int 61h
jmp .control
.jump:
mov si,jmpstr
call prnstr
call gethex
mov bx,var_a
inc bx
mov [bx],al
call gethex
dec bx
mov [bx],al
jmp .pagedown
.pageup:
mov dx,[var_a]
sub dx,0x07D0
mov [var_a],dx
.pagedown:
mov ah,0x06
int 0x61
xor dx,dx
call setpos
jmp .read_loop
.tab:
mov cl,0x06
xor ch,ch
mov al,0x20
.tabloop:
call printf
dec cx
cmp cx,0
jg .tabloop
jmp .loop

space:
mov al,0x20
call printf
ret

printf:
mov dl,al
mov ah,0x02
int 0x21
ret

printwordh:
mov dx,ax
mov ah,0x24
int 0x61
ret

getpos:
mov ah,0x30
int 0x61
ret

setpos:
mov ah,0x31
int 0x61
ret

prnstr:
mov dx,si
mov ah,0x03
int 0x61
ret

gethex:
mov ah,0x23
int 0x61
mov al,dl
ret

color_switch:
mov ah,0x02
int 0x64
mov [var_y],dl
mov ah,0x03
int 0x64
mov [var_z],dl
mov ah,0x01
int 0x61
mov dl,[var_y]
mov ah,0x02
int 0x61
ret

read_helpstr:
db 'Enter,PgDwn Home,PgUp F123',0
posstr:
db 'pos',0
jmpstr:
db 'jmp:',0
loc:
dw 0x8000
var_a:
dw 0
var_b:
dw 0
var_x:
db 0
var_y:
db 0
var_z:
db 0
var_p:
db 0
times 512-($-$$) db 0