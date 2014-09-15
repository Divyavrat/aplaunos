org 0x6000
use16

main:
call newline
mov dx,soundblaster
call prnstr
call newline
mov dx,detecting
call prnstr

call reset_both_timer

mov dx,0x388
in al,dx
mov [.temp1],al

mov al,[.temp1]
and al,0xE0
cmp al,0
jne .error

mov si,2
mov di,0xFF
call setreg
mov si,4
mov di,0x21
call setreg

call slow
call slow

mov dx,0x388
in al,dx
mov [.temp2],al

mov al,[.temp2]
and al,0xE0
cmp al,0xC0
jne .error

call reset_both_timer
jmp .done

.error:
call newline
call newline
mov dx,errorstr
call prnstr
call newline
mov dx,errorstr2
call prnstr
call newline
mov dx,errorstr3
call prnstr
jmp .done

.done:
call getkey
ret
.temp1:
dw 0
.temp2:
dw 0

setreg:
; pusha
; mov dx,si
; xor dh,dh
; mov ah,0x24
; int 0x61
; mov dx,di
; xor dh,dh
; mov ah,0x24
; int 0x61
; popa
mov ax,si
mov dx,0x388
out dx,al
;mov cx,6
mov cx,20
.loop1:
mov dx,0x388
in al,dx
loop .loop1
mov ax,di
mov dx,0x389
out dx,al
;mov cx,35
mov cx,55
.loop2:
mov dx,0x388
in al,dx
loop .loop2
ret

reset_both_timer:
mov si,4
mov di,0x60
call setreg
mov di,0x80
call setreg
ret

slow:
mov ah,0x02
int 1ah
mov al,dh
mov byte [.temp],al
.slow_loop:
mov ah,0x02
int 0x1a
cmp byte dh,[.temp]
je .slow_loop
ret
.temp: db 0

getkey:
xor ah,ah
int 0x16
ret

newline:
mov ah,0x0B
int 0x61
ret

prnstr:
mov ah,0x03
int 0x61
ret

soundblaster:
db "Sound Blaster 16",0
detecting:
db "Detecting...",0
errorstr:
db "No Compatible AdLib Card",0
errorstr2:
db "Or No Soundblaster 16 Card",0
errorstr3:
db "Or A Crazy guy has coded me.",0

times 512-($-$$) db 0