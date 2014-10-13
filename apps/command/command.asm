;Command Shell

org 6000h
use16

; Get Command
mov bx,enter_command_str
mov dx,command_str
mov ah,23h
int 2Bh

; Store it in buffer
; from where it will
; be executed
mov dx,command_str
mov ah,0Dh
int 61h

; Storing Enter key
mov cx,1C0Dh
mov ah,05h
int 16h

; Return to kernel
ret

; Data
enter_command_str:
db "Enter OS command :",0
command_str:
times 40 db 0
