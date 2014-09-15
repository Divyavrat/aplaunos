org 0x6000
use16
start:
mov ah,0x0a;slow
int 61h
mov ah,0x09;delay
int 61h
mov ah,0x01;set_color
mov dl,0xf2
int 61h
mov ah,0x02;set_color2
mov dl,0x04
int 61h
mov ah,0x06;cls
int 61h
;mov ah,0x07
;mov dl,0x01
;int 21h
mov ah,0x08;change_typemode
int 61h
mov ah,0x09;delay
int 61h
mov ah,0x03;print_string
mov dx,message
int 61h
mov ah,0x08;change_typemode
int 61h
;mov ah,0x07
;int 21h
mov ah,0x09
int 61h
mov ah,0x0a
int 61h
mov ah,0x09
int 61h
mov ah,0x0a
int 61h
mov ah,0x06;cls
int 21h
mov ah,0x0b;newline
int 61h

; mov bx,title
; mov dx,message2
; mov cx,0x0300
; int 2ch;message_box
; mov ah,0x0b;newline
; int 61h
mov dx,title
mov bx,message2
mov cx,0
mov ah,0x20
int 0x2b
ret
title:
db 'MsgBox',0
message2:
db 'Hello Neighbour',0
message:
db 'Messages can be Deceitful',0
times 512 - ($-$$) db 0