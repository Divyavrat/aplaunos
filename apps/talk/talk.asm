org 0x6000
use16

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

mov dx,c_debug
mov bx,founddebug
call findword

mov dx,c_hy
mov bx,foundhy
call findword

mov dx,c_hi
mov bx,foundhy
call findword

mov dx,c_hey
mov bx,foundhy
call findword

mov dx,c_hello
mov bx,foundhello
call findword

mov dx,c_thank
mov bx,foundthank
call findword

mov dx,c_time
mov bx,foundtime
call findword

mov dx,c_date
mov bx,founddate
call findword

mov dx,c_name
mov bx,foundname
call findword

mov dx,c_book
mov bx,foundbook
call findword

mov dx,c_song
mov bx,foundmusic
call findword

mov dx,c_music
mov bx,foundmusic
call findword

mov dx,c_boring
mov bx,foundboring
call findword

mov dx,c_do
mov bx,founddo
call findword

mov dx,c_cook
mov bx,foundcook
call findword

mov dx,c_food
mov bx,foundfood
call findword

mov dx,c_like
mov bx,foundlike
call findword

mov dx,c_love
mov bx,foundlike
call findword

mov dx,c_lol
mov bx,foundlol
call findword

mov dx,c_fine
mov bx,foundgood
call findword

mov dx,c_good
mov bx,foundgood
call findword

mov dx,c_what
mov bx,foundwhat
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

mov dx,c_you
mov bx,foundyou
call findword

mov dx,c_me
mov bx,foundyou
call findword

mov bx,[loc]
add bx,[pos]
cmp byte [bx],'0'
jl .not_found
cmp byte [bx],'9'
jg .not_found

push bx
mov dx,bx
mov ah,0x2b
int 0x61
mov [found_number],dx
;mov dx,[strlen]
;add [pos],dx
pop bx
mov dx,si
sub dx,bx
add [pos],dx
jmp .cmploop

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

;mov ah,0x33
;mov dx,[loc]
;int 0x61
;mov [strlen],dx

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

mov dx,[loc]
mov ah,0x3d
int 0x21

cmp dx,0xf0f0
jne .notfound
call ax
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

founddebug:
not byte [debug_switch]
inc word [pos]
jmp start.cmploop

foundhy:
mov dx,hystr
call prnstr
jmp start

foundhello:
mov dx,hellostr
call prnstr
jmp start

foundthank:
mov dx,thankstr
call prnstr
jmp start

foundtime:
mov dx,timestr
call prnstr
mov dl,'t'
mov ah,0x0E
int 0x61
jmp start

founddate:
mov dx,datestr
call prnstr
mov dl,'d'
mov ah,0x0E
int 0x61
jmp start

foundname:
mov dx,namestr
call prnstr
mov dx,[loc]
call getstr
call newline
mov dx,c_hy
call prnstr
mov dl,' '
mov ah,0x02
int 0x21
mov dx,[loc]
call prnstr
jmp start

foundbook:
mov dx,bookstr
call prnstr
jmp start

foundmusic:
mov dx,musicstr
call prnstr
jmp start

foundboring:
mov dx,boringstr
call prnstr
jmp start

founddo:
mov bx,.found
jmp presence_word
.process:
mov word [.found],0
mov dx,dostr
call prnstr
mov dx,[loc]
call getstr
call newline
mov dx,dostr2
call prnstr
jmp start
.found: dw 0

foundcook:
mov dx,cookstr
call prnstr
jmp start

foundfood:
mov dx,foodstr
call prnstr
jmp start

foundlike:
mov dx,.process
call add_presence_location
mov bx,.found
jmp presence_word
.process:
mov word [.found],0
mov dx,likestr
call prnstr
jmp start
.found: dw 0

foundlol:
mov dx,lolstr
call prnstr
jmp start

foundgood:
mov dx,goodstr
call prnstr
jmp start

foundwhat:
mov dx,.process
call add_presence_location
mov bx,.found
jmp presence_word
.process:
mov word [.found],0
mov dx,whatstr
call prnstr
jmp start
.found: dw 0

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
cmp dl,0
je .number
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

foundyou:
mov dx,.process
call add_presence_location
mov bx,.found
jmp presence_word
.process:
mov word [.found],0
mov dx,youstr
call prnstr
jmp start
.found: dw 0

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

helpstr:
db ' Talk to me : ',0
debugstr:
db " Found :: ",0
debugstr2:
db " : ",0
total_words_str:
db " Total Words found: ",0
hystr:
db " Hy , Greetings , Wha'sup!! ",0
hellostr:
db "Well hello to you too sir.",0
thankstr:
db " Welcome :)",0
timestr:
db "Time is :",0
datestr:
db "Date is :",0
namestr:
db "My name is Talk.App and what's yours ? ",0
bookstr:
db "Reading calms me down...",0
musicstr:
db "  They say music can alter moods and talk to you.",0
boringstr:
db "There is nothing to do...",0
notfoundstr:
db "I didn't understand that.",0
cookstr:
db "I just cannot cook. Not taught to me yet.",0
foodstr:
db "Good Food can fix everything"
db " from angry men to broken hearts.",0
likestr:
db "Everything is good.",0
lolstr:
db "Lots o' Laffs.",0
goodstr:
db " Great !! ",0
whatstr:
db " A Cow is a four legged animal"
db " that roams the common land"
db " eating grass, leaves, etc.",0
dostr:
db " What do you plan on doing today ? ",0
dostr2:
db "Best-'o-luck for that.",0
youstr:
db "You, Me, We are all the same.",0
c_debug:
db 'debug',0
c_hy:
db 'hy',0
c_hi:
db 'hi',0
c_hey:
db 'hey',0
c_hello:
db 'hello',0
c_thank:
db 'thank',0
c_time:
db 'time',0
c_date:
db 'date',0
c_name:
db 'name',0
c_book:
db 'book',0
c_song:
db 'song',0
c_music:
db 'music',0
c_boring:
db 'boring',0
c_do:
db 'do',0
c_cook:
db 'cook',0
c_food:
db 'food',0
c_like:
db 'like',0
c_love:
db 'love',0
c_lol:
db 'lol',0
c_fine:
db 'fine',0
c_good:
db 'good',0
c_what:
db 'what',0
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
c_you:
db 'you',0
c_me:
db 'me',0
loc:
dw 0x8000
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

times (512*4)-($-$$) db 0