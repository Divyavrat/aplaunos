; =================================================================
; Blue Jay -- The Mike Operating System kernel
; Copyright (C) 2011 - 2012 Blue Jay Developers -- see LICENSE.TXT
; Copyright (C) 2006 - 2012 MikeOS Developers -- see LICENSE.TXT
;
; MAIN OS SECTION
; =================================================================


	BITS 16

	%DEFINE BJ_VER '0.50'
	%DEFINE BASIC_VER '4.3.1'
	%DEFINE BJ_API_VER 1
	%DEFINE BJ_API_VER2 '1'


; -----------------------------------------------------------------
; Program data section -- Pad out for app space (DO NOT CHANGE)

os_app_data:
	times 32768-($-$$)	db 0	; 32K of program space


; -----------------------------------------------------------------
; OS call vectors -- Static locations for system calls
; NOTE: THESE CANNOT BE MOVED -- it'll break the calls!
; Comments show exact locations of instructions in this section.

os_call_vectors:
	jmp os_main			; 0x8000 -- Called from bootloader
	jmp os_print_string		; 0x8003
	jmp os_move_cursor		; 0x8006
	jmp os_clear_screen		; 0x8009
	jmp os_print_horiz_line		; 0x800C
	jmp os_print_newline		; 0x800F
	jmp os_wait_for_key		; 0x8012
	jmp os_check_for_key		; 0x8015
	jmp os_int_to_string		; 0x8018
	jmp os_speaker_tone		; 0x801B
	jmp os_speaker_off		; 0x801E
	jmp os_load_file		; 0x8021
	jmp os_pause			; 0x8024
	jmp os_fatal_error		; 0x8027
	jmp os_draw_background		; 0x802A
	jmp os_string_length		; 0x802D
	jmp os_string_uppercase		; 0x8030
	jmp os_string_lowercase		; 0x8033
	jmp os_input_string		; 0x8036
	jmp os_string_copy		; 0x8039
	jmp os_dialog_box		; 0x803C
	jmp os_string_join		; 0x803F
	jmp os_modify_int_handler	; 0x8042
	jmp os_get_file_list		; 0x8045
	jmp os_string_compare		; 0x8048
	jmp os_string_chomp		; 0x804B
	jmp os_string_strip		; 0x804E
	jmp os_string_truncate		; 0x8051
	jmp os_bcd_to_int		; 0x8054
	jmp os_get_time_string		; 0x8057
	jmp os_get_api_version		; 0x805A
	jmp os_file_selector		; 0x805D
	jmp os_get_date_string		; 0x8060
	jmp os_send_via_serial		; 0x8063
	jmp os_get_via_serial		; 0x8066
	jmp os_find_char_in_string	; 0x8069
	jmp os_get_cursor_pos		; 0x806C
	jmp os_get_int_handler		; 0x806F
	jmp os_print_space		; 0x8072
	jmp os_dump_string		; 0x8075
	jmp os_print_digit		; 0x8078
	jmp os_print_1hex		; 0x807B
	jmp os_print_2hex		; 0x807E
	jmp os_print_4hex		; 0x8081
	jmp os_long_int_to_string	; 0x8084
	jmp os_long_int_negate		; 0x8087
	jmp os_set_time_fmt		; 0x808A
	jmp os_set_date_fmt		; 0x808D
	jmp os_show_cursor		; 0x8090
	jmp os_hide_cursor		; 0x8093
	jmp os_dump_registers		; 0x8096
	jmp os_write_file		; 0x8099
	jmp os_file_exists		; 0x809C
	jmp os_create_file		; 0x809F
	jmp os_remove_file		; 0x80A2
	jmp os_rename_file		; 0x80A5
	jmp os_get_file_size		; 0x80A8
	jmp os_port_byte_out		; 0x80AB
	jmp os_port_byte_in		; 0x80AE
	jmp os_port_word_out		; 0x80B1
	jmp os_port_word_in		; 0x80B4
	jmp os_draw_block		; 0x80B7
	jmp os_string_strincmp		; 0x80BA
	jmp os_string_parse		; 0x80BD
	jmp os_input_dialog		; 0x80C0
	jmp os_list_dialog		; 0x80C3
	jmp os_string_reverse		; 0x80C6
	jmp os_string_to_int		; 0x80C9
	jmp os_get_random		; 0x80CC
	jmp os_string_charchange	; 0x80CF
	jmp os_sint_to_string		; 0x80D2
	jmp os_get_api_ver_string	; 0x80D5
	jmp os_list_directory		; 0x80D8
	jmp os_string_tokenize		; 0x80DB
	jmp os_speaker_freq		; 0x80DE
	jmp os_run_basic		; 0x80E1
	jmp os_serial_port_enable	; 0x80E4

; =================================================================

os_buffer:
	times 8192		db 0		; 8K of generic buffer for syscalls & programs

; =================================================================
; START OF MAIN KERNEL CODE

os_main:
	cli				; Clear interrupts
	mov ax, 0
	mov ss, ax			; Set stack segment and pointer
	mov sp, 0xF000
	sti				; Restore interrupts

	cld				; The default direction for string operations
					; will be 'up' - incrementing address

	mov ax, 0x2000
	mov ds, ax			; Set data segments to where we loaded
	mov es, ax

	mov cx, 00h                     ; Divide by 0 error handler
	mov si, os_compat_int00
	call os_modify_int_handler

	mov cx, 20h			; Set up DOS compatibility...
	mov si, os_compat_int20		; ...for interrupts 20h and 21h
	call os_modify_int_handler

	mov cx, 21h
	mov si, os_compat_int21
	call os_modify_int_handler

	mov ax, 03			; Set to normal (80x25 text) video mode
	int 10h

.redraw_select:
	mov ax, 1003h			; For text intensity (no blinking)
	mov bx, 0
	int 10h

	call os_seed_random		; Set Up cursor to _

.start_msg:
	call os_clear_screen
	call os_print_splash

.dir_screen:
	; Let's see if there's a file called AUTORUN.COM and execute
	; it if so, before going to the program launcher menu

	mov ax, .autorun_com_file_name
	call os_file_exists
	jc .autorun_bas				; Skip next three lines if AUTORUN.COM doesn't exist

	mov cx, 100h
	call os_load_file			; ...and move on to the executing part
	call os_execute_program
	jmp .done

	; Or perhaps there's an AUTORUN.BAS file?

.autorun_bas:
	mov ax, .autorun_bas_file_name
	call os_file_exists
	jc .done			; Skip next section if AUTORUN.BAS doesn't exist

	call os_clear_screen
	mov cx, 100h			; Otherwise load the program into RAM
	call os_load_file
	mov ax, .autorun_bas_file_name
	call os_get_file_size
	mov ax, 100h
	call os_run_basic		; Run the kernel's BASIC interpreter

	jmp .done			; And go to the app selector menu when BASIC ends

.done:
	jmp os_function_interface

;------------------------------------------------------------------
; Data for the above code

	.autorun_com_file_name	db 'AUTORUN COM', 0
	.autorun_bas_file_name	db 'AUTORUN BAS', 0

; =================================================================
; SYSTEM VARIABLES -- Settings for programs and system calls


	; Time and date formatting

	fmt_12_24	db 0		; Non-zero = 24-hr format

	fmt_date	db 0, '/'	; 0, 1, 2 = M/D/Y, D/M/Y or Y/M/D
					; Bit 7 = use name for months
					; If bit 7 = 0, second byte = separator character


; =================================================================
; INTERNAL OS ROUTINES -- Not accessible to user programs


	%INCLUDE "SYSCALLS/INTERNAL.ASM"


; =================================================================
; DOS COMPATIBILITY INTERRUPT HANDLERS


	%INCLUDE "SYSCALLS/DOS.ASM"


; =================================================================
; BLUE JAY FUNCTION INTERFACE


	%INCLUDE "SYSCALLS/BJFUNCINT.ASM"


; =================================================================
; FAT12 WRITE SUPPORT ROUTINES


	%INCLUDE "SYSCALLS/FILE.ASM"


; =================================================================
; SYSTEM CALL SECTION -- Accessible to user programs


        %INCLUDE "SYSCALLS/KEYBOARD.ASM"
        %INCLUDE "SYSCALLS/MATH.ASM"
        %INCLUDE "SYSCALLS/MISC.ASM"
        %INCLUDE "SYSCALLS/PORTS.ASM"
        %INCLUDE "SYSCALLS/SCREEN.ASM"
        %INCLUDE "SYSCALLS/SOUND.ASM"
        %INCLUDE "SYSCALLS/STRING.ASM"
        %INCLUDE "SYSCALLS/SPLASH.ASM"

; =================================================================
; MikeBASIC INTERPRETER


	%INCLUDE "SYSCALLS/BASIC.ASM"


; =================================================================
; END OF KERNEL
; =================================================================