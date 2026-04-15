org 0x6000
use16

mov byte [color],0x4a

start:
mov ax,0x0013
int 0x10
mov ax,0x0500
int 10h
mov ch,0x20
mov ah,0x01
int 0x10

logo:
xor dx,dx
call setpos
mov cx,40
mov al,0x20
.loop:
call printf
loop .loop

xor dx,dx
call setpos
mov al,'>'
call printf
mov di,command
call getarg

mov si,command
mov di,c_exit
call cmpstr
jc exit_f

mov si,command
mov di,c_quit
call cmpstr
jc exit_f

mov si,command
mov di,c_bye
call cmpstr
jc exit_f

mov si,command
mov di,c_cls
call cmpstr
jc start

mov si,command
mov di,c_clear
call cmpstr
jc start

mov si,command
mov di,c_color
call cmpstr
jc c_color_f

mov si,command
mov di,c_dot
call cmpstr
jc c_dot_f

mov si,command
mov di,c_line
call cmpstr
jc c_line_f

mov si,command
mov di,c_bar
call cmpstr
jc c_bar_f

mov si,command
mov di,c_rect
call cmpstr
jc c_bar_f

jmp logo
;mov ah,0x01
;int 0x16
;jz logo
exit_f:
mov ax,0x0003
int 0x10
mov ax,0x0500
int 10h
mov dx,0x0a00
call setpos
mov cx,0x0506
mov ah,0x01
int 0x10
xor bx,bx
mov es,bx
ret

printf:
pusha
xor bh,bh
mov bl,[color]
mov ah,0x0E
int 0x10
popa
ret

printh:
push ax
shr al,4
cmp al,10
sbb al,69h
das
call printf
pop ax
ror al,4
shr al,4
cmp al,10
sbb al,69h
das
call printf
ret

getpos:
mov ah,0x03
xor bh,bh
int 0x10
ret

setpos:

mov ah,0x02
xor bh,bh

int 0x10
ret

getkey:
xor ah,ah
int 0x16
ret

getarg:
call getkey
call printf
cmp al,0x20
je .argf
cmp al,0x0d
je .argf
cmp ah,0x0e
je .argb
stosb
jmp getarg
.argb:
dec di
call getpos
inc dl
call setpos
call eraseback
call eraseback
call getpos
dec dl
call setpos
jmp getarg
.argf:
mov ax,0x0000
stosb
ret

cmpstr:
lodsb
mov bl,[di]
cmp al,bl
jne .nequal
;cmp al,dh
;je .cmpend
cmp al,0
je .cmpend
inc di
jmp cmpstr
.nequal:
clc
ret
.cmpend:
stc
ret

eraseback:
call getpos
dec dl
call setpos
mov al,0x20
call printf
ret

getno:
push bx
push cx
push dx
xor bx,bx
.getno_loop:
call getkey
call printf
cmp al,0x0D
je .getno2e
cmp al,0x20
je .getno2e
sub al,0x30
mov cl,al
mov ax,bx
mov dx,0x000a
mul dx
mov bx,ax
xor ch,ch
add bx,cx
jmp .getno_loop
.getno2e:
xor eax,eax
mov ax,bx
pop dx
pop cx
pop bx
ret

; delay:
; xor ah,ah
; int 1ah
; mov [wx],dl
; .delay_loop:
; xor ah,ah
; int 1ah
; cmp [wx],dl
; je .delay_loop
; ret

dot:
pusha
;mov ah,0x0c
;int 10h
mov bx,0xA000
mov es,bx
;mov bx,320
push ax
push cx
mov ax,320
mov cx,dx
xor dx,dx
mul cx
pop cx
mov bx,ax
add bx,cx
pop ax
mov [es:bx],al
xor dx,dx
mov es,dx
popa
ret

line:

        pushad                  ;this instruction pushes ALL the registers onto the stack

.x1_check:
cmp [x1],320
jge .x1_error
jmp .y1_check
.x1_error:
sub [x1],320
jmp .x1_check
.y1_check:
cmp [y1],200
jge .y1_error
jmp .x2_check
.y1_error:
sub [y1],200
jmp .y1_check
.x2_check:
cmp [x2],320
jge .x2_error
jmp .y2_check
.x2_error:
sub [x2],320
jmp .x2_check
.y2_check:
cmp [y2],200
jge .y2_error
jmp .fine
.y2_error:
sub [y2],200
jmp .y2_check
.fine:
		mov  ax, 0a000h
        mov  es, ax
        ;mov  ah, 0
        ;mov  al, 13h
        ;int  10h
        mov  cl, [color]          ;cl contains color thruout
        mov  eax, [x2]
        sub  eax,[x1]
        mov  [ddx], eax
        cmp  eax, 0
        jg   x2x1pos
        neg  eax
x2x1pos:
        mov  ebx, [y2]
        sub  ebx,[y1]
        mov  [ddy], ebx
        cmp  ebx, 0
        jg   y2y1pos
        neg  ebx
y2y1pos:
        cmp  eax, ebx
;       jl   ybigger

; The case where abs(x2-x1) >= abs(y2-y1)
        mov  [e], 0
        mov  eax,[x1]
        mov  [x], eax
        mov  eax, [y1]
        mov  [y], eax
again:
        mov  eax, [x]
        cmp  eax, [x2]
        jg   endloop
        mov  eax, [y]
        imul eax, 320
        add  eax, [x]
        mov  byte [es:eax], cl
        add  [x], 1
        mov  eax, [ddy]
        add  [e], eax
        mov  eax, [e]
        shl  eax, 1
        cmp  eax, [ddx]
        jl   again
        mov  eax, [ddx]
        sub  [e], eax
        add  [y], 1
        jmp  again

endloop:
        ;mov  ah, 1
        ;int  21h
        ;mov  ah, 0
        ;mov  al, 3
        ;int  10h
        popad                  ; this instruction pops all the registers from the stack in the reverse order employed by PUSHAD            
		xor ax,ax
		mov ds,ax
		mov es,ax
		ret
		
bar:
call line
inc [y1]
inc [y2]
dec word [var_a]
cmp word [var_a],0
jg bar
ret

gethex:
call getkey
call printf
call atohex
shl al,4
mov byte [var_a],al

call getkey
call printf
call atohex
mov byte ah,[var_a]
add al,ah
ret

atohex:
cmp al,0x3a
jle hex_num_found
cmp al,0x5a
jg hex_small_found
add al,0x20
hex_small_found:
sbb al,0x28
hex_num_found:
sbb al,0x2f
ret

c_color_f:
call gethex
mov [color],al
jmp logo

c_dot_f:
call getno
mov cx,ax
call getno
mov dx,ax
mov al,[color]
call dot
jmp logo

c_line_f:
call getno
mov [x1],eax
call getno
mov [y1],eax
call getno
mov [x2],eax
call getno
mov [y2],eax

call line
jmp logo

c_bar_f:
call getno
mov [x1],eax
call getno
mov [y1],eax
call getno
mov [x2],eax
call getno
mov [y2],eax
call getno
mov [var_a],ax

call bar
jmp logo

x1      dd  0
y1      dd  0
x2      dd  0
y2      dd  0
x       dd  ?
y       dd  ?
ddx     dd  ?
ddy     dd  ?
e       dd  ?

var_a:
dw 0
color:
db 0x31

c_exit:
db 'exit',0
c_quit:
db 'quit',0
c_bye:
db 'bye',0
c_cls:
db 'cls',0
c_clear:
db 'clear',0
c_color:
db 'color',0
c_dot:
db 'dot',0
c_line:
db 'line',0
c_bar:
db 'bar',0
c_rect:
db 'rect',0

command:
times 10 db 0

times (512*2)-($-$$) db 0x90