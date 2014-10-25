CODELOC equ 0x6000
TEMPLOC equ 0x9000
FILESIZE equ 5
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
	je exit_handler
	cmp al, 13 ;Enter
	je exit_handler
	mov [.key_pressed_value],ax
	
	;Check for button shortcut keys
	mov si,buttons_list
	.button_key_check_loop:
	lodsw ; Get button data pointer
	cmp ax,0 ; End If zero found
	je .button_key_check_loop_end
	push si ; Save
	mov si,ax
	add si,6*2
	lodsw ; Get Mouse Handler
	mov bx,ax
	lodsw ; Get Shortcut key
	pop si ; Restore
	mov dx,[.key_pressed_value]
	cmp al,dl ;Check low value
	je .key_found ; Found
	cmp dh,0
	je .button_key_check_loop
	cmp ah,dh ;Check higher value
	je .key_found
	jmp .button_key_check_loop ;Check more keys
	.button_key_check_loop_end:
	
	jmp .loop
	.key_found:
	jmp bx ; If equal execute handler
	.key_pressed_value:
	dw 0
.button:
call mouselib_hide
call mouselib_locate
;call mouselib_freemove

cmp dx,3
jl exit_handler
cmp dx,22
jg exit_handler

;Save Mouse data
mov [mouse_button],bx
mov [mouse_x],cx
mov [mouse_y],dx

;Check Mouse position over buttons
mov si,buttons_list
.mouse_button_check:
lodsw ; Get button data pointer
cmp ax,0 ; End If zero found
je .mouse_button_check_done
push si ;Store
mov si,ax
mov ax,[si+2] ; Get X Start
cmp [mouse_x],ax
jl .mouse_button_not_found
add ax,[si+6] ;Add Width
cmp [mouse_x],ax
jge .mouse_button_not_found

mov ax,[si+4] ; Get Y Start
cmp [mouse_y],ax
jl .mouse_button_not_found
add ax,[si+8] ;Add Height
cmp [mouse_y],ax
jge .mouse_button_not_found

;Else mouse is over a button

mov ax,[si+12] ; Get Mouse Handler
pop si

;Restore Mouse data
mov bx,[mouse_button]
mov cx,[mouse_x]
mov dx,[mouse_y]

jmp ax ; Jump to handler

.mouse_button_not_found:
pop si ;ReStore
jmp .mouse_button_check
.mouse_button_check_done:

jmp main_screen

.osstring:
db ' Aplaun OS Quick Shell',0
.welcome_str:
db ' Use Capital Characters for shortcuts.',0

;Mouse data
mouse_button:
dw 0
mouse_x:
dw 0
mouse_y:
dw 0

;===================
;Return back to OS
;after resetting drivers
;===================
exit_handler:
	call mouselib_hide
	call os_clear_screen
	call os_show_cursor
	call mouselib_remove_driver
	ret

;List of all button data pointers
;Each word to indicate one button. End with zero.
buttons_list:
dw file_button_data
dw shutdown_button_data
dw restart_button_data
dw halt_button_data

dw command_line_button_data
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

file_button_data:
dw 0x29,2,5,10,3,0,file_handler,'f'
db '[f] File',0
shutdown_button_data:
dw 0x8D,6,13,20,3,0,shutdown_handler,'q'
db '[q] Shutdown',0
restart_button_data:
dw 0x49,27,13,20,3,0,restart_handler,'r'
db '[r] Restart',0
halt_button_data:
dw 0x8D,48,13,10,3,0,halt_handler,0
db 'Halt',0

command_line_button_data:
dw 0x12,0x32,0x13,20,3,0,exit_handler,'c'
db 'Commandline ->>',0

;===================
;File Manager
;===================
file_handler:
call os_file_selector
cmp dx,0x0f0f
je main_screen
mov bx,0
mov cx,0
call os_dialog_box
jmp main_screen

;===================
;Try to connect to APM to Shutdown
;Else Show error and Return
;===================
shutdown_handler:
mov ax,0x4C0D
call keybsto
mov ax,.connecting_apm_str
mov bx,0
mov cx,0
call os_dialog_box

mov ax, 5301h				; Connect to the APM
	xor bx, bx
	int 15h
	je near .connection		; Pass if connected
	cmp ah, 2
	je near .connection		; Pass if already connected
	jc .error				; Bail if fail

mov ax,0x4C0D
call keybsto
mov ax,0
mov bx,.checking_apm_version_str
mov cx,0
call os_dialog_box
	
.connection:
	mov ax, 530Eh				; Check APM Version
	xor bx, bx
	mov cx, 0102h				; v1.2 Required
 	int 15h
	jc .error				; Bail if wrong version

mov ax,0x4C0D
call keybsto
mov ax,0
mov bx,0
mov cx,.shutting_down_str
call os_dialog_box
	
	mov ax, 5307h				; Shutdown
	mov bx, 0001h
	mov cx, 0003h
	int 15h
.error:

mov ax,0
mov bx,0
mov cx,failed_str
call os_dialog_box

mov ax,0x5307
mov bx,0x0001
mov cx,0x0003
int 0x15

jmp main_screen
.connecting_apm_str:
db "Connecting APM...",0
.checking_apm_version_str:
db "Checking APM version...",0
.shutting_down_str:
db "Shutting down....",0

;===================
;Handler to Restart PC
;===================
restart_handler:
mov ax,.restart_str
mov bx,unsaved_str
mov cx,confirm_str
call os_dialog_box2
cmp ax,0
jne main_screen
.check_loop:
in al,0x64
cmp al,0x02
je .check_loop
mov al,0xfe
out 0x64,al
jmp main_screen
.restart_str:
db "Restart >>",0

halt_handler:
mov bl,0xF0
mov dx,0x0202
mov si,40
mov di,20
call os_draw_block
mov dh,(20-2)/2
;mov dl,(2+40)/2
mov dl,3
call os_move_cursor
mov si,.halt_str
call os_print_string
.loop:
cli
hlt
jmp .loop
.halt_str:
db 'System Halted. Safe to turn off.',0

unsaved_str:
db "Unsaved Data will lost.",0
confirm_str:
db "Are you sure ?",0
failed_str:
db "Failed",0

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
mov dx,ax
mov ah,0x21
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