; ------------------------------------------------------------------
; Include file for MikeOS program development (API version 16)
; ------------------------------------------------------------------

; ------------------------------------------------------------------
; IMPORTANT LOCATIONS

os_main			equ	0x0500	; Where the OS code starts


; ------------------------------------------------------------------
; COLOURS (eg for os_draw_background and os_draw_block)

%DEFINE BLACK_ON_WHITE		11110000b
%DEFINE WHITE_ON_BLACK		00001111b
%DEFINE WHITE_ON_LIGHT_RED	11001111b
%DEFINE WHITE_ON_GREEN		00101111b
%DEFINE RED_ON_LIGHT_GREEN	10100100b


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


; Misc OS functions

os_run_basic		equ	os_main+00C6h	; AX = code location in RAM, BX = size,
					; SI = parameter string (or 0 if none)
os_get_api_version	equ	os_main+0057h	; Returns API version in AL
os_pause		equ	os_main+0024h	; AX = 10ths of second to wait
os_fatal_error		equ	os_main+0027h	; AX = error string location


; ------------------------------------------------------------------

; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; GRAPHICS ROUTINES
; ==================================================================

os_text_mode equ os_main+00D5h
os_graphics_mode equ os_main+00D8h
os_set_pixel equ os_main+00DBh
os_get_pixel equ os_main+00DEh

os_clear_graphics equ os_main+00EAh

os_draw_horizontal_line equ os_main+010Bh
os_draw_vertical_line equ os_main+010Eh

os_draw_polygon equ os_main+00E7h
os_draw_circle equ os_main+0165h

;os_return:
;ret
	
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
	
	.done:
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	popa
	;dec byte [internal_call]
	ret
	
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
	
; Draw (straight) rectangle
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour, CF = set if filled or clear if not
; OUT: None, registers preserved
os_draw_rectangle:
	pusha
	pushf
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	
	;inc byte [internal_call]
	
	mov word [.x1], cx
	mov word [.y1], dx
	mov word [.x2], si
	mov word [.y2], di
	
	; top line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y1]
	call os_draw_line
	
	; left line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x1]
	mov di, [.y2]
	call os_draw_line
	
	; right line
	mov cx, [.x2]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line

	; bottom line
	mov cx, [.x1]
	mov dx, [.y2]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line
	
	popf
	jnc .finished_fill
	
.fill_shape:
	inc word [.y1]
	
	mov ax, [.y1]
	cmp ax, [.y2]
	jge .finished_fill
	
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y1]
	call os_draw_line
	
	jmp .fill_shape
	
.finished_fill:
	popa
	;dec byte [internal_call]
	ret
	
	.x1				dw 0
	.x2				dw 0
	.y1				dw 0
	.y2				dw 0

; ------------------------------------------------------------------
; os_draw_border -- draw a single character border
; BL = colour, CH = start row, CL = start column, DH = end row, DL = end column

os_draw_border:
	pusha
	
	;mov ax, 0x1000
	;mov ds, ax
	
	;inc byte [internal_call]

	mov [.start_row], ch
	mov [.start_column], cl
	mov [.end_row], dh
	mov [.end_column], dl

	mov al, [.end_column]
	sub al, [.start_column]
	dec al
	mov [.width], al
	
	mov al, [.end_row]
	sub al, [.start_row]
	dec al
	mov [.height], al
	
	mov ah, 09h
	mov bh, 0
	mov cx, 1

	mov dh, [.start_row]
	mov dl, [.start_column]
	call os_move_cursor

	mov al, [.character_set + 0]
	int 10h
	
	mov dh, [.start_row]
	mov dl, [.end_column]
	call os_move_cursor
	
	mov al, [.character_set + 1]
	int 10h
	
	mov dh, [.end_row]
	mov dl, [.start_column]
	call os_move_cursor
	
	mov al, [.character_set + 2]
	int 10h
	
	mov dh, [.end_row]
	mov dl, [.end_column]
	call os_move_cursor
	
	mov al, [.character_set + 3]
	int 10h
	
	mov dh, [.start_row]
	mov dl, [.start_column]
	inc dl
	call os_move_cursor
	
	mov al, [.character_set + 4]
	mov cx, 0
	mov cl, [.width]
	int 10h
	
	mov dh, [.end_row]
	call os_move_cursor
	int 10h
	
	mov al, [.character_set + 5]
	mov cx, 1
	mov dh, [.start_row]
	inc dh
	
.sides_loop:
	mov dl, [.start_column]
	call os_move_cursor
	int 10h
	
	mov dl, [.end_column]
	call os_move_cursor
	int 10h
	
	inc dh
	dec byte [.height]
	cmp byte [.height], 0
	jne .sides_loop
	
	popa
	;dec byte [internal_call]
	ret
	
	
.start_column				db 0
.end_column				db 0
.start_row				db 0
.end_row				db 0
.height					db 0
.width					db 0

.character_set				db 218, 191, 192, 217, 196, 179
