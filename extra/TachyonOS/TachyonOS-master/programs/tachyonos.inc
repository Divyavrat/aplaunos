; ------------------------------------------------------------------
; Include file for Tachyon OS program development (API version 6)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; IMPORTANT LOCATIONS

os_main			equ	0000h	; Where the OS code starts


; ------------------------------------------------------------------
; COLOURS (eg for os_draw_background and os_draw_block)

%DEFINE DIALOG_BOX_OUTER_COLOUR		01001111b
%DEFINE DIALOG_BOX_INNER_COLOUR		11110000b
%DEFINE DIALOG_BOX_SELECT_COLOUR	00001111b
%DEFINE TITLEBAR_COLOUR			01110000b

; ------------------------------------------------------------------
; KEYS

%DEFINE KEY_UP		72
%DEFINE KEY_DOWN	80
%DEFINE KEY_LEFT	75
%DEFINE KEY_RIGHT	77

%DEFINE KEY_ESC		27
%DEFINE KEY_ENTER	13


; ------------------------------------------------------------------
; SYSTEM CALLS

; Screen control

os_clear_screen		equ	0009h	; (Nothing used)
os_print_string		equ	0003h	; SI = zero-terminated string location
os_move_cursor		equ	0139h	; DH, DL = row, column
os_print_horiz_line	equ	000Ch	; AX = 1 for double line, else single
os_print_newline	equ	000Fh	; (Nothing used)
os_draw_background	equ	002Ah	; AX, BX = strings, CX = colour
os_draw_block		equ	013Eh	; BL = colour, DH/DL/SI/DI = pos
os_input_dialog		equ	00A8h	; AX = input string, BX = msg string
os_dialog_box		equ	003Ch	; AX, BX, CX = strings, DX = type
					; OUT: AX = 0 for OK, 1 for cancel
					; (only multi choice for DX = 1)
os_list_dialog		equ	00ABh	; IN: AX = comma-separated list of
					; option strings, BX, CX = help to
					; display at top of list
					; OUT: AX = number (starting from 1)
					; of option selected, or carry if Esc
os_file_selector	equ	005Ah	; Returns filename in AX
os_get_cursor_pos	equ	0069h	; OUT: DH = row, DL = column
os_print_space		equ	006Ch	; (Nothing used)
os_dump_string		equ	006Fh	; SI = string location
os_print_digit		equ	0072h	; AX = digit to print
os_print_1hex		equ	0075h	; Display low nibble of AL in hex
os_print_2hex		equ	0078h	; Display AL in hex
os_print_4hex		equ	007Bh	; Display AX in hex
os_show_cursor		equ	008Ah	; (Nothing used)
os_hide_cursor		equ	008Dh	; (Nothing used)
os_dump_registers	equ	0090h	; Shows contents of AX, BX, CX, DX
os_draw_border		equ 	012Ah
os_draw_horizontal_line	equ 	012Fh
os_draw_vertical_line	equ 	0134h


; Keyboard handling

os_wait_for_key		equ	0184h	; Returns AL = key pressed
os_check_for_key	equ	0189h	; Returns AL = key pressed
os_check_for_extkey	equ	01C0h


; File handling

os_get_file_list	equ	0042h	; AX = string to store filenames
os_load_file		equ	0021h	; IN: AX = filename string location,
					; CX = location to load file
					; OUT: BX = file size in bytes,
					; carry clear if OK, set if missing
os_write_file		equ	0096h	; AX = filename, BX = data location,
					; CX = number of bytes to save
os_file_exists		equ	0099h	; AX = filename, carry clear if exists
os_create_file		equ	009Ch	; AX = filename
os_remove_file		equ	009Fh	; AX = filename
os_rename_file		equ	00A2h	; AX = filename, BX = new filename
os_get_file_size	equ	00A5h	; AX = filename, OUT: BX = bytes
					; (64K max)


; Sound

os_speaker_freq		equ	011Bh	; AX = note frequency
os_speaker_tone		equ	0120h	; AX = tone value
os_speaker_off		equ	0125h	; (Nothing used)


; String handling

os_int_to_string	equ	0018h	; AX = unsigned integer, out AX = string
os_sint_to_string	equ	00C0h	; AX = signed integer, out AX = string
os_string_reverse	equ	00AEh	; SI = string location
os_string_length	equ	002Dh	; AX = string loc, returns AX = length
os_string_uppercase	equ	0030h	; AX = zero-terminated string
os_string_lowercase	equ	0033h	; AX = zero-terminated string
os_input_string		equ	0036h	; AX = string location
os_string_copy		equ	0039h	; SI = source, DI = dest strings
os_string_join		equ	003Fh	; AX, BX = source strings, CX = dest
os_string_compare	equ	0045h	; SI, DI = strings, carry set if same
os_string_strincmp	equ	0093h	; As above, but with CL = chars to check
os_string_chomp		equ	0048h	; AX = string location
os_string_strip		equ	004Bh	; SI = string, AX = char to remove
os_string_truncate	equ	004Eh	; SI = string, AX = number of chars
os_set_time_fmt		equ	0084h	; AL = format
os_set_date_fmt		equ	0087h	; AX = format
os_get_time_string	equ	0054h	; BX = string location for eg '20:41'
os_get_date_string	equ	005Dh	; BX = string loc for eg '12/31/2007'
os_find_char_in_string	equ	0066h	; IN: SI = string, AL = char to find
os_long_int_to_string	equ	007Eh	; DX:AX = num, BX = base, DI = string
os_string_to_int	equ	00B1h	; SI = string (up to 65535), AX = int
os_string_charchange	equ	00BAh	; SI = string, AL = old char, BL = new
os_string_parse		equ	00C3h	; SI = string; output: AX/BX/CX/DX =
					; substrings (or 0 if not present)
os_string_tokenize	equ	00CFh	; SI = string, AL = sep char; returns
					; DI = next token


; Math routines

os_get_random		equ	0193h	; IN: AX, BX = low, high; OUT: CX = num
os_bcd_to_int		equ	0198h	; AL = BCD number, returns AX = integer
os_long_int_negate	equ	019Dh	; DX:AX = number
os_square_root		equ	01BBh


; Ports

os_port_byte_out	equ	01A2h	; IN: DX = port, AL = byte
os_port_byte_in		equ	01A7h	; IN: DX = port; OUT: AL = byte
os_serial_port_enable	equ	01ACh	; AX = 0 for 9600 baud, 1 for 1200
os_send_via_serial	equ	01B1h	; AL = byte to send
os_get_via_serial	equ	01B6h	; Returns AL = byte received
					; OUT: AX = location, or 0 if not found

; Graphical routines

os_text_mode		equ	00D5h
os_graphics_mode	equ	00DAh
os_set_pixel		equ	00DFh
os_get_pixel		equ	00E4h
os_draw_line		equ	00E9h
os_draw_rectangle	equ	00EEh
os_draw_polygon		equ	00F3h
os_clear_graphics	equ	00F8h

; Extended Memory Functions

os_memory_allocate	equ	00FDh
os_memory_release	equ	0102h
os_memory_free		equ	0107h
os_memory_reset		equ	010Ch
os_memory_read		equ	0111h
os_memory_write		equ	0116h

; Mouse routines

os_mouse_setup		equ	0143h
os_mouse_locate		equ	0148h
os_mouse_move		equ	014Dh
os_mouse_show		equ	0152h
os_mouse_hide		equ	0157h
os_mouse_range		equ	015Ch
os_mouse_wait		equ	0161h
os_mouse_anyclick	equ	0166h
os_mouse_leftclick	equ	016Bh
os_mouse_middleclick	equ	0170h
os_mouse_rightclick	equ	0175h
os_input_wait		equ	017Ah
os_mouse_scale		equ	017Fh


; Misc OS functions

os_run_basic		equ	00C6h	; AX = code location in RAM, BX = size,
					; SI = parameter string (or 0 if none)
os_get_api_version	equ	0057h	; Returns API version in AL
os_pause		equ	0024h	; AX = 10ths of second to wait
os_fatal_error		equ	0027h	; AX = error string location


; ------------------------------------------------------------------

