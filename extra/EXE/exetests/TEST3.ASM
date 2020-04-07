org 0x6000
use16

mov ax,0x0003	; reset text mode
int 0x10
mov ax,0x0500	; set page to zero
int 0x10

mov di,0x6000

jmp word start

input:
push di
mov ah,0x00
int 0x16
pop di
mov [di],al

output:
push di
mov al,[di]
;mov bh,color	; color
;mov bl,0		; page
mov bx,0x0700
mov ah,0x0E		; Print character function
int 0x10
pop di
;ret
pop bx
add bx,3
jmp bx

start:
times 3 db 0x90
jmp word input
times 3 db 0x90
jmp word output
times 3 db 0x90
inc di
times 3 db 0x90
dec di
times 3 db 0x90
inc byte [di]
times 3 db 0x90
dec byte [di]
times 3 db 0x90
mov cx,0x6000
push cx
times 3 db 0x90
pop cx
times 3 db 0x90
jmp word input
times 3 db 0x90
jmp word output
times 3 db 0x90
jmp word start
times 3 db 0x90
;times 3 db 0x90
jmp 0x6000
ret

;times 1024-($-$$) db 0x90		; Padding will NOPs