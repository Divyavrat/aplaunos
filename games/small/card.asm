;main:
mov dx,0x0205
call showcard
mov ah,0x07
int 0x21
ret
;int62h:
;pusha
;xor ax,ax
;mov ds,ax
;mov es,ax
;mov al,0x62
;call ackport
;popa
;jmp int62_card
;iret
showcard:
pusha
mov al,218
call printf
mov al,196
call printf
mov al,191
call printf
call getpos
sub dl,3
inc dh
call setpos
mov al,179
call printf
call space
mov al,179
call printf
call getpos
sub dl,3
inc dh
call setpos
mov al,179
call printf
call space
mov al,179
call printf
call getpos
sub dl,3
inc dh
call setpos
mov al,192
call printf
mov al,196
call printf
mov al,217
call printf

call getpos
dec dh
sub dl,2
call setpos
popa
pusha
cmp dh,'H'
je .heart
cmp dh,'D'
je .diamond
cmp dh,'C'
je .club
cmp dh,'S'
je .spade
cmp dh,'h'
je .heart
cmp dh,'d'
je .diamond
cmp dh,'c'
je .club
cmp dh,'s'
je .spade
cmp dh,1
je .heart
cmp dh,2
je .diamond
cmp dh,3
je .club
jmp .spade
.coatdrawn:
call printf
call getpos
dec dh
dec dl
call setpos
popa
cmp dl,0
je .ace
cmp dl,11
je .jack
cmp dl,12
je .queen
cmp dl,13
je .king
cmp dl,14
je .ace
mov al,dl
call printn
.armyshown:
call getpos
dec dh
sub dl,2
call setpos
ret
;iret
.heart:
mov al,0x03
jmp .coatdrawn
.diamond:
mov al,0x04
jmp .coatdrawn
.club:
mov al,0x05
jmp .coatdrawn
.spade:
mov al,0x06
jmp .coatdrawn
.ace:
mov al,'A'
call printf
jmp .armyshown
.jack:
mov al,'J'
call printf
jmp .armyshown
.queen:
mov al,'Q'
call printf
jmp .armyshown
.king:
mov al,'K'
call printf
jmp .armyshown
printf:
pusha
mov dl,al
mov ah,0x02
int 0x21
popa
ret
space:
mov al,0x20
call printf
ret
printn:
mov dx,ax
xor dh,dh
mov ah,0x20
int 0x61
ret
getpos:
mov ah,0x30
int 0x61
ret
setpos:
pusha
mov ah,0x31
int 0x61
popa
ret

times 512-($-$$) db 0