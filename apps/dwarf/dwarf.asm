org 0x7C00
use16

;TODO:
;text,code
jmp 0:start

start:
;cli
xor ax,ax
mov ds,ax
mov es,ax
mov fs,ax
mov gs,ax
mov ax,0x9000
mov ss,ax
mov sp,0xFFFF
;sti

mov [drive],dl
reset:
mov ax,0x0003
int 0x10
mov ax,0x0500
int 10h

shell:
call newline

mov al,'>'
call printf

mov di,found
call getstr

call newline

mov si,found
mov di,c_head
call cmpstr
jc head_f

mov si,found
mov di,c_track
call cmpstr
jc track_f

mov si,found
mov di,c_load
call cmpstr
jc load_f

mov si,found
mov di,c_save
call cmpstr
jc save_f

mov si,found
mov di,c_size
call cmpstr
jc size_f

mov si,found
mov di,c_drive
call cmpstr
jc drive_f

mov si,found
mov di,c_loc
call cmpstr
jc loc_f

mov si,found
mov di,c_type
call cmpstr
jc type_f

mov si,found
mov di,c_run
call cmpstr
jc run

mov si,found
mov di,c_cls
call cmpstr
jc reset

mov si,failstr
call prnstr
jmp shell

printf:
pusha
mov ah,0x0E
int 0x10
popa
ret

;printh:
;push ax
;shr al,4
;cmp al,10
;sbb al,69h
;das
;call printf
;pop ax
;ror al,4
;shr al,4
;cmp al,10
;sbb al,69h
;das
;call printf
;ret

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

prnstr:
lodsb
cmp al,0
je .end
call printf
jmp prnstr
.end:
ret

getstr:
call getkey
cmp al,0x0D
je .end
stosb
call printf
jmp getstr
.end:
xor al,al
stosb
ret

cmpstr:
lodsb
mov bl,[di]
inc di
cmp al,bl
jne .no
cmp al,0
je .yes
jmp cmpstr
.no:
clc
ret
.yes:
stc
ret

newline:
mov al,0x0D
call printf
mov al,0x0A
call printf
ret

drive_comm:
;pusha
;xor ah,ah
;int 0x13
;popa
mov cl,al
mov bx,ds
mov es,bx
mov byte al,[size]
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

;help:
;mov si,helpstr
;call prnstr
;jmp shell

head_f:
call gethex
mov [head],al
jmp shell

track_f:
call gethex
mov [track],al
jmp shell

load_f:
call gethex
mov ah,0x02
call drive_comm
jmp shell

save_f:
call gethex
mov ah,0x03
call drive_comm
jmp shell

size_f:
call gethex
mov [size],al
jmp shell

drive_f:
call gethex
mov [drive],al
jmp shell

loc_f:
call gethex
mov [loc+1],al
call gethex
mov [loc],al
jmp shell

type_f:
mov si,[loc]
mov cx,0x0200
.loop:
lodsb
call printf
loop .loop
jmp shell

run:
call word [loc]
;mov ax,es
;cmp ax,0
;jne reset
;mov ax,bp
;cmp ax,0
;jne reset
jmp shell

c_head:
db 'head',0
c_track:
db 'track',0
c_load:
db 'load',0
c_save:
db 'save',0
c_size:
db 'size',0
c_drive:
db 'drive',0
c_loc:
db 'loc',0
c_type:
db 'type',0
c_run:
db 'run',0
c_cls:
db 'cls',0

failstr:
db 0x20,'Failed',0

head:
db 0x00
track:
db 0x00
size:
db 0x01
drive:
db 0x00
loc:
dw 0x6000
found:

times 510-($-$$) db 0x90
db 0x55
db 0xaa