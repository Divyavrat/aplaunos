;Mouse
org 6000h
mov ah,06h
int 61h
mov ah,00h
int 33h
mov byte [char_no],0dbh
mainloop:
mov dx,0
mov ah,31h
int 61h
;int 60h
mov ah,01h
int 33h
mov ah,09h
int 61h
mov ah,03h
int 33h
pusha
mov ah,02h
int 33h
mov dh,cl
xchg dh,dl
mov ah,31h
int 61h
mov dl,[char_no]
mov ah,2
int 21h
popa
cmp bx,2
je col
cmp bx,3
je char
cmp bx,0
jne closeloop
jmp done
col:
mov ah,2
int 64h
inc dl
mov ah,1
int 61h
jmp done
char:
inc byte [char_no]
done:
jmp mainloop
closeloop:
ret
char_no:
db 0dbh
;0