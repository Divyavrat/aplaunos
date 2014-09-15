org 0x6000
use16

main_program:
cmp si,0
jne start.argument_found
start:
cmp byte [.argument_call],0xf0
je .foundexit
mov word [pos],0
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

mov dx,c_hy
mov bx,.foundhy
call findword

mov dx,c_hi
mov bx,.foundhy
call findword

mov dx,c_hey
mov bx,.foundhy
call findword

mov dx,c_hello
mov bx,.foundhello
call findword

mov dx,c_thank
mov bx,.foundthank
call findword

mov dx,c_time
mov bx,.foundtime
call findword

mov dx,c_date
mov bx,.founddate
call findword

mov dx,c_name
mov bx,.foundname
call findword

mov dx,c_book
mov bx,.foundbook
call findword

mov dx,c_song
mov bx,.foundmusic
call findword

mov dx,c_music
mov bx,.foundmusic
call findword

mov dx,c_boring
mov bx,.foundboring
call findword

mov dx,c_do
mov bx,.founddo
call findword

mov dx,c_cook
mov bx,.foundcook
call findword

mov dx,c_food
mov bx,.foundfood
call findword

mov dx,c_like
mov bx,.foundlike
call findword

mov dx,c_love
mov bx,.foundlike
call findword

mov dx,c_lol
mov bx,.foundlol
call findword

mov dx,c_fine
mov bx,.foundgood
call findword

mov dx,c_good
mov bx,.foundgood
call findword

mov dx,c_what
mov bx,.foundwhat
call findword

mov dx,c_cls
mov bx,.foundclear
call findword

mov dx,c_clear
mov bx,.foundclear
call findword

mov dx,c_bye
mov bx,.foundexit
call findword

mov dx,c_close
mov bx,.foundexit
call findword

mov dx,c_quit
mov bx,.foundexit
call findword

mov dx,c_exit
mov bx,.foundexit
call findword

mov dx,c_you
mov bx,.foundyou
call findword

mov dx,c_me
mov bx,.foundyou
call findword

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
cmp byte [start.present_like],0
jne .word_like
cmp byte [start.present_do],0
jne .word_do
cmp byte [start.what_present],0
jne .word_what
cmp byte [start.present_you],0
jne .word_you

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
je .foundexit
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

.foundhy:
mov dx,hystr
call prnstr
jmp start

.foundhello:
mov dx,hellostr
call prnstr
jmp start

.foundthank:
mov dx,thankstr
call prnstr
jmp start

.foundtime:
mov dx,timestr
call prnstr
mov dl,'t'
mov ah,0x0E
int 0x61
jmp start

.founddate:
mov dx,datestr
call prnstr
mov dl,'d'
mov ah,0x0E
int 0x61
jmp start

.foundname:
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

.foundbook:
mov dx,bookstr
call prnstr
jmp start

.foundmusic:
mov dx,musicstr
call prnstr
jmp start

.foundboring:
mov dx,boringstr
call prnstr
jmp start

.founddo:
mov dx,[word_count]
mov [.present_do],dx
inc word [pos]
jmp start.cmploop
.word_do:
mov word [.present_do],0
mov dx,dostr
call prnstr
mov dx,[loc]
call getstr
call newline
mov dx,dostr2
call prnstr
jmp start
.present_do: dw 0

.foundcook:
mov dx,cookstr
call prnstr
jmp start

.foundfood:
mov dx,foodstr
call prnstr
jmp start

.foundlike:
mov dx,[word_count]
mov [.present_like],dx
inc word [pos]
jmp start.cmploop
.word_like:
mov word [.present_like],0
mov dx,likestr
call prnstr
jmp start
.present_like: dw 0

.foundlol:
mov dx,lolstr
call prnstr
jmp start

.foundgood:
mov dx,goodstr
call prnstr
jmp start

.foundwhat:
mov dx,[word_count]
mov [.what_present],dx
inc word [pos]
jmp start.cmploop
.word_what:
mov word [.what_present],0
mov dx,whatstr
call prnstr
jmp start
.what_present: dw 0

.foundclear:
mov ah,0x06
int 0x61
jmp start

.foundexit:
ret

.foundyou:
mov dx,[word_count]
mov [.present_you],dx
inc word [pos]
jmp start.cmploop
.word_you:
mov word [.present_you],0
mov dx,youstr
call prnstr
jmp start
.present_you: dw 0

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
inc word [word_count]
popa
pop ax
jmp bx

helpstr:
db ' Talk to me : ',0
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
times (512*4)-($-$$) db 0