org 0x6000
use16

;========================
;
; Help Utility
;
;by - Divyavrat Jugtawat
;
;Searches for word
;in input
;provide help
;========================

main_program:
cmp si,0
jne start.argument_found
start:
mov word [pos],0
mov dx,[word_count]
add [total_count],dx
mov word [word_count],0
cmp byte [.argument_call],0xf0
je foundexit
call newline
mov dx,helpstr
call prnstr
mov dx,[loc]
call getstr
.string_recieved:
mov dx,[loc]
mov ah,0x1B;lowerstr
int 0x61
mov ah,0x33;strlen
mov dx,[loc]
int 0x61
mov [strlen],dx
mov di,[loc]
add di,[strlen]
mov cx,0x0200
.clearbuffer:
xor al,al
stosb
loop .clearbuffer
call newline
.cmploop:
cmp byte [.argument_call],0xf0;;skip
je .skip
mov ah,0x06
mov dl,0xff
int 0x21
cmp dl,0x0f
jne .key

.skip:

;Search for commands

mov dx,c_debug
mov bx,founddebug
call findword

mov dx,c_file
mov bx,foundfile
call findword

mov dx,c_app
mov bx,foundapp
call findword

mov dx,c_batch
mov bx,foundbatch
call findword

mov dx,c_cls
mov bx,foundclear
call findword

mov dx,c_clear
mov bx,foundclear
call findword

mov dx,c_color
mov bx,foundcolor
call findword

mov dx,c_bye
mov bx,foundexit
call findword

mov dx,c_close
mov bx,foundexit
call findword

mov dx,c_quit
mov bx,foundexit
call findword

mov dx,c_exit
mov bx,foundexit
call findword

mov bx,[loc]
add bx,[pos]
cmp byte [bx],'0'
jl .not_number
cmp byte [bx],'9'
jg .not_number

mov word [found_number],0

.number_loop:
mov dx,[found_number]
imul dx,10
mov al,[bx]
sub al,'0'
mov ah,0
add dx,ax
; mov ah,0x0E
; int 10h
mov [found_number],dx
inc word [pos]
inc bx
cmp byte [bx],'0'
jl .not_number
cmp byte [bx],'9'
jg .not_number
jmp .number_loop
.not_number:

.not_found:
inc word [pos]
;cmp byte [.argument_call],0xf0;;skip
;jne .complete_check
;mov dx,[strlen]
;cmp word [pos],dx
;jg .cmploop_end
;.complete_check:
cmp word [pos],0x0200
jl .cmploop
.cmploop_end:

;Presence checks
mov si,found_presence
lodsw
cmp ax,0
je .presence_not_found
mov bx,ax
call shift_presence_pop
jmp bx
.presence_not_found:

mov ah,0x33
mov dx,[loc]
int 0x61
mov [strlen],dx

cmp byte [.argument_call],0xf0;;skip
je .notfound

mov di,[loc]
add di,[strlen]
dec di
mov al,'.'
stosb
mov al,'C'
stosb
mov al,'O'
stosb
mov al,'M'
stosb

; mov dx,[loc]
; call prnstr
; mov dx,[loc]
; mov ah,0x3d
; int 0x21

; mov dx,[loc]
; mov bx,0x8000
; mov ah,0x85
; int 0x61

mov ah,0x50
mov dx,[loc]
mov cx,0x8000
int 0x2b

cmp dx,0xf0f0
jne .notfound
;call ax
call 0x8000
jmp start
.notfound:
mov dx,notfoundstr
call prnstr
jmp start
.key:
cmp ah,0x01
je foundexit
jmp start
.argument_found:
mov byte [.argument_call],0xf0
push si
mov dx,si
mov ah,0x33;strlen
int 0x61
mov cx,dx
pop si
mov di,[loc]
rep movsb
jmp .string_recieved
.argument_call:
db 0x0f

presence_word:
mov ax,[word_count]
mov [bx],ax
inc word [pos]
jmp start.cmploop

newline:
mov ah,0x0B
int 0x61
ret

prnstr:
mov ah,0x03
int 0x61
ret

getstr:
mov ah,0x04
int 0x61
ret

findword:
pusha
mov ah,0x33
int 0x61
mov [strlen],dx
popa
pusha
mov bx,dx
mov dx,[loc]
add dx,[pos]
mov cx,[strlen]
mov ah,0x15
int 0x61
cmp al,0xF0
je .found
popa
ret
.found:
popa
pop ax
inc word [word_count]
cmp byte [debug_switch],0xf0
jne .process
push dx
;call newline
mov dx,debugstr
call prnstr
pop dx
call prnstr
mov dx,debugstr2
call prnstr
mov dx,[word_count]
mov ah,0x20
int 0x61
mov dx,debugstr2
call prnstr
mov dx,[pos]
mov ah,0x20
int 0x61
call newline
.process:
jmp bx

;IN: dx=word location to add
add_presence_location:
pusha
mov si,found_presence
.loop:
lodsw
cmp si,found_presence_end
jg .end
cmp ax,0
jne .loop
.end:
mov [si-2],dx
popa
ret

;IN: si=string to shift by word
;ended when string-end is encountered
shift_presence_pop:
mov si,found_presence
;inc si
.loop:
add si,2
mov ax,[si]
;dec si
sub si,2
mov [si],ax
add si,2
cmp ax,0
jne .loop
ret

; Actions and Events
founddebug:
not byte [debug_switch]
inc word [pos]
jmp start.cmploop

foundclear:
mov ah,0x06
int 0x61
jmp start

foundcolor:
mov dx,.process
call add_presence_location
mov bx,.found
jmp presence_word
.process:
mov word [.found],0
mov dx,[found_number]
cmp dx,0
jne .number
;mov bx,[loc]
;mov dx,[bx]
mov dl,0x45
.number:
mov ah,0x01
int 0x61
jmp start
.found: dw 0

foundexit:
cmp byte [debug_switch],0xf0
jne .process
mov dx,total_words_str
call prnstr
mov dx,[total_count]
mov ah,0x20
int 0x61
.process:
ret

foundfile:
mov dx,filestr
call prnstr
jmp start

foundapp:
mov dx,appstr
call prnstr
jmp start

foundbatch:
mov dx,batchstr
call prnstr
jmp start

debugstr:
db " Found :: ",0
debugstr2:
db " : ",0
total_words_str:
db " Total Words found: ",0

;Help Strings
helpstr:
db "Command Help >> ",0
;db 'file, app, batch, bye,close,quit,exit, clock, alarm, roam, pipe :',0
filestr:
db 'Define a file name using - fname and then search'
db ' the current directory using - q command .'
db ' This will load the file at current location (loc).',0
appstr:
db 'Just load an app like any other file and run it.'
db ' You can also use roam command to control selection easily.'
db 0
batchstr:
db 'Load batch file and run it. Or just type its name.'
db ' You can also use roam command to control selection easily.'
db 0
microhelp:
db ' Or you can just mention its name like - pwd and'
db ' this will search the current directory for a COM or a BAT file'
db ' named pwd and accordingly run it or batch it.'
db 0
notfoundstr:
db 'NotFound',0

;Commands
c_debug:
db 'debug',0
c_file:
db 'file',0
c_app:
db 'app',0
c_batch:
db 'batch',0

c_cls:
db 'cls',0
c_clear:
db 'clear',0
c_color:
db 'color',0
c_bye:
db 'bye',0
c_close:
db 'close',0
c_quit:
db 'quit',0
c_exit:
db 'exit',0

;Variables
loc:
dw 0x7000
pos:
dw 0
strlen:
dw 0

word_count:
dw 0
total_count:
dw 0
found_number:
dw 0
debug_switch: db 0x0f

found_presence:
times 40 dw 0
found_presence_end:

times (512*3)-($-$$) db 0
