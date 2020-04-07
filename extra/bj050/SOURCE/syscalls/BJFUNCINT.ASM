; =================================================================
; Blue Jay -- The Mike Operating System kernel
; Copyright (C) 2011 - 2012 Blue Jay Developers -- see LICENSE.TXT
; Copyright (C) 2006 - 2012 MikeOS Developers -- see LICENSE.TXT
;
; MAIN INTERFACE
; =================================================================

os_function_interface:

.more:
	call os_clear_screen			; Setup Main Screen
	call .draw_background

	mov si, .version2_msg
	call os_print_string

	mov si, .version3_msg
	call os_print_string

	call .list_hardware
	call os_print_newline

	call os_print_newline
	mov si, .help_msg
	call os_print_string
	call os_print_newline

	mov si, .help_1
	call os_print_string

	mov si, .help_2
	call os_print_string

	mov si, .help_3
	call os_print_string

	mov si, .help_4
	call os_print_string

	mov si, .help_5
	call os_print_string

	mov si, .help_6
	call os_print_string

	mov ax, 1003h				; For text intensity (no blinking)
	mov bx, 0
	int 10h

.loop:
	call os_wait_for_key			; Get input

	cmp ax, 3B00h				; F1 pressed?
	je near .execute_com

	cmp ax, 3C00h				; F2 pressed?
	je near .file_op

	cmp ax, 3D00h				; F3 pressed?
	je near .time

	cmp ax, 3E00h				; F4 pressed?
	je near .date

	cmp ax, 3F00h				; F5 pressed?
	je near .restart

	cmp ax, 4000h				; F6 pressed?
	je near .about

	jmp .loop				; Start Loop


; =================================================================

.execute_com:
	mov ax, .title_msg
	mov bx, .footer2_msg
	mov cx, 00001111b
	call os_draw_background			; Draw main screen layout

	call os_file_selector		; Get user to select a file, and store
					; the resulting string location in AX
					; (other registers are undetermined)

	jc os_function_interface	; Return to the CLI/menu choice screen if Esc pressed

	mov si, ax			; Did the user try to run 'KERNEL.BJK'?
	mov di, .kern_file_name
	call os_string_compare
	jc .no_kernel_execute		; Show an error message if so


	; Next, we need to check that the program we're attempting to run is
	; valid -- in other words, that it has a .COM extension

	push si				; Save filename temporarily

	mov ax, si
	call os_get_file_size

	mov word [.tmpstring], bx

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax			; SI now points to end of filename...

	dec si
	dec si
	dec si				; ...and now to start of extension!

	mov di, .com_ext
	mov cx, 3
	rep cmpsb			; Are final 3 chars 'COM'?
	jne .not_com_extension		; If not, it might be a '.BAS'

	pop si				; Restore filename

	call os_clear_screen
	mov ax, si
	mov bx, 0
	mov cx, 100h
	call os_load_file
	jc .fail
	call os_execute_program
	jmp .more


.no_kernel_execute:				; Warn about trying to executing kernel!
	mov ax, .kerndlg_string_1
	mov bx, 0
	mov cx, 0
	mov dx, 0				; One button for dialog box
	call os_dialog_box

	jmp .execute_com			; Start over again...

.not_com_extension:
	pop si					; We pushed during the .COM extension check

	push si					; Save it again in case of error...

	mov bx, si
	mov ax, si
	call os_string_length

	mov si, bx
	add si, ax				; SI now points to end of filename...

	dec si
	dec si
	dec si					; ...and now to start of extension!

	mov di, .bas_ext
	mov cx, 3
	rep cmpsb				; Are final 3 chars 'BAS'?
	jne .no_execute				; If not, error out


	pop si

	mov ax, si
	mov bx, 0
	mov cx, 100h				; Where to load the program file
	call os_load_file			; Load filename pointed to by AX

	call os_clear_screen			; Clear screen before running

	mov ax, 100h
	mov si, 0
	mov word bx, [.tmpstring]
	call os_run_basic			; And run our BASIC interpreter on the code!

	mov si, .basic_finished_msg
	call os_print_string
	call os_wait_for_key

	call os_clear_screen
	jmp os_function_interface		; and go back to the program list

.no_execute:
	pop si

	mov ax, .ext_string_1
	mov bx, .ext_string_2
	mov cx, 0
	mov dx, 0				; One button for dialog box
	call os_dialog_box

	jmp .execute_com			; Start over again...

.fail:
	mov ax, .reset_msg
	call os_fatal_error

; =================================================================

.file_op:

	call .draw_background_2

	mov ax, .command_list			; Draw list of disk operations
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog

	jc near .exit				; User pressed Esc?

	cmp ax, 1				; Otherwise respond to choice
	je near .delete_file

	cmp ax, 2
	je near .rename_file

	cmp ax, 3
	je near .create_file

	cmp ax, 4
	je near .file_size

	cmp ax, 5
	je near .disk_info_2



.delete_file:
	call .draw_background

	call os_file_selector			; Get filename from user
	jc .no_delete_file_selected		; If Esc pressed, quit out

	push ax					; Save filename for now

	call .draw_background

	mov ax, .delete_confirm_msg		; Confirm delete operation
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box

	cmp ax, 0
	je .ok_to_delete

	pop ax
	jmp .delete_file

.ok_to_delete:
	pop ax
	call os_remove_file
	jc near .writing_error

	call .draw_background

	mov ax, .success_msg_3
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

.no_delete_file_selected:
	jmp .file_op



.rename_file:
	call .draw_background

	call os_file_selector			; Get filename from user
	jc .no_rename_file_selected		; If Esc pressed, quit out

	mov si, ax				; And store it
	mov di, .filename_tmp1
	call os_string_copy

.retry_rename:
	call .draw_background

	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax				; Store it for later
	mov di, .filename_tmp2
	call os_string_copy

	mov ax, di				; Does the second filename already exist?
	call os_file_exists
	jnc .rename_fail			; Quit out if so

	mov ax, .filename_tmp1
	mov bx, .filename_tmp2

	call os_rename_file
	jc near .writing_error

	call .draw_background

	mov ax, .success_msg
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .file_op


.rename_fail:
	mov ax, .err_file_exists
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .retry_rename


.no_rename_file_selected:
	jmp .file_op


.create_file:
	call .draw_background
	mov bx, .filename_msg			; Get second filename
	mov ax, .filename_input
	call os_input_dialog

	mov si, ax				; Store it for later
	mov di, .filename_tmp1
	call os_string_copy

	mov ax, di				; Does the filename already exist?
	call os_file_exists
	jnc .create_fail			; Quit out if so

	mov ax, .filename_tmp1

	call os_create_file
	jc near .writing_error

	call .draw_background

	mov ax, .success_msg_2
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .file_op


.create_fail:
	mov ax, .err_file_exists
	mov bx, 0
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .retry_rename


.file_size:
	call .draw_background

	call os_file_selector			; Get filename from user
	jc .no_rename_file_selected		; If Esc pressed, quit out

	call os_get_file_size

	mov ax, bx				; Move size into AX for conversion
	call os_int_to_string
	mov bx, ax				; Size into second line of dialog box...

	mov ax, .size_msg
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .file_op


.disk_info_2:
	mov cx, 1				; Load first disk sector into RAM
	mov dx, 0
	mov bx, os_buffer

	mov ah, 2
	mov al, 1
	stc
	int 13h					; BIOS load sector call

	mov si, os_buffer + 2Bh			; Disk label starts here

	mov di, .tmp_string1
	mov cx, 11				; Copy 11 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov si, os_buffer + 36h			; Filesystem string starts here

	mov di, .tmp_string2
	mov cx, 8				; Copy 8 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov ax, .label_string_text		; Add results to info strings
	mov bx, .tmp_string1
	mov cx, .label_string_full
	call os_string_join

	mov ax, .fstype_string_text
	mov bx, .tmp_string2
	mov cx, .fstype_string_full
	call os_string_join

	call .draw_background

	mov ax, .label_string_full		; Show the info
	mov bx, .fstype_string_full
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .file_op


.writing_error:
	call .draw_background
	mov ax, .error_msg
	mov bx, .error_msg2
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .file_op


.exit:
	call os_clear_screen
	jmp os_function_interface

.draw_background_2:
	mov ax, .title_msg
	mov bx, .footer3_msg
	mov cx, 00001111b
	call os_draw_background			; Draw main screen layout
	ret

; =================================================================

.time:
	mov bx, .tmpstring
        call os_get_time_string
	mov ax, .time_string_1
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .more

; =================================================================

.date:
	mov bx, .tmpstring
	call os_get_date_string
	mov ax, .date_string_1
	mov cx, 0
	mov dx, 0
	call os_dialog_box
	jmp .more

; =================================================================

.disk_info:
	mov cx, 1				; Load first disk sector into RAM
	mov dx, 0
	mov bx, os_buffer

	mov ah, 2
	mov al, 1
	stc
	int 13h					; BIOS load sector call

	mov si, os_buffer + 2Bh			; Disk label starts here

	mov di, .tmp_string1
	mov cx, 11				; Copy 11 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov si, os_buffer + 36h			; Filesystem string starts here

	mov di, .tmp_string2
	mov cx, 8				; Copy 8 chars of it
	rep movsb

	mov byte [di], 0			; Zero-terminate it

	mov ax, .label_string_text		; Add results to info strings
	mov bx, .tmp_string1
	mov cx, .label_string_full
	call os_string_join

	mov ax, .fstype_string_text
	mov bx, .tmp_string2
	mov cx, .fstype_string_full
	call os_string_join

	mov ax, .label_string_full		; Show the info
	mov bx, .fstype_string_full
	mov cx, 0
	mov dx, 0
	call os_dialog_box

	jmp .more

; =================================================================

.restart:
	mov ax, .restart_string
	mov bx, 0
	mov cx, 0
	mov dx, 1
	call os_dialog_box

	cmp ax, 1
	jne near .restart_sucess

	jmp .more

.restart_sucess:
	mov        al, 0feh 
	out        64h, al

; =================================================================

.about:
	call .draw_background

	mov si, .about_1
	call os_print_string
	mov si, .about_2
	call os_print_string
	mov si, .about_3
	call os_print_string
	mov si, .about_4
	call os_print_string
	mov si, .about_5
	call os_print_string
	call os_print_newline
	mov si, .about_6
	call os_print_string
	call os_wait_for_key

	jmp .more

; =================================================================

.list_hardware:
	call os_print_newline

	int 11h					; Get hardware info word into AX

	bt ax, 2				; Bit 2 = do we have a mouse?
	jc .mouse_ok

	mov si, .no_mouse_msg
	call os_print_string
	jmp .gameport

.mouse_ok:
	mov si, .mouse_ok_msg
	call os_print_string


.gameport:
	bt ax,12				; Bit 12 = do we have a gamepad?
	jc .gameport_ok

	mov si, .no_gameport_msg
	call os_print_string
	jmp .math

.gameport_ok:
	mov si, .gameport_ok_msg
	call os_print_string


.math:
	bt ax, 1				; Bit 2 = do we have a math co-processor?
	jc .math_ok

	mov si, .no_math_msg
	call os_print_string
	call os_wait_for_key

	jmp os_main

.math_ok:
	mov si, .math_ok_msg
	call os_print_string

	ret					; Back to OS

; =================================================================

.draw_background:
	mov ax, .title_msg
	mov bx, .footer_msg
	mov cx, 00001111b
	call os_draw_background
	ret

; =================================================================


	.no_mouse_msg		db 'No mouse present', 13, 10, 0
	.mouse_ok_msg		db 'Mouse detected', 13, 10, 0

	.no_gameport_msg	db 'No game port present', 13, 10, 0
	.gameport_ok_msg	db 'Game port detected', 13, 10, 0

	.no_math_msg		db 'No math co-processor', 13, 10, 0
	.math_ok_msg		db 'Math co-processor OK', 13, 10, 0

	.tmpstring		times 15 db 0
	.tmp_string		times 15 db 0
	.tmp_string1		times 15 db 0
	.tmp_string2		times 15 db 0

	.label_string_text	db 'Filesystem label: ', 0
	.label_string_full	times 30 db 0

	.fstype_string_text	db 'Filesystem type: ', 0
	.fstype_string_full	times 30 db 0

	.version_msg		db 'RLI-Blue Jay Version ', BJ_VER, ', API Version ', BJ_API_VER2, 13, 10, 0
	.reset_msg		db 'Can not load file into RAM', 0

	.about_1		db 'RLI-Blue Jay Version ', BJ_VER, ', API Version ', BJ_API_VER2, 13, 10, 0
	.about_2		db 'MikeBASIC Version ', BASIC_VER, 13, 10, 0
	.about_3		db 'Copyright (C) 2011 - 2012 RLI', 13, 10, 0
	.about_4		db 'Copyright (C) 2006 - 2012 MikeOS Developers', 13, 10, 0
	.about_5		db 'All rights reserved', 13, 10, 0
	.about_6		db 'Press any key to return to Blue Jay...', 13, 10, 0

	.com_ext		db 'COM'
	.bas_ext		db 'BAS'

	.kerndlg_string_1	db 'Cannot load and execute the kernel!', 0
	.kern_file_name		db 'KERNEL  BJK', 0

	.restart_string		db 'Are you sure you want to restart?', 0

	.time_string_1		db 'The time is:', 0
	.date_string_1		db 'The date is:', 0

	.basic_finished_msg	db '>>> BASIC program finished -- press a key', 0

	.ext_string_1		db 'Invalid filename extension! You can', 0
	.ext_string_2		db 'only execute .COM and .BAS programs.', 0

	.title_msg		db 'Blue Jay Function Interface', 0
	.footer_msg		db 'http://bluejay.xtreemhost.com/', 0
	.footer2_msg		db 'Execution Center, Press <ESC> to return to main menu', 0

	.file_msg		db 'Files on disk:', 13, 10, 0

	.version2_msg		db '                                    Blue Jay', 13, 10, 0
	.version3_msg		db '                                  Version ', BJ_VER, 13, 10, 0
	.help_msg		db 'Please select an option:', 13, 10, 0
	.help_1			db '<F1> Execute a program', 13, 10, 0
	.help_2			db '<F2> Manage a file', 13, 10, 0
	.help_3			db '<F3> Get the time', 13, 10, 0
	.help_4			db '<F4> Get the date', 13, 10, 0
	.help_5			db '<F5> Restart', 13, 10, 0
	.help_6			db '<F6> About Blue Jay', 13, 10, 0

	.command_list		db 'Delete a file,Rename a file,Create a file,Show file size,Show disk info', 0

	.success_msg		db 'Rename success!', 0
	.success_msg_2		db 'File created!', 0
	.success_msg_3		db 'File deleted!', 0

	.help_msg1		db 'Select a file operation to perform,', 0
	.help_msg2		db 'or press the Esc key to exit...', 0

	.footer3_msg		db 'File Manager, Press <ESC> to return to main menu', 0

	.delete_confirm_msg	db 'Are you sure?', 0

	.filename_msg		db 'Enter filename with extension (eg FOO.BAR):', 0
	.filename_input		times 255 db 0
	.filename_tmp1		times 15 db 0
	.filename_tmp2		times 15 db 0

	.size_msg		db 'File size (in bytes):', 0

	.error_msg		db 'Error writing to the disk!', 0
	.error_msg2		db 'Read-only media, or file exists!', 0
	.err_too_large_msg	db 'File too large (max 24K)!', 0
	.err_file_exists	db 'File of that name exists!', 0


; =================================================================

