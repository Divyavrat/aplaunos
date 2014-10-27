; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Based on the MikeOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; BASIC CODE INTERPRETER (4.4b3)
; ==================================================================

use16
org 0x6000
; ------------------------------------------------------------------
; Token types

%DEFINE VARIABLE 1
%DEFINE STRING_VAR 2
%DEFINE NUMBER 3
%DEFINE STRING 4
%DEFINE QUOTE 5
%DEFINE CHAR 6
%DEFINE UNKNOWN 7
%DEFINE LABEL 8

%INCLUDE "progapi.inc"
basic_main:
; ------------------------------------------------------------------
; The BASIC interpreter execution starts here -- a parameter string
; is passed in SI and copied into the first string, unless SI = 0

mov word [orig_stack],sp		; Save stack pointer -- we might jump to the
						; error printing code and quit in the middle
						; some nested loops, and we want to preserve
						; the stack
push si
mov di, string_vars			; If so, copy it into $1
call os_string_copy
; call os_print_string
; mov si,progstart_keyword
; call os_print_string

mov	ax,1003h
	xor	bx,bx
	int	10h			; enable background intensity
		
call clear_ram				; Clear variables etc. from previous run
							; of a BASIC program
pop si
cmp si,0
je .getfilename
mov di,token
call os_string_copy
jmp .recieved_file
;jmp .name_ok
.getfilename:
mov si,filename_msg
call os_print_string

mov ax,token
call os_input_string
.recieved_file:
mov si,token

.loop:
lodsb
cmp al,0x20
je .space
cmp al,0
jne .loop
mov si,0
jmp .name_ok
.space:
mov byte [si-1],0
mov di, string_vars			; If so, copy it into $1
call os_string_copy
.name_ok:

mov ax,token
call os_file_exists
jc .notfound
mov cx,[loc]
mov ax,token
call os_load_file
;pop si
mov si,[string_buffer]
jmp .found

.notfound:
;mov si,select_msg
mov si,filename_msg
call os_print_string
mov dx,[loc]
mov ah,0x80
int 0x61
;pop si
; mov di, string_vars			; If so, copy it into $1
; call os_string_copy
.found:
mov ax,token
call os_get_file_size
call os_print_newline
; mov si,progstart_keyword
; call os_print_string
; call os_print_newline
;os_run_basic:
mov ax,[loc]
mov word [load_point], ax		; AX was passed as starting location of code

mov word [prog], ax			; prog = pointer to current execution point in code

	add bx, ax				; We were passed the .BAS byte size in BX
	dec bx
	dec bx
	mov word [prog_end], bx			; Make note of program end point

mainloop:
cmp word [prog],0
je .done_basic

	call get_token				; Get a token from the start of the line

	cmp ax, STRING				; Is the type a string of characters?
	je .keyword				; If so, let's see if it's a keyword to process

	cmp ax, VARIABLE			; If it's a variable at the start of the line,
	je near assign				; this is an assign (eg "X = Y + 5")

	cmp ax, STRING_VAR			; Same for a string variable (eg $1)
	je near assign

	cmp ax, LABEL				; Don't need to do anything here - skip
	je mainloop

	mov si, err_syntax			; Otherwise show an error and quit
	jmp error

.done_basic:
mov word sp, [orig_stack]
mov dl,[temp_color]
	mov byte [ink_colour],dl
	call os_set_color
ret

.keyword:
	mov si, token				; Start trying to match commands
	
	mov di, alert_cmd
	call os_string_compare
	jc near do_alert

	mov di, askfile_cmd
	call os_string_compare
	jc near do_askfile
	
	mov di, blockif_cmd
	call os_string_compare
	jc near do_blockif
	
	mov di, box_cmd
	call os_string_compare
	jc near do_box
	
	mov di, boxfilled_cmd
	call os_string_compare
	jc near do_boxfilled
	
	mov di, break_cmd
	call os_string_compare
	jc near do_break

	mov di, case_cmd
	call os_string_compare
	jc near do_case

	mov di, call_cmd
	call os_string_compare
	jc near do_call

	mov di, circle_cmd
	call os_string_compare
	jc near do_circle
	
	mov di, clock_cmd
	call os_string_compare
	jc near do_clock
	
	mov di, cls_cmd
	call os_string_compare
	jc near do_cls

	mov di, cursor_cmd
	call os_string_compare
	jc near do_cursor

	mov di, curschar_cmd
	call os_string_compare
	jc near do_curschar

	mov di, curscol_cmd
	call os_string_compare
	jc near do_curscol

	mov di, curspos_cmd
	call os_string_compare
	jc near do_curspos
	
	mov di, delete_cmd
	call os_string_compare
	jc near do_delete
	
	mov di, do_cmd
	call os_string_compare
	jc near do_do
	
	mov di, else_cmd
	call os_string_compare
	jc near do_else
	
	mov di, end_cmd
	call os_string_compare
	jc near do_end
	
	mov di, endif_cmd
	call os_string_compare
	jc near do_endif

	mov di, files_cmd
	call os_string_compare
	jc near do_files
	
	mov di, flood_cmd
	call os_string_compare
	jc near do_flood

	mov di, for_cmd
	call os_string_compare
	jc near do_for

	mov di, getkey_cmd
	call os_string_compare
	jc near do_getkey

	mov di, gosub_cmd
	call os_string_compare
	jc near do_gosub

	mov di, goto_cmd
	call os_string_compare
	jc near do_goto
	
	mov di, graphicsmode_cmd
	call os_string_compare
	jc near do_graphicsmode
	
	mov di, hline_cmd
	call os_string_compare
	jc near do_hline

	mov di, if_cmd
	call os_string_compare
	jc near do_if

	mov di, include_cmd
	call os_string_compare
	jc near do_include

	mov di, ink_cmd
	call os_string_compare
	jc near do_ink
	
	mov di, interface_cmd
	call os_string_compare
	jc near do_interface

	mov di, input_cmd
	call os_string_compare
	jc near do_input
	
	mov di, inputbox_cmd
	call os_string_compare
	jc near do_inputbox

	mov di, left_cmd
	call os_string_compare
	jc near do_left
	
	mov di, len_cmd
	call os_string_compare
	jc near do_len
	
	mov di, line_cmd
	call os_string_compare
	jc near do_line

	mov di, listbox_cmd
	call os_string_compare
	jc near do_listbox

	mov di, load_cmd
	call os_string_compare
	jc near do_load
	
	mov di, locatemouse_cmd
	call os_string_compare
	jc near do_locatemouse
	
	mov di, lockmouse_cmd
	call os_string_compare
	jc near do_lockmouse

	mov di, loop_cmd
	call os_string_compare
	jc near do_loop

	mov di, memory_cmd
	call os_string_compare
	jc near do_memory
	
	mov di, mid_cmd
	call os_string_compare
	jc near do_mid
	
	mov di, move_cmd
	call os_string_compare
	jc near do_move
	
	mov di, movemouse_cmd
	call os_string_compare
	jc near do_movemouse

	mov di, next_cmd
	call os_string_compare
	jc near do_next

	mov di, number_cmd
	call os_string_compare
	jc near do_number

	mov di, page_cmd
	call os_string_compare
	jc near do_page

	mov di, pause_cmd
	call os_string_compare
	jc near do_pause

	mov di, peek_cmd
	call os_string_compare
	jc near do_peek

	mov di, peekint_cmd
	call os_string_compare
	jc near do_peekint

	mov di, plot_cmd
	call os_string_compare
	jc near do_plot
	
	mov di, point_cmd
	call os_string_compare
	jc near do_point
	
	mov di, poke_cmd
	call os_string_compare
	jc near do_poke
	
	mov di, pokeint_cmd
	call os_string_compare
	jc near do_pokeint
	
	mov di, polygon_cmd
	call os_string_compare
	jc near do_polygon

	mov di, port_cmd
	call os_string_compare
	jc near do_port

	mov di, print_cmd
	call os_string_compare
	jc near do_print
	
	mov di, question_cmd
	call os_string_compare
	jc near do_question

	mov di, rand_cmd
	call os_string_compare
	jc near do_rand

	mov di, read_cmd
	call os_string_compare
	jc near do_read
	
	mov di, releasemouse_cmd
	call os_string_compare
	jc near do_releasemouse

	mov di, rem_cmd
	call os_string_compare
	jc near do_rem

	mov di, rename_cmd
	call os_string_compare
	jc near do_rename

	mov di, return_cmd
	call os_string_compare
	jc near do_return
	
	mov di, reverse_cmd
	call os_string_compare
	jc near do_reverse
	
	mov di, right_cmd
	call os_string_compare
	jc near do_right

	mov di, save_cmd
	call os_string_compare
	jc near do_save

	mov di, serial_cmd
	call os_string_compare
	jc near do_serial
	
; 	mov di, shift_cmd
; 	call os_string_compare
; 	jc near do_shift

	mov di, size_cmd
	call os_string_compare
	jc near do_size

	mov di, sound_cmd
	call os_string_compare
	jc near do_sound
	
	mov di, split_cmd
	call os_string_compare
	jc near do_split
	
	mov di, string_cmd
	call os_string_compare
	jc near do_string
	
	mov di, textmode_cmd
	call os_string_compare
	jc near do_textmode
	
	mov di, trim_cmd
	call os_string_compare
	jc near do_trim
	
	mov di, usemouse_cmd
	call os_string_compare
	jc near do_usemouse
	
	mov di, vline_cmd
	call os_string_compare
	jc near do_vline

	mov di, waitany_cmd
	call os_string_compare
	jc near do_waitany
	
	mov di, waitkey_cmd
	call os_string_compare
	jc near do_waitkey
	
	mov di, waitmouse_cmd
	call os_string_compare
	jc near do_waitmouse

	mov si, err_cmd_unknown			; Command not found?
	jmp error


; ------------------------------------------------------------------
; CLEAR RAM

clear_ram:
pusha
	mov al, 0

	mov di, variables
	mov cx, 52
	rep stosb

	mov di, for_variables
	mov cx, 52
	rep stosb

	mov di, for_code_points
	mov cx, 52
	rep stosb
	
	mov di, do_loop_store
	mov cx, 10
	rep stosb

	mov byte [gosub_depth], 0
	mov byte [loop_in], 0

	mov di, gosub_points
	mov cx, 20
	rep stosb

	mov di, string_vars
	mov cx, 1024
	rep stosb

	mov ah,0x02
	int 0x64
	mov [temp_color],dl
	mov byte [ink_colour], 7		; White ink
	call os_set_color
popa
	ret


; ------------------------------------------------------------------
; ASSIGNMENT

assign:
	cmp ax, VARIABLE			; Are we starting with a number var?
	je .do_num_var_link

	mov di, string_vars			; Otherwise it's a string var
	mov ax, 128
	mul bx					; (BX = string number, passed back from get_token)
	add di, ax

	push di

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token				; See if second is quote
	cmp ax, QUOTE
	je .second_is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars			; Otherwise it's a string var
	mov ax, 128
	mul bx					; (BX = string number, passed back from get_token)
	add si, ax

	pop di
	call os_string_copy

	jmp .string_check_for_more

.do_num_var_link:
jmp .do_num_var

.second_is_quote:
	mov si, token
	pop di
	call os_string_copy



.string_check_for_more:
	push di
	mov word ax, [prog]			; Save code location in case there's no delimiter
	mov word [.tmp_loc], ax

	call get_token				; Any more to deal with in this assignment?
	mov byte al, [token]
	cmp al, '+'
	je .string_theres_more

	mov word ax, [.tmp_loc]			; Not a delimiter, so step back before the token
	mov word [prog], ax			; that we just grabbed

	pop di
	jmp mainloop				; And go back to the code interpreter!


.string_theres_more:
	call get_token
	cmp ax, STRING_VAR
	je .another_string_var
	cmp ax, QUOTE
	je .another_quote
	cmp ax, VARIABLE
	je .add_number_var
	jmp .error


.another_string_var:
	pop di

	mov si, string_vars
	mov ax, 128
	mul bx					; (BX = string number, passed back from get_token)
	add si, ax

	mov ax, di
	mov cx, di
	mov bx, si
	call os_string_join

	jmp .string_check_for_more



.another_quote:
	pop di

	mov ax, di
	mov cx, di
	mov bx, token
	call os_string_join

	jmp .string_check_for_more


.add_number_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	call os_int_to_string

	mov bx, ax
	pop di
	mov ax, di
	mov cx, di
	call os_string_join

	jmp .string_check_for_more
	



.do_num_var:
	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	mov byte al, [token]
	cmp al, '='
	jne near .error

	call get_token
	cmp ax, NUMBER
	je .second_is_num

	cmp ax, VARIABLE
	je .second_is_variable

	cmp ax, STRING
	je near .second_is_string

	cmp ax, UNKNOWN
	jne near .error

	mov byte al, [token]			; Address of string var?
	cmp al, '&'
	jne near .error

	call get_token				; Let's see if there's a string var
	cmp ax, STRING_VAR
	jne near .error

	mov di, string_vars
	mov ax, 128
	mul bx
	add di, ax

	mov bx, di

	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.second_is_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_num:
	mov si, token
	call os_string_to_int

	mov bx, ax				; Number to insert in variable table

	mov ax, 0
	mov byte al, [.tmp]

	call set_var


	; The assignment could be simply "X = 5" etc. Or it could be
	; "X = Y + 5" -- ie more complicated. So here we check to see if
	; there's a delimiter...

.check_for_more:
	mov word ax, [prog]			; Save code location in case there's no delimiter
	mov word [.tmp_loc], ax

	call get_token				; Any more to deal with in this assignment?
	mov byte al, [token]
	cmp al, '+'
	je .theres_more
	cmp al, '-'
	je .theres_more
	cmp al, '*'
	je .theres_more
	cmp al, '/'
	je .theres_more
	cmp al, '%'
	je .theres_more

	mov word ax, [.tmp_loc]			; Not a delimiter, so step back before the token
	mov word [prog], ax			; that we just grabbed

	jmp mainloop				; And go back to the code interpreter!


.theres_more:
	mov byte [.delim], al

	call get_token
	cmp ax, VARIABLE
	je .handle_variable

	mov si, token
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var				; This also points SI at right place in variable table

	cmp byte [.delim], '+'
	jne .not_plus

	add ax, bx
	jmp .finish

.not_plus:
	cmp byte [.delim], '-'
	jne .not_minus

	sub ax, bx
	jmp .finish

.not_minus:
	cmp byte [.delim], '*'
	jne .not_times

	mul bx
	jmp .finish

.not_times:
	cmp byte [.delim], '/'
	jne .not_divide

	mov dx, 0
	;xor dx,dx
	div bx
	jmp .finish

.not_divide:
	mov dx, 0
	div bx
	mov ax, dx				; Get remainder

.finish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.handle_variable:
	mov ax, 0
	mov byte al, [token]

	call get_var

	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp]

	call get_var

	cmp byte [.delim], '+'
	jne .vnot_plus

	add ax, bx
	jmp .vfinish

.vnot_plus:
	cmp byte [.delim], '-'
	jne .vnot_minus

	sub ax, bx
	jmp .vfinish

.vnot_minus:
	cmp byte [.delim], '*'
	jne .vnot_times

	mul bx
	jmp .vfinish

.vnot_times:
	cmp byte [.delim], '/'
	jne .vnot_divide

	mov dx, 0
	div bx
	jmp .finish

.vnot_divide:
	mov dx, 0
	div bx
	mov ax, dx				; Get remainder

.vfinish:
	mov bx, ax
	mov byte al, [.tmp]
	call set_var

	jmp .check_for_more


.second_is_string:				; These are "X = word" functions
	mov di, token
	
	mov si, freemem_keyword
	call os_string_compare
	je .is_freemem
	
	mov si, ink_keyword
	call os_string_compare
	je .is_ink
	
	mov si, leftclick_keyword
	call os_string_compare
	je .is_leftclick
	
	mov si, middleclick_keyword
	call os_string_compare
	je .is_middleclick
	
	mov si, progstart_keyword
	call os_string_compare
	je .is_progstart

	mov si, ramstart_keyword
	call os_string_compare
	je .is_ramstart
	
	mov si, rightclick_keyword
	call os_string_compare
	je .is_rightclick

	mov si, timer_keyword
	call os_string_compare
	je .is_timer
	
	mov si, variables_keyword
	call os_string_compare
	je .is_variables
	
	mov si, version_keyword
	call os_string_compare
	je .is_version

	jmp .error

.is_freemem:
	mov ax, 0
	mov byte al, [.tmp]
	
	call os_memory_free
	call set_var
	
	jmp mainloop
	
.is_ink:
	mov ax, 0
	mov byte al, [.tmp]
	
	mov bx, 0
	mov byte bl, [ink_colour]
	call set_var
	
	jmp mainloop
	
	
.is_leftclick:
	mov ax, 0
	mov al, [.tmp]
	
	call os_mouse_leftclick
	jc .left_down
	
	mov bx, 0
	call set_var
	
	jmp mainloop

.left_down:
	mov bx, 1
	call set_var
	
	jmp mainloop
	
	
.is_middleclick:
	mov ax, 0
	mov al, [.tmp]
	
	call os_mouse_middleclick
	jc .middle_down
	
	mov bx, 0
	call set_var
	
	jmp mainloop
	
.middle_down:
	mov bx, 1
	call set_var
	
	jmp mainloop

.is_progstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [load_point]
	call set_var

	jmp mainloop



.is_ramstart:
	mov ax, 0
	mov byte al, [.tmp]

	mov word bx, [prog_end]
	inc bx
	inc bx
	inc bx
	call set_var

	jmp mainloop
	
	
.is_rightclick:
	mov ax, 0
	mov al, [.tmp]
	
	call os_mouse_rightclick
	jc .right_down
	
	mov bx, 0
	call set_var
	
	jmp mainloop
	
.right_down:
	mov bx, 1
	call set_var
	
	jmp mainloop


.is_timer:
	mov ah, 0
	int 1Ah
	mov bx, dx

	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.is_variables:
	mov bx, vars_loc
	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop


.is_version:
	call os_get_api_version
	
	mov bh, 0
	mov bl, al
	mov al, [.tmp]
	call set_var
	
	jmp mainloop 


.error:
	mov si, err_syntax
	jmp error


	.tmp		db 0
	.tmp_loc	dw 0
	.delim		db 0


; ==================================================================
; SPECIFIC COMMAND CODE STARTS HERE

; ------------------------------------------------------------------
; ALERT

do_alert:
	mov bh, [work_page]			; Store the cursor position
	mov ah, 03h
	int 10h

	call get_token

	cmp ax, QUOTE
	je .is_quote
	
	cmp ax, STRING_VAR
	je .is_string

	mov si, err_syntax
	jmp error

.is_string:
	mov si, string_vars
	mov ax, 128
	mul bx
	add ax, si
	jmp .display_message
	
.is_quote:
	mov ax, token				; First string for alert box
	
.display_message:
	mov bx, 0				; Others are blank
	mov cx, 0
	mov dx, 0				; One-choice box
	call os_dialog_box
	
	mov bh, [work_page]			; Move the cursor back
	mov ah, 02h
	int 10h
	
	jmp mainloop


;-------------------------------------------------------------------
; ASKFILE

do_askfile:
	mov bh, [work_page]			; Store the cursor position
	mov ah, 03h
	int 10h
	
	call get_token
	
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars			; Get the string location
	mov ax, 128
	mul bx
	add ax, si
	mov word [.tmp], ax
	
	call os_file_selector			; Present the selector
	
	mov word di, [.tmp]			; Copy the string
	mov si, ax
	call os_string_copy

	mov bh, [work_page]			; Move the cursor back
	mov ah, 02h
	int 10h
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error

.data:
	.tmp					dw 0




; ------------------------------------------------------------------
; BLOCKIF

do_blockif:
	call check_token
	
	cmp ax, VARIABLE
	je .check_variable
	
	cmp ax, STRING_VAR
	je .check_string
	
	jmp .error
	
	
.check_variable:
	mov di, .first_variable
	mov cx, 1
	call autofetch_variables
	
	call get_token
	mov dl, [token]
	
	mov di, .second_variable
	mov cx, 1
	call autofetch_variables
	
	mov ax, [.first_variable]
	mov bx, [.second_variable]
	
	cmp dl, '>'
	je .greater
	
	cmp dl, '<'
	je .lesser
	
	cmp dl, '='
	je .equal
	
	cmp dl, '!'
	je .not_equal
	
	jmp .error
	
	.error:
	mov si, err_syntax
	jmp error
	
.check_string:
	call get_string_pointer
	jc .error
	mov [.first_variable], si

	call get_token
	mov dl, [token]
	
	call get_string_pointer
	mov di, si
	mov si, [.first_variable]
		
	cmp dl, '='
	je .str_equal
	
	cmp dl, '!'
	je .str_not_equal
	
	jmp .error
	
.greater:
	cmp ax, bx
	jg .true
	
	jmp .false
	
.lesser:
	cmp ax, bx
	jl .true
	
	jmp .false
	
.equal:
	cmp ax, bx
	je .true
	
	jmp .false
	
.not_equal:
	cmp ax, bx
	jne .true
	
	jmp .false
	
.str_equal:
	call os_string_compare
	jc .true
	
	jmp .false
	
.str_not_equal:
	call os_string_compare
	jc .true
	
	jmp .false
	
.true:
	mov ax, [prog]
	mov [.tmp], ax
	
	call get_token
	mov si, [token]
	mov di, and_keyword
	call os_string_compare
	jc do_blockif
	
	mov ax, [.tmp]
	mov [prog], ax
	jmp mainloop
	
.false:
	mov si, [prog]
	mov [.tmp], si

	mov cx, [prog_end]
	sub cx, si
	inc cx
	
.new_line:
	mov si, [.tmp]
	mov di, string_buffer
	dec cx
	
	cmp cx, 0
	je .no_endif
	
.get_line:
	lodsb
	cmp al, 10
	je .line_finished
	stosb
	
	loop .get_line
	
	jmp .no_endif
	
.line_finished:
	mov [.tmp], si
	
	mov al, 0
	stosb
	
	mov ax, string_buffer
	call os_string_chomp
	
	mov si, string_buffer
	call os_string_parse
	
	call os_string_uppercase
	
	mov di, blockif_cmd
	call os_string_compare
	jc .sub_block
	
	mov di, endif_cmd
	call os_string_compare
	jnc .new_line
	
	cmp byte [.block_in], 0
	jne .inside_sub
	
	mov ax, [.tmp]
	mov [prog], ax
	
	jmp mainloop
	
.sub_block:
	inc byte [.block_in]
	jmp .new_line
	
.inside_sub:
	dec byte [.block_in]
	jmp .new_line
	
.no_endif:
	mov si, err_no_endif
	jmp error
	


.first_variable					dw 0
.sign						dw 0
.second_variable				dw 0
.tmp						dw 0
.block_in					db 0

; ------------------------------------------------------------------
; BOX

do_box:	
	mov di, .x_start				; fetch 5 variables
	mov cx, 5
	call autofetch_variables
	
	cmp byte [graphicsmode], 0
	je .text_mode

	mov cx, [.x_start]
	mov dx, [.y_start]
	mov si, cx					; create second set of coordinents from width and height
	add si, [.width]
	mov di, dx
	add di, [.height]
	mov bl, [.colour]
	clc						; draw an unfilled rectangle
	call os_draw_rectangle
	
	jmp mainloop
	
.text_mode:
	mov bl, [.colour]
	mov ch, [.y_start]
	mov cl, [.x_start]
	mov dh, [.height]
	add dh, ch
	dec dh
	mov dl, [.width]
	add dl, cl
	dec dl
	call os_draw_border
	
	jmp mainloop

	
	.x_start					dw 0
	.y_start					dw 0
	.width						dw 0
	.height						dw 0
	.colour						dw 0
	

; ------------------------------------------------------------------
; BOXFILLED

do_boxfilled:
	mov di, .x_start
	mov cx, 5
	call autofetch_variables

	cmp byte [graphicsmode], 0
	je .textmode
		
	mov cx, [.x_start]
	mov dx, [.y_start]
	mov si, cx
	add si, [.width]
	mov di, dx
	add di, [.height]
	mov bl, [.colour]
	stc
	call os_draw_rectangle
	
	jmp mainloop
	
.textmode:
	mov bl, [.colour]
	shl bl, 4
	mov dl, [.x_start]
	mov dh, [.y_start]
	mov si, [.width]
	mov di, [.y_start]
	add di, [.height]
	call os_draw_block
	
	jmp mainloop
	
	.x_start					dw 0
	.y_start					dw 0
	.width						dw 0
	.height						dw 0
	.colour						dw 0
	
	
; ------------------------------------------------------------------
; BREAK

do_break:
	mov si, err_break
	jmp error


; ------------------------------------------------------------------
; CALL

do_call:
	call get_token
	cmp ax, NUMBER
	je .is_number

	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .execute_call

.is_number:
	mov si, token
	call os_string_to_int

.execute_call:
	mov bx, 0
	mov cx, 0
	mov dx, 0
	mov di, 0
	mov si, 0

	call ax

	jmp mainloop


; ------------------------------------------------------------------
; CASE

do_case:
	call get_token
	cmp ax, STRING
	jne .error
	
	mov si, token

	mov di, upper_keyword
	call os_string_compare
	jc .uppercase
	
	mov di, lower_keyword
	call os_string_compare
	jc .lowercase
	
	jmp .error
	
.uppercase:
	call get_token
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars
	mov ax, 128
	mul bx
	add ax, si
	
	call os_string_uppercase
	
	jmp mainloop
	
.lowercase:
	call get_token
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars
	mov ax, 128
	mul bx
	add ax, si
	
	call os_string_lowercase
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; CIRCLE

do_circle:
	cmp byte [graphicsmode], 1
	jne .error
	
	mov di, .x
	mov cx, 4
	call autofetch_variables
	
	mov al, [.colour]
	mov bx, [.radius]
	mov cx, [.x]
	mov dx, [.y]
	call os_draw_circle
	
	jmp mainloop
	
.error:
	mov si, err_graphics
	jmp error

.x							dw 0
.y							dw 0
.radius							dw 0
.colour							dw 0
	
	
; ------------------------------------------------------------------
; CLOCK

do_clock:
	call get_string_pointer
	jc .error
	
	mov di, si
	call os_get_time_string
	mov si, bx
	call os_string_copy
	
	call get_string_pointer
	jc .error
	
	mov di, si
	call os_get_date_string
	mov si, bx
	call os_string_copy

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error
	
	
; ------------------------------------------------------------------
; CLS

do_cls:
	cmp byte [graphicsmode], 1				; if in graphics mode, do a graphical clear
	je .graphics_clear
	
	mov ah, 5
	mov byte al, [work_page]
	int 10

	call os_clear_screen

	mov ah, 5
	mov byte al, [disp_page]
	int 10

	jmp mainloop

.graphics_clear:
	mov bl, 0						; make all pixels black
	call os_clear_graphics
	
	jmp mainloop

; ------------------------------------------------------------------
; CURSOR

do_cursor:
	call get_token

	mov si, token
	mov di, .on_str
	call os_string_compare
	jc .turn_on

	mov si, token
	mov di, .off_str
	call os_string_compare
	jc .turn_off

	mov si, err_syntax
	jmp error

.turn_on:
	call os_show_cursor
	jmp mainloop

.turn_off:
	call os_hide_cursor
	jmp mainloop


	.on_str db "ON", 0
	.off_str db "OFF", 0


; ------------------------------------------------------------------
; CURSCHAR

do_curschar:
	call get_token

	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax				; Store variable we're going to use

	mov ah, 08h
	mov bx, 0
	mov byte bh, [work_page]
	int 10h				; Get char at current cursor location

	mov bx, 0			; We only want the lower byte (the char, not attribute)
	mov bl, al

	pop ax				; Get the variable back

	call set_var			; And store the value

	jmp mainloop


; ------------------------------------------------------------------
; CURSCOL

do_curscol:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ah, 0
	mov byte al, [token]
	push ax

	mov ah, 8
	mov bx, 0
	mov byte bh, [work_page]
	int 10h
	mov bh, 0
	mov bl, ah			; Get colour for higher byte; ignore lower byte (char)

	pop ax
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; CURSPOS

do_curspos:
	mov byte bh, [work_page]
	mov ah, 3
	int 10h

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov ah, 0			; Get the column in the first variable
	mov byte al, [token]
	mov bx, 0
	mov bl, dl
	call set_var

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov ah, 0			; Get the row to the second
	mov byte al, [token]
	mov bx, 0
	mov bl, dh
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; DELETE

do_delete:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_filename

.is_quote:
	mov si, token

.get_filename:
	mov ax, si
	call os_file_exists
	jc .no_file

	call os_remove_file
	jc .del_fail

	jmp .returngood

.no_file:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 2
	call set_var
	jmp mainloop

.returngood:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var
	jmp mainloop

.del_fail:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error
	

; ------------------------------------------------------------------
; DO

do_do:
	cmp byte [loop_in], 20
	je .loop_max
	mov word di, do_loop_store
	mov byte al, [loop_in]
	mov ah, 0
	add di, ax
	mov word ax, [prog]
	sub ax, 3
	stosw
	inc byte [loop_in]
	inc byte [loop_in]
	jmp mainloop

.loop_max:
	mov si, err_doloop_maximum
	jmp error

	
;-------------------------------------------------------------------
; ELSE

do_else:
	cmp byte [last_if_true], 1
	je .last_true
	
	inc word [prog]
	jmp mainloop
	
.last_true:
	mov word si, [prog]
	
.next_line:
	lodsb
	cmp al, 10
	jne .next_line
	
	dec si
	mov word [prog], si
	
	jmp mainloop

	
	textmode_finish_link:
jmp textmode_finish

; ------------------------------------------------------------------
; END

do_end:
	mov ah, 5				; Restore active page
	mov al, 0
	int 10h

	mov byte [work_page], 0
	mov byte [disp_page], 0

	mov dl,[temp_color]
	mov byte [ink_colour],dl
	call os_set_color
	
	mov word sp, [orig_stack]
	
	cmp byte [graphicsmode], 1
	je textmode_finish_link
	
	ret

; ------------------------------------------------------------------
; ENDIF
	
do_endif:
	jmp mainloop				; no action - just something for BLOCKIF to search for

; ------------------------------------------------------------------
; FILES

do_files:
	mov ax, .filelist			; get a copy of the filelist
	call os_get_file_list
	
	mov si, ax

	call os_get_cursor_pos			; move cursor to start of line
	mov dl, 0
	call os_move_cursor
	
	mov ah, 9				; print character function
	mov bh, [work_page]			; define parameters (page, colour, times)
	mov bl, [ink_colour]
	mov cx, 1
.file_list_loop:
	lodsb					; get a byte from the list
	cmp al, ','				; a comma means the next file, so create a new line for it
	je .nextfile
	
	cmp al, 0				; the list is null terminated
	je .end_of_list
	
	int 10h					; okay, it's not a comma or a null so print it

	call os_get_cursor_pos			; find the location of the cursor
	inc dl					; move the cursor forward
	call os_move_cursor

	jmp .file_list_loop			; keep going until the list is finished
	
.nextfile:
	call os_get_cursor_pos			; if the column is over 60 we need a new line
	cmp dl, 60
	jge .newline

.next_column:					; print spaces until the next column
	mov al, ' '
	int 10h
	
	inc dl
	call os_move_cursor
	
	cmp dl, 15
	je .file_list_loop
	
	cmp dl, 30
	je .file_list_loop
	
	cmp dl, 45
	je .file_list_loop
	
	cmp dl, 60
	je .file_list_loop
	
	jmp .next_column
	
.newline:
	call os_print_newline			; create a new line
	jmp .file_list_loop
	
.end_of_list:
	call os_print_newline
	jmp mainloop				; preform next command
	
.data:
	.filelist		times 256	db 0
	


; ------------------------------------------------------------------
; FLOOD

do_flood:
	cmp byte [graphicsmode], 0
	je .no_graphics

	mov di, .colour
	mov cx, 1
	call autofetch_variables
	
	mov bl, [.colour]
	call os_clear_graphics
	
	jmp mainloop

.no_graphics:
	mov si, err_graphics
	jmp error
	
	.colour						dw 0

	
	
; ------------------------------------------------------------------
; FOR

do_for:
	call get_token				; Get the variable we're using in this loop

	cmp ax, VARIABLE
	jne near .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al			; Store it in a temporary location for now

	call get_token

	mov ax, 0				; Check it's followed up with '='
	mov byte al, [token]
	cmp al, '='
	jne .error

	call get_token				; Next we want a number

	cmp ax, VARIABLE
	je .first_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token				; Convert it
	call os_string_to_int
	jmp .continue

	.error:
	mov si, err_syntax
	jmp error
	
.first_is_var:
	mov ax, 0				; It's a variable, so get it's value
	mov al, [token]
	call get_var
	
	; At this stage, we've read something like "FOR X = 1"
	; so let's store that 1 in the variable table

.continue:
	mov bx, ax
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var


	call get_token				; Next we're looking for "TO"

	cmp ax, STRING
	jne .error

	mov ax, token
	call os_string_uppercase

	mov si, token
	mov di, .to_string
	call os_string_compare
	jnc .error


	; So now we're at "FOR X = 1 TO"

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

.second_is_number:
	mov si, token					; Get target number
	call os_string_to_int
	jmp .continue2

.second_is_var:
	mov ax, 0				; It's a variable, so get it's value
	mov al, [token]
	call get_var

.continue2:
	mov bx, ax

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					; Store target number in table
	mov di, for_variables
	add di, ax
	add di, ax
	mov ax, bx
	stosw


	; So we've got the variable, assigned it the starting number, and put into
	; our table the limit it should reach. But we also need to store the point in
	; code after the FOR line we should return to if NEXT X doesn't complete the loop...

	mov ax, 0
	mov byte al, [.tmp_var]

	sub al, 65					; Store code position to return to in table
	mov di, for_code_points
	add di, ax
	add di, ax
	mov word ax, [prog]
	stosw

	jmp mainloop


	.tmp_var	db 0
	.to_string	db 'TO', 0

; ------------------------------------------------------------------
; GETKEY

do_getkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_check_for_extkey

	cmp ax, 48E0h
	je .up_pressed

	cmp ax, 50E0h
	je .down_pressed

	cmp ax, 4BE0h
	je .left_pressed

	cmp ax, 4DE0h
	je .right_pressed

.store:	
	mov bx, 0
	mov bl, al
	
	pop ax

	call set_var

	jmp mainloop

.up_pressed:
	mov ax, 1
	jmp .store

.down_pressed:
	mov ax, 2
	jmp .store

.left_pressed:
	mov ax, 3
	jmp .store

.right_pressed:
	mov ax, 4
	jmp .store

; ------------------------------------------------------------------
; GOSUB

do_gosub:
	call get_token				; Get the number (label)

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Back up this label
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Add ':' char to end for searching
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	


	inc byte [gosub_depth]

	mov ax, 0
	mov byte al, [gosub_depth]		; Get current GOSUB nest level

	cmp al, 9
	jle .within_limit

	mov si, err_nest_limit
	jmp error


.within_limit:
	mov di, gosub_points			; Move into our table of pointers
	add di, ax				; Table is words (not bytes)
	add di, ax
	mov word ax, [prog]
	stosw					; Store current location before jump


	mov word ax, [load_point]
	mov word [prog], ax			; Return to start of program to find label

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop


.line_loop:					; Go to end of line
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	;cmp al, 13
	;je .done_13
	cmp al, 10
	jne .line_loop
	;jmp .done
	;.done_13:
;inc word [prog]
;.done:
	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop


.past_end:
	mov si, err_label_notfound
	jmp error


	.tmp_token	times 30 db 0

; ------------------------------------------------------------------
; GOTO

do_goto:
	call get_token				; Get the next token

	cmp ax, STRING
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Back up this label
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Add ':' char to end for searching
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb	

	mov word ax, [load_point]
	mov word [prog], ax			; Return to start of program to find label

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc mainloop

.line_loop:					; Go to end of line
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	
	cmp al, 13
	je .done_13
	cmp al, 10
	jne .line_loop
	jmp .done
	.done_13:
inc word [prog]
.done:

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error


	.tmp_token 	times 30 db 0


;------------------------------------------------------------------
; GRAPHICSMODE

do_graphicsmode:
	call os_graphics_mode
	
	mov byte [graphicsmode], 1
	
	mov ax, 0
	mov bx, 0
	mov cx, 319
	mov dx, 239
	call os_mouse_range
	
	mov dl, 1
	mov dh, 1
	call os_mouse_scale
	
	jmp mainloop


;------------------------------------------------------------------
; HLINE

do_hline:
	mov di, .start_x
	mov cx, 4
	call autofetch_variables
	
	cmp byte [graphicsmode], 1
	jne .textmode
	
	mov cx, [.start_x]
	mov dx, [.start_y]
	mov si, cx
	add si, [.width]
	mov di, [.start_y]
	mov bh, [.colour]
	call os_draw_line
	
	jmp mainloop
	
.textmode:
	mov bh, [.width]
	mov bl, [.colour]
	mov dh, [.start_x]
	mov dl, [.start_y]
	call os_draw_horizontal_line
	
	jmp mainloop

.start_x					dw 0
.start_y					dw 0
.width						dw 0
.colour						dw 0

;------------------------------------------------------------------
; IF

do_if:
	; Test if we need to do a variable or a string comparison
	call check_token
	
	cmp ax, VARIABLE
	je .variable_comparison
	
	cmp ax, STRING_VAR
	je .string_comparison
	
	jmp .error
	
.variable_comparison:
	mov cx, 1
	mov di, .var1
	call autofetch_variables
	
	call get_token
	mov dl, [token]
	
	mov cx, 1
	mov di, .var2
	call autofetch_variables
	
	mov ax, [.var1]
	mov bx, [.var2]
	
	cmp dl, '='
	je .equal
	
	cmp dl, '>'
	je .greater
	
	cmp dl, '<'
	je .lesser
	
	cmp dl, '!'
	je .not_equal
	
	jmp .error
	
.equal:
	cmp ax, bx
	je .true
	
	jmp .false
	
.greater:
	cmp ax, bx
	jg .true
	
	jmp .false
	
.lesser:
	cmp ax, bx
	jl .true
	
	jmp .false
	
.not_equal:
	cmp ax, bx
	jne .true
	
	jmp .false
	
.string_comparison:
	call get_string_pointer
	jc .error
	mov di, si
	
	push di
	call get_token
	mov dl, [token]
	pop di
	
	call get_string_pointer

	cmp dl, '='
	je .str_equal
	
	cmp dl, '!'
	je .str_not_equal
	
	jmp .error
	
.str_equal:
	call os_string_compare
	jc .true
	
	jmp .false
	
.str_not_equal:
	call os_string_compare
	jnc .true
	
	jmp .false
	
.true:
	call get_token

	mov si, token			; Look for AND for more comparison
	mov di, and_keyword
	call os_string_compare
	jc do_if

	mov si, token			; Look for THEN to perform more operations
	mov di, then_keyword
	call os_string_compare
	jc .then_present

	mov si, err_syntax
	jmp error

.then_present:				; Continue rest of line like any other command!
	mov byte [last_if_true], 1
	jmp mainloop


.false:					; IF wasn't fulfilled, so skip rest of line
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	
	cmp al, 13
	je .done_13
	cmp al, 10
	jne .false
	jmp .done
	.done_13:
inc word [prog]
.done:

	mov byte [last_if_true], 0
	jmp mainloop


.error:
	mov si, err_syntax
	jmp error
	
.var1						dw 0
.sign						dw 0
.var2						dw 0




; ------------------------------------------------------------------
; INCLUDE

do_include:
	call get_token
	cmp ax, QUOTE
	je .is_ok

	mov si, err_syntax
	jmp error

.is_ok:
	mov ax, token
	mov word cx, [prog_end]
	inc cx				; Add a bit of space after original code
	inc cx
	inc cx
	; pusha
; mov dx,cx
; mov ah,0x24
; int 0x61
; call os_wait_for_key
; popa
	; .check_size:
	; cmp cx,0xB000
	; jge .size_ok
	; add cx,0x0200
	; jmp .check_size
	; .size_ok:
	push cx
	call os_file_exists
	pop cx
	push cx
	jc .load_fail
	mov ax,token
	call os_load_file
	jc .load_fail
	mov ax,token
	call os_get_file_size
	pop cx
	add cx, bx
	mov word [prog_end], cx
	jmp mainloop

.load_fail:
	pop cx
	mov si, err_file_notfound
	jmp error


; ------------------------------------------------------------------
; INK

do_ink:
	call get_token				; Get column

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	mov byte [ink_colour], al
	call os_set_color
	jmp mainloop

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov byte [ink_colour], al
	call os_set_color
	jmp mainloop

	
; ------------------------------------------------------------------
; INTERFACE

do_interface:
	call get_string_pointer
	mov di, string_buffer
	call os_string_copy
	mov dx, di
	
	call get_string_pointer
	mov di, alt_string_buffer
	call os_string_copy
	mov bx, di
	
	mov di, .colour
	mov cx, 1
	call autofetch_variables
	mov cx, [.colour]
	shl cx, 4
	
	mov ax, dx
	call os_draw_background
	
	jmp mainloop
	
	.colour					dw 0
	

; ------------------------------------------------------------------
; INPUT

do_input:
	mov al, 0				; Clear string from previous usage
	mov di, string_buffer
	mov cx, 128
	rep stosb

	call get_token

	cmp ax, VARIABLE			; We can only INPUT to variables!
	je .number_var

	cmp ax, STRING_VAR
	je .string_var

	mov si, err_syntax
	jmp error

.number_var:
	mov ax, string_buffer			; Get input from the user
	call os_input_string

	mov ax, string_buffer
	call os_string_length
	cmp ax, 0
	jne .char_entered

	mov byte [string_buffer], '0'		; If enter hit, fill variable with zero
	mov byte [string_buffer + 1], 0

.char_entered:
	mov si, string_buffer			; Convert to integer format
	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [token]			; Get the variable where we're storing it...
	call set_var				; ...and store it!

	call os_print_newline

	jmp mainloop


.string_var:
	push bx

	mov ax, string_buffer
	call os_input_string

	mov si, string_buffer
	mov di, string_vars

	pop bx

	mov ax, 128
	mul bx

	add di, ax
	call os_string_copy

	call os_print_newline

	jmp mainloop
	

; -----------------------------------------------------------
; INPUTBOX

do_inputbox:
	call get_string_pointer
	mov di, string_buffer
	call os_string_copy
	
	call get_string_pointer
	jc .error
	
	mov ax, si
	mov bx, di
	call os_input_dialog
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error
	call get_string_pointer
	mov di, string_buffer
	call os_string_copy
	
	call get_string_pointer
	jc .error
	
	mov ax, si
	mov bx, di
	call os_input_dialog
	
	jmp mainloop

	.tmpstring	times 128 db 0

; -----------------------------------------------------------
; LEFT

do_left:
	call get_string_pointer
	mov di, string_buffer
	call os_string_copy
	
	mov di, .length
	mov cx, 1
	call autofetch_variables
	
	call get_string_pointer
	jc .error
	mov di, si
	
	mov si, string_buffer
	mov cx, [.length]
	rep movsb
	mov al, 0
 	stosb
 	
 	jmp mainloop
 	
 .error:
	mov si, err_syntax
	jmp error

.length					dw 0	

; -----------------------------------------------------------
; LEN

do_len:
	call get_token
	cmp ax, STRING_VAR
	jne .error
 
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov ax, si
	call os_string_length
	mov word [.num1], ax

	call get_token
	cmp ax, VARIABLE
	je .is_ok
	
	mov si, err_syntax
	jmp error

.is_ok:
	mov ax, 0
	mov byte al, [token]
	mov bl, al
	jmp .finish

.finish:	
	mov bx, [.num1]
	mov byte al, [token]
	call set_var
	mov ax, 0
	jmp mainloop
 
.error:
	mov si, err_syntax
	jmp error


	.num1 dw 0

	
; ------------------------------------------------------------------
; LINE

do_line:
	cmp byte [graphicsmode], 0			; make sure graphics mode is active
	je .no_graphics
	
	mov di, .x_start				; fetch 5 variables
	mov cx, 5
	call autofetch_variables
	
	mov cx, [.x_start]				; draw the line
	mov dx, [.y_start]
	mov si, [.x_finish]
	mov di, [.y_finish]
	mov bl, [.colour]
	call os_draw_line
	
	jmp mainloop
	
.no_graphics:
	mov si, err_graphics
	jmp error
	
.x_start			dw 0
.y_start			dw 0
.x_finish			dw 0
.y_finish			dw 0
.colour				dw 0
	

; ------------------------------------------------------------------
; LISTBOX

do_listbox:
	mov bh, [work_page]			; Store the cursor position
	mov ah, 03h
	int 10h
	
	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s1], si

	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s2], si

	call get_token
	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov word [.s3], si


	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.var], al

	mov word ax, [.s1]
	mov word bx, [.s2]
	mov word cx, [.s3]

	call os_list_dialog
	jc .esc_pressed

	pusha
	mov bh, [work_page]			; Move the cursor back
	mov ah, 02h
	int 10h
	popa

	mov bx, ax
	mov ax, 0
	mov byte al, [.var]
	call set_var

	jmp mainloop


.esc_pressed:
	mov ax, 0
	mov byte al, [.var]
	mov bx, 0
	call set_var
	jmp mainloop


.error:
	mov si, err_syntax
	jmp error

	.s1 dw 0
	.s2 dw 0
	.s3 dw 0
	.var db 0


; ------------------------------------------------------------------
; LOAD

do_load:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov ax, si
	call os_file_exists
	jc .file_not_exists

	mov dx, ax			; Store for now

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.load_part:
	mov cx, ax

	mov ax, dx

	call os_load_file

	mov ax, 0
	mov byte al, 'S'
	call set_var

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop


.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .load_part


.file_not_exists:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	call get_token				; Skip past the loading point -- unnecessary now

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; LOCATEMOUSE

do_locatemouse:
	call os_mouse_locate
	
	mov [.mouse_x], cx
	mov [.mouse_y], dx
	
	mov si, .mouse_x
	mov cx, 2
	call autostore_variables
	
	jmp mainloop
	
.mouse_x					dw 0
.mouse_y					dw 0

	

; ------------------------------------------------------------------
; LOCKMOUSE

do_lockmouse:
	mov cx, 4
	mov di, .min_x
	call autofetch_variables
	
	mov ax, [.min_x]
	mov bx, [.min_y]
	mov cx, [.max_x]
	mov dx, [.max_y]
	call os_mouse_range
	
	jmp mainloop
	
	
.min_x						dw 0
.min_y						dw 0
.max_x						dw 0
.max_y						dw 0


	
; ------------------------------------------------------------------
; LOOP

do_loop:
	cmp byte [loop_in], 0
	je .no_do

	dec byte [loop_in]
	dec byte [loop_in]

	mov dx, 0

	call get_token
	mov di, token
	
	mov si, .endless_word
	call os_string_compare
	jc .loop_back_link
	
	mov si, .while_word
	call os_string_compare
	jc .while_set
	
	mov si, .until_word
	call os_string_compare
	jnc .error

.get_first_var:
	call get_token
	cmp ax, VARIABLE
	jne .error
	
	mov al, [token]
	call get_var
	mov cx, ax
	
.check_equals:
	call get_token
	cmp ax, UNKNOWN
	jne .error

	mov ax, [token]
	cmp al, '='
	je .sign_ok
	cmp al, '>'
	je .sign_ok
	cmp al, '<'
	je .sign_ok
	cmp al, '!'
	je .sign_ok
	jmp .error
	
	.no_do:
	mov si, err_loop
	jmp error
	
	.sign_ok:
	mov byte [.sign], al
	
.get_second_var:
 	call get_token

	cmp ax, NUMBER
	je .second_is_num

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, CHAR
	jne .error

.second_is_char:
	mov ah, 0
	mov al, [token]
	jmp .check_true
	
.second_is_var:
	mov al, [token]
	call get_var
	jmp .check_true
	
	.while_set:
	mov dx, 1
	jmp .get_first_var
	
.error:
	mov si, err_syntax
	jmp error
	
	.loop_back_link:
	jmp .loop_back
	
.second_is_num:
	mov si, token
	call os_string_to_int
	
.check_true:
	mov byte bl, [.sign]
	cmp bl, '='
	je .sign_equals
	
	cmp bl, '>'
	je .sign_greater
	
	cmp bl, '<'
	je .sign_lesser
	
	jmp .sign_inequal
	
.sign_equals:
	cmp ax, cx
	jne .false
	jmp .true
	
.sign_greater:
	cmp ax, cx
	jge .false
	jmp .true
	
.sign_lesser:
	cmp ax, cx
	jle .false
	jmp .true
	
.sign_inequal:
	cmp ax, cx
	je .false
	jmp .true

.true:
	cmp dx, 1
	je .loop_back
	jmp mainloop
.false:
	cmp dx, 1
	je mainloop
	
.loop_back:	
	mov word si, do_loop_store
	mov byte al, [loop_in]
	mov ah, 0
	add si, ax
	lodsw
	mov word [prog], ax
	jmp mainloop
	
.data:
	.while_word			db "WHILE", 0
	.until_word			db "UNTIL", 0
	.endless_word			db "ENDLESS", 0
	.sign				db 0
	
;-------------------------------------------------------------------
; MEMORY
do_memory:
	call get_token
	mov si, token
	
	mov di, .allocate_cmd
	call os_string_compare
	jc .allocate
	
	mov di, .release_cmd
	call os_string_compare
	jc .release
	
	mov di, .read_cmd
	call os_string_compare
	jc .read
	
	mov di, .write_cmd
	call os_string_compare
	jc .write
	
	jmp .error
	
.allocate:
	mov di, .blocks
	mov cx, 1
	call autofetch_variables
	
	mov dx, [.blocks]
	call os_memory_allocate
	
	cmp bh, 0
	je .out_of_memory
	
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	
	mov bl, bh
	mov bh, 0
	call set_var
	
	jmp mainloop
	
.release:
	mov di, .handle
	mov cx, 1
	call autofetch_variables
	
	mov bh, [.handle]
	call os_memory_release
	
	jmp mainloop
	
.read:
	mov di, .handle
	mov cx, 2
	call autofetch_variables
	
	mov bh, [.handle]
	mov di, [.address]
	mov ax, 0x2000
	mov es, ax
	call os_memory_read
	
	jmp mainloop
	
.write:
	mov di, .handle
	mov cx, 2
	call autofetch_variables
	
	mov bh, [.handle]
	mov si, [.address]
	mov ax, 0x2000
	mov ds, ax
	call os_memory_write
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error
	
.out_of_memory:
	mov si, memory_cmd
	jmp error
	
.blocks					dw 0
.handle					dw 0
.address				dw 0

.allocate_cmd				db 'ALLOCATE', 0
.release_cmd				db 'RELEASE', 0
.read_cmd				db 'READ', 0
.write_cmd				db 'WRITE', 0



; ------------------------------------------------------------------
; MID

do_mid:
	call get_string_pointer
	mov di, string_buffer
	call os_string_copy
	
	mov di, .start
	mov cx, 2
	call autofetch_variables
	
	call get_string_pointer
	jc .error
	mov di, si
	
	mov si, string_buffer
	add si, [.start]
	dec si
	mov cx, [.length]
	rep movsb
	mov al, 0
	stosb
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error

.start					dw 0
.length					dw 0



; ------------------------------------------------------------------
; MOVE

do_move:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	mov dl, al
	jmp .onto_second

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dl, al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	mov dh, al
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	mov dh, al

.finish:
	mov byte bh, [work_page]
	mov ah, 2
	int 10h

	jmp mainloop

	
; ------------------------------------------------------------------
; MOVEMOUSE

do_movemouse:
	mov cx, 2
	mov di, .mousex
	call autofetch_variables
	
	mov cx, [.mousex]
	mov dx, [.mousey]
	call os_mouse_move
	
	jmp mainloop
	
.mousex						dw 0
.mousey						dw 0
	

; ------------------------------------------------------------------
; NEXT

do_next:
	call get_token

	cmp ax, VARIABLE			; NEXT must be followed by a variable
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	inc ax					; NEXT increments the variable, of course!

	mov bx, ax

	mov ax, 0
	mov byte al, [token]

	sub al, 65
	mov si, for_variables
	add si, ax
	add si, ax
	lodsw					; Get the target number from the table

	inc ax					; (Make the loop inclusive of target number)
	cmp ax, bx				; Do the variable and target match?
	je .loop_finished

	mov ax, 0				; If not, store the updated variable
	mov byte al, [token]
	call set_var

	mov ax, 0				; Find the code point and go back
	mov byte al, [token]
	sub al, 65
	mov si, for_code_points
	add si, ax
	add si, ax
	lodsw

	mov word [prog], ax
	jmp mainloop


.loop_finished:
	jmp mainloop

.error:
	mov si, err_syntax
	jmp error



;-------------------------------------------------------------------
; NUMBER

do_number:
	call get_token			; Check if it's string to number, or number to string

	cmp ax, STRING_VAR
	je .is_string

	cmp ax, VARIABLE
	je .is_variable

	jmp .error

.is_string:

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov [.tmp], si

	call get_token

	mov si, [.tmp]

	cmp ax, VARIABLE
	jne .error

	call os_string_to_int
	mov bx, ax

	mov ax, 0
	mov byte al, [token]
	call set_var

	jmp mainloop

.is_variable:

	mov ax, 0			; Get the value of the number
	mov byte al, [token]
	call get_var

	call os_int_to_string		; Convert to a string
	mov [.tmp], ax

	call get_token			; Get the second parameter

	mov si, [.tmp]

	cmp ax, STRING_VAR		; Make sure it's a string variable
	jne .error

	mov di, string_vars		; Locate string variable
	mov ax, 128
	mul bx
	add di, ax

	call os_string_copy		; Save converted string

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


	.tmp		dw 	0


;-------------------------------------------------------------------
; PAGE

do_page:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov byte [work_page], al	; Set work page variable

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov byte [disp_page], al	; Set display page variable

	; Change display page -- AL should already be present from the os_string_to_int
	mov ah, 5
	int 10h

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; PAUSE

do_pause:
	call get_token

	cmp ax, VARIABLE
	je .is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause
	jmp mainloop


; ------------------------------------------------------------------
; PEEK

do_peek:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	mov byte [.tmp_var], al

	call get_token

	cmp ax, VARIABLE
	je .dereference

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.store:
	mov si, ax
	mov bx, 0
	mov byte bl, [si]
	mov ax, 0
	mov byte al, [.tmp_var]
	call set_var

	jmp mainloop

.dereference:
	mov byte al, [token]
	call get_var
	jmp .store

.error:
	mov si, err_syntax
	jmp error


	.tmp_var	db 0
	
	
	
; ------------------------------------------------------------------
; PEEKINT

do_peekint:
	call get_token
	
	cmp ax, VARIABLE
	jne .error

.get_second:
	mov al, [token]
	mov cx, ax
	
	call get_token
	
	cmp ax, VARIABLE
	je .address_is_var
	
	cmp ax, NUMBER
	jne .error
	
.address_is_number:
	mov si, token
	call os_string_to_int
	jmp .load_data
	
.address_is_var:
	mov al, [token]
	call get_var
	
.load_data:
	mov si, ax
	mov bx, [si]
	mov ax, cx
	call set_var
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; PLOT

do_plot:
	cmp byte [graphicsmode], 0			; check graphics mode is active
	je .no_graphics
	
	mov di, .x					; fetch three variables: x, y, colour
	mov cx, 3
	call autofetch_variables
	
	mov ax, [.x]					; set a pixel
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	jmp mainloop
	
	.x			dw 0
	.y			dw 0
	.colour			dw 0
	
.no_graphics:
	mov si, err_graphics
	jmp error
	
; ------------------------------------------------------------------
; POINT

do_point:
	cmp byte [graphicsmode], 0			;  check graphics mode is active
	je .no_graphics
	
	mov di, .x					; fetch x and y
	mov cx, 2
	call autofetch_variables
	
	mov ax, [.x]					; get pixel colour
	mov cx, [.y]
	call os_get_pixel	
	push bx
	
	call get_token					; set variable to pixel colour
	
	cmp ax, VARIABLE
	jne .error
	
	mov al, [token]
	pop bx
	mov bh, 0
	call set_var
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error
	
.no_graphics:
	mov si, err_graphics
	jmp error
	
	.x			dw 0
	.y			dw 0
	
; ------------------------------------------------------------------
; POKE

do_poke:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

	cmp ax, 255
	jg .error

	mov byte [.first_value], al
	jmp .onto_second


.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	mov byte [.first_value], al

.onto_second:
	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.got_value:
	mov di, ax
	mov ax, 0
	mov byte al, [.first_value]
	mov byte [di], al

	jmp mainloop

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .got_value

.error:
	mov si, err_syntax
	jmp error


	.first_value	db 0




; ------------------------------------------------------------------
; POKEINT

do_pokeint:
	call get_token
	
	cmp ax, VARIABLE
	je .data_is_var
	
	cmp ax, NUMBER
	jne .error

.data_is_num:
	mov si, token
	call os_string_to_int
	jmp .get_second
	
.data_is_var:
	mov al, [token]
	call get_var
	
.get_second:
	mov cx, ax
	
	call get_token
	
	cmp ax, VARIABLE
	je .address_is_var
	
	cmp ax, NUMBER
	jne .error
	
.address_is_num:
	mov si, token
	call os_string_to_int
	jmp .save_data
	
.address_is_var:
	mov al, [token]
	call get_var
	
.save_data:
	mov si, ax
	mov [si], cx
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error



; ------------------------------------------------------------------
; POLYGON

do_polygon:
	cmp byte [graphicsmode], 0
	je .no_graphics
	
	mov di, .points					; fetch number of points and colour
	mov cx, 2
	call autofetch_variables
	
	mov cx, [.points]
	
	cmp cx, 2					; make sure there is enought points
	jle ._points
	
	cmp cx, 10					; but not too many
	jg ._points
	
	shl cx, 1					; we need two coordinents for each point
	mov di, .point_data				; fetch all points to a data array
	call autofetch_variables
	
	mov bh, [.points]				; send the polygon routine the number of points, colour and the address of the data array 
	mov bl, [.colour]
	mov si, .point_data
	call os_draw_polygon
	
	jmp mainloop
	
.no_graphics:
	mov si, err_graphics
	jmp error
	
._points:
	mov si, err_polygon_no
	jmp error

.points					dw 0
.colour					dw 0
.point_data		times 20	dw 0



; ------------------------------------------------------------------
; PORT

do_port:
	call get_token
	mov si, token

	mov di, .out_cmd
	call os_string_compare
	jc .do_out_cmd

	mov di, .in_cmd
	call os_string_compare
	jc .do_in_cmd

	jmp .error


.do_out_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int		; Now AX = port number
	mov dx, ax

	call get_token
	cmp ax, NUMBER
	je .out_is_num

	cmp ax, VARIABLE
	je .out_is_var

	jmp .error

.out_is_num:
	mov si, token
	call os_string_to_int
	call os_port_byte_out
	jmp mainloop

.out_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_port_byte_out
	jmp mainloop


.do_in_cmd:
	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov dx, ax

	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte cl, [token]

	call os_port_byte_in
	mov bx, 0
	mov bl, al

	mov al, cl
	call set_var

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.out_cmd	db "OUT", 0
	.in_cmd		db "IN", 0


; ------------------------------------------------------------------
; PRINT

do_print:
	call get_token				; Get part after PRINT
;mov si, token
;call os_print_string
	
	cmp ax, QUOTE				; What type is it?
	je .print_quote

	cmp ax, VARIABLE			; Numerical variable (eg X)
	je .print_var

	cmp ax, STRING_VAR			; String variable (eg $1)
	je .print_string_var

	cmp ax, STRING				; Special keyword (eg CHR or HEX)
	je .print_keyword

	mov si, err_print_type			; We only print quoted strings and vars!
	jmp error

.print_var:
	mov ax, 0
	mov byte al, [token]
	call get_var				; Get its value

	call os_int_to_string			; Convert to string
	mov si, ax
	call os_print_string

	jmp .newline_or_not


.print_quote:					; If it's quoted text, print it
	mov si, token
.print_quote_loop:
	lodsb
	cmp al, 0
	je .newline_or_not_link

	mov ah, 09h
	mov byte bl, [ink_colour]
	mov byte bh, [work_page]
	mov cx, 1
	int 10h

	mov ah, 3
	int 10h

	cmp dl, 79
	jge .quote_newline
	inc dl

.move_cur_quote:
	mov byte bh, [work_page]
	mov ah, 02h
	int 10h
	jmp .print_quote_loop

	.newline_or_not_link:
	jmp .newline_or_not
	
.quote_newline:
	cmp dh, 24
	je .move_cur_quote
	mov dl, 0
	inc dh
	jmp .move_cur_quote

.print_string_var:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	jmp .print_quote_loop


.print_keyword:
	mov si, token
	mov di, chr_keyword
	call os_string_compare
	jc .is_chr

	mov di, hex_keyword
	call os_string_compare
	jc .is_hex

	mov si, err_syntax
	jmp error
	

.is_chr:
	call get_token

	cmp ax, VARIABLE
	je .is_chr_variable
	
	cmp ax, NUMBER
	je .is_chr_number

.is_chr_variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .print_chr
	
.is_chr_number:
	mov si, token
	call os_string_to_int

.print_chr:
	mov ah, 09h
	mov byte bl, [ink_colour]
	mov byte bh, [work_page]
	mov cx, 1
	int 10h

	mov ah, 3		; Move the cursor forward
	int 10h
	inc dl
	cmp dl, 79
	jg .end_line		; If it's over the end of the line
.move_cur:
	mov ah, 2
	int 10h

	jmp .newline_or_not


.is_hex:
	call get_token

	cmp ax, VARIABLE
	jne .error

	mov ax, 0
	mov byte al, [token]
	call get_var

	call os_print_2hex

	jmp .newline_or_not

.end_line:
	mov dl, 0
	inc dh
	cmp dh, 25
	jl .move_cur
	mov dh, 24
	mov dl, 79
	jmp .move_cur
	
.error:
	mov si, err_syntax
	jmp error
	
	.newline_or_not:
	; We want to see if the command ends with ';' -- which means that
	; we shouldn't print a newline after it finishes. So we store the
	; current program location to pop ahead and see if there's the ';'
	; character -- otherwise we put the program location back and resume
	; the main loop

	mov word ax, [prog]
	mov word [.tmp_loc], ax

	call get_token
	cmp ax, UNKNOWN
	jne .ignore

	mov ax, 0
	mov al, [token]
	cmp al, ';'
	jne .ignore

	jmp mainloop				; And go back to interpreting the code!

.ignore:
	mov ah, 5
	mov al, [work_page]
	int 10h

	mov bh, [work_page]
	call os_print_newline

	mov ah, 5
	mov al, [disp_page]
	int 10h

	mov word ax, [.tmp_loc]
	mov word [prog], ax

	jmp mainloop

	.tmp_loc	dw 0

	
	
; ------------------------------------------------------------------
; QUESTION

do_question:
	call get_string_pointer
	mov ax, si
	mov bx, 0
	mov cx, 0
	
	mov dx, 1
	call os_dialog_box
	mov bx, ax
	
	call get_token
	
	cmp ax, VARIABLE
	
	mov byte al, [token]
	call set_var
	
	jmp mainloop
	


; ------------------------------------------------------------------
; RAND

do_rand:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]
	mov byte [.tmp], al

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num1], ax

	call get_token
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	mov word [.num2], ax

	mov word ax, [.num1]
	mov word bx, [.num2]
	call os_get_random

	mov bx, cx
	mov ax, 0
	mov byte al, [.tmp]
	call set_var

	jmp mainloop


	.tmp	db 0
	.num1	dw 0
	.num2	dw 0


.error:
	mov si, err_syntax
	jmp error


; ------------------------------------------------------------------
; READ

do_read:
	call get_token				; Get the next token

	cmp ax, STRING				; Check for a label
	je .is_ok

	mov si, err_goto_notlabel
	jmp error

.is_ok:
	mov si, token				; Back up this label
	mov di, .tmp_token
	call os_string_copy

	mov ax, .tmp_token
	call os_string_length

	mov di, .tmp_token			; Add ':' char to end for searching
	add di, ax
	mov al, ':'
	stosb
	mov al, 0
	stosb

	call get_token				; Now get the offset variable
	cmp ax, VARIABLE
	je .second_part_is_var

	mov si, err_syntax
	jmp error


.second_part_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

	cmp ax, 0				; Want to be searching for at least the first byte!
	jg .var_bigger_than_zero

	mov si, err_syntax
	jmp error


.var_bigger_than_zero:
	mov word [.to_skip], ax


	call get_token				; And now the var to store result into
	cmp ax, VARIABLE
	je .third_part_is_var

	mov si, err_syntax
	jmp error


.third_part_is_var:				; Keep it for later
	mov ax, 0
	mov byte al, [token]
	mov byte [.var_to_use], al



	; OK, so now we have all the stuff we need. Let's search for the label

	mov word ax, [prog]			; Store current location
	mov word [.curr_location], ax

	mov word ax, [load_point]
	mov word [prog], ax			; Return to start of program to find label

.loop:
	call get_token

	cmp ax, LABEL
	jne .line_loop

	mov si, token
	mov di, .tmp_token
	call os_string_compare
	jc .found_label

.line_loop:					; Go to end of line
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]

	cmp al, 10
	jne .line_loop

	mov word ax, [prog]
	mov word bx, [prog_end]
	cmp ax, bx
	jg .past_end

	jmp .loop

.past_end:
	mov si, err_label_notfound
	jmp error


.found_label:
	mov word cx, [.to_skip]			; Skip requested number of data entries

.data_skip_loop:
	push cx
	call get_token
	pop cx
	loop .data_skip_loop

	cmp ax, NUMBER
	je .data_is_num

	mov si, err_syntax
	jmp error

.data_is_num:
	mov si, token
	call os_string_to_int

	mov bx, ax
	mov ax, 0
	mov byte al, [.var_to_use]
	call set_var

	mov word ax, [.curr_location]
	mov word [prog], ax

	jmp mainloop


	.curr_location	dw 0

	.to_skip	dw 0
	.var_to_use	db 0
	.tmp_token 	times 30 db 0


	
; ------------------------------------------------------------------
; RELEASEMOUSE

do_releasemouse:
	cmp byte [graphicsmode], 1
	je .graphics_mode
	
	mov ax, 0
	mov bx, 0
	mov cx, 79
	mov dx, 24
	call os_mouse_range
	
	jmp mainloop
	
.graphics_mode:
	mov ax, 0
	mov bx, 0
	mov cx, 319
	mov dx, 239
	call os_mouse_range
	
	jmp mainloop
	
	
; ------------------------------------------------------------------
; REM

do_rem:
	mov word si, [prog]
	mov byte al, [si]
	inc word [prog]
	cmp al, 10			; Find end of line after REM
	jne do_rem

	jmp mainloop


; ------------------------------------------------------------------
; RENAME

do_rename:
	call get_token

	cmp ax, STRING_VAR		; Is it a string or a quote?
	je .first_is_string

	cmp ax, QUOTE
	je .first_is_quote

	jmp .error

.first_is_string:
	mov si, string_vars		; Locate string
	mov ax, 128
	mul bx
	add si, ax

	jmp .save_file1

.first_is_quote:
	mov si, token			; The location of quotes is provided

.save_file1:
	mov word di, .file1		; The filename is saved to temporary strings because
	call os_string_copy		; getting a second quote will overwrite the previous
	
.get_second:
	call get_token

	cmp ax, STRING_VAR
	je .second_is_string

	cmp ax, QUOTE
	je .second_is_quote

	jmp .error

.second_is_string:
	mov si, string_vars		; Locate second string
	mov ax, 128
	mul bx
	add si, ax

	jmp .save_file2

.second_is_quote:
	mov si, token

.save_file2:
	mov word di, .file2
	call os_string_copy
	
.check_exists:
	mov word ax, .file1		; Check if the source file exists
	call os_file_exists
	jc .file_not_found		; If it doesn't exists set "R = 1"

	clc
	mov ax, .file2			; The second file is the destination and should not exist
	call os_file_exists
	jnc .file_exists		; If it exists set "R = 3"
	
.rename:
	mov word ax, .file1		; Seem to be okay, lets rename
	mov word bx, .file2
	call os_rename_file

	jc .rename_failed		; If it failed set "R = 2", usually caused by a read-only disk

	mov ax, 0			; It worked sucessfully, so set "R = 0" to indicate no error
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.file_not_found:
	mov ax, 0			; Set R variable to 1
	mov byte al, 'R'
	mov bx, 1
	call set_var

	jmp mainloop

.rename_failed:
	mov ax, 0			; Set R variable to 2
	mov byte al, 'R'
	mov bx, 2
	call set_var

	jmp mainloop

.file_exists:
	mov ax, 0
	mov byte al, 'R'		; Set R variable to 3
	mov bx, 3
	call set_var

	jmp mainloop

.data:
	.file1				times 12 db 0
	.file2				times 12 db 0


; ------------------------------------------------------------------
; RETURN

do_return:
	mov ax, 0
	mov byte al, [gosub_depth]
	cmp al, 0
	jne .is_ok

	mov si, err_return
	jmp error

.is_ok:
	mov si, gosub_points
	add si, ax				; Table is words (not bytes)
	add si, ax
	lodsw
	mov word [prog], ax
	dec byte [gosub_depth]

	jmp mainloop	
	

; ------------------------------------------------------------------
; REVERSE

do_reverse:
	call get_string_pointer
	jc .error
	
	call os_string_reverse
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error

	
; ------------------------------------------------------------------
; RIGHT

do_right:
	call get_string_pointer
	mov di, string_buffer
	call os_string_copy
	
	mov si, string_buffer
	call os_string_reverse
	
	mov di, .length
	mov cx, 1
	call autofetch_variables
	
	call get_string_pointer
	mov di, si
	push di
	
	mov si, string_buffer
	mov cx, [.length]
	rep movsb
	mov al, 0
	stosb
	
	pop di
	mov si, di
	call os_string_reverse
	
	jmp mainloop
	
	
.length					dw 0
	
; ------------------------------------------------------------------
; SAVE

do_save:
	call get_token
	cmp ax, QUOTE
	je .is_quote

	cmp ax, STRING_VAR
	jne near .error

	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	jmp .get_position

.is_quote:
	mov si, token

.get_position:
	mov di, .tmp_filename
	call os_string_copy

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.set_data_loc:
	mov word [.data_loc], ax

	call get_token

	cmp ax, VARIABLE
	je .third_is_var

	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int

.check_exists:
	mov word [.data_size], ax
	mov word ax, .tmp_filename
	call os_file_exists
	jc .write_file
	jmp .file_exists_fail
	
.write_file:

	mov word ax, .tmp_filename
	mov word bx, [.data_loc]
	mov word cx, [.data_size]
	
	call os_write_file
	jc .save_failure

	mov ax, 0
	mov byte al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop


.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .set_data_loc


.third_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var
	jmp .check_exists

.file_exists_fail:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 2
	call set_var
	jmp mainloop
	
.save_failure:
	mov ax, 0
	mov byte al, 'R'
	mov bx, 1
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error


	.filename_loc	dw 0
	.data_loc	dw 0
	.data_size	dw 0

	.tmp_filename	times 15 db 0


; ------------------------------------------------------------------
; SERIAL

do_serial:
	call get_token
	mov si, token

	mov di, .on_cmd
	call os_string_compare
	jc .do_on_cmd

	mov di, .send_cmd
	call os_string_compare
	jc .do_send_cmd

	mov di, .rec_cmd
	call os_string_compare
	jc .do_rec_cmd

	jmp .error

.do_on_cmd:
	call get_token
	cmp ax, NUMBER
	je .do_on_cmd_ok
	jmp .error

.do_on_cmd_ok:
	mov si, token
	call os_string_to_int
	cmp ax, 1200
	je .on_cmd_slow_mode
	cmp ax, 9600
	je .on_cmd_fast_mode

	jmp .error

.on_cmd_fast_mode:
	mov ax, 0
	call os_serial_port_enable
	jmp mainloop

.on_cmd_slow_mode:
	mov ax, 1
	call os_serial_port_enable
	jmp mainloop


.do_send_cmd:
	call get_token
	cmp ax, NUMBER
	je .send_number

	cmp ax, VARIABLE
	je .send_variable

	jmp .error

.send_number:
	mov si, token
	call os_string_to_int
	call os_send_via_serial
	jmp mainloop

.send_variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	call os_send_via_serial
	jmp mainloop


.do_rec_cmd:
	call get_token
	cmp ax, VARIABLE
	jne .error

	mov byte al, [token]

	mov cx, 0
	mov cl, al
	call os_get_via_serial

	mov bx, 0
	mov bl, al
	mov al, cl
	call set_var

	jmp mainloop


.error:
	mov si, err_syntax
	jmp error


	.on_cmd		db "ON", 0
	.send_cmd	db "SEND", 0
	.rec_cmd	db "REC", 0


; ------------------------------------------------------------------
; SIZE

do_size:
	call get_token

	cmp ax, STRING_VAR
	je .is_string

	cmp ax, QUOTE
	je .is_quote

	jmp .error

.is_string:
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax

	mov ax, si
	jmp .get_size

.is_quote:
	mov ax, token

.get_size:
	call os_get_file_size
	jc .file_not_found

	mov ax, 0
	mov al, 'S'
	call set_var

	mov ax, 0
	mov al, 'R'
	mov bx, 0
	call set_var

	jmp mainloop

.error:
	mov si, err_syntax
	jmp error

.file_not_found:
	mov ax, 0
	mov al, [token]
	mov bx, 0
	call set_var

	mov ax, 0
	mov al, 'R'
	mov bx, 1
 	call set_var
 	
	jmp mainloop



; ------------------------------------------------------------------
; SOUND

do_sound:
	call get_token

	cmp ax, VARIABLE
	je .first_is_var

	mov si, token
	call os_string_to_int
	jmp .done_first

.first_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.done_first:
	call os_speaker_tone

	call get_token

	cmp ax, VARIABLE
	je .second_is_var

	mov si, token
	call os_string_to_int
	jmp .finish

.second_is_var:
	mov ax, 0
	mov byte al, [token]
	call get_var

.finish:
	call os_pause
	call os_speaker_off

	jmp mainloop


	
; ------------------------------------------------------------------
; SPLIT

do_split:
	call get_string_pointer
	
	call os_string_parse
	
	call get_string_pointer
	jc .error
	cmp ax, 0
	je .string_one_null
	
	mov di, si
	mov si, ax
	call os_string_copy
	
	call get_string_pointer
	jc .error
	cmp bx, 0
	je .string_two_null
	
	mov di, si
	mov si, bx
	call os_string_copy
	
	call get_string_pointer
	jc .error
	cmp cx, 0
	je .string_three_null
	
	mov di, si
	mov si, cx
	call os_string_copy

	call get_string_pointer
	jc .error
	cmp dx, 0
	je .string_four_null
	
	mov di, si
	mov si, dx
	call os_string_copy
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error
	
.string_one_null:
	mov byte [si], 0
	
	call get_string_pointer
	
.string_two_null:
	mov byte [si], 0
	
	call get_string_pointer
	
.string_three_null:
	mov byte [si], 0
	
	call get_string_pointer
	
.string_four_null:
	mov byte [si], 0
	
	jmp mainloop
	
	
;-------------------------------------------------------------------
; STRING
do_string:
	call get_token			; The first parameter is the word 'GET', 'SET', LOAD or SAVE
	mov si, token
	
	mov di, .get_cmd
	call os_string_compare
	jc .set_str
		
	mov di, .set_cmd
	call os_string_compare
	jc .get_str
	
	mov di, .load_cmd
	call os_string_compare
	jc .load_str
	
	mov di, .save_cmd
	call os_string_compare
	jc .save_str

	jmp .error
	
	.set_str:
	mov cx, 1
	jmp .check_second
	.get_str:
	mov cx, 2
	jmp .check_second
	
	.load_str:
	mov cx, 3
	jmp .check_second
	
	.save_str:
	mov cx, 4
	jmp .check_second

.check_second:
	call get_token			; The next should be a string variable, locate it
	
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	mov word [.string_loc], si
	
.check_third:
	call get_token			; Now there should be a number
	
	cmp ax, NUMBER
	je .third_is_number
	
	cmp ax, VARIABLE
	je .third_is_variable
	
	jmp .error
	
.third_is_number:	
	mov si, token
	call os_string_to_int
	jmp .got_number	

.third_is_variable:
	mov ah, 0
	mov al, [token]
	call get_var
	jmp .got_number

.got_number:
	cmp ax, 128
	jg .outrange
	cmp ax, 0
	je .outrange
	sub ax, 1
	mov dx, ax
	
	cmp cx, 3			; load/save only need two variables
	je .load_var
	
	cmp cx, 4
	je .save_var
	
.check_forth:
	call get_token			; Next a numerical variable
	
	cmp ax, VARIABLE
	jne .error
	
	mov byte al, [token]
	mov byte [.tmp], al
	
	cmp cx, 2
	je .set_var
	
.get_var:
	mov word si, [.string_loc]	; Move to string location
	add si, dx			; Add offset
	lodsb				; Load data
	mov ah, 0
	mov bx, ax			; Set data in numerical variable
	mov byte al, [.tmp]
	call set_var
	jmp mainloop
	
.set_var:
	mov byte al, [.tmp]		; Retrieve the variable
	call get_var			; Get it's value
	mov di, [.string_loc]		; Locate the string
	add di, dx			; Add the offset
	stosb				; Store data
	jmp mainloop
	
.load_var:
	inc dx
	mov si, dx
	mov di, [.string_loc]
	call os_string_copy
	jmp mainloop
	
.save_var:
	inc dx
	mov si, [.string_loc]
	mov di, dx
	call os_string_copy
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error
	
.outrange:
	mov dx, ax
	dec dx

	cmp cx, 3
	je .load_var
	
	cmp cx, 4
	je .save_var

	mov si, err_string_range
	jmp error

.data:
	.get_cmd		db "GET", 0
	.set_cmd		db "SET", 0
	.load_cmd		db "LOAD", 0
	.save_cmd		db "STORE", 0
	.string_loc		dw 0
	.tmp			db 0


; ------------------------------------------------------------------
; TEXTMODE

do_textmode:
	call os_text_mode
	
	mov byte [graphicsmode], 0
	
	mov ax, 0
	mov bx, 0
	mov cx, 79
	mov dx, 24
	call os_mouse_range
	
	mov dl, 2
	mov dh, 3
	call os_mouse_scale
	
	jmp mainloop

	
; ------------------------------------------------------------------
; TRIM

do_trim:
	call get_string_pointer
	jc .error
	mov ax, si
	call os_string_chomp
	
	jmp mainloop
	
.error:
	mov si, err_syntax
	jmp error
	
	
;------------------------------------------------------------------
; USEMOUSE

do_usemouse:
	call os_mouse_show
	call os_input_wait
	jc .keypress
	
	call os_mouse_anyclick
	jc .click
	
	call os_mouse_hide
	jmp do_usemouse

.keypress:
	call os_check_for_extkey

	cmp ax, 48E0h
	je .up_pressed

	cmp ax, 50E0h
	je .down_pressed

	cmp ax, 4BE0h
	je .left_pressed

	cmp ax, 4DE0h
	je .right_pressed
	
	mov ah, 0
	mov [.key], ax
	jmp .finish
	
.up_pressed:
	mov byte [.key], 1
	jmp .finish
	
.down_pressed:
	mov word [.key], 2
	jmp .finish
	
.left_pressed:
	mov word [.key], 3
	jmp .finish
	
.right_pressed:
	mov word [.key], 4
	jmp .finish
	
.click:
	mov word [.key], 0
	
.finish:
	call os_mouse_hide
	call os_mouse_locate
	mov [.mouse_x], cx
	mov [.mouse_y], dx
	
	mov si, .key
	mov cx, 3
	call autostore_variables
	
	jmp mainloop
	

.key					dw 0
.mouse_x				dw 0
.mouse_y				dw 0

	
;------------------------------------------------------------------
; VLINE

do_vline:
	mov di, .start_x
	mov cx, 4
	call autofetch_variables
	
	cmp byte [graphicsmode], 1
	jne .textmode
	
	mov cx, [.start_x]
	mov dx, [.start_y]
	mov si, [.start_x]
	mov di, dx
	add di, [.length]
	mov bh, [.colour]
	call os_draw_line
	
	jmp mainloop
	
.textmode:
	mov bh, [.length]
	mov bl, [.colour]
	mov dh, [.start_x]
	mov dl, [.start_y]
	call os_draw_vertical_line
	
	jmp mainloop

.start_x					dw 0
.start_y					dw 0
.length						dw 0
.colour						dw 0


; ------------------------------------------------------------------
; WAITANY

do_waitany:
	call os_input_wait
	jmp mainloop


; ------------------------------------------------------------------
; WAITKEY

do_waitkey:
	call get_token
	cmp ax, VARIABLE
	je .is_variable

	mov si, err_syntax
	jmp error

.is_variable:
	mov ax, 0
	mov byte al, [token]

	push ax

	call os_wait_for_key

	
cmp al,0
	jne .store
	
.check:
	xchg ah,al
	
	cmp al, 0x48
	je .up_pressed

	cmp al, 0x50
	je .down_pressed

	cmp al, 0x4B
	je .left_pressed

	cmp al, 0x4D
	je .right_pressed
	
	;.skip:
jmp .store

.up_pressed:
	mov al, 1
	jmp .store

.down_pressed:
	mov al, 2
	jmp .store

.left_pressed:
	mov al, 3
	jmp .store

.right_pressed:
	mov al, 4
	;jmp .store
	
	; cmp ax, 48E0h
	; je .up_pressed

	; cmp ax, 50E0h
	; je .down_pressed

	; cmp ax, 4BE0h
	; je .left_pressed

	; cmp ax, 4DE0h
	; je .right_pressed
	
	;.skip:

.store:
	mov bx, 0
	mov bl, al

	pop ax

	call set_var

	jmp mainloop

; ------------------------------------------------------------------
; WAITMOUSE
do_waitmouse:
	call os_mouse_wait
	jmp mainloop
; ==================================================================
; INTERNAL ROUTINES FOR INTERPRETER

; ------------------------------------------------------------------
; Get value of variable character specified in AL (eg 'A')

get_var:
	mov ah, 0
	sub al, 65
	mov si, variables
	add si, ax
	add si, ax
	lodsw
	ret


; ------------------------------------------------------------------
; Set value of variable character specified in AL (eg 'A')
; with number specified in BX

set_var:
	mov ah, 0
	sub al, 65				; Remove ASCII codes before 'A'

	mov di, variables			; Find position in table (of words)
	add di, ax
	add di, ax
	mov ax, bx
	stosw
	ret


; ------------------------------------------------------------------
; Get token from current position in prog

get_token:
	mov word si, [prog]
	lodsb

	cmp al, 13
	je .newline
	
	cmp al, 10
	je .newline

	cmp al, ' '
	je .newline

	call is_number
	jc get_number_token

	cmp al, '"'
	je get_quote_token

	cmp al, 39			; Quote mark (')
	je get_char_token

	cmp al, '$'
	je near get_string_var_token

	jmp get_string_token


.newline:
	inc word [prog]
	jmp get_token


get_number_token:
	mov word si, [prog]
	mov di, token

.loop:
	lodsb
	cmp al, 13
	je .done_13
	cmp al, 10
	je .done
	cmp al, ' '
	je .done
	call is_number
	jc .fine

	mov si, err_char_in_num
	jmp error

.fine:
	stosb
	inc word [prog]
	jmp .loop
.done_13:
inc word [prog]
.done:
	mov al, 0			; Zero-terminate the token
	stosb

	mov ax, NUMBER			; Pass back the token type
	ret


get_char_token:
	inc word [prog]			; Move past first quote (')

	mov word si, [prog]
	lodsb

	mov byte [token], al

	lodsb
	cmp al, 39			; Needs to finish with another quote
	je .is_ok

	mov si, err_quote_term
	jmp error

.is_ok:
	inc word [prog]
	inc word [prog]

	mov ax, CHAR
	ret


get_quote_token:
	inc word [prog]			; Move past first quote (") char
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, '"'
	je .done
	cmp al, 13
	je .error
	cmp al, 10
	je .error
	stosb
	inc word [prog]
	jmp .loop

.done:
	mov al, 0			; Zero-terminate the token
	stosb
	inc word [prog]			; Move past final quote

	mov ax, QUOTE			; Pass back token type
	ret

.error:
	mov si, err_quote_term
	jmp error


get_string_var_token:
	lodsb
	mov bx, 0			; If it's a string var, pass number of string in BX
	mov bl, al
	sub bl, 49

	inc word [prog]
	inc word [prog]

	mov ax, STRING_VAR
	ret
	

get_string_token:
	mov word si, [prog]
	mov di, token
.loop:
	lodsb
	cmp al, 13
	je .done_13
	cmp al, 10
	je .done
	cmp al,0
	je .done
	cmp al, ' '
	je .done
	stosb
	inc word [prog]
	jmp .loop
.done_13:
inc word [prog]
.done:
	mov al, 0			; Zero-terminate the token
	stosb

	mov ax, token
	call os_string_uppercase
	;mov si, token
	;call os_print_string

	mov ax, token
	call os_string_length		; How long was the token?
	cmp ax, 1			; If 1 char, it's a variable or delimiter
	je .is_not_string

	mov si, token			; If the token ends with ':', it's a label
	add si, ax
	dec si
	lodsb
	cmp al, ':'
	je .is_label

	mov ax, STRING			; Otherwise it's a general string of characters
	ret

.is_label:
	mov ax, LABEL
	ret


.is_not_string:
	mov byte al, [token]
	call is_letter
	jc .is_var

	mov ax, UNKNOWN
	ret

.is_var:
	; mov si,token
	; call os_print_string
	mov ax, VARIABLE		; Otherwise probably a variable
	ret
	
	
check_token:
	push bx
	mov bx, [prog]
	mov [.tmp], bx
	
	call get_token
	
	mov bx, [.tmp]
	mov [prog], bx
	
	pop bx
	ret
	
	.tmp				dw 0
	
; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII number

is_number:
	cmp al, 48
	jl .not_number
	cmp al, 57
	jg .not_number
	stc
	ret
.not_number:
	clc
	ret


; ------------------------------------------------------------------
; Set carry flag if AL contains ASCII letter

is_letter:
	cmp al, 65
	jl .not_letter
	cmp al, 90
	jg .not_letter
	stc
	ret

.not_letter:
	clc
	ret

os_set_color:
mov dl,[ink_colour]
mov ah,0x01
int 0x61
ret

loc:	;dw 0x9000
;dw 0x6000+(512*FILESIZE)
dw basic_interpreter_end
temp_color: db 0x00

; ------------------------------------------------------------------
; Automatically collect a series of variables and place then in storage
; IN: CX = number of variables, DI = starting address
autofetch_variables:
	push cx
	push di
	call get_token

	cmp ax, VARIABLE
	je .variable

	cmp ax, CHAR
	je .char
	
	cmp ax, NUMBER
	jne .error

	mov si, token
	call os_string_to_int
	
	pop di
	stosw

	pop cx
	loop autofetch_variables
	ret

.variable:
	mov ax, 0
	mov byte al, [token]
	call get_var
	
	pop di
	stosw
	
	pop cx
	loop autofetch_variables
	ret
	
.char:
	mov ax, 0
	mov byte al, [token]
	
	pop di
	stosw
	
	pop cx
	loop autofetch_variables
	ret
	
.error:
	mov si, err_syntax
	jmp error


; Automatically copy a string of numbers into variables
; IN: CX = number of variables, SI = starting address	
autostore_variables:
	push cx
	push si
	call get_token
	
	cmp ax, VARIABLE
	jne .error
	
	pop si
	lodsw
	mov bx, ax
	
	mov ax, 0
	mov al, [token]
	call set_var
	
	pop cx
	loop autostore_variables
	ret
	
.error:
	mov si, err_syntax
	jmp error
	
	
get_string_pointer:
	; OUT: SI = pointer address, CF = set if quote, clear if string
	pusha
	call get_token
	
	cmp ax, QUOTE
	je .quote
	
	cmp ax, STRING_VAR
	jne .error
	
	mov si, string_vars
	mov ax, 128
	mul bx
	add si, ax
	
	mov [.tmp], si
	popa
	mov si, [.tmp]
	clc
	ret
	
.quote:
	mov si, token
	
	mov [.tmp], si
	popa
	mov si, [.tmp]
	stc
	ret
	
.error:
	mov si, err_syntax
	jmp error
	
.tmp					dw 0


; ------------------------------------------------------------------
; Print error message and quit out

error:
	mov ah, 5			; Revert display page
	mov al, 0
	int 10h

	mov byte [work_page], 0
	mov byte [disp_page], 0

	mov dl,[temp_color]
	mov byte [ink_colour],dl
	call os_set_color
	
	cmp byte [graphicsmode], 0
	je textmode_finish
	mov byte [graphicsmode], 0
	call os_text_mode
	textmode_finish:
	
	call os_print_newline
	call os_print_string		; Print error message


	mov si, line_num_starter
	call os_print_string


	; And now print the line number where the error occurred. We do this
	; by working from the start of the program to the current point,
	; counting the number of newline characters along the way

	mov word si, [load_point]
	mov word bx, [prog]
	mov cx, 1

.loop:
	lodsb
	cmp al, 10
	jne .not_newline
	inc cx
.not_newline:
	cmp si, bx
	je .finish
	jmp .loop
.finish:

	mov ax, cx
	call os_int_to_string
	mov si, ax
	call os_print_string

	call os_print_newline
	
	mov si,[prog]
	mov cx,40h
	.print_error_line_loop:
	lodsb
	cmp al,10
	je .print_error_line_newline
	cmp al,13
	je .print_error_line_newline
	mov ah,0Eh
	int 10h
	loop .print_error_line_loop
	jmp .print_error_line_end
	.print_error_line_newline:
	call os_print_newline
	loop .print_error_line_loop
	.print_error_line_end:
	
	call os_wait_for_key
	
	mov word sp, [orig_stack]	; Restore the stack to as it was when BASIC started

	ret				; And finish

	alert_cmd		db "ALERT", 0
	askfile_cmd		db "ASKFILE", 0
	blockif_cmd		db "BLOCKIF", 0
	box_cmd			db "BOX", 0
	boxfilled_cmd		db "BOXFILLED", 0
	break_cmd		db "BREAK", 0
	call_cmd		db "CALL", 0
	case_cmd		db "CASE", 0
	circle_cmd		db "CIRCLE", 0
	clock_cmd		db "CLOCK", 0
	cls_cmd			db "CLS", 0
	cursor_cmd		db "CURSOR", 0
	curschar_cmd		db "CURSCHAR", 0
	curscol_cmd		db "CURSCOL", 0
	curspos_cmd		db "CURSPOS", 0
	delete_cmd		db "DELETE", 0
	do_cmd			db "DO", 0
	else_cmd		db "ELSE", 0
	end_cmd			db "END", 0
	endif_cmd		db "ENDIF", 0
	files_cmd		db "FILES", 0
	flood_cmd		db "FLOOD", 0
	for_cmd 		db "FOR", 0
	getkey_cmd		db "GETKEY", 0
	gosub_cmd		db "GOSUB", 0
	goto_cmd		db "GOTO", 0
	graphicsmode_cmd	db "GRAPHICSMODE", 0
	hline_cmd		db "HLINE", 0
	if_cmd 			db "IF", 0
	include_cmd		db "INCLUDE", 0
	ink_cmd			db "INK", 0
	interface_cmd		db "INTERFACE", 0
	input_cmd 		db "INPUT", 0
	inputbox_cmd		db "INPUTBOX", 0
	left_cmd		db "LEFT", 0
	len_cmd			db "LEN", 0
	line_cmd		db "LINE", 0
	listbox_cmd		db "LISTBOX", 0
	load_cmd		db "LOAD", 0
	locatemouse_cmd		db "LOCATEMOUSE", 0
	lockmouse_cmd		db "LOCKMOUSE", 0
	loop_cmd		db "LOOP", 0
	memory_cmd		db "MEMORY", 0
	mid_cmd			db "MID", 0
	move_cmd 		db "MOVE", 0
	movemouse_cmd		db "MOVEMOUSE", 0
	next_cmd 		db "NEXT", 0
	number_cmd		db "NUMBER", 0
	page_cmd		db "PAGE", 0
	pause_cmd 		db "PAUSE", 0
	peek_cmd		db "PEEK", 0
	peekint_cmd		db "PEEKINT", 0
	plot_cmd		db "PLOT", 0
	point_cmd		db "POINT", 0
	poke_cmd		db "POKE", 0
	pokeint_cmd		db "POKEINT", 0
	polygon_cmd		db "POLYGON", 0
	port_cmd		db "PORT", 0
	print_cmd 		db "PRINT", 0
	question_cmd		db "QUESTION", 0
	rand_cmd		db "RAND", 0
	read_cmd		db "READ", 0
	releasemouse_cmd	db "RELEASEMOUSE", 0
	rem_cmd			db "REM", 0
	rename_cmd		db "RENAME", 0
	return_cmd		db "RETURN", 0
	reverse_cmd		db "REVERSE", 0
	right_cmd		db "RIGHT", 0
	save_cmd		db "SAVE", 0
	serial_cmd		db "SERIAL", 0
	size_cmd		db "SIZE", 0
	sound_cmd 		db "SOUND", 0
	split_cmd		db "SPLIT", 0
	string_cmd		db "STRING", 0
	textmode_cmd		db "TEXTMODE", 0
	trim_cmd		db "TRIM", 0
	usemouse_cmd		db "USEMOUSE", 0
	vline_cmd		db "VLINE", 0
	waitany_cmd		db "WAITANY", 0
	waitkey_cmd		db "WAITKEY", 0
	waitmouse_cmd		db "WAITMOUSE", 0

	and_keyword		db "AND", 0
	then_keyword		db "THEN", 0
	chr_keyword		db "CHR", 0
	hex_keyword		db "HEX", 0
	
	lower_keyword		db "LOWER", 0
	upper_keyword		db "UPPER", 0

	freemem_keyword		db "FREEMEM", 0
	ink_keyword		db "INK", 0
	leftclick_keyword	db "LEFTCLICK", 0
	middleclick_keyword	db "MIDDLECLICK", 0
	progstart_keyword	db "PROGSTART", 0
	ramstart_keyword	db "RAMSTART", 0
	rightclick_keyword	db "RIGHTCLICK", 0
	timer_keyword		db "TIMER", 0
	variables_keyword	db "VARIABLES", 0
	version_keyword		db "VERSION", 0
	
	filename_msg	db "File >> ",0
	;select_msg		db 0x0d,0x0a," Select a file >> ", 0
	
	; Error messages text...

	err_char_in_num		db "Error: char in no.", 0
	err_cmd_unknown		db "Error: unknown command", 0
	;err_divide_by_zero	db "Error: attempt to divide by zero", 0
	err_doloop_maximum	db "Error: DO/LOOP nesting limit", 0
	err_file_notfound	db "Error: file not found", 0
	err_goto_notlabel	db "Error: GOTO or GOSUB label", 0
	err_graphics		db "Error: graphic mode needed", 0
	err_label_notfound	db "Error: label not found", 0
	err_nest_limit		db "Error: FOR or GOSUB nest limit", 0
	err_next		db "Error: NEXT w/o FOR", 0
	err_no_endif		db "Error: BLOCKIF without ENDIF", 0
	err_loop		db "Error: LOOP without DO", 0
	err_print_type		db "Error: PRINT text/variable", 0
	err_polygon_no		db "Error: polygon points", 0
	err_quote_term		db "Error: quotes", 0
	err_return		db "Error: RETURN ", 0
	err_string_range	db "Error: string location", 0
	err_syntax		db "Error: syntax error", 0
	err_break		db "BREAK CALLED", 0

	line_num_starter	db " - line ", 0

	gosub_depth		db 0
	gosub_points		times 10 dw 0	; Points in code to RETURN to

	string_vars		times 1024 db 0	; 8 * 128 byte strings

string_buffer		times 128 db 0
	alt_string_buffer	times 128 db 0
; ------------------------------------------------------------------


; ==================================================================
; DATA SECTION

	orig_stack		dw 0		; Original stack location when BASIC started

	prog			dw 0		; Pointer to current location in BASIC code
	prog_end		dw 0		; Pointer to final byte of BASIC code

	load_point		dw 0

	token_type		db 0		; Type of last token read (eg NUMBER, VARIABLE)
	token			times 255 db 0	; Storage space for the token

vars_loc:
	variables		times 26 dw 0	; Storage space for variables A to Z

	for_variables		times 26 dw 0	; Storage for FOR loops
	for_code_points		times 26 dw 0	; Storage for code positions where FOR loops start
	
	do_loop_store		times 10 dw 0	; Storage for DO loops
	loop_in			db 0		; Loop level

	last_if_true		db 1		; Checking for 'ELSE'

	ink_colour		db 0x31		; Text printing colour
	work_page		db 0		; Page to print to
	disp_page		db 0		; Page to display
	graphicsmode		db 0		; Keeps track of whether the system is in graphics mode

	;FILESIZE equ 22
	;FILESIZE equ basic_interpreter_end/512
	
;times (512*FILESIZE)-($-$$) db 0
;times (512*25)-($-$$) db 0
basic_interpreter_end: