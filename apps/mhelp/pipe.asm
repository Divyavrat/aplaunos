org 0x8000
use16
mov ah,0x0B
int 0x61
mov dx,helpstr
mov ah,0x03
int 0x61
ret
helpstr:
db "Pipe to run many commands."
db " Enter the commands seperated from each other by a space,"
db " and ending with a fullstop."
db " These are inserted into the keyboard stream as long as there is space."
db " Usually 15 chars can fit."
db "         Example->  Enter: calc 1 5 3   , will perform calc commands"
db " with future input to add.",0
times (512)-($-$$) db 0