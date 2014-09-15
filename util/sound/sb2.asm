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

mov cx,0x388
in al,0x388
mov [.temp1],al

;mov al,[.temp1]
and al,0xE0
cmp al,0
jne .error

mov bl,2
mov dl,0xFF
call setreg
mov bl,4
mov dl,0x21
call setreg

call slow
call slow

mov ax,0x388
in al,0x388
mov [.temp2],al

;mov al,[.temp2]
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
;mov ax,si
mov ax,0x388
out ax,bl
mov cx,6
.loop1:
mov ax,0x388
in al,ax
loop .loop1
;mov ax,di
mov ax,0x389
out ax,dl
mov cx,35
.loop2:
mov ax,0x388
in al,ax
loop .loop2
ret

reset_both_timer:
mov bl,4
mov dl,0x60
call setreg
mov dl,0x80
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