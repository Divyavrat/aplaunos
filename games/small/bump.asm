org 0x6000
use16
pop ax
mov [return_loc],ax

mov ax,0x0013
int 10h

game_loop:
;mov bx,[player_x]
mov byte [color],0x4e

call player_draw
call monster_draw
call delay
xor bx,bx
mov [color],bl
call player_draw
call jump_action
call gravity
call monster_ai
call chkkey
jz game_loop
call getkey
call control
jmp game_loop

quit:
mov ax,0x0003
int 10h
jmp word [return_loc]

control:
cmp ah,0x48
je up_key
cmp ah,0x4b
je left_key
cmp ah,0x4d
je right_key
cmp ah,0x50
je down_key
cmp ah,0x01
je quit_key
ret
up_key:
cmp byte [jump_flag],0x0f
jne .up_done
not byte [jump_flag]
mov dx,[player_y]
mov [jump_pos],dx
.up_done:
ret
left_key:
;dec word [player_x]
sub word [player_x],3
ret
right_key:
;inc word [player_x]
add word [player_x],5
ret
down_key:
;inc word [player_y]
add word [player_y],5
ret
quit_key:
pop ax
jmp quit

getkey:
xor ah,ah
int 16h
ret
chkkey:
mov ah,0x01
int 0x16
ret

player_draw:
xor eax,eax
mov ax,[player_x]
mov [x1],eax
mov [x2],eax
mov ax,[player_y]
mov [y1],eax
mov [y2],eax

sub [x1],10
sub [y1],10
;mov byte al,[color]
;add bx,10
mov word [var_a],10
call bar
ret

monster_draw:
mov cx,[monster_x]
mov dx,[monster_y]
sub cx,10
sub dx,10
mov al,0x29

add cl,0x02
call dot
sub cl,0x04
call dot
add cl,0x02
add dl,0x02
call dot
sub dl,0x04
call dot
add dl,0x02
ret

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
        mov  eax,[ x1]
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
inc [x1]
inc [y1]
dec word [var_a]
cmp word [var_a],0
jg bar
ret

delay:
xor ah,ah
int 1ah
mov byte [var_a],dl
delay_loop:
xor ah,ah
int 1ah
cmp byte [var_a],dl
je delay_loop
ret

jump_action:
cmp byte [jump_flag],0x0f
je no_jump
sub word [player_y],0x0006
mov ax,[jump_pos]
sub ax,0x001C
cmp word [player_y],ax
jg no_jump
not byte [jump_flag]
no_jump:
ret

gravity:
cmp word [player_y],0x00ca
jge .under_ground
cmp word [player_y],0x00c7
jge .on_ground
;inc word [player_y]
add word [player_y],2
.on_ground:
ret
.under_ground:
mov word [player_y],0x00c7
ret

monster_ai:
mov ax,[player_x]
mov bx,[monster_x]
cmp ax,bx
jge .x_ok
xchg ax,bx
.x_ok:
xor dx,dx
div bx
mov dx,ax
mov ax,[player_x]
mov bx,[monster_x]
cmp ax,bx
jg .bigx
jl .smallx
jmp .y_update
.bigx:
add [monster_x],dx
jmp .y_update
.smallx:
;sub bx,dx
sub [monster_x],dx

.y_update:
mov ax,[player_y]
mov bx,[monster_y]
cmp ax,bx
jge .y_ok
xchg ax,bx
.y_ok:
xor dx,dx
div bx
mov dx,ax
mov ax,[player_y]
mov bx,[monster_y]
cmp ax,bx
jg .bigy
jl .smally
ret
.bigy:
add [monster_y],dx
ret
.smally:
sub [monster_y],dx
ret

return_loc:
dw 0
player_x:
dw 0x0030
player_y:
dw 0x00c0
monster_x:
dw 0x0030
monster_y:
dw 0x000c
jump_pos:
dw 0x0000
jump_flag:
db 0x0f

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
db 0x34
times (512*2)-($-$$) db 0x90