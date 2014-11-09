;==============================
;  Visual Editor
; -To Edit and Create
; ASCII pictures and videos
; Author - Divyavrat Jugtawat
;==============================

org 0x6000
use16

vedit:
mov bx,[loc]
cmp si,0
jne .load_file_arg
.file_selector:
mov ah,0x86
int 0x61
mov si,ax
;jmp .file_loaded
.load_file_arg:
pusha
mov cx,8+3
mov di,filename
rep movsb
popa
mov bx,[loc]
mov dx,si
mov ah,0x85
int 0x61
.file_loaded:
mov ah,0x02
int 0x64
mov [tempcolor],dl
mov dx,0x0A0A
push dx
;mov si,[loc]
mov word [pos],0x0654
mov ah,0x06
int 0x64
mov ax,dx
mov dx,0
mov cx,0x0200
div cx
mov word [frame],ax
mov word [cur_frame],0x0001
.loop:
mov ax,0x0FA0
mov dx,[cur_frame]
dec dx
mul dx
add ax,[loc]
mov si,ax
xor dx,dx
call setpos
;mov cx,0x07D0
call memcpyprint
pop dx
push dx
call setpos
.vedit_control:
call getkey
cmp ah,0x01
je .quit
cmp ah,0x48
je .up
cmp ah,0x4b
je .left
cmp ah,0x4d
je .right
cmp ah,0x50
je .down
cmp ah,0x53
je .color_down
cmp ah,0x4F
je .color_up
cmp ah,0x52
je .char_down
cmp ah,0x47
je .char_up
cmp ah,0x51
je .page_down
cmp ah,0x49
je .page_up
cmp ah,0x3b
je .help
cmp ah,0x3c
je .chaincopy
cmp ah,0x3D
je .copy
cmp ah,0x3E
je .paste
cmp ah,0x3f
je .spec
cmp ah,0x40
je .fill
cmp ah,0x41
je .clear
cmp ah,0x42
je .clean
cmp ah,0x43
je .setwall
cmp ah,0x44
je vedit.file_selector
cmp ah,0x85
je .save_file
cmp ah,0x86
je .play_video
push ax
call .calculate_pos
pop ax
mov [bx],al
inc bx
mov ah,[bx]
;mov [color],ah
call setcolor
call printf
add word [pos],2
jmp .vedit_control
.quit:
pop dx
; mov dl,[color2]
; mov [color],dl
; jmp kernel
ret
.up:
sub word [pos],0x00A0
call getpos
dec dh
call setpos
jmp .vedit_control
.left:
sub word [pos],2
call getpos
dec dl
call setpos
jmp .vedit_control
.right:
add word [pos],2
call getpos
inc dl
call setpos
jmp .vedit_control
.down:
add word [pos],0x00A0
call getpos
inc dh
call setpos
jmp .vedit_control
.color_up:
call .calculate_pos
mov al,[bx]
inc bx
inc byte [bx]
mov ah,[bx]
;mov [color],ah
call setcolor
call printf
call getpos
dec dl
call setpos
jmp .vedit_control
.color_down:
call .calculate_pos
mov al,[bx]
inc bx
dec byte [bx]
mov ah,[bx]
;mov [color],ah
call setcolor
call printf
call getpos
dec dl
call setpos
jmp .vedit_control
.char_up:
call .calculate_pos
inc byte [bx]
mov al,[bx]
inc bx
mov ah,[bx]
;mov [color],ah
call setcolor
call printf
call getpos
dec dl
call setpos
jmp .vedit_control
.char_down:
call .calculate_pos
dec byte [bx]
mov al,[bx]
inc bx
mov ah,[bx]
;mov [color],ah
call setcolor
call printf
call getpos
dec dl
call setpos
jmp .vedit_control
.chaincopy:
mov byte [.chain],0xf0
call .calculate_pos
mov di,bx
jmp .vedit_control
.chain: db 0x0f
.copy:
mov byte [.chain],0x0f
call .calculate_pos
mov al,[bx]
inc bx
mov ah,[bx]
mov di,ax
jmp .vedit_control
.paste:
call .calculate_pos

cmp byte [.chain],0xf0
je .chain_on
mov [bx],di
mov si,bx
jmp .done_paste
.chain_on:
mov ax,[di]
mov [bx],ax
mov si,bx
add di,2
.done_paste:
inc si
lodsb
mov ah,al
;mov [color],ah
call setcolor
sub si,2
lodsb
call printf
inc si

add word [pos],2
jmp .vedit_control
.spec:
mov word ax,[pos]
xor dx,dx
mov cx,2
div cx
xor dx,dx
mov cx,80
div cx
push ax
mov bx,x_str
mov ah,0x45
mov cx,0x0005
int 0x61
pop ax
mov bx,y_str
mov dx,ax
mov ah,0x45
mov cx,0x0005
int 0x61
jmp .vedit_control
.play_video:
call video
jmp vedit.loop
.save_file:
mov ah,0x81
mov dx,[loc]
int 0x61
jmp .vedit_control
.setwall:
mov ah,0x50
int 0x61
jmp .vedit_control
.fill:
call .calculate_pos
mov byte [bx],0xdb
call .re_print
jmp .vedit_control
.clear:
call .calculate_pos
mov byte [bx],0x20
call .re_print
jmp .vedit_control
.clean:
call .calculate_pos
mov word [bx],0x0f20
call .re_print
jmp .vedit_control
.help:
mov dx,vedit_helpstr
xor ah,ah
int 61h
mov dx,vedit_helpstr2
xor ah,ah
int 61h
mov dx,vedit_helpstr3
xor ah,ah
int 61h
mov dx,vedit_helpstr4
xor ah,ah
int 61h
jmp .vedit_control
.page_down:
pop dx
call getpos
push dx
dec word [cur_frame]
cmp word [cur_frame],1
jl .frameless
jmp .loop
.frameless:
mov dl,[frame]
mov [cur_frame],dl
jmp .loop
.page_up:
pop dx
call getpos
push dx
mov dl,[frame]
inc word [cur_frame]
cmp [cur_frame],dl
jg .framemore
jmp .loop
.framemore:
mov word [cur_frame],1
jmp .loop

.calculate_pos:
mov ax,0x0FA0
mov dx,[cur_frame]
dec dx
mul dx
add ax,[loc]
mov bx,ax
add bx,[pos]
ret

.re_print:
mov si,bx
inc si
lodsb
mov ah,al
;mov [color],ah
call setcolor
sub si,2
lodsb
call printf
inc si
add word [pos],2
ret
.width: db 80
.height: db 25

video:
mov si,[loc]
mov word [cur_frame],0x0001
;mov di,0xB800
;sub di,0x0500
;call memcpy
.loop:
;mov bl,0x36
;mov ax,0x1201
;int 0x10
;call newline
mov dx,0
call setpos
call memcpyprint
;mov bl,0x36
;mov ax,0x1200
;int 0x10
mov dx,[frame]
cmp dx,1
jle .videoexit
cmp byte [slowmode],0xf0
je .slowmode
;call delay
mov ah,0x09
int 0x61
jmp .timewarpdone
.slowmode:
;call slow
mov ah,0x09
int 0x61
.timewarpdone:
;call chkkey
mov ah,0x07
int 0x2b
cmp al,0
jne .videoexit
mov dx,[cur_frame]
cmp dx,[frame]
jge .limit
inc word [cur_frame]
jmp .loop
.videoexit:
call getkey
cmp ah,0x43
je .setwall
;jmp kernel
ret
.limit:
mov word [cur_frame],0x0001
mov si,[loc]
jmp .loop
.setwall:
mov ah,0x50
int 0x61
jmp video

setcolor:
pusha
mov dl,ah
mov ah,0x01
int 0x61
popa
ret

setpos:
mov ah,0x31
int 0x61
ret
getpos:
mov ah,0x30
int 0x61
ret

getkey:
mov ah,0x01
int 0x16
jz getkey
mov ah,0x0
;xor ah,ah
int 0x16
ret

printf:
pusha
mov dl,al
mov ah,0x10
int 0x2b
popa
ret

memcpyprint:
;mov word ax,[cur_frame]
;xor dx,dx
;mov cx,0x0200
;mul cx
mov bx,0xB800
mov es,bx
xor bx,bx
;mov si,[loc]
;add si,ax
mov cx,0x07D0
.loop:
lodsw
;cmp [es:bx],ax
;je .skip
mov [es:bx],ax
;.skip:
add bx,2
loop .loop
xor bx,bx
mov es,bx
ret

x_str:
db 'X :',0
y_str:
db 'Y :',0

vedit_helpstr:
db 'Esc-Close,F1-Help,F2-Menu,F3-Copy,F4-Paste,F5-Details',0
vedit_helpstr2:
db ' (Del-ColorDown,End-ColorUp), (Insert-CharDown,Home-CharUp)',0
vedit_helpstr3:
db ' (PgUp-FrameUp,PgDown-FrameDown)',0
vedit_helpstr4:
db 0x1B,0x18,0x19,0x1A,'-Move F6-Fill,F7-Clear,F8-Clean,F9-SetWall,F10-Load,F11-Save,F12-Video',0

tempcolor: db 0x42
pos: dw 0
frame: dw 4
cur_frame: dw 4
loc: dw 0xA000
slowmode: db 0x0f

filename:
times 8+3 db 0
dw 0

times (512*3)-($-$$) db 0