;=============================
;Dynamically used system calls
;
; can be used in Aplaun OS
; to add use include "api2b.inc"
; compatible with MikeOS calls
;
; Made by -
; Divyavrat Jugtawat
;=============================

os_print_string:
pusha
mov ah,0x01
int 0x2b
popa
ret

os_move_cursor:
pusha
mov ah,0x03
int 0x2b
popa
ret

os_show_cursor:
pusha
mov ah,0x05
int 0x2b
popa
ret

os_hide_cursor:
pusha
mov ah,0x06
int 0x2b
popa
ret

os_clear_screen:
pusha
mov ah,0x06
int 0x61
popa
ret

os_dialog_box:
pusha
mov dx,ax
mov ah,0x20
int 0x2b
popa
ret

os_dialog_box2:
mov dx,ax
mov ah,0x21
int 0x2b
ret

os_list_dialog:
mov dx,ax
mov ah,0x22
int 0x2b
ret

os_input_dialog:
mov dx,ax
mov ah,0x23
int 0x2b
ret

os_draw_background:
pusha
mov dx,ax
mov ah,0x25
int 0x2b
popa
ret

os_draw_block:
pusha
mov ah,0x26
int 0x2b
popa
ret

;ax=selected file name
os_file_selector:
mov ah,0x57
int 0x2b
ret

os_load_file:
pusha
mov dx,ax
mov ah,0x50
int 0x2b
mov [.temp],dx
mov [.tempsize],bx
popa
mov dx,[.temp]
mov bx,[.tempsize]
ret
.temp:
dw 0
.tempsize:
dw 0

os_write_file:
pusha
mov dx,ax
mov ah,0x51
int 0x2b
popa
ret
