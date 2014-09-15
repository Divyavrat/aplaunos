use16
org 0x6000
pop ax
mov [return_loc],ax

mov ax,0x0013
int 10h

mov word [player_x],0x0030
mov word [player_y],0x00c0
mov word [player2_x],0x0040
mov word [player2_y],0x00c0
mov word [monster_x],0x0030
mov word [monster_y],0x000c
mov word [eraser_x],0x0060
mov word [eraser_y],0x000c
mov word [score],0x0000
mov word [packet_x],0x00a0
mov word [packet_y],0x0064
mov byte [mov_flag],0x4d
mov byte [mov2_flag],0x11

game_loop:

call show_score
call bounds
mov cx,[player_x]
mov dx,[player_y]
call player_draw
mov cx,[player2_x]
mov dx,[player2_y]
call player_draw
call monster_draw
call eraser_draw
call packet_draw
call delay
call move_action
call monster_ai
call eraser_ai
call packet_check
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
cmp ah,0x01
je quit_key
cmp ah,0x11
je mov2_key
cmp ah,0x1E
je mov2_key
cmp ah,0x1F
je mov2_key
cmp ah,0x20
je mov2_key
jmp mov_key
ret

mov2_key:
mov [mov2_flag],ah
ret
mov_key:
mov [mov_flag],ah
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

bounds:
mov ax,[player_x]
cmp ax,0x0140
jge .bounds_player_x
cmp ax,0x0000
jl .bounds_player_x_small
mov ax,[player_y]
cmp ax,0x00c8
jge .bounds_player_y
cmp ax,0x0000
jl .bounds_player_y_small
mov ax,[player2_x]
cmp ax,0x0140
jge .bounds_player2_x
cmp ax,0x0000
jl .bounds_player2_x_small
mov ax,[player2_y]
cmp ax,0x00c8
jge .bounds_player2_y
cmp ax,0x0000
jl .bounds_player2_y_small
mov ax,[packet_x]
sub ax,0x0005
cmp ax,0x013b
jge .bounds_packet_x
mov ax,[packet_y]
sub ax,0x0005
cmp ax,0x00c3
jge .bounds_packet_y
ret
.bounds_player_x:
sub word [player_x],0x0140
jmp bounds
.bounds_player_y:
sub word [player_y],0x00c8
jmp bounds
.bounds_player_x_small:
add word [player_x],0x0140
jmp bounds
.bounds_player_y_small:
add word [player_y],0x00c8
jmp bounds
.bounds_player2_x:
sub word [player2_x],0x0140
jmp bounds
.bounds_player2_y:
sub word [player2_y],0x00c8
jmp bounds
.bounds_player2_x_small:
add word [player2_x],0x0140
jmp bounds
.bounds_player2_y_small:
add word [player2_y],0x00c8
jmp bounds
.bounds_packet_x:
sub word [packet_x],0x013b
jmp bounds
.bounds_packet_y:
sub word [packet_y],0x00c3
jmp bounds

show_score:
xor dx,dx
call setpos
mov ax,[score]
call printwordh
ret

player_draw:
mov al,cl
add al,[mov_flag]
call dot
inc cx
call dot
sub cl,0x02
call dot
inc cx
inc dx
call dot
sub dl,0x02
call dot
inc dx
ret

monster_draw:
mov cx,[monster_x]
mov dx,[monster_y]
mov byte al,[monster_y]
call dot
add cl,0x02
call dot
sub cl,0x04
call dot
add cl,0x02
add dl,0x02
call dot
sub dl,0x04
call dot
;add dl,0x02
ret

eraser_draw:
mov cx,[eraser_x]
mov dx,[eraser_y]
;mov al,cl
;add al,dl
mov al,0
call dot
inc cx
call dot
inc dx
call dot
inc cx
call dot
inc dx
call dot
ret

packet_draw:
mov cx,[packet_x]
mov dx,[packet_y]
mov al,0x0f
call dot
mov bx,0x05
call bar
ret

dot:
mov ah,0x0c
int 10h
ret

line_x:
call dot
dec bx
inc cx
cmp bx,0x0000
jg line_x
ret

line_y:
call dot
dec bx
inc dx
cmp bx,0x0000
jg line_y
ret

bar:
mov [var_a],bx
bar_loop:
push bx
push cx
mov bx,[var_a]
call line_x
pop cx
pop bx
dec bx
inc dx
cmp bx,0x0000
jg bar_loop
ret

delay:
call clock
mov byte [var_a],dl
delay_loop:
call clock
cmp byte [var_a],dl
je delay_loop
ret

move_action:
mov si,player_x
mov di,player_y
mov cx,[player_x]
mov dx,[player_y]
mov al,dl
mov ah,1
call move_action_main
mov si,player2_x
mov di,player2_y
mov cx,[player2_x]
mov dx,[player2_y]
mov al,dl
mov ah,2
call move_action_main
ret

move_action_main:
mov bx,0x0003
cmp ah,2
je move2_action_main
cmp byte [mov_flag],0x48
je mov_up
cmp byte [mov_flag],0x4b
je mov_left
cmp byte [mov_flag],0x4d
je mov_right
cmp byte [mov_flag],0x50
je mov_down
ret
move2_action_main:
cmp byte [mov2_flag],0x11
je mov_up
cmp byte [mov2_flag],0x1E
je mov_left
cmp byte [mov2_flag],0x1F
je mov_down
cmp byte [mov2_flag],0x20
je mov_right
ret
mov_up:
call line_y
dec word [di]
dec word [di]
ret
mov_left:
call line_x
dec word [si]
dec word [si]
ret
mov_right:
inc word [si]
inc word [si]
call line_x
ret
mov_down:
inc word [di]
inc word [di]
call line_y
ret

monster_ai:
mov cx,[monster_x]
mov dx,[monster_y]
mov bx,monster_ai_y
cmp [player_x],cx
jg mon_right
jl mon_left
monster_ai_y:
mov bx,monster2_ai_y
cmp [player_y],dx
jg mon_down
jl mon_up
monster2_ai_y:
mov bx,monster2_ai_x
cmp [player2_y],dx
jg mon_down
jl mon_up
monster2_ai_x:
mov bx,monster_done
cmp [player2_x],cx
jg mon_right
jl mon_left
monster_done:
ret
mon_up:
dec word [monster_y]
jmp bx
mon_left:
dec word [monster_x]
jmp bx
mon_right:
inc word [monster_x]
jmp bx
mon_down:
inc word [monster_y]
jmp bx

eraser_ai:
call clock
dec word [eraser_x]
cmp dl,0x15
jl ers_up
cmp dl,0x27
jl ers_left
cmp dl,0x40
jl ers_right
jmp ers_down
ers_up:
sub word [eraser_y],5
ret
ers_left:
dec word [eraser_x]
ret
ers_right:
add word [eraser_x],2
ret
ers_down:
add word [eraser_y],3
ret

packet_check:
mov ax,[player_x]
mov bx,[player_y]
call packet_check_main
mov ax,[player2_x]
mov bx,[player2_y]
call packet_check_main
ret
packet_check_main:
mov cx,[packet_x]
mov dx,[packet_y]
cmp ax,cx
jge packet_x_big
ret
packet_x_big:
add cx,0x0005
cmp ax,cx
jle packet_x_small
ret
packet_x_small:
cmp bx,dx
jge packet_y_big
ret
packet_y_big:
add dx,0x0005
cmp bx,dx
jle packet_y_small
ret
packet_y_small:
inc word [score]
call clock
mov ax,dx
mov [packet_x],al
mul ah
mov [packet_y],al
ret

getpos:
mov ah,0x03
xor bh,bh
int 10h
ret

setpos:
mov ah,0x02
xor bh,bh
int 10h
ret

printf:
xor bh,bh
mov ah,0x09
mov bl,0x0f
mov cx,0x0001
int 10h
call getpos
inc dl
call setpos
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

printwordh:
push ax
mov al,ah
call printh
pop ax
call printh
ret

clock:
xor ah,ah
int 1ah
ret

return_loc:
dw 0x0000
player_x:
dw 0x0000
player_y:
dw 0x0000
player2_x:
dw 0x0000
player2_y:
dw 0x0000
monster_x:
dw 0x0000
monster_y:
dw 0x0000
eraser_x:
dw 0x0000
eraser_y:
dw 0x0000
packet_x:
dw 0x0000
packet_y:
dw 0x0000
score:
dw 0x0000
mov_flag:
db 0x00
mov2_flag:
db 0x00
var_a:
db 0x00
times (512*2)-($-$$) db 0