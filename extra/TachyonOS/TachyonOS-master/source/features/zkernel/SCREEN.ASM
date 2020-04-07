; ------------------------------------------------------------------
; os_draw_border -- draw a single character border
; BL = colour, CH = start row, CL = start column, DH = end row, DL = end column

os_draw_border:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	inc byte [internal_call]

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
	dec byte [internal_call]
	jmp os_return
	
	
.start_column				db 0
.end_column				db 0
.start_row				db 0
.end_row				db 0
.height					db 0
.width					db 0

.character_set				db 218, 191, 192, 217, 196, 179

; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = width, BL = colour, DH = start row, DL = start column

os_draw_horizontal_line:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	inc byte [internal_call]
	
	mov cx, 0
	mov cl, bh
	
	call os_move_cursor
	
	mov ah, 09h
	mov al, 196
	mov bh, 0
	int 10h

	popa
	dec byte [internal_call]
	jmp os_return
	
; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = length, BL = colour, DH = start row, DL = start column

os_draw_vertical_line:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	inc byte [internal_call]
	
	mov cx, 0
	mov cl, bh
	
	mov ah, 09h
	mov al, 179
	mov bh, 0
	
.lineloop:
	push cx
	
	call os_move_cursor
	
	mov cx, 1
	int 10h
	
	inc dh
	
	pop cx
	
	loop .lineloop

	popa
	dec byte [internal_call]
	jmp os_return
	

; ------------------------------------------------------------------
; os_move_cursor -- Moves cursor in text mode
; IN: DH, DL = row, column; OUT: Nothing (registers preserved)

os_move_cursor:
	pusha

	mov bh, 0
	mov ah, 2
	int 10h				; BIOS interrupt to move cursor

	popa
	jmp os_return

	

; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

os_draw_block:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	; find starting byte
	
	mov [.colour], bl
	mov byte [.character], 32
	
	mov [.rows], di
	
	mov ax, 0			; start with row * 80
	mov al, dh
	mov bx, ax			; use bit shifts for fast multiplication
	shl ax, 4			; 2^4 = 16 
	shl bx, 6			; 2^6 = 64
	add ax, bx			; 16 + 64 = 80
	mov bx, 0			; add column
	mov bl, dl
	add ax, bx
	shl ax, 1			; each text mode character takes two bytes (colour and value)
	mov di, ax
	
	mov [.width], si		; store the width, this will need to be reset
	
	mov bx, 80			; find amount to increment by to get to next line ((screen width - block width) * 2)
	sub bx, si
	shl bx, 1
	mov si, bx
	
	mov ax, 0			; find number of rows to do (finish Y - start Y)
	mov al, dh
	sub [.rows], ax
	
	mov ax, 0xB800			; set the text segment
	mov es, ax
	
	mov ax, [.character]		; get the value to write
	
.write_data:
	mov cx, [.width]		; get line width
	rep stosw			; write character value
	
	add di, si			; move to next line
	
	dec word [.rows]
	cmp word [.rows], 0		; check if we have processed every row
	
	jne .write_data			; if not continue
	
	popa
	jmp os_return

	.width				dw 0
	.rows				dw 0
	.character			db 0
	.colour				db 0
	
	
; ---------
; Stuff copied from alternate build
; --------

; ------------------------------------------------------------------
; os_file_selector -- Show a file selection dialog
; IN: Nothing; OUT: AX = location of filename string (or carry set if Esc pressed)

os_file_selector:
	pusha
	
	mov dx, es
	mov [.output_segment], dx
	
	mov dx, gs
	mov ds, dx
	mov es, dx
	inc byte [internal_call]

	mov word [.filename], 0		; Terminate string in case user leaves without choosing

	mov ax, .buffer			; Get comma-separated list of filenames
	call os_get_file_list
	
	mov ax, .buffer			; Show those filenames in a list dialog box
	mov bx, .help_msg1
	mov cx, .help_msg2
	call os_list_dialog
	jc .esc_pressed

	dec ax				; Result from os_list_box starts from 1, but
					; for our file list offset we want to start from 0

	mov cx, ax
	mov bx, 0

	mov si, .buffer			; Get our filename from the list
.loop1:
	cmp bx, cx
	je .got_our_filename
	lodsb
	cmp al, ','
	je .comma_found
	jmp .loop1

.comma_found:
	inc bx
	jmp .loop1


.got_our_filename:			; Now copy the filename string
	mov ax, gs
	call os_dump_registers
	cli
	hlt
	cmp word [.output_segment], ax
	je .system_segment

	mov [.output_loc], di
	mov di, CROSSOVER_BUFFER
	mov dx, [.output_segment]
	mov es, dx
.loop2:
	lodsb
	cmp al, ','
	je .finished_copying
	cmp al, 0
	je .finished_copying
	mov [es:di], al
	inc di
	jmp .loop2

.finished_copying:
	mov byte [es:di], 0		; Zero terminate the filename string

	popa

	mov ax, [.output_loc]

	dec byte [internal_call]
	clc
	jmp os_return


.esc_pressed:				; Set carry flag if Escape was pressed
	popa
	dec byte [internal_call]
	stc
	jmp os_return
	
	
.system_segment:
	mov word [.output_loc], .filename
	mov di, .filename
	mov dx, [.output_segment]
	mov es, dx
	
	jmp .loop2


	.buffer		times 1024 db 0

	.help_msg1	db 'Please select a file using the cursor', 0
	.help_msg2	db 'keys from the list below...', 0

	.filename	times 13 db 0
	
	.output_segment	dw 0
	.output_loc	dw 0
	


; ------------------------------------------------------------------
; os_list_dialog -- Show a dialog with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog:
	pusha
	mov dx, gs
	mov ds, dx
	mov es, dx
	
	cmp byte [internal_call], 0
	jne .start_system_list
	
.prepare_list:
	inc byte [internal_call]

	push ax				; Store string list for now

	push cx				; And help strings
	push bx

	call os_hide_cursor


	mov cl, 0			; Count the number of entries in the list
	mov si, ax
.count_loop:
	mov byte al, [fs:si]
	inc si
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	mov bl, [FS:CFG_DLG_OUTER_COLOUR]
	mov dl, 20			; Start X position
	mov dh, 2			; Start Y position
	mov si, 40			; Width
	mov di, 23			; Finish Y position
	call os_draw_block		; Draw option selector window

	mov dl, 21			; Show first line of help text...
	mov dh, 3
	call os_move_cursor

	push fs
	pop ds
	
	pop si				; Get back first string
	call os_print_string

	inc dh				; ...and the second
	call os_move_cursor

	pop si
	call os_print_string

	push gs
	pop ds

	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 25			; Set up starting position for selector
	mov dh, 7

	call os_move_cursor

.more_select:
	pusha
	mov bl, [FS:CFG_DLG_INNER_COLOUR]		; Black on white for option list box
	mov dl, 21
	mov dh, 6
	mov si, 38
	mov di, 22
	call os_draw_block
	popa

.change_select:
	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list
	
.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp ah, 49h
	je .page_up
	cmp ah, 51h
	je .page_down
	cmp ah, 47h
	je .go_top
	cmp ah, 4Fh
	je .go_bottom
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	jmp .more_select		; If not, wait for another key


.go_up:
	cmp dh, 7			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .change_select


.go_down:				; Already at bottom of list?
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .change_select

.page_up:
	cmp dh, 11			; check if we have to scroll
	jle .scroll_up
	
	call .draw_white_bar		; erase current entry

	sub dh, 5			; more cursor up 5 places
	
	jmp .change_select
	
.scroll_up:
	mov cl, 12			; find the number of places to scroll
	sub cl, dh
	
	cmp cl, [.skip_num]		; check if there are enough
	jg .go_top			; if not just jump to the top
	
	sub byte [.skip_num], cl	; if so scroll required amount
	
	call .draw_white_bar
		
	mov dh, 7			; move cursor to top
	jmp .more_select
	
.go_top:
	cmp dh, 7
	je .at_top
	
	mov byte [.skip_num], 0
	
	call .draw_white_bar
	
	mov dh, 7
	jmp .more_select

.at_top:
	cmp byte [.skip_num], 0
	je .another_key
	
	mov byte [.skip_num], 0
	
	jmp .more_select
	
.page_down:
	cmp dh, 16
	jge .scroll_down
	
	mov cl, dh
	sub cl, 6
	add cl, [.skip_num]
	add cl, 5
	cmp cl, [.num_of_entries]
	jg .go_bottom
	
	call .draw_white_bar
		
	add dh, 5
	
	jmp .change_select
	
.scroll_down:
	mov ch, dh			; Find the number of entries to scroll
	sub ch, 15
	
	mov cl, dh			; New entry number (screen row - 2 + previous offscreen items + scroll amount)
	sub cl, 2
	add cl, [.skip_num]
	add cl, ch
	
	cmp cl, [.num_of_entries]	; Would this amount exceed the number of items in the list?
	jg .go_bottom			; If so jump to the last.
	
	call .draw_white_bar
	
	add byte [.skip_num], ch	; Otherwise scroll the list down and set the last item selected
	mov dh, 20
	
	jmp .more_select
	
.go_bottom:
	cmp byte [.num_of_entries], 14
	jle .no_skip
	
	mov cl, [.num_of_entries]
	sub cl, 14
	cmp cl, [.skip_num]
	je .at_bottom
	
.not_at_bottom:
	call .draw_white_bar
	
	mov cl, [.num_of_entries]
	sub cl, 14
	mov [.skip_num], cl
	mov dh, 20
	
	jmp .more_select
	
.at_bottom:
	cmp dh, 20
	jne .not_at_bottom
	
	jmp .another_key

.no_skip:
	cmp dh, 20
	je .another_key
	
	mov dh, [.num_of_entries]
	add dh, 6
	
	jmp .more_select

.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .another_key			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select



.option_selected:
	call os_show_cursor

	sub dh, 7

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	dec byte [internal_call]

	cmp byte [internal_call], 0
	jne .finish_system_list_option
	
	clc				; Clear carry as Esc wasn't pressed
	jmp os_return



.esc_pressed:
	mov ax, 1
	call os_pause
	call os_check_for_key
	call os_check_for_key

	call os_show_cursor
	popa
	dec byte [internal_call]
	
	cmp byte [internal_call], 0
	jne .finish_system_list_esc
	
	stc				; Set carry for Esc
	jmp os_return



.draw_list:
	pusha

	mov dl, 23			; Get into position for option list text
	mov dh, 7
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	mov al, [fs:si]
	inc si
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	mov al, [fs:si]			; Get next character in file name, increment pointer
	inc si

	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 23			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	cmp bx, 14			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, [FS:CFG_DLG_SELECT_COLOUR]
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, [FS:CFG_DLG_INNER_COLOUR]	
	mov al, ' '
	int 10h

	popa
	ret

.start_system_list:
	push fs
	pop word [.fs_tmp]
	
	push gs
	pop fs
	jmp .prepare_list
	
.finish_system_list_esc:
	push word [.fs_tmp]
	pop fs
	stc
	jmp os_return
	
.finish_system_list_option:
	push word [.fs_tmp]
	pop fs
	clc
	jmp os_return
	
	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0
	.fs_tmp			dw 0


; ------------------------------------------------------------------
os_get_text_block:
	; CH = start row, CL = start column, DH = end row, DL = end column, ES:SI = address
	API_START
	
	xchg cx, dx
.read_characters:
	inc dl
	call os_move_cursor
	
	cmp dl, cl
	jg .next_line
	
	mov ah, 08h
	mov bh, 0
	int 10h
	
	mov [es:si], ax
	add si, 2
	
	jmp .read_characters
	
.next_line:
	mov dl, 0
	inc dh
	call os_move_cursor
	
	cmp dh, ch
	jle .read_characters
	
	API_END

; ------------------------------------------------------------------
os_put_text_block:
	; CH = start row, CL = start column, DH = end row, DL = end column, ES:SI = address
	
	API_START
	xchg cx, dx

.write_characters:
	inc dl
	call os_move_cursor
	
	cmp dl, cl
	jg .next_line
	
	mov ax, [es:si]
	add si, 2
	mov bl, ah
	
	mov ah, 09h
	mov bh, 0
	mov cx, 1
	int 10h
	
	jmp .write_characters
	
.next_line:
	mov dl, 0
	inc dh
	call os_move_cursor
	
	cmp dh, ch
	jle .write_characters
	
	API_END
	
; ------------------------------------------------------------------
os_set_text_block:
	; AH = colour, AL = character, CH = start row, CL = start column, DH = end row, DL = end column
	
	API_START
	
	mov bx, 0
	mov bl, dl
	sub bl, cl
	mov [.length], bx
	
	xchg cx, dx
	
	mov [.colour], ah
	mov [.char], al
	
.write_lines:
	inc dh
	call os_move_cursor
	
	cmp dh, ch
	jle .finish
	
	mov ah, 09h
	mov al, [.char]
	mov bh, 0
	mov bl, [.colour]
	mov cx, [.length]
	int 10h

	jmp .write_lines
	
.finish:
	API_END
	
	.length					dw 0
	.char					db 0
	.colour					db 0
