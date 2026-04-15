org 0x6000
use16
jmp start
db '  Define your password here (any length just after colon) :'
pwd:
db 'user',0
times 300-($-$$) db 0
start:
mov ah,0x06
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,ask
int 61h
mov ah,0x04
mov dx,strfound
int 61h
xor al,al
mov ah,0x05
mov bx,strfound
mov dx,pwd
int 61h
cmp al,0xF0
jne start
mov ah,0x06
int 61h
mov ah,0x03
mov dx,correct
int 61h
mov ah,0x0D
mov dx,autorun
int 61h
ret
ask:
db '  Enter Password:',0
correct:
db '  Password Correct',0
autorun:
db 'confg vlh ',0
strfound:
times 20 db 0
times 512-($-$$) db 0