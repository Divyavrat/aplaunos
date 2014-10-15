;--------------------------
; Sample Hello World Program
; for Aplaun OS
;--------------------------

org 6000h ; org to default location

mov ah,03h ; Print String function
mov dx,hello_str ; Giving String Location
int 61h ; General API of Aplaun OS
ret ; Return back to OS

;Data - Variables and Strings
hello_str:
db "Hello World",0
