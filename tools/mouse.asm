;Mouse
org 6000h
mov ah,06h
int 61h
mov ah,00h
int 33h
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
mov ah,02h
int 33h
mov dh,cl
xchg dh,dl
mov ah,31h
int 61h
mov al,0dbh
mov ah,2
int 21h
cmp bx,2
je col
cmp bx,0
jne closeloop
jmp done
col:
mov ah,02h
int 64h
inc dl
mov ah,01
int 61h
done:
jmp mainloop
closeloop:
ret
;0