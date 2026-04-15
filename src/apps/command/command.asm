;Command Shell

org 6000h
use16

;Set shell as default to run
mov dx,set_idle_command
mov ah,30h
int 64h

mov dx,set_idle_time
mov ah,0Dh
int 61h
mov ah,0Fh
int 61h

jmp shell_start
set_idle_command:
db "command ",0
set_idle_time:
db "idletime 0 ",0
set_extra_idle_time:
db "idletime 20 ",0

shell_start:

; Get Command
mov bx,enter_command_str
mov dx,command_str
mov ah,23h
int 2Bh

;Check for shell commands
mov si,command_str

;If quit command is recieved
mov di,quit_cmd
call cmpstr
jc .quit_shell

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

; Move to start of display
mov dx,0
mov ah,31h
int 61h

; Return to kernel
ret

.quit_shell:

;Store command to reset idle time
mov dx,set_extra_idle_time
mov ah,0x0D
int 0x61
mov ah,0x0F
int 0x61
ret

; Common Functions
cmpstr:
pusha
.loop:
lodsb
mov bl,[di]
inc di
cmp al,bl
jne .nequal
cmp al,0
je .cmpend
jmp .loop
.nequal:
popa
clc
ret
.cmpend:
popa
stc
ret

; Data
enter_command_str:
db "Enter OS command : ",0
quit_cmd:
db "quit",0
command_str:
times 40 db 0
