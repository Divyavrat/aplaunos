;======================
;Quick Shell
; for Aplaun OS
;
; Made by -
; Divyavrat Jugtawat
;======================

CODELOC equ 0x6000
TEMPLOC equ 0x9000
FILESIZE equ 6
org CODELOC
use16

jmp code_start
version_string:
db " Aplaun OS Quick Shell ver 1.5",0

code_start:
mov [initial_stack],sp
;start:
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

mov dx,set_idle_command
mov ah,0x0D
int 0x61
mov ah,0x0F
int 0x61
mov dx,set_idle_time
mov ah,0x0D
int 0x61
mov ah,0x0F
int 0x61

jmp welcome_screen
set_idle_command:
db "idlecmd qshell ",0
set_idle_time:
db "idletime 0 ",0
set_extra_idle_time:
db "idletime 20 ",0

welcome_screen:
call mouselib_setup
mov cx, 0
mov dx, 0
call mouselib_move
mov si,buttons_list
mov [selected_button],si
main_screen:
call os_hide_cursor
call os_clear_screen
;call mouselib_hide
.loop:
	mov ax,version_string
	mov bx,.welcome_str
	mov cx,[color]
	call os_draw_background
	
	;Draw all Buttons
	mov si,buttons_list
	.button_draw_loop:
	mov ax,[si]
	mov [currently_drawing_button],si
	cmp ax,0
	je .button_draw_loop_done
	mov si,ax ;Get button data pointer
	call draw_button
	add word [currently_drawing_button],2
	mov si,[currently_drawing_button]
	jmp .button_draw_loop
	.button_draw_loop_done:
	
	.recheck:
	call mouselib_locate
	;call mouselib_freemove
	call mouselib_show
	call mouselib_input_wait
	jc .key_pressed
	; call mouselib_anyclick
	; jc .button
	; call mouselib_hide
	; jmp .recheck
	jmp .button
.key_pressed:
	;call os_check_for_key
	call mouselib_hide
	mov ah,0x00
	int 0x16
	; cmp al, 27 ;Esc
	; je exit_handler
	cmp al, 13 ;Enter
	je .enter_selected_button
	
cmp ah,0x47
je .decrease_selected_button;.home
cmp ah,0x4f
je .increase_selected_button;.end
cmp ah,0x51
je .increase_selected_button;.page_down
cmp ah,0x49
je .decrease_selected_button;.page_up
cmp ah,0x48
je .decrease_selected_button;.up
cmp ah,0x4B
je .decrease_selected_button;.left
cmp ah,0x4D
je .increase_selected_button;.right
cmp ah,0x50
je .increase_selected_button;.down
	
jmp .check_shortcut_buttons

.increase_selected_button:
mov dx,[selected_button]
add dx,2 ; Adjustment for the ending zero
cmp dx,buttons_list_end
jge .reset_selection
add word [selected_button],2
jmp main_screen

.decrease_selected_button:
mov dx,[selected_button]
cmp dx,buttons_list
jle .reset_selection
sub word [selected_button],2
jmp main_screen

.reset_selection:
mov dx,buttons_list
mov [selected_button],dx
jmp main_screen

.enter_selected_button:
mov si,[selected_button]
lodsw
mov si,ax
add si,6*2
lodsw ; Get Mouse Handler
call ax
jmp main_screen

	.check_shortcut_buttons:
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
	cmp ax,0
	je .button_key_check_loop
	cmp al,dl ;Check low value
	je .key_found ; Found
	cmp ah,dh ;Check higher value
	je .key_found
	jmp .button_key_check_loop ;Check more keys
	.button_key_check_loop_end:
	
	jmp .loop
.key_found:
sub si,2
mov [selected_button],si
	call bx ; If equal execute handler
	jmp main_screen
	.key_pressed_value:
	dw 0
.button:
call mouselib_hide
call mouse_get_button_value
call mouselib_locate
;call mouselib_freemove

; cmp dx,3
; jl exit_handler
; cmp dx,22
; jg exit_handler

;Save Mouse data
mov [mouse_button],bx
mov [mouse_x],cx
mov [mouse_y],dx

;Check Mouse position over buttons
mov si,buttons_list
.mouse_button_check:
mov [currently_drawing_button],si
lodsw ; Get button data pointer
cmp ax,0 ; End If zero found
je .mouse_button_check_done
;push si ;Store
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

mov di,[si+10] ; Get Draw Handler
mov ax,[si+12] ; Get Mouse Handler
;pop si

;Restore Mouse data
mov bx,[mouse_button]
mov cx,[mouse_x]
mov dx,[mouse_y]
mov si,[currently_drawing_button]
mov [selected_button],si

cmp bx,0 ; Check if mouse was clicked
je .mouse_over ; If not then just over draw

call ax ; Jump to handler
jmp .mouse_button_check_done
;jmp main_screen
.mouse_over:
;Redraw button with over graphics

cmp di,0 ; Check if draw handler is present
je .no_draw_handler
call di
jmp .mouse_button_done
.no_draw_handler:
;Draw with default function
mov si,[selected_button]
lodsw
mov si,ax
call draw_button
.mouse_button_done:
;jmp .recheck
jmp .mouse_button_check_done

.mouse_button_not_found:
mov si,[selected_button]
lodsw
mov si,ax
mov word [selected_button],0
call draw_button

;pop si ;ReStore
mov si,[currently_drawing_button]
add si,2
jmp .mouse_button_check
.mouse_button_check_done:
cmp word [mouse_button],0
jne .button_clicked
jmp .recheck
.button_clicked:
jmp main_screen
.welcome_str:
db ' Use Capital Characters for shortcuts.'
db ' You can use mouse or keys to control.'
db 0

;Button data
button_width:
dw 0
button_text:
dw 0

;Mouse data
mouse_button:
dw 0
mouse_x:
dw 0
mouse_y:
dw 0

collect_button_data:
lodsw ;Get colour
mov bx,ax
lodsw ;Get X Start
mov dl,al
lodsw ;Get Y Start
mov dh,al
lodsw ;Get Width
mov [button_width],ax
lodsw ;Get Height
mov di,ax
mov ax,0
add al,dh
add di,ax
ret

; SI-pointing to button data
draw_button:
call collect_button_data
mov ax,[currently_drawing_button]
clc
cmp [selected_button],ax
jne .not_selected
not bx
stc
.not_selected:
lodsw ;Load draw handler
cmp ax,0
je .draw_with_default
call ax
ret
.draw_with_default:
call default_draw_function
ret

default_draw_function:
;Skip Mouse Handler
;Skip Shortcut key
add si,4
mov [button_text],si ;Save pointer to text
mov si,[button_width]

;Draw Block Function
call os_draw_block

inc dh
inc dl
call os_move_cursor
mov si,[button_text] ;Get pointer to text
;Print Button Text
call os_print_string
ret

mouse_get_button_value:
mov bx,0
call mouselib_anyclick
jc .click
jmp .done
.click:
call mouselib_leftclick
jc .left
jmp .clickright
.left:
add bx,1
.clickright:
call mouselib_rightclick
jc .right
jmp .midclick
.right:
add bx,2
.midclick:
call mouselib_middleclick
jc .middle
jmp .done
.middle:
add bx,4
.done:
ret

;===================
;Return back to OS
;after resetting drivers
;===================
exit_handler:
mov dx,set_extra_idle_time
mov ah,0x0D
int 0x61
mov ah,0x0F
int 0x61
quick_exit_handler:
mov sp,[initial_stack]
call mouselib_hide
call os_clear_screen
call os_show_cursor
call mouselib_remove_driver
ret

;List of all button data pointers
;Each word to indicate one button. End with zero.
buttons_list:
dw file_button_data
dw command_button_data
dw shutdown_button_data
dw restart_button_data
dw halt_button_data

dw command_line_button_data

buttons_list_end:
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
command_button_data:
dw 0x4F,20,5,15,3,0,command_handler,'c'
db '[c] Command',0

shutdown_button_data:
dw 0x74,6,20,20,3,0,shutdown_handler,'q'
db '[q] Shutdown',0
restart_button_data:
dw 0x74,27,20,20,3,0,restart_handler,'r'
db '[r] Restart',0
halt_button_data:
dw 0x7F,48,20,10,3,0,halt_handler,0
db 'Halt',0

command_line_button_data:
dw 0x12,0x32,13,20,3,0,exit_handler,0x011B
db 'Commandline ->>',0

selected_button:
dw 0
currently_drawing_button:
dw 0

;===================
;File Manager
;===================
file_handler:
call os_file_selector ; Get file name
cmp dx,0x0f0f ; If file not selected
je .quit

; mov bx,0
; mov cx,0
; call os_dialog_box

mov dx,ax ; Store in keyboard buffer
mov ah,0x0D
int 0x61
jmp quick_exit_handler ; Execute
.quit:
ret

;===================
;Command Execution
;===================
command_handler:
mov ah,0x37 ; Get kernel buffer address
int 0x61
mov bx,.enter_command_str
mov ax,dx ; Get command as input
call os_input_dialog

; Store it in keyboard buffer
; from where it will
; be executed
mov dx,ax
mov ah,0x0D
int 0x61
; Storing Enter key
mov cx,1C0Dh
mov ah,05h
int 16h
jmp quick_exit_handler ; Execute
;mov ah,0x36 ;Execute kernel buffer
;int 0x61
;ret
.enter_command_str:
db "Enter OS command :",0

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

ret
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
jne .quit
.check_loop:
in al,0x64
cmp al,0x02
je .check_loop
mov al,0xfe
out 0x64,al
.quit:
ret
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