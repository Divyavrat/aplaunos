org 0x6000
use16

code:
call newline
mov si,mainstr
call prnstr

call getkey

cmp ah,0x01
je exit
cmp ah,0x3c
je load_command
cmp ah,0x3e
je save_f
cmp ah,0x1c
je editor

jmp code

exit:
ret

load_command:
call newline
mov si,enterstr
call prnstr
call gethex
mov [drive],al
mov al,':'
call printf
call gethex
mov [head],al
mov al,':'
call printf
call gethex
mov [track],al
mov al,':'
call printf
call gethex
mov [sector],al
mov al,':'
call printf
call load_f

jmp code

editor:
call newline

mov word [current],0x0000
mov si,[loc]
mov cx,0x0200
.loop:
lodsb
call printh
inc word [current]
loop .loop

control:
call chkkey
jz control
cmp ah,0x01
je .quit
cmp ah,0x48
je move_up
cmp ah,0x4B
je move_left
cmp ah,0x4D
je move_right
cmp ah,0x50
je move_down

call gethex
mov bx,[loc]
add bx,[current]
mov [bx],al
inc word [current]

jmp control

.quit:
call getkey
jmp code

move_up:
call getkey
call getpos
dec dh
sub word [current],40
call setpos
jmp control

move_left:
call getkey
call getpos
sub dl,2
dec word [current]
call setpos
jmp control

move_right:
call getkey
call getpos
add dl,2
inc word [current]
call setpos
jmp control

move_down:
call getkey
call getpos
inc dh
add word [current],40
call setpos
jmp control

printf:
pusha
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

prnstr:
lodsb
cmp al,0
je .end
call printf
jmp prnstr
.end:
ret

gethex:
call getkey
call printf
call atohex
shl al,4
mov bl,al
push bx

call getkey
call printf
call atohex
pop bx
add al,bl
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

chkkey:
mov ah,0x01
int 0x16
ret

getkey:
xor ah,ah
int 0x16
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

;pusha
;mov ax,0x0601
;xor cx,cx
;mov dl,79
;mov dh,24
;mov bh,0x31
;int 10h
;popa

mov dh,24
jmp setpos
update_pos_e:
mov ah,0x02
xor bh,bh

int 10h
ret

newline:
mov al,0x0D
call printf
mov al,0x0A
call printf
ret

load_f:
mov ah,0x02
call drive_comm
ret

save_f:
mov ah,0x03
call drive_comm
jmp code

drive_comm:
;pusha
;xor ah,ah
;int 0x13
;popa
mov cl,[sector]
mov bx,ds
mov es,bx
mov al,1
mov ch,[track]
mov dh,[head]
mov byte dl,[drive]
mov word bx,[loc]
stc
int 0x13
jnc .success
mov al,'F'
call printf
;mov si,failstr
;call prnstr
.success:
ret

loc:
dw 0x7000
drive:
db 0x00
head:
db 0x00
track:
db 0x00
sector:
db 0x00
current:
dw 0x0000

mainstr:
db ' F2-Load F4-Sve Entr,Esc',0
enterstr:
db ' D:H:T:Sctr= ',0
;failstr:
;db 'F',0
times 512-($-$$) db 0x90