org 0x6000
use16
jmp start
db '    Enter your settings here (just after colons) and run this file.  '
db '  Your Default prompt (15 characters) :'
prompt:
db 'Bigger Picture:',0
db ' The Commonly used Color Setting.'
db ' Default Color (2 bytes in hex) :'
color:
db 0x31
db ' The typemode and notification color. '
db '  Default Color2 (2 bytes in hex) :'
color2:
db 0x74
db ' Your Starting directory .'
db '  Default Dir (4 bytes in hex) :'
currentdir:
dw 0x0013
db ' This will be starting size. '
db ' Size (2 bytes in hex) :'
size:
db 0x01
db ' Type mode = on/off ( 1 byte as 0F=OFF F0=ON ). '
db ' Typemode (1 byte in hex) :'
typemode:
db 0x0F
;db ' The Following is the real code so leave it as it is.   '
start:
mov ah,0x0C
mov dx,prompt
int 61h
mov ah,0x01
mov dl,[color]
int 61h
mov ah,0x02
mov dl,[color2]
int 61h
mov ah,0x3B
mov dx,[currentdir]
int 21h
mov ah,0x05
mov dl,[size]
int 61h
cmp byte [typemode],0xF0
jne .skip
mov ah,0x06
int 61h
.skip:
ret

times 512-($-$$) db 0