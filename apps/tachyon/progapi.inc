; ------------------------------------------------------------------
; Include file for program development (API version 16)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; IMPORTANT LOCATIONS

os_main			equ	0500h	; Where the OS code starts


; ------------------------------------------------------------------
; COLOURS (eg for os_draw_background and os_draw_block)
DEFINE DIALOG_BOX_OUTER_COLOUR		01001111b
DEFINE DIALOG_BOX_INNER_COLOUR		11110000b
DEFINE DIALOG_BOX_SELECT_COLOUR	00001111b
DEFINE TITLEBAR_COLOUR			01110000b

DEFINE BLACK_ON_WHITE		11110000b
DEFINE WHITE_ON_BLACK		00001111b
DEFINE WHITE_ON_LIGHT_RED	11001111b
DEFINE WHITE_ON_GREEN		00101111b
DEFINE RED_ON_LIGHT_GREEN	10100100b
DEFINE WHITE_ON_RED		01001111b


; ------------------------------------------------------------------
; KEYS

DEFINE KEY_UP		72
DEFINE KEY_DOWN	80
DEFINE KEY_LEFT	75
DEFINE KEY_RIGHT	77

DEFINE KEY_ESC		27
DEFINE KEY_ENTER	13


; ------------------------------------------------------------------
; SYSTEM CALLS

; Screen control

os_clear_screen		equ	os_main+0009h	; (Nothing used)
os_print_string		equ	os_main+0003h	; SI = zero-terminated string location
os_move_cursor		equ	os_main+0006h	; DH, DL = row, column
os_print_horiz_line	equ	os_main+000Ch	; AX = 1 for double line, else single
os_print_newline	equ	os_main+000Fh	; (Nothing used)
os_draw_background	equ	os_main+002Ah	; AX, BX = strings, CX = colour
os_draw_block		equ	os_main+00B4h	; BL = colour, DH/DL/SI/DI = pos
os_input_dialog		equ	os_main+00A8h	; AX = input string, BX = msg string
os_dialog_box		equ	os_main+003Ch	; AX, BX, CX = strings, DX = type
					; OUT: AX = 0 for OK, 1 for cancel
					; (only multi choice for DX = 1)
os_list_dialog		equ	os_main+00ABh	; IN: AX = comma-separated list of
					; option strings, BX, CX = help to
					; display at top of list
					; OUT: AX = number (starting from 1)
					; of option selected, or carry if Esc
os_file_selector	equ	os_main+005Ah	; Returns filename in AX
os_get_cursor_pos	equ	os_main+0069h	; OUT: DH = row, DL = column
os_print_space		equ	os_main+006Ch	; (Nothing used)
os_dump_string		equ	os_main+006Fh	; SI = string location
os_print_digit		equ	os_main+0072h	; AX = digit to print
os_print_1hex		equ	os_main+0075h	; Display low nibble of AL in hex
os_print_2hex		equ	os_main+0078h	; Display AL in hex
os_print_4hex		equ	os_main+007Bh	; Display AX in hex
os_show_cursor		equ	os_main+008Ah	; (Nothing used)
os_hide_cursor		equ	os_main+008Dh	; (Nothing used)
os_dump_registers	equ	os_main+0090h	; Shows contents of AX, BX, CX, DX


; Keyboard handling

os_wait_for_key		equ	os_main+0012h	; Returns AL = key pressed
os_check_for_key	equ	os_main+0015h	; Returns AL = key pressed


; File handling

os_get_file_list	equ	os_main+0042h	; AX = string to store filenames
os_load_file		equ	os_main+0021h	; IN: AX = filename string location,
					; CX = location to load file
					; OUT: BX = file size in bytes,
					; carry clear if OK, set if missing
os_write_file		equ	os_main+0096h	; AX = filename, BX = data location,
					; CX = number of bytes to save
os_file_exists		equ	os_main+0099h	; AX = filename, carry clear if exists
os_create_file		equ	os_main+009Ch	; AX = filename
os_remove_file		equ	os_main+009Fh	; AX = filename
os_rename_file		equ	os_main+00A2h	; AX = filename, BX = new filename
os_get_file_size	equ	os_main+00A5h	; AX = filename, OUT: BX = bytes
					; (64K max)


; Sound
os_speaker_freq		equ	os_main+00D2h	; AX = note frequency
os_speaker_tone		equ	os_main+001Bh	; AX = note frequency
os_speaker_off		equ	os_main+001Eh	; (Nothing used)


; String handling

os_int_to_string	equ	os_main+0018h	; AX = unsigned integer, out AX = string
os_sint_to_string	equ	os_main+00C0h	; AX = signed integer, out AX = string
os_string_reverse	equ	os_main+00AEh	; SI = string location
os_string_length	equ	os_main+002Dh	; AX = string loc, returns AX = length
os_string_uppercase	equ	os_main+0030h	; AX = zero-terminated string
os_string_lowercase	equ	os_main+0033h	; AX = zero-terminated string
os_input_string		equ	os_main+0036h	; AX = string location
os_string_copy		equ	os_main+0039h	; SI = source, DI = dest strings
os_string_join		equ	os_main+003Fh	; AX, BX = source strings, CX = dest
os_string_compare	equ	os_main+0045h	; SI, DI = strings, carry set if same
os_string_strincmp	equ	os_main+0093h	; As above, but with CL = chars to check
os_string_chomp		equ	os_main+0048h	; AX = string location
os_string_strip		equ	os_main+004Bh	; SI = string, AX = char to remove
os_string_truncate	equ	os_main+004Eh	; SI = string, AX = number of chars
os_set_time_fmt		equ	os_main+0084h	; AL = format
os_set_date_fmt		equ	os_main+0087h	; AX = format
os_get_time_string	equ	os_main+0054h	; BX = string location for eg '20:41'
os_get_date_string	equ	os_main+005Dh	; BX = string loc for eg '12/31/2007'
os_find_char_in_string	equ	os_main+0066h	; IN: SI = string, AL = char to find
os_long_int_to_string	equ	os_main+007Eh	; DX:AX = num, BX = base, DI = string
os_string_to_int	equ	os_main+00B1h	; SI = string (up to 65535), AX = int
os_string_charchange	equ	os_main+00BAh	; SI = string, AL = old char, BL = new
os_string_parse		equ	os_main+00C3h	; SI = string; output: AX/BX/CX/DX =
					; substrings (or 0 if not present)
os_string_tokenize	equ	os_main+00CFh	; SI = string, AL = sep char; returns
					; DI = next token


; Math routines

os_get_random		equ	os_main+00B7h	; IN: AX, BX = low, high; OUT: CX = num
os_bcd_to_int		equ	os_main+0051h	; AL = BCD number, returns AX = integer
os_long_int_negate	equ	os_main+0081h	; DX:AX = number


; Ports

os_port_byte_out	equ	os_main+00C9h	; IN: DX = port, AL = byte
os_port_byte_in		equ	os_main+00CCh	; IN: DX = port; OUT: AL = byte
os_serial_port_enable	equ	os_main+00BDh	; AX = 0 for 9600 baud, 1 for 1200

os_send_via_serial	equ	os_main+0060h	; AL = byte to send
os_get_via_serial	equ	os_main+0063h	; Returns AL = byte received
					; OUT: AX = location, or 0 if not found


; ------------------------------------------------------------------

; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; GRAPHICS ROUTINES
; ==================================================================
os_set_pixel		equ	os_main+00DBh
os_get_pixel		equ	os_main+00DEh
os_draw_line		equ	os_main+00E1h
os_draw_rectangle	equ	os_main+00E4h
os_draw_polygon		equ	os_main+00E7h
os_clear_graphics	equ	os_main+00EAh
os_draw_horizontal_line equ os_main+010Bh
os_draw_vertical_line equ os_main+010Eh
os_draw_border equ os_main+0108h
os_draw_circle equ os_main+0165h

; Extended Memory Functions

os_memory_allocate	equ	os_main+00EDh
os_memory_release	equ	os_main+00F0h
os_memory_free		equ	os_main+00F3h
os_memory_reset		equ	os_main+00F6h
os_memory_read		equ	os_main+00FCh
os_memory_write		equ	os_main+00FCh

; Mouse routines

os_mouse_setup		equ	os_main+0117h
os_mouse_locate		equ	os_main+011Ah
os_mouse_move		equ	os_main+011Dh
os_mouse_show		equ	os_main+0120h
os_mouse_hide		equ	os_main+0123h
os_mouse_range		equ	os_main+0126h
os_mouse_wait		equ	os_main+0129h
os_mouse_anyclick	equ	os_main+012Ch
os_mouse_leftclick	equ	os_main+012Fh
os_mouse_middleclick	equ	os_main+0132h
os_mouse_rightclick	equ	os_main+0135h
os_input_wait		equ	os_main+0138h
os_mouse_scale		equ	os_main+013Bh

; Misc OS functions

os_run_basic		equ	os_main+00C6h	; AX = code location in RAM, BX = size,
					; SI = parameter string (or 0 if none)
os_get_api_version	equ	os_main+0057h	; Returns API version in AL
os_pause		equ	os_main+0024h	; AX = 10ths of second to wait
os_fatal_error		equ	os_main+0027h	; AX = error string location

os_get_api_ver_string	equ	os_main+0168h	; IN: Nothing; OUT: SI = API version number


os_text_mode equ os_main+00D5h
os_graphics_mode equ os_main+00D8h

; ------------------------------------------------------------------

; ---------------------------------

