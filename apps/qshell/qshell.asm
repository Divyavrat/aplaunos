CODELOC equ 0x6000
TEMPLOC equ 0x9000
FILESIZE equ 4
org CODELOC
use16
;jmp start
;db '  Define your password here (any length just after colon) :'
;times 200-($-$$) db 0
code_start:
mov [initial_stack],sp
start:
call buffer_clear
mov ah,0x02
int 0x64
mov [oldcolor],dl
; shr dl,4
; shl dl,4
;mov [color_background],dl
call setcolor1
mov ah,0x06
int 61h

welcome_screen:
call mouselib_setup
mov cx, 0
mov dx, 0
call mouselib_move
main_screen:
call os_hide_cursor
call os_clear_screen
;call mouselib_hide
.loop:
	mov ax,.osstring
	mov bx,.welcome_str
	mov cx,[color]
	call os_draw_background
	
	mov bl,0x12
	mov dx,0x1032
	mov si,20
	mov di,0x15
	call os_draw_block
	mov dx,0x1235
	call os_move_cursor
	mov si,.command_str
	call os_print_string
	
	;Draw all Buttons
	mov si,buttons_list
	.button_draw_loop:
	lodsw
	cmp ax,0
	je .button_draw_loop_done
	push si
	mov si,ax ;Get button data pointer
	lodsw ;Get colour
	mov bx,ax
	lodsw ;Get X Start
	mov dl,al
	lodsw ;Get Y Start
	mov dh,al
	lodsw ;Get Width
	mov [.button_width],ax
	lodsw ;Get Height
	mov di,ax
	mov ax,0
	add al,dh
	add di,ax
	lodsw ;Load draw handler
	cmp ax,0
	je .default_draw_function
	call ax
	pop si
	jmp .button_draw_loop
	.default_draw_function:
	;Skip Mouse Handler
	;Skip Shortcut key
	add si,4
	mov [.button_text],si ;Save pointer to text
	mov si,[.button_width]
	
	;Draw Block Function
	call os_draw_block
	
	inc dh
	inc dl
	call os_move_cursor
	mov si,[.button_text] ;Get pointer to text
	;Print Button Text
	call os_print_string
	pop si
	jmp .button_draw_loop
	.button_width:
	dw 0
	.button_text:
	dw 0
	.button_draw_loop_done:
	
	.recheck:
	call mouselib_locate
	;call mouselib_freemove
	call mouselib_show
	call mouselib_input_wait
	jc .key_pressed
	call mouselib_anyclick
	jc .button
	call mouselib_hide
	jmp .recheck
.key_pressed:
	;call os_check_for_key
	call mouselib_hide
	mov ah,0x00
	int 0x16
	cmp al, 27 ;Esc
	je .exit
	cmp al, 13 ;Enter
	je .exit
	
	;Check for button shortcut keys
	; cmp al,'c'
	; je .common_link
	jmp shutdown_handler
	
	jmp .loop
.button:
call mouselib_hide
call mouselib_locate
;call mouselib_freemove
cmp dx,6
jl .exit
cmp dx,20
jg .exit

;Check Mouse position over buttons
jmp shutdown_handler

.exit:
	call mouselib_hide
	call os_clear_screen
	call os_show_cursor
	call mouselib_remove_driver
	ret

.osstring:
db ' Aplaun OS Quick Shell',0
.welcome_str:
db ' Use Capital Characters for shortcuts.',0

.command_str:
db 'Commandline ->>',0

;List of all button data pointers
;Each word to indicate one button. End with zero.
buttons_list:
dw shutdown_button_data
dw restart_button_data
dw 0

;===================
;Button Data
;
; Structure :
; 1 word - Colour
; 1 word - X Start Pos
; 1 word - Y Start Pos
; 1 word - Width
; 1 word - Height
; 1 word - Draw Handler
; 1 word - Mouse Handler
; 1 word - Shortcut key
;
;===================

shutdown_button_data:
dw 0x8D,6,13,10,3,0,shutdown_handler,'q'
db 'Shutdown',0
restart_button_data:
dw 0x49,17,13,10,3,0,restart_handler,'r'
db 'Restart',0

shutdown_handler:
mov ax,0x4C0D
call keybsto
mov ax,.shutting_down_str
mov bx,0
mov cx,0
call os_dialog_box

jmp main_screen
.shutting_down_str:
db "Shutting down....",0

restart_handler:
mov ax,.restart_str
mov bx,unsaved_str
mov cx,confirm_str
call os_dialog_box2
cmp ax,0
je main_screen
.check_loop:
in al,0x64
cmp al,0x02
je .check_loop
mov al,0xfe
out 0x64,al
jmp main_screen
.restart_str:
db "Restart >>",0

unsaved_str:
db "Unsaved Data will lost.",0
confirm_str:
db "Are you sure ?",0

keybsto:
pusha
mov cx,ax
mov ah,0x05
int 16h
popa
ret

buffer_clear:
mov ah,0x01
int 0x16
jz .clear
mov ah,0x00
int 0x16
jmp buffer_clear
.clear:
ret

setcolor1:
mov dl,[color1]
mov ah,0x01
int 0x61
ret

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
pusha
mov dx,ax
mov ah,0x21
int 0x2b
popa
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

initial_stack:
dw 0x9000
message_flag:
db 0x0f
color:
dw 0x3534
color1:
db 0xf1
color2:
db 0xf4
oldcolor:
db 0x30
;color_background:
;db 0x30

include 'mouse.lib'
times (512*FILESIZE)-($-$$) db 0