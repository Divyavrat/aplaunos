org 0x6000
use16

;mov ax,0x0003
;int 0x10
;mov ax,0x0500
;int 10h
mov ch,0x20
mov ah,0x01
int 0x10
clock:
call space
call time
call space
call newline
call space
call date
call space
call newline
call space
call timer
call space
call space

call getpos
sub dh,2
xor dl,dl
call setpos
mov ah,0x01
int 0x16
jz clock
call getpos
add dh,2
call setpos
mov cx,0x0506
mov ah,0x01
int 0x10
ret

printf:
pusha
mov ah,0x0E
int 0x10
popa
ret

colon:
mov al,':'
call printf
ret

space:
mov al,' '
call printf
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

printnb:
mov bl,'A'
push bx
mov bh,al
.reverse:
mov al,bh
mov bl,10
mov ah,0
div bl
mov bh,al
mov al,ah
add al,48
push ax
cmp bh,0
jg .reverse
.printne:
pop ax
cmp al,'A'
jne .printnf
ret
.printnf:
call printf
jmp .printne

newline:
mov al,0x0D
call printf
mov al,0x0A
call printf
ret

date:
mov ah,0x04
int 0x1a
mov al,dl
call printh
call colon
mov al,dh
call printh
call colon
mov al,ch
call printh
;call colon
mov al,cl
call printh
ret

time:
mov ah,0x02
int 0x1a
mov al,ch
call printh
call colon
mov al,cl
call printh
call colon
mov al,dh
call printh
ret

timer:
;mov ah,0x00
xor ah,ah
int 0x1a
mov al,ch
call printnb
call colon
mov al,cl
call printnb
call colon
mov al,dh
call printnb
call colon
mov al,dl
call printnb
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

times 512-($-$$) db 0x90