; Show about dialog
; for Basic details

org 6000h
use16

; Store Screen
mov ah,10h
int 61h
mov ah,30h
int 61h
mov ah,12h
int 61h

; Clear Screen
mov ah,6
int 61h

; Get Version String
mov ah,0FFh
int 64h

; Show about dialog box
mov bx,contributors
mov cx,acknowledgement
mov ah,20h
int 2Bh

; Restore Screen
mov ah,11h
int 61h
mov ah,13h
int 61h
mov ah,31h
int 61h

; Return to kernel
ret

; Data
contributors:
db "DivJ"," ",0

acknowledgement:
db "With help of many Open Source projects.",0