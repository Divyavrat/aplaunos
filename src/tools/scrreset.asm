;restore screen test
org 6000h
mov ah,11h
int 61h
mov ah,13h
int 61h
mov ah,31h
int 61h
ret
;EoF
