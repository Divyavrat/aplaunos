;======================
;Quick Shell
; for Aplaun OS
;
; Made by -
; Divyavrat Jugtawat
;======================

;Predefinitions

CODELOC equ 0x6000
TEMPLOC equ data_settings_end
FILESIZE equ 16
PASSWORD_DIALOG_LOC equ 0x0202
PASSWORD_LENGTH equ 256
pwd equ PASSWORD_LENGTH*0
message equ PASSWORD_LENGTH*1
recieved equ PASSWORD_LENGTH*2

org CODELOC
use16

;Jump to main code
jmp code_start
version_string:
db " Aplaun OS Quick Shell ver 1.9",0

;Main Code
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

;Load settings from memory
mov ah,0x61 ;Allocate function
mov dx,1 ; One block
int 0x2b
cmp dx,0xf0f0
jne .set_configuration
mov [data_settings_handle],bh

mov ah,0x63
mov bh,[data_settings_handle]
mov di,data_settings
int 0x2b
cmp word [configuration_finished],0xf0f0
je .set_configuration_skip
.set_configuration:
;Set shell as default to run
call load_setting_file
call data_settings_save
call lock_handler
mov dx,autorun_str
call execute_string
jmp code_start
.set_configuration_skip:

jmp welcome_screen
set_extra_idle_time:
db "idletime 20 ",0
autorun_str:
db "confg ",0

welcome_screen:
call mouselib_setup
mov cx, 0
mov dx, 0
call mouselib_move
mov si,buttons_list
mov [selected_button],si
main_screen:
;call mouselib_hide
; .loop:
call os_hide_cursor
call os_clear_screen
	mov ax,version_string
	mov bx,.welcome_str
	mov cx,[color]
	call os_draw_background
	
	;Draw all Buttons
	mov si,buttons_list
	.button_draw_loop:
	mov [currently_drawing_button],si
	lodsw ; Get data pointer in register
	cmp ax,0
	je .button_draw_loop_done
	mov si,ax ;Get button data pointer
	call draw_button
	add word [currently_drawing_button],2
	mov si,[currently_drawing_button]
	jmp .button_draw_loop
	.button_draw_loop_done:
	
	.recheck:
call mouselib_locate ; Get Mouse position
;call mouselib_freemove
call mouselib_show ; Show mouse
	;call mouselib_input_wait ; Wait for an event
call waitevent_idle_functions

jc .key_pressed ; If keyboard input is recieved
; call mouselib_anyclick
; jc .button
; call mouselib_hide
; jmp .recheck ; Else check mouse
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
	
	;jmp .loop
	jmp main_screen
.key_found:
sub si,2
mov [selected_button],si
	call bx ; If equal execute handler
	jmp main_screen
	.key_pressed_value:
	dw 0
	
; Check mouse position
; if its over a button or not
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

pusha
;Redraw the previous button
mov bx,[selected_button]
mov bx,[bx]
mov si,[currently_drawing_button]
mov [selected_button],si ;Set new button
mov si,bx
;call draw_button
;call draw_selected_button
popa

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
call draw_selected_button
.mouse_button_done:
;jmp .recheck
jmp .mouse_button_check_done

.mouse_button_not_found:

mov si,[currently_drawing_button]
lodsw
mov si,ax
call draw_button

;mov ax,buttons_list
;mov [selected_button],ax

;pop si ;ReStore
mov si,[currently_drawing_button]
add si,2
jmp .mouse_button_check
.mouse_button_check_done:
call draw_selected_button
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
pusha
; mov dx,[selected_button]
; mov ah,0x24
; int 0x61
; mov dx,[currently_drawing_button]
; mov ah,0x24
; int 0x61
; mov ah,0
; int 16h
popa
call collect_button_data
mov ax,[currently_drawing_button]
clc
cmp [selected_button],ax
jne .not_selected
not bx
stc
.not_selected:

; cmp si,buttons_list_end
; jge .do_not_draw
lodsw ;Load draw handler
cmp ax,0
je .draw_with_default
call ax

; cmp word [currently_drawing_button],buttons_list
; jl .do_not_draw
; cmp word [currently_drawing_button],buttons_list_end
; jge .do_not_draw
; call os_print_string
ret
.draw_with_default:
call default_draw_function
.do_not_draw:
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

draw_selected_button:
mov si,[selected_button]
lodsw
mov si,ax
call draw_button
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

;While no event occurs
;execute idle functions
waitevent_idle_functions:
	pusha
	
	; Clear the mouse update flag so we can tell when the driver had updated it
	mov byte [mouselib_int_changed], 0
.input_wait:
	; Check with BIOS if there is a keyboard key available - but don't collect the key

	mov ah, 11h
	int 16h
	jnz .keyboard_input
	
	; Check if the mouse driver has received anything
	cmp byte [mouselib_int_changed], 1
	je .mouselib_int_input

; call mouselib_remove_driver
mov dx,idle_functions_list
mov [.current_idle_function],dx
;TODO add watch and other pins
.idle_function_loop:
mov si,[.current_idle_function]
cmp si,0
je .no_idle_command
lodsw
mov dx,ax
cmp dx,0
je .no_idle_command
mov [.current_idle_function],si
call dx
jmp .idle_function_loop
.current_idle_function:
dw 0
.no_idle_command:
; call mouselib_setup
call os_hide_cursor

	hlt
	
	jmp .input_wait
	
.keyboard_input:
	popa
	stc
	ret
	
.mouselib_int_input:
	popa
	clc
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
;mov word [robot_position],0
call data_settings_save
mov word [configuration_finished],0xf0f0
call save_setting_file
mov dx,common_filename
mov ah,0x52
int 0x2b
ret ; Return to OS
common_filename:
db "common.txt",0

execute_string:
mov ah,0x0D
int 0x61
mov ah,0x0F
int 0x61
ret

close_execute_file:
; mov ah,0x0D
; int 0x61
mov si,dx
call pipestore
mov ax,0x1C0D
call keybsto
jmp quick_exit_handler

pipestore:
pusha
.loop:
lodsb
cmp al,0x0D
je .enter
cmp al,0x00
je .end
cmp al,'|'
je .end
mov ah,0x00
call keybsto
jmp .loop
.enter:
mov ah,0x1C
call keybsto
jmp .loop
.end:
popa
ret

data_settings_save:
mov ah,0x64 ;Data Write
mov bh,[data_settings_handle]
mov si,data_settings
int 0x2b
mov ah,0x62 ;Memory Released
mov bh,[data_settings_handle]
int 0x2b
ret

;List to pointers to execute when idle
;Each word for each function. End with zero.
idle_functions_list:
dw draw_digital_watch
; dw draw_analog_watch
dw roaming_robot
dw 0

;List of all button data pointers
;Each word to indicate one button. End with zero.
buttons_list:
dw file_button_data
dw edit_button_data
dw command_button_data
dw password_button_data
dw tutorial_button_data
dw favorites_button_data
dw settings_button_data

dw shutdown_button_data
dw restart_button_data
dw halt_button_data
dw lock_button_data
dw save_setting_button_data
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
edit_button_data:
dw 0x2A,13,5,6,3,0,edit_handler,0
db 'Edit',0
command_button_data:
dw 0x4F,20,5,13,3,0,command_handler,'c'
db '[c] Command',0
password_button_data:
dw 0x6F,2,10,10,3,0,password_handler,0
db 'Password',0
tutorial_button_data:
dw 0x5F,12,10,10,3,0,tutorial_screen,0x3B3B
db 'Tutorial',0
favorites_button_data:
dw 0x18,2,15,15,3,0,favorites_handler
db '`','~'
db '[`] Favorites',0
settings_button_data:
dw 0xC1,18,15,14,3,0,settings_handler,0x3D3D
db '[F3]Settings',0

shutdown_button_data:
dw 0x47,7,21,14,3,0,shutdown_handler,'q'
db '[q] Shutdown',0
restart_button_data:
dw 0x47,22,21,13,3,0,restart_handler,'r'
db '[r] Restart',0
halt_button_data:
dw 0x87,36,21,6,3,0,halt_handler,0
db 'Halt',0
lock_button_data:
dw 0x67,43,21,10,3,0,lock_handler,'l'
db '[l] Lock',0
save_setting_button_data:
dw 0x26,54,21,10,3,0,save_setting_file,0x3C3C
db '[F2]Save',0
command_line_button_data:
dw 0x12,65,21,5,3,0,exit_handler,0x011B
db 'CLD',0

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
mov [.selected_file],ax

mov ax,.command_list
mov bx,.file_operation_str
mov cx,.file_operation_str_help
call os_list_dialog
cmp dx,0x0f0f ;Failed
je file_handler

cmp ax,1
je .execute_file
cmp ax,2
je .copy_file
cmp ax,3
je .delete_file
cmp ax,4
je .rename_file
cmp ax,5
je .new_file
cmp ax,6
je .new_directory
cmp ax,7
je .add_to_path
cmp ax,8
je .show_size
jmp .quit
; mov bx,0
; mov cx,0
; call os_dialog_box

.execute_file:
;Change file name to
; name.extension
;format
mov si,[.selected_file]
mov al,0x20
call os_string_tokenize
push di
mov di,TEMPLOC ; Copy file name
call memcpy
mov byte [di-1],'.' ; Add dot in the end
pop si
mov al,' ' ; Remove extra spaces
call os_string_strip
call memcpy ; Add extension
mov byte [di-1],0x0D ; Store Enter key
mov byte [di-0],0

mov dx,TEMPLOC ; Store in keyboard buffer
; Execute
; pop ax
mov ah,0x0D
int 0x61
jmp quick_exit_handler

.copy_file:
mov dx,.copy_cmd
jmp .file_command

.delete_file:
mov dx,.del_cmd
jmp .file_command

.rename_file:
mov dx,.rename_cmd
jmp .file_command

.new_file:
mov ax,TEMPLOC
mov word [.selected_file],TEMPLOC
mov bx,.enter_new_filename_str
call os_input_dialog
mov dx,.new_file_cmd
jmp .file_command

.new_directory:
mov ax,TEMPLOC
mov word [.selected_file],TEMPLOC
mov bx,.enter_new_directoryname_str
call os_input_dialog
mov dx,.new_dir_cmd
jmp .file_command

.add_to_path:
mov dx,.add_to_path_cmd
jmp .file_command

.show_size:
mov ax,[.selected_file]
mov cx,TEMPLOC
call os_load_file

mov dx,bx
mov bx,TEMPLOC
mov ah,0x2A
int 0x61
mov bx,TEMPLOC ; Size into second line of dialog box...

	mov ax, .size_msg_str
	mov cx, [.selected_file]
	call os_dialog_box

jmp file_handler
.size_msg_str:
db 'File size (in bytes):', 0

.file_command:
push dx
mov dx,[.selected_file]
mov ah,0x52
int 0x2b
pop dx
call execute_string
jmp file_handler

.quit:
ret
.selected_file:
dw 0

.file_operation_str:
db "Select a file operation : ",0
.file_operation_str_help:
db "Press esc to cancel",0
.command_list:
db "Execute the file"
db ",Create a Copy"
db ",Delete"
db ",Rename"
db ",Create a new file"
db ",Create a new directory"
db ",Add directory to path list"
;db ",Load file to memory"
;db ",Open with application"
db ",Show file size"
db ",Quit"
db 0

.copy_cmd:
db 'copy ',0
.del_cmd:
db 'del ',0
.rename_cmd:
db 'rename ',0
.new_file_cmd:
db 'fnew ',0
.new_dir_cmd:
db 'newdir ',0
.add_to_path_cmd:
db 'addpathc ',0

.enter_new_filename_str:
db 'Enter new file name :',0
.enter_new_directoryname_str:
db 'Enter new directory name :',0

edit_handler:
mov dx,.edit_cmd
call execute_string
ret
.edit_cmd:
db "edit ",0

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

favorites_handler:
mov ax,favorites_list
mov bx,.select_app_str
mov cx,.line_str
call os_list_dialog
cmp dx,0x0f0f ;Failed
je .quit
dec ax
imul ax,11+1
add ax,favorites_list
mov si,ax
mov di,TEMPLOC
mov cx,11
rep movsb
mov byte [di],0
mov dx,TEMPLOC
;call execute_string
pop ax
jmp close_execute_file
.quit:
ret
.select_app_str:
db "Select the application to run :",0
.line_str:
db "-------------------------------",0

settings_handler:
mov ax,.settings_menu
mov bx,.setting_head_str
mov cx,.setting_esc_str
call os_list_dialog
cmp dx,0x0f0f ;Failed
je .quit

cmp ax,1
je .edit_favorites
cmp ax,2
je save_setting_file
.quit:
ret

.edit_favorites:
mov ax,favorites_list
mov bx,.enter_new_favorites_str
call os_input_dialog
jmp settings_handler
.enter_new_favorites_str:
db "Edit Favorites List :",0

.setting_head_str:
db "Settings >>",0
.setting_esc_str:
db "Press esc to cancel",0
.settings_menu:
db "Edit favorites list"
db ",Save and Close"
db 0

load_setting_file:
;Save current directory
mov ah,0x47
int 0x21
push dx
;Set to root directory
mov dx,0x0013
mov ah,0x3B
int 0x21
;Load settings file
mov ax,data_settings_filename
mov cx,data_settings
call os_load_file
cmp dx,0x0f0f
jne .found
;RESET data
call reset_settings_data
call save_setting_file
.found:
mov word [configuration_finished],0xf0f0
pop dx
mov ah,0x3B ;Restore
int 0x21
ret

save_setting_file:
;Save current directory
mov ah,0x47
int 0x21
push dx
;Set to root directory
mov dx,0x0013
mov ah,0x3B
int 0x21
;Save settings file
mov word [configuration_finished],0x0f0f
mov ax,data_settings_filename
mov bx,data_settings
mov cx,data_settings_end-data_settings
call os_write_file
pop dx
mov ah,0x3B ;Restore
int 0x21
ret

reset_settings_data:
mov di,data_settings
mov si,.default_settings
mov cx,.default_settings_end-.default_settings
rep movsb
ret
.default_settings:
dw 0x0f0f
dw 0x1010

db "edit|      ",','
db "calc|      ",','
db "MEDIT|     ",','
db "CALENDAR|  "
db 0
times PASSWORD_LENGTH-(12*3) times 0

.default_settings_end:

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

memcpy:
lodsb
stosb
cmp al,0
jne memcpy
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

; ------------------------------------------------------------------
; os_string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning; OUT: DI = next token or 0 if none

os_string_tokenize:
	push si

.next_char:
	cmp byte [si], al
	je .return_token
	cmp byte [si], 0
	jz .no_more
	inc si
	jmp .next_char

.return_token:
	mov byte [si], 0
	inc si
	mov di, si
	pop si
	ret

.no_more:
	mov di, 0
	pop si
	ret

; ------------------------------------------------------------------
; os_string_strip -- Removes specified character from a string (max 255 chars)
; IN: SI = string location, AL = character to remove

os_string_strip:
	pusha

	mov di, si

	mov bl, al			; Copy the char into BL since LODSB and STOSB use AL
.nextchar:
	lodsb
	stosb
	cmp al, 0			; Check if we reached the end of the string
	je .finish			; If so, bail out
	cmp al, bl			; Check to see if the character we read is the interesting char
	jne .nextchar			; If not, skip to the next character

.skip:					; If so, the fall through to here
	dec di				; Decrement DI so we overwrite on the next pass
	jmp .nextchar

.finish:
	popa
	ret

; Password Utility
lock_handler:
; password_start:
; shr dl,4
; shl dl,4
;mov [color_background],dl
call load_password_file

; If password is empty
; then get new one
cmp byte [pwd+TEMPLOC],0
je password_handler.getnew_password

;Get password and check it
call check_pwd

;Show message if it exists
cmp byte [message+TEMPLOC],0
je .no_message
mov ax,welcome_str
mov bx,haveamsg_str
mov cx,message+TEMPLOC
call os_dialog_box
mov byte [message+TEMPLOC],0
.no_message:

;Return
call save_password_file
ret

load_password_file:
;Save current directory
mov ah,0x47
int 0x21
push dx
;Set to root directory
mov dx,0x0013
mov ah,0x3B
int 0x21
;Load password file
mov ax,password_file_name
mov cx,TEMPLOC
call os_load_file
cmp dx,0x0f0f
jne .found
mov byte [pwd+TEMPLOC],0
mov byte [message+TEMPLOC],0
.found:
pop dx
mov ah,0x3B ;Restore
int 0x21
ret

save_password_file:
;Save current directory
mov ah,0x47
int 0x21
push dx
;Set to root directory
mov dx,0x0013
mov ah,0x3B
int 0x21
;Save password file
mov ax,password_file_name
mov bx,TEMPLOC
mov cx,512
call os_write_file
pop dx
mov ah,0x3B ;Restore
int 0x21
ret

password_handler:
call load_password_file
; .skip:
.password_menu_loop:
;Show menu for choices
call os_clear_screen
mov ax,password_menu
mov bx,welcome_str
mov cx,welcome_str2
call os_list_dialog
cmp dx,0x0f0f ;Failed
je .quit
cmp ax,1
je .quit
cmp ax,2
je .passchange
; cmp al,'2'
; je .autorunstring
; cmp al,'3'
; je welcome_screen
cmp ax,3
je .message
; cmp al,'5'
; je .save_quit
.quit:
call save_password_file
ret

.passchange:
call check_pwd
jmp .passchange_skip
.getnew_password:
mov ax,welcome_str3
mov bx,welcome_recommend
mov cx,welcome_recommend2
call os_dialog_box
.passchange_skip:
mov bx,enter_new_password_str
mov ax,pwd+TEMPLOC
call os_input_dialog
;jmp .password_menu_loop
jmp .password_menu_loop

.message:
mov bx,enter_msg_str
mov ax,message+TEMPLOC
call os_input_dialog
jmp .password_menu_loop

check_pwd:
call os_clear_screen
call os_show_cursor
; mov bl,0x3F
; mov dx,PASSWORD_DIALOG_LOC
; mov si,80-2-2
; mov di,25-2
; call os_draw_block
mov dx,PASSWORD_DIALOG_LOC
call os_move_cursor
mov si,enter_password_str
call os_print_string
mov dx,PASSWORD_DIALOG_LOC
add dx,0x020A
call os_move_cursor
mov di,recieved+TEMPLOC
call getpwd

mov al,0
mov ah,0x05
mov bx,recieved+TEMPLOC
mov dx,pwd+TEMPLOC
int 0x61
cmp al,0xF0
jne .wrong
ret
.wrong:
jmp check_pwd

getpwd:
mov ah,0
int 0x16
cmp al,13
je .done
stosb
mov dl,0xFE
mov ah,0x02
int 0x21
jmp getpwd
.done:
mov al,0
stosb
ret

get_string:
mov ah,0
int 0x16
cmp al,13
je .end
stosb
mov dl,al
mov ah,0x02
int 0x21
jmp get_string
.end:
mov al,0
stosb
ret

setcolor2:
mov dl,[color2]
mov ah,0x01
int 0x61
ret

cryption:

ret
.ecode: db 0x40

tutorial_screen:
;call mouselib_setup
; mov cx, 0
; mov dx, 0
; call mouselib_move
call os_hide_cursor
call os_clear_screen
;call mouselib_hide
.loop:
	mov ax,.osstring
	mov bx,.welcome_str1
	mov cx,[color]
	call os_draw_background
	mov bl,0x30
	mov dx,0x0202
	mov si,76
	mov di,5
	call os_draw_block
	mov dx,0x0305
	call os_move_cursor
	mov si,.welcome_str_t1
	call os_print_string
	mov bl,0x30
	mov dx,0x1502
	mov si,76
	mov di,0x18
	call os_draw_block
	mov dx,0x1605
	call os_move_cursor
	mov si,.welcome_str_t2
	call os_print_string
	mov bl,0x97
	mov dx,0x0602
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0704
	call os_move_cursor
	mov si,.welcome_str_t3
	call os_print_string
	mov bl,0x8D
	mov dx,0x060C
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x070E
	call os_move_cursor
	mov si,.welcome_str_t4
	call os_print_string
	mov bl,0x29
	mov dx,0x0616
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0717
	call os_move_cursor
	mov si,.welcome_str_t5
	call os_print_string
	mov bl,0xAC
	mov dx,0x0620
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0722
	call os_move_cursor
	mov si,.welcome_str_t6
	call os_print_string
	mov bl,0xE4
	mov dx,0x062A
	mov si,11
	mov di,9
	call os_draw_block
	mov dx,0x072B
	call os_move_cursor
	mov si,.welcome_str_t7
	call os_print_string
	mov bl,0x6F
	mov dx,0x0635
	mov si,10
	mov di,9
	call os_draw_block
	mov dx,0x0736
	call os_move_cursor
	mov si,.welcome_str_t8
	call os_print_string
	
	mov bl,0x7F
	mov dx,0x0A02
	mov si,20
	mov di,0x0D
	call os_draw_block
	mov dx,0x0B06
	call os_move_cursor
	mov si,.welcome_str_e1
	call os_print_string
	mov bl,0xF7
	mov dx,0x0A16
	mov si,20
	mov di,0x0D
	call os_draw_block
	mov dx,0x0B18
	call os_move_cursor
	mov si,.welcome_str_e2
	call os_print_string
	mov bl,0x70
	mov dx,0x0A2A
	mov si,20
	mov di,0x0D
	call os_draw_block
	mov dx,0x0B2C
	call os_move_cursor
	mov si,.welcome_str_e3
	call os_print_string
	
	mov bl,0x12
	mov dx,0x1032
	mov si,20
	mov di,0x15
	call os_draw_block
	mov dx,0x1235
	call os_move_cursor
	mov si,.continue_str
	call os_print_string
	
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
	cmp al, 27
	je .exit
	cmp al, 13
	je .exit
	cmp al,'c'
	je .common_link
	cmp al,'f'
	je .folder
	cmp al,'a'
	je .app
	cmp al,'e'
	je .editing
	cmp al,'u'
	je .customize
	cmp al,'s'
	je .shutdown
	cmp al,'m'
	je .example_link
	cmp al,'p'
	je .examplefolder
	cmp al,'l'
	je .exampleapp
	jmp .loop
.button:
call mouselib_hide
call mouselib_locate
;call mouselib_freemove
cmp dx,6
jl .exit
cmp dx,20
jg .exit
cmp dx,9
jl .common
cmp dx,0x0D
jl .example
.exit:
call mouselib_hide
call os_clear_screen
call os_show_cursor
;call mouselib_remove_driver
;jmp password_start
ret

.common:
cmp cx,0x35
jge .shutdown
cmp cx,0x2A
jge .customize
cmp cx,0x20
jge .editing
cmp cx,0x16
jge .app
cmp cx,0x0C
jge .folder
.common_link:
mov ax,.welcome_str_t3m1
mov bx,.welcome_str_t3m2
mov cx,.welcome_str_t3m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.folder:
mov ax,.welcome_str_t4m1
mov bx,.welcome_str_t4m2
mov cx,.welcome_str_t4m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.app:
mov ax,.welcome_str_t5m1
mov bx,.welcome_str_t5m2
mov cx,.welcome_str_t5m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.editing:
mov ax,.welcome_str_t6m1
mov bx,.welcome_str_t6m2
mov cx,.welcome_str_t6m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.customize:
mov ax,.welcome_str_t7m1
mov bx,.welcome_str_t7m2
mov cx,.welcome_str_t7m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.shutdown:
mov ax,.welcome_str_t8m1
mov bx,.welcome_str_t8m2
mov cx,.welcome_str_t8m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.example:
cmp cx,0x2A
jge .exampleapp
cmp cx,0x16
jge .examplefolder
.example_link:
mov ax,.welcome_str_e1m1
mov bx,.welcome_str_e1m2
mov cx,.welcome_str_e1m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.examplefolder:
mov ax,.welcome_str_e2m1
mov bx,.welcome_str_e2m2
mov cx,.welcome_str_e2m3
mov dx,0
call os_dialog_box
jmp tutorial_screen
.exampleapp:
mov ax,.welcome_str_e3m1
mov bx,.welcome_str_e3m2
mov cx,.welcome_str_e3m3
mov dx,0
call os_dialog_box
jmp tutorial_screen

.osstring:
db ' Aplaun OS Tutorial ',0
.welcome_str1:
db 'Welcome User to a new newbee World. Check out the commands first.',0
.welcome_str_t1:
db ' For all commands ask for "help". Or click on these to read.',0
.welcome_str_t2:
db ' Reminder: Try the commands without the quotes.',0
.welcome_str_t3:
db 'Common',0
.welcome_str_t3m1:
db 't is time d is date (check clock too).',0
.welcome_str_t3m2:
db 'calc to open calculator. (try "2+6-3")',0
.welcome_str_t3m3:
db 'cls to clear screen',0
.welcome_str_t4:
db 'Folder',0
.welcome_str_t4m1:
db 'nm to name a file/folder (example.txt)',0
.welcome_str_t4m2:
db 'q to list all files and folders.',0
.welcome_str_t4m3:
db 'q also loads the file if found equal.',0
.welcome_str_t5:
db 'App/Prog',0
.welcome_str_t5m1:
db 'to start it just type the name',0
.welcome_str_t5m2:
db 'to give arguments press space and type',0
.welcome_str_t5m3:
db 'Add commonly used programs to path list.',0
.welcome_str_t6:
db 'Editing',0
.welcome_str_t6m1:
db 'edit to change text documents',0
.welcome_str_t6m2:
db 'code to alter machine codes',0
.welcome_str_t6m3:
db 'read to open simple txt books',0
.welcome_str_t7:
db 'cUstomize',0
.welcome_str_t7m1:
db 'color , color2 to change colors',0
.welcome_str_t7m2:
db 'prompt and scrollmode for more customs',0
.welcome_str_t7m3:
db 'Apps can even change your font and cursor',0
.welcome_str_t8:
db 'Shutdown',0
.welcome_str_t8m1:
db 'e to exit / fhlt to halt',0
.welcome_str_t8m2:
db 'restart to restart',0
.welcome_str_t8m3:
db 'reboot to reboot',0

.welcome_str_e1:
db 'exaMple-file',0
.welcome_str_e1m1:
db 'nm test.txt',0
.welcome_str_e1m2:
db 'q',0
.welcome_str_e1m3:
db 'edit',0
.welcome_str_e2:
db 'examPle-folder',0
.welcome_str_e2m1:
db 'nm folder',0
.welcome_str_e2m2:
db 'q',0
.welcome_str_e2m3:
db 'dir',0
.welcome_str_e3:
db 'exampLe-app',0
.welcome_str_e3m1:
db 'hangman',0
.welcome_str_e3m2:
db 'life',0
.welcome_str_e3m3:
db 'viewer',0

.continue_str:
db 'Continue ->>',0

password_menu:
db 'Continue ->>'
db ',Change password'
db ',Leave a message for the next user'
db 0

enter_password_str:
db ' Enter Password: ',0
enter_new_password_str:
db ' Enter New Password: ',0
enter_msg_str:
db ' Enter Message: ',0
haveamsg_str:
db ' You have a message : ',0
; correct_str:
; db ' Correct ',0
welcome_str:
db ' Welcome User.',0
welcome_str2:
db ' Select your action ->',0

welcome_str3:
db 'Thankyou for trying out Aplaun OS. ',0
welcome_recommend:
db 'We recommend you to enter a new password',0
welcome_recommend2:
db 'also check our new tutorial. ',0
password_file_name:
db "pass.pwd",0

roaming_robot:
cmp word [robot_position],0
jne .update
mov word [robot_position],0x1010
jmp .new_update
.update:
call draw_robot
.new_update:
call update_robot_position
call draw_robot
ret
draw_robot:
mov dx,[robot_position]
;call setpos
call os_move_cursor
call invert_char
ret

get_current_cursor:
; Find the colour of the character
	mov ah, 08h
	mov bh, 0
	int 10h
ret

invert_char:
call get_current_cursor
	
	; Invert it to get its opposite
	not ah
	
	; Display new character
	mov bl, ah
	mov ah, 09h
	mov bh, 0
	mov cx, 1
	int 10h
ret
update_robot_position:
; mov dx,[robot_position]
; call os_move_cursor
; call get_current_cursor
; mov [.previous_color],ah
mov ah,0x17
mov dx,0
mov bx,8
int 0x61
mov bx,[robot_position]
cmp dx,1
je .left
cmp dx,2
je .up
cmp dx,3
je .down
cmp dx,4
je .right

cmp dx,5
je .up_left
cmp dx,6
je .up_right
cmp dx,7
je .down_left
cmp dx,8
je .down_right

jmp .done
.left:
dec bl
jmp .done
.up:
dec bh
jmp .done
.down:
inc bh
jmp .done
.right:
inc bl
jmp .done

.up_left:
dec bl
dec bh
jmp .done
.up_right:
inc bl
dec bh
jmp .done
.down_left:
dec bl
inc bh
jmp .done
.down_right:
inc bl
inc bh
jmp .done

.done:
cmp bl,0
jl .reset
cmp bh,0
jl .reset
cmp bl,80
jge .reset
cmp bh,25
jge .reset
jmp .update
;mov bx,0x1010
.update:
; push bx
; mov dx,bx
; call os_move_cursor
; call get_current_cursor
; pop bx
; cmp [.previous_color],ah
; jne .reset
mov [robot_position],bx
.reset:
ret
.previous_color:
db 0

draw_digital_watch:
; call getpos
; push dx
; mov byte [color],0x11
;call getpos
mov dx,[detail_pos]
call setpos
call time
mov dx,[detail_pos]
inc dh
call setpos
call date
mov dx,[detail_pos]
inc dh
inc dh
call setpos
call timer
; pop dx
; call os_move_cursor
ret

draw_analog_watch:
; mov ax,0x0003
; int 0x10
; mov ax,0x0500
; int 10h
; call getpos
; push dx
mov dl,[color]
push dx
; call os_hide_cursor

;mov bx,0x0F38
;add bl,dl
;sub bl,dh
;add bh,bl

mov bl,0 ;Color
mov dl,0x15 ;Start X
add dl,0x14
mov dh,0x07 ;Start Y
mov si,0x27-0x15+1 ;Width
mov di,0x13+1 ;End Y
call os_draw_block

mov ah,0x02
int 0x1a
mov al,ch
call bcd2hex
mov ch,al
call convert
add bh,0x14
push bx
mov dx,[centre_pos]
;push dx
call line

mov ah,0x02
int 0x1a
mov al,cl
call bcd2hex
xor ah,ah
mov cl,0x05
div cl
mov ch,al
call convert
add bh,0x14
push bx
mov dx,[centre_pos]
mov byte [color],0x45
call line

mov ah,0x02
int 0x1a
mov al,dh
call bcd2hex
xor ah,ah
mov cl,0x05
div cl
mov ch,al
call convert
add bh,0x14
push bx
mov dx,[centre_pos]
mov byte [color],0x34
; mov byte [color],0x38
call line

xor cx,cx
mov byte [color],0x0f
.board:
push cx
mov ch,cl
call convert
add bh,0x14
xchg bh,bl
mov dx,bx
call setpos
pop cx
;push cx
mov ax,cx
add al,0x30
call printc
;pop cx
inc cx
cmp cx,12
jl .board

call delay
mov byte [color],0x07
mov dx,[centre_pos]
pop bx
call line
mov dx,[centre_pos]
pop bx
call line
mov dx,[centre_pos]
pop bx
call line

; mov ah,0x01
; int 0x16
; jz watch
; mov dx,0x0a00
; call setpos
; mov cx,0x0506
; mov ah,0x01
; int 0x10
; call os_show_cursor
xor bx,bx
mov es,bx
pop dx
mov [color],dl
; pop dx
;call setpos
; call os_move_cursor
ret

printf:
pusha
mov ah,0x0E
int 0x10
popa
ret

printc:
;mov al,0x20
;printf:
pusha
xor bh,bh
mov ah,0x09
mov bl,[color]
mov cx,0x0001
int 0x10
;call getpos
;inc dl
;call setpos
popa
ret

colon:
mov al,':'
call printf
ret

space:
mov al,' '
call printf
ret

printh:
push ax
shr al,4
cmp al,10
sbb al,69h
das
call printf
pop ax
ror al,4
shr al,4
cmp al,10
sbb al,69h
das
call printf
ret

newline:
mov al,0x0D
call printf
mov al,0x0A
call printf
ret

date:
mov ah,0x04
int 0x1a
mov al,dl
call printh
call colon
mov al,dh
call printh
call colon
mov al,ch
call printh
;call colon
mov al,cl
call printh
ret

time:
mov ah,0x02
int 0x1a
mov al,ch
call printh
call colon
mov al,cl
call printh
call colon
mov al,dh
call printh
ret

timer:
;mov ah,0x00
xor ah,ah
int 0x1a
mov al,ch
call printh
call colon
mov al,cl
call printh
call colon
mov al,dh
call printh
call colon
mov al,dl
call printh
ret

getpos:
mov ah,0x03
xor bh,bh
int 10h
ret

setpos:
mov ah,0x02
xor bh,bh
int 10h
ret

delay:
xor ah,ah
int 1ah
mov [wx],dl
.delay_loop:
xor ah,ah
int 1ah
cmp [wx],dl
je .delay_loop
ret

line:
mov [x],bh
mov [y],bl
;mov [x1],bh
;mov [y1],bl
mov [x2],dh
mov [y2],dl

mov ch,0
mov cl,bh
mov dh,0
mov dl,bl

mov ah,0
mov al,[x2]
mov si,ax
mov ah,0
mov al,[y2]
mov di,ax
mov bl,[color]
call os_draw_line
;call delay
ret

; Change the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved

os_set_pixel:
pusha
mov dl,al
mov dh,cl
mov [color],bl
call setpos
mov al,0x20
call printc
popa
ret

; Implementation of Bresenham's line algorithm. Translated from an implementation in C (http://www.edepot.com/linebresenham.html)
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour
; OUT: None, registers preserved
os_draw_line:
	pusha				; Save parameters
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	;inc byte [internal_call]
	
	xor ax, ax			; Clear variables
	mov di, .x1
	mov cx, 11
	rep stosw
	
	popa				; Restore and save parameters
	pusha
	
	mov [.x1], cx			; Save points
	mov [.x], cx
	mov [.y1], dx
	mov [.y], dx
	mov [.x2], si
	mov [.y2], di
	
	mov [.colour], bl		; Save the colour
	
	mov bx, [.x2]
	mov ax, [.x1]
	cmp bx, ax
	jl .x1gtx2
	
	sub bx, ax
	mov [.dx], bx
	mov ax, 1
	mov [.incx], ax
	jmp .test2
	
.x1gtx2:
	sub ax, bx
	mov [.dx], ax
	mov ax, -1
	mov [.incx], ax
	
.test2:
	mov bx, [.y2]
	mov ax, [.y1]
	cmp bx, ax
	jl .y1gty2
	
	sub bx, ax
	mov [.dy], bx
	mov ax, 1
	mov [.incy], ax
	jmp .test3
	
.y1gty2:
	sub ax, bx
	mov [.dy], ax
	mov ax, -1
	mov [.incy], ax
	
.test3:
	mov bx, [.dx]
	mov ax, [.dy]
	cmp bx, ax
	jl .dygtdx
	
	mov ax, [.dy]
	shl ax, 1
	mov [.dy], ax
	
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dx], bx
	
.xloop:
	mov ax, [.x]
	mov bx, [.x2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .xloop1
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	mov ax, [.balance]
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
.xloop1:
	mov ax, [.balance]
	mov bx, [.dy]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	jmp .xloop
	
.dygtdx:
	mov ax, [.dx]
	shl ax, 1
	mov [.dx], ax
	
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dy], bx
	
.yloop:
	mov ax, [.y]
	mov bx, [.y2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .yloop1
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	mov ax, [.balance]
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
.yloop1:
	mov ax, [.balance]
	mov bx, [.dx]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	jmp .yloop
	
.done:
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	popa
	;dec byte [internal_call]
	ret
	
	
	.x1 dw 0
	.y1 dw 0
	.x2 dw 0
	.y2 dw 0
	
	.x dw 0
	.y dw 0
	.dx dw 0
	.dy dw 0
	.incx dw 0
	.incy dw 0
	.balance dw 0
	.colour db 0
	.pad db 0

convert:
cmp ch,0x00
je .h12
cmp ch,0x01
je .h1
cmp ch,0x02
je .h2
cmp ch,0x03
je .h3
cmp ch,0x04
je .h4
cmp ch,0x05
je .h5
cmp ch,0x06
je .h6
cmp ch,0x07
je .h7
cmp ch,0x08
je .h8
cmp ch,0x09
je .h9
cmp ch,0x0A
je .h10
cmp ch,0x0B
je .h11
mov byte [color],0x23
sub ch,12
jmp convert
.h1:
mov bx,0x2108
ret
.h2:
mov bx,0x250A
ret
.h3:
mov bx,0x270D
ret
.h4:
mov bx,0x2510
ret
.h5:
mov bx,0x2112
ret
.h6:
mov bx,0x1E13
ret
.h7:
mov bx,0x1B12
ret
.h8:
mov bx,0x1710
ret
.h9:
mov bx,0x150D
ret
.h10:
mov bx,0x170A
ret
.h11:
mov bx,0x1B08
ret
.h12:
mov bx,0x1E07
ret

bcd2hex:
mov bl,al
and al,0xF0
ror al,4

mov cl,0x0A
mul cl
and bl,0x0F
add al,bl
ret

x:
db 0x00
y:
db 0x00
;x1:
;db 0x00
;y1:
;db 0x00
x2:
db 0x00
y2:
db 0x00
wx:
db 0x00
wy:
db 0x00
eps:
db 0x00
; color:
; db 0x31
centre_pos:
dw 0x320D
detail_pos:
dw 0x032A

;Variables
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

data_settings_filename:
db 'qsetting.txt',0
data_settings_handle:
db 0
data_settings:
configuration_finished:
dw 0x0f0f
robot_position:
dw 0
favorites_list:
times PASSWORD_LENGTH db 0
data_settings_end:
; dw 0x0A0A
; dw 0x0101

times (512*FILESIZE)-($-$$) db 0