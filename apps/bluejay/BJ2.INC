; -----------------------------------------------------------------
; Include file for Blue Jay program development (API version 1)
; -----------------------------------------------------------------

; -----------------------------------------------------------------
; IMPORTANT LOCATIONS

os_main			equ	0x8000	; Jump here to completely restart OS
os_buffer		equ	0xE000	; 8K scratchpad space


; -----------------------------------------------------------------
; SYSTEM CALLS

; Screen control

os_clear_screen		equ	0x8009	; (Nothing used)
os_print_string		equ	0x8003	; SI = zero-terminated string location
os_move_cursor		equ	0x8006	; DH, DL = row, column
os_print_horiz_line	equ	0x800C	; AX = 1 for double line, else single
os_print_newline	equ	0x800F	; (Nothing used)
os_draw_background	equ	0x802A	; AX, BX = strings, CX = colour
os_draw_block		equ	0x80B7	; BL = colour, DH/DL/SI/DI = pos
os_input_dialog		equ	0x80C0	; AX = input string, BX = msg string
os_dialog_box		equ	0x803C	; AX, BX, CX = strings, DX = type
					; OUT: AX = 0 for OK, 1 for cancel
					; (only multi choice for DX = 1)
os_list_dialog		equ	0x80C3	; IN: AX = comma-separated list of
					; option strings, BX, CX = help to
					; display at top of list
					; OUT: AX = number (starting from 1)
					; of option selected, or carry if Esc
os_file_selector	equ	0x805D	; Returns filename in AX
os_get_cursor_pos	equ	0x806C	; OUT: DH = row, DL = column
os_print_space		equ	0x8072	; (Nothing used)
os_dump_string		equ	0x8075	; SI = string location
os_print_digit		equ	0x8078	; AX = digit to print
os_print_1hex		equ	0x807B	; Display low nibble of AL in hex
os_print_2hex		equ	0x807E	; Display AL in hex
os_print_4hex		equ	0x8081	; Display AX in hex
os_show_cursor		equ	0x8090	; (Nothing used)
os_hide_cursor		equ	0x8093	; (Nothing used)
os_dump_registers	equ	0x8096	; Shows contents of AX, BX, CX, DX

; Keyboard handling

os_wait_for_key		equ	0x8012	; Returns AL = key pressed
os_check_for_key	equ	0x8015	; Returns AL = key pressed


; File handling

os_get_file_list	equ	0x8045	; AX = string to store filenames
os_load_file		equ	0x8021	; AX = filename string location,
					; CX = location to load file
os_write_file		equ	0x8099	; AX = filename, BX = data location,
					; CX = number of bytes to save
os_file_exists		equ	0x809C	; AX = filename, carry clear if exists
os_create_file		equ	0x809F	; AX = filename
os_remove_file		equ	0x80A2	; AX = filename
os_rename_file		equ	0x80A5	; AX = filename, BX = new filename
os_get_file_size	equ	0x80A8	; AX = filename, OUT: BX = bytes
					; (64K max)
os_list_directory	equ	0x80D8	; (Nothing used)


; Sound

os_speaker_tone		equ	0x801B	; AX = note frequency
os_speaker_off		equ	0x801E	; (Nothing used)
os_speaker_freq		equ	0x80DE	; AX = note frequency


; String handling

os_int_to_string	equ	0x8018	; AX = unsigned integer, out AX = string
os_sint_to_string	equ	0x80D2	; AX = signed integer, out AX = string
os_string_reverse	equ	0x80C6	; SI = string location
os_string_length	equ	0x802D	; AX = string loc, returns AX = length
os_string_uppercase	equ	0x8030	; AX = zero-terminated string
os_string_lowercase	equ	0x8033	; AX = zero-terminated string
os_input_string		equ	0x8036	; AX = string location
os_string_copy		equ	0x8039	; SI = source, DI = dest strings
os_string_join		equ	0x803F  ; AX, BX = source strings, CX = dest
os_string_compare	equ	0x8048	; SI, DI = strings, carry set if same
os_string_strincmp	equ	0x80BA	; As above, but with CL = chars to check
os_string_chomp		equ	0x804B	; AX = string location
os_string_strip		equ	0x804E	; SI = string, AX = char to remove
os_string_truncate	equ	0x8051	; SI = string, AX = number of chars
os_set_time_fmt		equ	0x808A	; AL = format
os_set_date_fmt		equ	0x808D	; AX = format
os_get_time_string	equ	0x8057	; BX = string location for eg '20:41'
os_get_date_string	equ	0x8060	; BX = string loc for eg '12/31/2007'
os_find_char_in_string	equ	0x8069	; IN: SI = string, AL = char to find
os_long_int_to_string	equ	0x8084	; DX:AX = num, BX = base, DI = string
os_string_to_int	equ	0x80C9	; SI = string (up to 65535), AX = int
os_string_charchange	equ	0x80CF	; SI = string, AL = old char, BL = new
os_string_parse		equ	0x80BD	; SI = string; output: AX/BX/CX/DX =
					; substrings (or 0 if not present)
os_string_tokenize	equ	0x80DB	; SI = string, AL = sep char; returns
					; DI = next token


; Math routines

os_get_random		equ	0x80CC	; IN: AX, BX = low, high; OUT: CX = num
os_bcd_to_int		equ	0x8054	; AL = BCD number, returns AX = integer
os_long_int_negate	equ	0x8087	; DX:AX = number


; Port routines

os_send_via_serial	equ	0x8063	; AL = byte to send
os_get_via_serial	equ	0x8066	; Returns AL = byte received
					; OUT: AX = location, or 0 if not found
os_port_byte_out	equ	0x80AB	; IN: DX = port, AL = byte
os_port_byte_in		equ	0x80AE	; IN: DX = port; OUT: AL = byte
os_port_word_out	equ	0x80B1	; IN: DX = port, AL = word
os_port_word_in		equ	0x80B4	; IN: DX = port; OUT: AL = word
os_serial_port_enable	equ	0x80E4	; AX = 0 for 9600 baud, 1 for 1200


; Misc OS functions

os_get_api_version	equ	0x805A	; Returns API version in AL
os_get_int_handler	equ	0x806F	; IN: AX = int, OUT: ES:BX = handler loc
os_modify_int_handler	equ	0x8042	; CX = int number, SI = handler loc
os_pause		equ	0x8024	; AX = 10ths of second to wait
os_fatal_error		equ	0x8027	; AX = error string location
os_get_api_ver_string	equ	0x80D5	; IN: Nothing; OUT: SI = API version number
os_run_basic		equ	0x80E1	; AX = code loc, BX = size


; -----------------------------------------------------------------
; COLOURS

%DEFINE BLACK_ON_WHITE		11110000b
%DEFINE WHITE_ON_BLACK		00001111b
%DEFINE WHITE_ON_LIGHT_RED	11001111b
%DEFINE WHITE_ON_GREEN		00101111b
%DEFINE RED_ON_LIGHT_GREEN	10100100b
%DEFINE WHITE_ON_RED		01001111b


; ------------------------------------------------------------------
; KEYS

%DEFINE KEY_UP		72
%DEFINE KEY_DOWN	80
%DEFINE KEY_LEFT	75
%DEFINE KEY_RIGHT	77

%DEFINE KEY_ESC		27
%DEFINE KEY_ENTER	13