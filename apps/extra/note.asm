org 0x6000
use16

mov dx,[loc]
mov [filepos],dx
mov ah,0x80
int 0x61

;mov ax,0x0003
;int 0x10
;mov ax,0x0500
;int 10h
mov word [firstrow],1
mov byte [row],0
mov byte [col],0

mainloop:
call checkpos
call checkline_eol
xor dx,dx
call setpos
mov ah,0x06
int 0x61
mov cx,[firstrow]
jmp showscreen.firstline

showscreen:
pusha
;call newline
mov ah,0x0B
int 0x61
popa
.firstline:
push cx
mov dx,cx
call loadlinepos
;mov ax,[si]
;cmp ax,0
;je .popexit
call showline
;call getkey
call getpos
pop cx
cmp dh,24
jge .exitloop
inc cx
;cmp cx,25
;jle showscreen
jmp showscreen
.exitloop:
mov dh,[row]
mov dl,[col]
call setpos
jmp control
.popexit:
pop cx
jmp .exitloop

control:
call getkey

cmp ah,0x01
je .quit
cmp al,0x08
je .back
cmp ah,0x3B
je .help
cmp ah,0x3C
je .save
cmp ah,0x47
je .home
cmp ah,0x4f
je .end
cmp ah,0x51
je .page_down
cmp ah,0x49
je .page_up
cmp ah,0x48
je .up
cmp ah,0x4B
je .left
cmp ah,0x4D
je .right
cmp ah,0x50
je .down
cmp ah,0x53
je .del

push ax
call getcurrentpos
call strshiftr
pop ax
mov [si],al
cmp al,13
je .enter
inc byte [col]
jmp mainloop
.home:
mov byte [col],0
jmp mainloop
.end:
call loadlineend
mov di,si
call loadlinepos
sub di,si
mov dx,di
dec dl
mov [col],dl
jmp mainloop
.page_down:
add word [firstrow],6
jmp mainloop
.page_up:
sub word [firstrow],6
jmp mainloop
.enter:
inc si
call strshiftr
mov byte [si],10
inc byte [row]
mov byte [col],0
jmp mainloop

.quit:
ret
.help:
xor ah,ah
mov dx,help_str
int 0x61
jmp control
.save:
mov ah,0x81
mov dx,[loc]
int 0x61
jmp control

.up:
dec byte [row]
sub word [filepos],80 ;check
jmp mainloop
.left:
dec byte [col]
dec word [filepos] ;check
jmp mainloop
.right:
inc byte [col]
inc word [filepos] ;check
jmp mainloop
.down:
inc byte [row]
add word [filepos],80 ;check
jmp mainloop
.back:
dec byte [col]
.del:
call getcurrentpos
call strshift
jmp mainloop

checkpos:
cmp word [firstrow],1
jl .firstrow_l
cmp byte [row],0
jl .row_l
cmp byte [row],24
jg .row_h
cmp byte [col],0
jl .col_l
cmp byte [col],79
jg .col_h
ret
.firstrow_l:
mov byte [row],0
mov word [firstrow],1
jmp checkpos
.row_l:
inc byte [row]
dec word [firstrow]
jmp checkpos
.row_h:
dec byte [row]
call checkline_eol
inc word [firstrow]
jmp checkpos

.col_l:
dec byte [row]
add byte [col],80
jmp checkpos
.col_h:
inc byte [row]
sub byte [col],80
jmp checkpos

checkline_eol:
call loadlineend
mov di,si
call getcurrentpos
cmp si,di
jge .eol
.ok:
ret
.eol:
inc byte [row]
mov byte [col],0
ret

getcurrentpos:
mov dx,[firstrow]
add dl,[row]
call loadlinepos
add si,[col]
; mov cx,si
; add cl,[col]
; mov si,cx
ret

loadlineend:
mov dx,[firstrow]
add dl,[row]
call loadlinepos
.loop:
lodsb
cmp al,13
je .eol
cmp al,10
je .eol
jmp .loop
.eol:
ret

printf:
cmp al,0x09
je .tab
mov ah,0x02
mov dl,al
int 0x21
ret
.tab:
mov cx,8
.loop:
mov ah,0x02
mov dl,0x20
int 0x21
loop .loop
ret

getkey:
xor ah,ah
int 0x16
ret

getpos:
mov ah,0x30
int 0x61
ret

setpos:
mov ah,0x31
int 0x61
ret

loadlinepos:
mov si,[loc]
mov word [.linecount],1
.check_end:
cmp word [.linecount],dx
jl .loop
ret
.loop:
lodsb
cmp al,0x0D
je .linefound
cmp al,0x0A
je .linefound2
jmp .loop

.linefound:
inc si
.linefound2:
inc word [.linecount]
jmp .check_end
.linecount:
dw 0

showline:
lodsb
cmp al,0x0D
je .done
cmp al,0x0A
je .done
call getpos
cmp dx,0x184F
jge .done
call printf
jmp showline
.done:
ret

; newline:
; mov ah,0x0B
; int 0x61
; ret

strshift:
inc si
mov al,[si]
dec si
mov [si],al
inc si
cmp al,0
jne strshift
ret

strshiftr:
pusha
call strlen
mov di,si
push si
dec si
call memcpyr
pop si
mov byte [si],0
popa
ret

strlen:
xor cx,cx
.loop:
lodsb
inc cx
cmp al,0
jne .loop
ret

memcpyr:
lodsb
stosb
sub si,2
sub di,2
loop memcpyr
ret

firstrow: dw 0
filepos: dw 0
row: db 0
col: db 0
loc:
dw 0x7000

help_str:
db "F2-save",0

times (512*2)-($-$$) db 0