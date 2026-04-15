org 0x6000
use16

c_play_f:
mov byte [player_y],0x0c
mov byte [player_x],0x00
mov byte [player2_y],0x0c
mov byte [player2_x],0x4f
mov byte [ball_y],0x0c
mov byte [ball_x],0x0c
mov byte [down_flag],0xf0
mov byte [right_flag],0xf0
mov byte [AI_flag],0xf0
mov word [var_a],0x0000
mov word [extra],0x0000
mov byte al,[color]
mov byte [color2],al
pop ax
mov [return_location],ax
mov ax,0x0003
int 0x10
mov ax,0x0500
int 10h
mov ch,0x20
mov ah,0x01
int 0x10
xor dx,dx
call setpos
play_loop:
call play2_draw
call play_draw
cmp byte [score],0xf0
jne score_off
call score_draw
score_off:
call ball_draw
xor dx,dx
call setpos_c
call delay
mov byte [color],0x00
call ball_draw
call play2_draw
call play_draw
mov byte al,[color2]
mov byte [color],al
call ball_update
call setpos_c

call chkkey
jz .continue_control

call getkey
cmp ah,0x01
je exit
cmp al,0x1b
je exit
cmp al,'`'
je exit
cmp ah,0x29
je exit
;cmp ah,0x12
;cmp ah,0x0f
;je switch_AI
cmp ah,0x3B ;F1
je AI_player_chance.help
cmp ah,0x3C
je switch_AI
cmp ah,0x3D
je AI_player_chance.color
cmp ah,0x3E
je AI_player_chance.switch_score
cmp ah,0x3F
je AI_player_chance.difficulty
cmp ah,0x40
je AI_player_chance.length
call keybsto

.continue_control:
cmp byte [AI_flag],0xF0
jne AI_player_chance
;je AI_play_loop
;jmp AI_player_chance
AI_play_loop:

mov byte al,[play_chance_flag]

cmp byte al,[difficulty]
jle AI_on
;jg AI_player_chance

AI_player_chance:
xor al,al
mov byte [play_chance_flag],al
xor dx,dx
call setpos
call chkkey
jz play_loop

.more_keys:

call getkey
cmp al,'e'
je play_clear
cmp ah,0x12
je play_clear
cmp ah,0x48
je player1_up
cmp ah,0x50
je player1_down

cmp byte [AI_flag],0xF0
je AI_on

cmp ah,0x11
je player2_up	;W
cmp ah,0x1f
je player2_down	;S

call chkkey
jnz .more_keys
jmp play_loop
.help:
mov dx,play_helpstr
mov bx,play_helpstr2
mov cx,play_helpstr3
mov ah,0x20
int 0x2B
call clean_screen
jmp AI_player_chance
.switch_score:
not byte [score]
call clean_screen
jmp AI_player_chance
.color:
mov dx,inputstr
mov bx,play_colorstr
mov ah,0x23
int 0x2B
mov dx,inputstr
mov ah,0x2b
int 0x61
mov [color],dl
;not dl
mov [color2],dl
call clean_screen
jmp AI_player_chance
.difficulty:
mov dx,inputstr
mov bx,play_diffstr
mov ah,0x23
int 0x2B
mov dx,inputstr
mov ah,0x2b
int 0x61
mov [difficulty],dl
call clean_screen
jmp AI_player_chance
.length:
mov dx,inputstr
mov bx,play_lenstr
mov ah,0x23
int 0x2B
mov dx,inputstr
mov ah,0x2b
int 0x61
mov [length],dl
call clean_screen
jmp AI_player_chance

AI_on:
call chkkey
jnz AI_player_chance.more_keys
jmp AI_play

switch_AI:
not byte [AI_flag]
jmp play_loop

player1_up:
mov dh,[player_y]
dec dh
mov [player_y],dh
jmp play_loop
player1_down:
mov dh,[player_y]
inc dh
mov [player_y],dh
jmp play_loop
player2_up:
mov dh,[player2_y]
dec dh
mov [player2_y],dh
jmp play_loop
player2_down:
mov dh,[player2_y]
inc dh
mov [player2_y],dh
jmp play_loop
play_clear:
call clean_screen
xor dx,dx
call setpos
jmp play_loop
;mov al,'e'
;mov ah,0x12
;call keybsto

AI_play:
inc al
mov byte [play_chance_flag],al
mov dh,[player2_y]
inc dh
cmp byte [ball_y],dh
jg AI_ball_ahead
jl AI_ball_behind
jmp AI_exit
AI_ball_ahead:
inc dh
jmp AI_exit
AI_ball_behind:
dec dh
jmp AI_exit

AI_exit:
dec dh
mov byte [player2_y],dh
jmp play_loop

play_draw:
mov cl,[length]
mov dl,[player_x]
mov dh,[player_y]
play_draw_loop:
call setpos_c
mov al,0xdb
call printf_c
dec cl
inc dh
cmp dh,0x19
jg play_loop_extra
cmp dh,0x01
jl play_loop_less
cmp cl,0x00
jg play_draw_loop
jmp play_loop_exit
play_loop_extra:
mov dh,0x19
sub dh,[length]
mov [player_y],dh
jmp play_loop
play_loop_less:
mov dh,0x00
mov [player_y],dh
jmp play_loop
play_loop_exit:
ret

play2_draw:
mov cl,[length]
mov dl,[player2_x]
mov dh,[player2_y]
play2_draw_loop:
call setpos_c
mov al,0xdb
call printf_c
dec cl
inc dh
cmp dh,0x19
jg play2_loop_extra
cmp dh,0x01
jl play2_loop_less
cmp cl,0x00
jg play2_draw_loop
jmp play2_loop_exit
play2_loop_extra:
mov dh,0x19
sub dh,[length]
mov [player2_y],dh
jmp play_loop
play2_loop_less:
mov dh,0x00
mov [player2_y],dh
jmp play_loop
play2_loop_exit:
ret

ball_draw:
mov dl,[ball_x]
mov dh,[ball_y]
inc dl
call setpos_c
mov al,0xdb
call printf_b
call printf_b
mov dl,[ball_x]
mov dh,[ball_y]
inc dh
call setpos_c
mov al,0xdb
call printf_b
call printf_b
call printf_b
call printf_b

mov dl,[ball_x]
mov dh,[ball_y]
add dh,2
call setpos_c
mov al,0xdb
call printf_b
call printf_b
call printf_b
call printf_b

mov dl,[ball_x]
mov dh,[ball_y]
add dh,3
inc dl
call setpos_c
mov al,0xdb
call printf_b
call printf_b
ret

ball_update:
mov dl,[ball_x]
mov dh,[ball_y]

cmp byte [down_flag],0xf0
jne ball_going_up
inc dh
jmp vertical_update_done
ball_going_up:
dec dh
vertical_update_done:

cmp byte [right_flag],0xf0
jne ball_going_left
inc dl
jmp horizontal_update_done
ball_going_left:
dec dl
horizontal_update_done:

cmp dl,0x4b
jg right_wall
cmp dl,0x01
jl left_wall
cmp dh,0x15
jg bottom_wall
cmp dh,0x01
jl top_wall

jmp bounds_done
left_wall:
mov byte ah,[player_y]
call play_check_collision
jnc left_wall_fine
inc word [extra]
left_wall_fine:
not byte [right_flag]
jmp bounds_done
right_wall:
mov byte ah,[player2_y]
call play_check_collision
jnc right_wall_fine
inc word [var_a]
right_wall_fine:
not byte [right_flag]
jmp bounds_done
bottom_wall:
mov dh,0x15
not byte [down_flag]
jmp bounds_done
top_wall:
mov dh,0x00
not byte [down_flag]
;jmp bounds_done
bounds_done:
mov byte [ball_x],dl
mov byte [ball_y],dh
ret

score_draw:
mov dx,0x1722
call setpos
mov word ax,[var_a]
call printwordh
mov al,':'
call printf_b
mov word ax,[extra]
call printwordh
ret

play_check_collision:
mov byte [XFLOW],dh
add dh,3
cmp dh,ah
jge coll_end_fine
jmp coll_detected
coll_end_fine:
sub dh,2
add byte ah,[length]
cmp dh,ah
jle coll_start_fine
jmp coll_detected
coll_start_fine:
mov byte dh,[XFLOW]
clc
ret
coll_detected:
mov byte dh,[XFLOW]
stc
ret

exit:
mov cx,0x0506
mov ah,0x01
int 0x10
jmp word [return_location]

printf:
pusha
xor bh,bh
mov ah,0x09
mov bl,[color]
mov cx,0x0001
int 0x10
call getpos
inc dl
call setpos
popa
ret

printf_c:
pusha
xor bh,bh
mov ah,0x09
mov bl,[color]
mov cx,0x0001
int 0x10
popa
ret

printf_b:
pusha
call printf_c
call getpos
inc dl
call setpos_c
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

printwordh:
push ax
mov al,ah
call printh
pop ax
call printh
ret

getpos:
mov ah,0x03
xor bh,bh
int 10h
ret

setpos:
cmp dl,0
jl update_pos_c_z
cmp dh,0
jl update_pos_r_z
cmp dh,24
jg update_pos_r
cmp dl,79
jg update_pos_c
jmp update_pos_e
update_pos_r_z:
xor dh,dh
jmp setpos
update_pos_c_z:
mov dl,79
dec dh
jmp setpos
update_pos_c:
inc dh
xor dl,dl
jmp setpos
update_pos_r:
;call scroll_down
mov dh,24
jmp setpos
update_pos_e:
mov ah,0x02
xor bh,bh

int 10h
ret

setpos_c:
mov ah,0x02
xor bh,bh
int 10h
ret

clean_screen:
mov ax,0x0600
mov ch,0x00
mov cl,0x00
mov dl,79
mov dh,24
mov bh,0x00
int 10h
ret

delay:
xor ah,ah
int 1ah
mov byte [comm],dl
delay_loop:
xor ah,ah
int 1ah
cmp byte [comm],dl
je delay_loop
ret

chkkey:
mov ah,0x11
;mov ah,0x01
int 0x16
ret

getkey:
call chkkey
jz getkey
mov ah,0x10
;xor ah,ah
int 0x16
;.skip:
ret

keybsto:
mov ch,ah
mov cl,al
mov ah,0x05
int 16h
ret

return_location:
dw 0x0500
difficulty:
db 0x00

length:
db 0x06
ball_x:
dw 0x000C
ball_y:
dw 0x000C
down_flag:
db 0xF0
right_flag:
db 0xF0
AI_flag:
db 0xF0
play_chance_flag:
dw 0x00F0
player_x:
dw 0x000A
player_y:
dw 0x000C
player2_x:
dw 0x0000
player2_y:
dw 0x0000

score:
db 0xf0

var_a:
dw 0x0000
extra:
dw 0x0000
comm:
dw 0x0000
XFLOW	db 0x00 

color:
db 49
color2:
db 49

play_helpstr: db 0x1B,0x18,0x19,0x1A,'-Player1, wasd-Player2,(Esc,~)-Close',0
play_helpstr2: db 'E-clrscr, F1-Help, F2-Player2 F3-Color',0
play_helpstr3: db 'F4-Score(ON/OFF) F5-Difficulty F6-Length ',0
play_diffstr: db 'Enter difficulty number (0-OFF)',0
play_lenstr: db 'Enter length of bats (6-DEFAULT)',0
play_colorstr: db 'Enter color (49-DEFAULT)',0
inputstr: times 40 db 0

times (512*3)-($-$$) db 0x90