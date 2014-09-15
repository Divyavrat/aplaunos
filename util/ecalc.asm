org 0x6000
use16

; mov ax,0x0003
; int 0x10
; mov ax,0x0500
; int 10h
; mov ch,0x20
; mov ah,0x01
; int 0x10

main:
mov dx,enterstr
call prnstr
mov di,[loc]
call getstr
mov si,[loc]
.loop:
lodsb

cmp al,0
je .end
cmp al,0x0D
je .end
cmp al,0x0A
je .end

cmp al,'+'
je .sym
cmp al,'-'
je .sym
cmp al,'*'
je .sym
cmp al,'/'
je .sym
cmp al,'%'
je .sym

cmp al,'0'
jge .num
jmp .loop

.end:
mov ah,0x0B
int 0x61
mov al,[symbol]
call .endsym
mov edx,[no2]
mov ah,0x27
int 0x61
ret

.endsym:
cmp al,'+'
je .add
cmp al,'-'
je .sub
cmp al,'*'
je .mul
cmp al,'/'
je .div
cmp al,'%'
je .rem
cmp al,0
je .empty
ret
.empty:
mov eax,[no1]
mov [no2],eax
ret

.sym:
push ax
mov al,[symbol]
call .currentsym
pop ax
mov [symbol],al
jmp .loop

.currentsym:
cmp al,'+'
je .add
cmp al,'-'
je .sub
cmp al,'*'
je .mul
cmp al,'/'
je .div
cmp al,'%'
je .rem
pop ax
pop ax
mov [symbol],al
mov eax,[no1]
add [no2],eax
mov word [no1],0
jmp .loop

.add:
mov eax,[no1]
add [no2],eax
mov word [no1],0
ret
.sub:
mov eax,[no1]
sub [no2],eax
mov word [no1],0
ret
.mul:
mov ecx,[no1]
mov eax,[no2]
xor edx,edx
mul ecx
mov [no2],eax
mov word [no1],0
ret
.div:
mov ecx,[no1]
mov eax,[no2]
xor edx,edx
div ecx
mov [no2],eax
mov word [no1],0
ret
.rem:
mov ecx,[no1]
mov eax,[no2]
xor edx,edx
div ecx
mov [no2],edx
mov word [no1],0
ret

.num:
cmp al,'9'
jg .loop
xor ecx,ecx
mov cl,al
sub cl,'0'
push ecx
mov eax,[no1]
mov ebx,10
xor edx,edx
mul ebx
pop ecx
add eax,ecx
mov [no1],eax
jmp .loop

getkey:
xor ah,ah
int 0x16
ret

prnstr:
mov ah,0x03
int 0x61
ret

getstr:
mov dx,di
mov ah,0x04
int 0x61
ret

loc:
dw 0x7000
symbol:
db 0
no1:
dd 0
no2:
dd 0

enterstr:
db 'Enter expression :',0
times 512-($-$$) db 0