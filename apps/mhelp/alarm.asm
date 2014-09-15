org 0x8000
use16
mov ah,0x0B
int 0x61
mov dx,helpstr
mov ah,0x03
int 0x61
mov ah,0x0B
int 0x61
mov dx,help2str
mov ah,0x03
int 0x61
mov ah,0x0B
int 0x61
mov dx,help3str
mov ah,0x03
int 0x61
mov ah,0x0B
int 0x61
mov dx,help4str
mov ah,0x03
int 0x61
ret
helpstr:
db "You can set a alarm by giving the time in HH:MM:SS format",0
help2str:
db "to interrupt you and show you the alarm text .",0
help3str:
db " This will stop you no matter what is currently running."
db " So you can use this to stop a program at a fix time,"
db " or as reminders or to show a message to a future user.",0
help4str:
db " When stopped :Press {any key to jmp to kernel} or {enter to continue}.",0

times (512)-($-$$) db 0