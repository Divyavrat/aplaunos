;org 7C00h ;To run as a bootloader
;org 0500h ;To run as a kernel
org 6000h ;To run as an application
cli
mov ax,0
mov es,ax
mov ds,ax
sti
main:
call new
mov si,hello
call print
mov di,extra
call get
call new
mov si,hy
call print
jmp main
print:
lodsb
mov ah,0Eh
int 10h
cmp al,0
jne print
ret
get:
mov ah,0
int 16h
cmp al,0Dh
je getend
stosb
mov ah,0Eh
int 10h
jmp get
getend:
mov al,0
stosb
ret
new:
mov ax,0E0Dh
int 10h
mov ax,0E0Ah
int 10h
ret
hello:
db "Ur Name ?",0
hy: db "Hy "
extra:
;0
