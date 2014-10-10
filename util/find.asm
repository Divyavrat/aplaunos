org 0x6000
use16
mov ah,0x03
mov dx,enterstr
int 0x61
mov ah,0x04
mov dx,cmpstr
int 0x61
mov ah,0x33
mov dx,cmpstr
int 0x61
mov [strlen],dx
.loop:
; mov ah,0x71
; mov dx,[cluster]
; int 0x61
mov dx,[cluster]
mov bx,[loc]
mov ah,0x72
int 0x61
;mov [loc],ax
cmp byte [show],0xf0
jne .cmploop
mov ah,0x0B
int 0x61
mov dx,[loc]
add dx,[pos]
mov cx,0x0200
mov ah,0x14
int 0x61
.cmploop:
mov ah,0x06
mov dl,0xff
int 0x21
cmp dl,0x0f
jne .key
mov bx,cmpstr
mov dx,[loc]
add dx,[pos]
;pusha
;popa
;pusha
;mov ah,0x03
;int 0x61
;mov ah,0x24
;mov dx,[loc]
;int 0x61
;popa
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .found
inc word [pos]
cmp word [pos],0x0200
jl .cmploop
mov word [pos],0
inc word [cluster]
cmp word [cluster],2880
jl .loop
mov ah,0x71
mov dx,0x0013
int 0x61
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,notstr
int 0x61
mov ah,0x03
mov dx,foundstr
int 0x61
ret
.found:
mov ah,0x0B
int 0x61
mov ah,0x03
mov dx,foundstr
int 0x61
call printspace
mov dl,'a'
call print
mov dl,'t'
call print
call printspace
mov dl,':'
call print

mov ah,0x71
mov dx,[cluster]
int 0x61
mov ah,0x74
int 0x61
pusha
call printspace
mov dl,'T'
call print
call printequal
popa
pusha
mov dl,ch
call printh
call printspace
mov dl,'H'
call print
call printequal
popa
pusha
mov dl,dh
call printh
call printspace
mov dl,'S'
call print
call printequal
popa
pusha
mov dl,cl
call printh
popa
call printspace
mov dl,'L'
call print
mov dl,'B'
call print
mov dl,'A'
call print
call printequal
mov dx,[cluster]
mov ah,0x24
int 0x61
mov ah,0x0B
int 0x61
mov dx,[loc]
add dx,[pos]
sub dx,0x14
mov ah,0x14
mov cx,0x50
int 0x61

mov ah,0x07
int 0x21
cmp ah,0x01
je .quit
cmp ah,0x3b
je .help
cmp ah,0x1C
je .show
inc word [pos]
jmp .cmploop
.quit:
ret
.key:
mov ah,0x07
int 0x21
cmp ah,0x1C
je .show
cmp ah,0x01
je .quit
cmp ah,0x3b
je .help
jmp .cmploop
.show:
not byte [show]
jmp .cmploop
.help:
xor ah,ah
mov dx,helpstr
int 0x61
jmp .cmploop
printspace:
mov dl,0x20
jmp print
printequal:
mov dl,'='
print:
mov ah,0x02
int 0x21
ret
printh:
mov ah,0x22
int 0x61
ret
show:
db 0x0f
strlen:
dw 0
cluster:
dw 0
loc:
dw 0xA000
pos:
dw 0
enterstr:
db 'Enter string to find:',0
helpstr:
db 'Press Enter-to show searched data or Esc-to quit.',0
notstr:
db 'Not',0
foundstr:
db 'Found',0
cmpstr:
db 0
times 512-($-$$) db 0