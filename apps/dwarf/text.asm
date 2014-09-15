org 0x6000
use16

text:
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

jmp text

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

jmp text

editor:
call newline

mov word [current],0x0000
mov si,[loc]
mov cx,0x0200
.loop:
lodsb
call printc
inc word [current]
loop .loop

control:
call getkey
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

mov bx,[loc]
add bx,[current]
mov [bx],al
call printc
inc word [current]

jmp control

.quit:
jmp text

move_up:
call getpos
dec dh
sub word [current],80
call setpos
jmp control

move_left:
call getpos
dec dl
dec word [current]
call setpos
jmp control

move_right:
call getpos
inc dl
inc word [current]
call setpos
jmp control

move_down:
call getpos
inc dh
add word [current],80
call setpos
jmp control

printf:
pusha
mov ah,0x0E
int 0x10
popa
ret

printc:
pusha
xor bh,bh
mov ah,0x09
mov bl,0x31
mov cx,0x0001
int 0x10
call getpos
inc dl
call setpos
popa
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

pusha
mov ax,0x0601
xor cx,cx
mov dl,79
mov dh,24
mov bh,0x31
int 10h
popa

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
jmp text

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
mov si,failstr
call prnstr
.success:
ret

drive:
db 0x00
head:
db 0x00
track:
db 0x00
sector:
db 0x00
loc:
dw 0x7000
current:
dw 0x0000

mainstr:
db ' F2-Load F4-Save Entr-Edit Esc-Exit',0
enterstr:
db ' D:H:T:Sctr =',0
failstr:
db 'Fl',0

times 512-($-$$) db 0x90