; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Based on the MikeOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; This is loaded from the drive by BOOTLOAD.BIN, as KERNEL.BIN.
; First we have the system call vectors, which start at a static point
; for programs to use. Following that is the main kernel code and
; then additional system call code is included.
; ==================================================================


	BITS 16
	
	%INCLUDE 'constants/bootmsg.asm'
	%INCLUDE 'constants/buffer.asm'
	%INCLUDE 'constants/config.asm'
	%INCLUDE 'constants/colours.asm'
	%INCLUDE 'constants/defaults.asm'
	%INCLUDE 'constants/osdata.asm'
	
	
	
%INCLUDE 'features/debug.asm'

	disk_buffer	equ	24576

; ------------------------------------------------------------------
; OS CALL VECTORS -- Static locations for system call vectors
; Note: these cannot be moved, or it'll break the calls!

; The comments show exact locations of instructions in this section,
; and are used in programs/mikedev.inc so that an external program can
; use a MikeOS system call without having to know its exact position
; in the kernel source code...

os_call_vectors:
	jmp os_main			; 0000h -- Called from bootloader
	jmp os_print_string		; 0003h
	jmp os_move_cursor		; 0006h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_clear_screen		; 0009h
	jmp os_print_horiz_line		; 000Ch
	jmp os_print_newline		; 000Fh
	jmp os_wait_for_key		; 0012h --- Moved to zkernel, redirects for binary compatibility with MikeOS--- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_check_for_key		; 0015h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_int_to_string		; 0018h
	jmp os_speaker_tone		; 001Bh --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_speaker_off		; 001Eh --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_load_file		; 0021h
	jmp os_pause			; 0024h
	jmp os_fatal_error		; 0027h
	jmp os_draw_background		; 002Ah
	jmp os_string_length		; 002Dh
	jmp os_string_uppercase		; 0030h
	jmp os_string_lowercase		; 0033h
	jmp os_input_string		; 0036h
	jmp os_string_copy		; 0039h
	jmp os_dialog_box		; 003Ch
	jmp os_string_join		; 003Fh
	jmp os_get_file_list		; 0042h
	jmp os_string_compare		; 0045h
	jmp os_string_chomp		; 0048h
	jmp os_string_strip		; 004Bh
	jmp os_string_truncate		; 004Eh
	jmp os_bcd_to_int		; 0051h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_get_time_string		; 0054h
	jmp os_get_api_version		; 0057h
	jmp os_file_selector		; 005Ah
	jmp os_get_date_string		; 005Dh
	jmp os_send_via_serial		; 0060h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_get_via_serial		; 0063h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_find_char_in_string	; 0066h
	jmp os_get_cursor_pos		; 0069h
	jmp os_print_space		; 006Ch
	jmp os_dump_string		; 006Fh
	jmp os_print_digit		; 0072h
	jmp os_print_1hex		; 0075h
	jmp os_print_2hex		; 0078h
	jmp os_print_4hex		; 007Bh
	jmp os_long_int_to_string	; 007Eh
	jmp os_long_int_negate		; 0081h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_set_time_fmt		; 0084h
	jmp os_set_date_fmt		; 0087h
	jmp os_show_cursor		; 008Ah
	jmp os_hide_cursor		; 008Dh
	jmp os_dump_registers		; 0090h
	jmp os_string_strincmp		; 0093h
	jmp os_write_file		; 0096h
	jmp os_file_exists		; 0099h
	jmp os_create_file		; 009Ch
	jmp os_remove_file		; 009Fh
	jmp os_rename_file		; 00A2h
	jmp os_get_file_size		; 00A5h
	jmp os_input_dialog		; 00A8h
	jmp os_list_dialog		; 00ABh
	jmp os_string_reverse		; 00AEh
	jmp os_string_to_int		; 00B1h
	jmp os_draw_block		; 00B4h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_get_random		; 00B7h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_string_charchange	; 00BAh
	jmp os_serial_port_enable	; 00BDh --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_sint_to_string		; 00C0h
	jmp os_string_parse		; 00C3h
	jmp os_run_basic		; 00C6h
	jmp os_port_byte_out		; 00C9h --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_port_byte_in		; 00CCh --- Moved to zkernel, redirects for binary compatibility with MikeOS
	jmp os_string_tokenize		; 00CFh
	jmp os_speaker_freq		; 00D2h
	
; Extended Call Vectors
; Intersegmental kernel calls
%INCLUDE 'zkernel.inc'

	jmp 0x1000:ptr_text_mode		; 00D5h
	jmp 0x1000:ptr_graphics_mode		; 00DAh
	jmp 0x1000:ptr_set_pixel		; 00DFh
	jmp 0x1000:ptr_get_pixel		; 00E4h
	jmp 0x1000:ptr_draw_line		; 00E9h
	jmp 0x1000:ptr_draw_rectangle		; 00EEh
	jmp 0x1000:ptr_draw_polygon		; 00F3h
	jmp 0x1000:ptr_clear_graphics		; 00F8h
	jmp 0x1000:ptr_memory_allocate		; 00FDh
	jmp 0x1000:ptr_memory_release		; 0102h
	jmp 0x1000:ptr_memory_free		; 0107h
	jmp 0x1000:ptr_memory_reset		; 010Ch
	jmp 0x1000:ptr_memory_read		; 0111h
	jmp 0x1000:ptr_memory_write		; 0116h
	jmp 0x1000:ptr_speaker_freq		; 011Bh
	jmp 0x1000:ptr_speaker_tone		; 0120h
	jmp 0x1000:ptr_speaker_off		; 0125h
	jmp 0x1000:ptr_draw_border		; 012Ah
	jmp 0x1000:ptr_draw_horizontal_line	; 012Fh
	jmp 0x1000:ptr_draw_vertical_line	; 0134h
	jmp 0x1000:ptr_move_cursor		; 0139h
	jmp 0x1000:ptr_draw_block		; 013Eh
	jmp 0x1000:ptr_mouse_setup		; 0143h
	jmp 0x1000:ptr_mouse_locate		; 0148h
	jmp 0x1000:ptr_mouse_move		; 014Dh
	jmp 0x1000:ptr_mouse_show		; 0152h
	jmp 0x1000:ptr_mouse_hide		; 0157h
	jmp 0x1000:ptr_mouse_range		; 015Ch
	jmp 0x1000:ptr_mouse_wait		; 0161h
	jmp 0x1000:ptr_mouse_anyclick		; 0166h
	jmp 0x1000:ptr_mouse_leftclick		; 016Bh
	jmp 0x1000:ptr_mouse_middleclick	; 0170h
	jmp 0x1000:ptr_mouse_rightclick		; 0175h
	jmp 0x1000:ptr_input_wait		; 017Ah
	jmp 0x1000:ptr_mouse_scale		; 017Fh
	jmp 0x1000:ptr_wait_for_key		; 0184h
	jmp 0x1000:ptr_check_for_key		; 0189h
	jmp 0x1000:ptr_seed_random		; 018Eh
	jmp 0x1000:ptr_get_random		; 0193h
	jmp 0x1000:ptr_bcd_to_int		; 0198h
	jmp 0x1000:ptr_long_int_negate		; 019Dh
	jmp 0x1000:ptr_port_byte_out		; 01A2h
	jmp 0x1000:ptr_port_byte_in		; 01A7h
	jmp 0x1000:ptr_serial_port_enable	; 01ACh
	jmp 0x1000:ptr_send_via_serial		; 01B1h
	jmp 0x1000:ptr_get_via_serial		; 01B6h
	jmp 0x1000:ptr_square_root		; 01BBh
	jmp 0x1000:ptr_check_for_extkey		; 01C0h
	jmp 0x1000:ptr_draw_circle		; 01C5h
	jmp 0x1000:ptr_add_custom_icons		; 01CAh
	jmp 0x1000:ptr_load_file		; 01CFh
	jmp 0x1000:ptr_get_file_list		; 01D4h
	jmp 0x1000:ptr_write_file		; 01D9h
	jmp 0x1000:ptr_file_exists		; 01DEh
	jmp 0x1000:ptr_create_file		; 01E3h
	jmp 0x1000:ptr_remove_file		; 01E8h
	jmp 0x1000:ptr_rename_file		; 01EDh
	jmp 0x1000:ptr_get_file_size		; 01F2h
	jmp 0x1000:ptr_file_selector		; 01F7h
	jmp 0x1000:ptr_list_dialog		; 01FCh
	jmp 0x1000:ptr_pause			; 0201h


; ------------------------------------------------------------------
; START OF MAIN KERNEL CODE

os_main:


	; Install the mouse driver
	BOOTMSG 'Installing Mouse Driver...'
	call os_mouse_setup
	BOOTOK
	
	; Define the range of cursor movement
	BOOTMSG 'Setting Mouse Parameters...'
	mov ax, 0
	mov bx, 0
	mov cx, [CFG_SCREEN_HEIGHT]
	mov dx, [CFG_SCREEN_WIDTH]
	dec cx
	dec dx
	call os_mouse_range
	
	mov dh, 3
	mov dl, 2
	call os_mouse_scale
	BOOTOK
	
	; Let's see if there's a file called AUTORUN.BIN and execute
	; it if so, before going to the program launcher menu
	
	BOOTMSG 'Checking for autorun binary...'
	mov ax, autorun_bin_file_name
	call os_file_exists
	jc no_autorun_bin		; Skip next three lines if AUTORUN.BIN doesn't exist
	BOOTOK

	mov cx, 32768			; Otherwise load the program into RAM...
	call os_load_file
	jmp execute_bin_program		; ...and move on to the executing part
	
	jmp start_shell


	; Or perhaps there's an AUTORUN.BAS file?

no_autorun_bin:
	BOOTFAIL
	BOOTMSG 'Checking for autorun BASIC program...'
	mov ax, autorun_bas_file_name
	call os_file_exists
	jc no_autorun_bas		; Skip next section if AUTORUN.BAS doesn't exist
	
	BOOTOK
	
	mov cx, 32768			; Otherwise load the program into RAM
	call os_load_file

	mov ax, 32768
	call os_run_basic		; Run the kernel's BASIC interpreter

	jmp start_shell			; And start the UI shell when BASIC ends
	
no_autorun_bas:
	BOOTFAIL
	jmp start_shell

	
load_kernel_extentions:	

	mov ax, zkernel_filename
	mov cx, 32768
	call os_load_file
	jc missing_important_file
	
	push es
	push 0x1000
	pop es
	
	mov si, 32768
	mov di, 0
	mov cx, bx
	rep movsb
	
	mov ax, 0000h
	mov es, ax
	
	mov word [es:0014h], 0x2000
	mov word [es:0016h], ctrl_break
	
	mov word [es:006Ch], 0x2000 
	mov word [es:006Eh], ctrl_break
	
	pop es
	
	call os_mouse_setup
	
	mov ax, 0
	mov bx, 0
	mov cx, 79
	mov dx, 24
	call os_mouse_range
	
	mov dh, 3
	mov dl, 2
	call os_mouse_scale

	call os_add_custom_icons

	ret

ctrl_break:
	cli
	pop ax
	pop ax
	push 2000h
	push load_menu
	sti
	iret
	
missing_important_file:
	mov si, ax
	mov di, missing_file_name
	call os_string_copy
	
	mov ax, missing_file_string
	call os_fatal_error

	; And now data for the above code...

	kern_file_name		db OS_KERNEL_FILENAME, 0
	zkernel_filename	db OS_KERNEL_EXT_FILENAME, 0
	autorun_bin_file_name	db OS_AUTORUN_BIN_FILE, 0
	autorun_bas_file_name	db OS_AUTORUN_BAS_FILE, 0
	background_file_name	db OS_BACKGROUND_FILE, 0
	menu_file_name		db OS_MENU_DATA_FILE, 0

	missing_file_string	db OS_MISSING_FILE_MSG, 0
	missing_file_name	__FILENAME_BUFFER__
	

; ------------------------------------------------------------------
; FEATURES -- Code to pull into the kernel
	%INCLUDE "features/cli.asm"
	%INCLUDE "features/misc.asm"
	%INCLUDE "features/screen.asm"
	%INCLUDE "features/shell.asm"
	%INCLUDE "features/string.asm"
	%INCLUDE "features/basic.asm"
	
	BOOT_DATA_BLOCK
	
	; Configuration section
	times CROSSOVER_BUFFER-($-$$) db 0
	times CONFIG_START-($-$$) db 0
	dw DEF_DLG_OUTER_COLOUR
	dw DEF_DLG_INNER_COLOUR
	dw DEF_DLG_SELECT_COLOUR
	dw DEF_TITLEBAR_COLOUR
	dw DEF_24H_TIME
	dw DEF_DATE_FMT
	dw DEF_DATE_SEPARATOR
	dw DEF_SCREEN_HEIGHT
	dw DEF_SCREEN_WIDTH


; ==================================================================
; END OF KERNEL
; ==================================================================

