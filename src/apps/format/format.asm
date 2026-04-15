;======================
; Format Utility
;
; Made by -
; Divyavrat Jugtawat
;======================

;Predefinitions
CODELOC equ 0x6000
TEMPLOC equ code_end
bpbBytesPerSector equ 512
bpbTotalSectors equ 2880

org CODELOC
use16

;Jump to main code
jmp code_start
version_string:
db " Aplaun OS FORMAT tool ver 0.3",0

;Main Code
code_start:
call os_clear_screen ;Clear

;Confirm formatting
mov ax,version_string
mov bx,unsaved_str
mov cx,confirm_str
call os_dialog_box2 ;OK/CANCEL
cmp ax,0 ;if cancelled
jne quit

;Load kernel file to memory
mov ax,0x4C0D
call keybsto
mov ax,version_string
mov bx,kernel_filename
mov cx,loading_str
call os_dialog_box

mov ax,kernel_filename
mov cx,TEMPLOC
call os_load_file
cmp dx,0xF0F0
jne not_loaded
mov [kernel_filesize],bx ;Save size for later

;Clear all drive sectors after MBR
mov cx,bpbTotalSectors
clear_loop:
push cx
mov dx,cx
inc dx
mov ah,0x71 ;Set cluster
int 0x61

mov bx,bpbTotalSectors
sub bx,dx
mov dx,bx
mov [current_cluster],dx
mov bx,tempstr
mov ah,0x2A ;INT to String
int 0x61

; mov bl,0x36
; mov ax,0x1201 ;Stop refresh
; int 0x10 ;BIOS API

;Show progress
mov ax,0x4C0D
call keybsto
mov ax,version_string
mov bx,clearing_str
mov cx,tempstr
call os_dialog_box

xor eax,eax
mov ax,[current_cluster]
xor edx,edx
;imul ax,100
imul eax,80
; mov ebx,80
; mul ebx
mov ebx,bpbTotalSectors
div ebx
mov dh,1
mov dl,1
mov si,ax
;dec si
mov di,2
mov bl,0x2F
cmp ax,1
jb .skip_progress
;cmp ax,80
cmp ax,78
ja .skip_progress
call os_draw_block
; mov dx,0
; call os_move_cursor
; mov dx,ax
; mov ah,0x20
; int 0x61
; mov ax,0x0E20
; int 0x10
; int 0x10
.skip_progress:
call os_hide_cursor

; mov bl,0x36
; mov ax,0x1200 ;Start refresh
; int 0x10 ;BIOS API

mov ah,0x73 ;Save cluster LBA
mov bx,clean_sector
int 0x61
pop cx
loop clear_loop

;Save kernel file back to drive
mov ax,0x4C0D
call keybsto
mov ax,version_string
mov bx,kernel_filename
mov cx,saving_str
call os_dialog_box

mov ax,kernel_filename
mov bx,TEMPLOC
mov cx,[kernel_filesize]
call os_write_file

call os_clear_screen
mov ax,0x4C0D
call keybsto
mov ax,version_string
mov bx,kernel_filename
mov cx,finished_str
call os_dialog_box
mov dx,0
call os_move_cursor

;After successful save
;quit to kernel
mov ah,0x4C ;Quit function
mov al,0 ;No Error
int 0x21 ;DOS API

quit:
;Return back
ret

not_loaded:
;Show load error
mov ax,load_error_str1
mov bx,load_error_str2
mov cx,load_error_str3
call os_dialog_box
;Return
ret

;Functions

keybsto:
pusha
mov cx,ax
mov ah,0x05
int 16h
popa
ret

;Strings and Variables
unsaved_str:
db "Unsaved Data will lost.",0
confirm_str:
db "Are you sure ?",0
kernel_filename:
db 'kernel.com',0
kernel_filesize:
dw 23552
current_cluster:
dw 1

loading_str:
db "Loading...",0
clearing_str:
db "Clearing data in sectors :",0
saving_str:
db "Saving...",0
finished_str:
db "Finished",0
load_error_str1:
db "Kernel file : Load error",0
load_error_str2:
db "Check if drive is still connected.",0
load_error_str3:
db "Or if file is present and can be loaded.",0

tempstr:
times 50 db 0

clean_sector:
times bpbBytesPerSector db 0

;Add API file
include "api2b.inc"

code_end:
