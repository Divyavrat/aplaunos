org 0x6000
use16
;jmp start
;db '  Define your password here (any length just after colon) :'
;times 200-($-$$) db 0
start:
mov ah,0x06
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,ask
int 61h
mov ah,0x03
mov dx,pass
int 61h
call passcheck
mov ah,0x06
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,correct
int 61h
cmp byte [message_flag],0xf0
jne menu
mov byte [message_flag],0x0f
mov ah,0x0B
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
;mov dx,[message]
mov dx,0x7000
int 61h
mov ah,0x0B
int 61h
jmp menu.skip
menu:
mov ah,0x06
int 61h
.skip:
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,menu1
int 61h
mov ah,0x03
mov dx,pass
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,menu2
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,menu3
int 61h
mov ah,0x03
mov dx,msg
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,menu4
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,menu5
int 61h
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,ask
int 61h
; mov ah,0x03
; mov dx,ask_ch
; int 61h
mov dl,':'
mov ah,0x02
int 0x21
;mov ah,0x04
;mov dx,[strfound]
;int 61h
mov ah,0x07
int 0x21

cmp al,'1'
je .passchange
cmp al,'2'
je .autorunstring
cmp al,'3'
je .message
cmp al,'4'
je .save_quit

.quit:
mov ah,0x3B
mov dx,0x0013
int 0x21
mov ah,0x0D
mov dx,autorun
int 61h
ret
.passchange:
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,ask
int 61h
mov ah,0x03
mov dx,old
int 61h
mov ah,0x03
mov dx,pass
int 61h
call passcheck
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,ask
int 61h
mov ah,0x03
mov dx,new
int 61h
mov ah,0x03
mov dx,pass
int 61h
mov ah,0x04
mov dx,pwd
int 61h
; mov ah,0x04
; mov dx,[strfound]
; int 61h
jmp menu

.autorunstring:
mov ah,0x03
mov dx,ask
int 61h
mov dl,':'
mov ah,0x02
int 0x21
mov ah,0x04
mov dx,autorun
int 61h
jmp menu

.message:
mov byte [message_flag],0xf0
mov ah,0x0B
int 61h
mov ah,0x03
mov dx,ask
int 61h
mov ah,0x03
mov dx,msg
int 61h
mov ah,0x04
;mov dx,[message]
mov dx,0x7000
int 61h
jmp start

.save_quit:
mov ah,0x81
mov dx,0x6000
int 0x61
jmp .quit

passcheck:
; mov ah,0x04
; mov dx,[strfound]
; int 61h
;mov di,[strfound]
mov di,0x8000
call getpwd
xor al,al
mov ah,0x05
;mov bx,[strfound]
mov bx,0x8000
mov dx,pwd
int 61h
cmp al,0xF0
jne .wrong
ret
.wrong:
pop ax
jmp start

getpwd:
mov ah,0x07
int 0x21
cmp al,13
je .done
stosb
mov dl,0xFE
mov ah,0x02
int 0x21
jmp getpwd
.done:
xor al,al
stosb
ret
message_flag:
db 0x0f
ask:
db ' Enter',0
pass:
db ' Password:',0
msg:
db ' Message:',0
old:
db ' old',0
new:
db ' new',0
correct:
db ' Correct',0
menu1:
db '1:Change',0
menu2:
db '2:Autorun string',0
menu3:
db '3:Leave',0
menu4:
db '4:Save&Quit',0
menu5:
db 'Quit',0
;ask_ch:
;db ' Choice:',0
autorun:
db 'confg lvlhiXit ',0
;message:
;dw 0x7000
;strfound:
;dw 0x8000
pwd:
db 'user',0
times 10 db 0
;times 20 db 0

times (512)-($-$$) db 0