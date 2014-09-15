org 0x6000
use16

mov bx,0xB800
mov es,bx
xor bx,bx
mov byte [char],0
mov byte [color],0
mov cx,(80*25)
.loop:
mov dl,[char]
mov [es:bx],dl
inc bx
mov dl,[color]
mov [es:bx],dl
inc bx
inc byte [char]
inc byte [color]
loop .loop
xor bx,bx
mov es,bx
ret

char:
db 0x00
color:
db 0x00

times 512-($-$$) db 0x90