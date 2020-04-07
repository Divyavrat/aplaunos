; =================================================================
; Blue Jay -- The Mike Operating System kernel
; Copyright (C) 2011 - 2012 Blue Jay Developers -- see LICENSE.TXT
; Copyright (C) 2006 - 2012 MikeOS Developers -- see LICENSE.TXT
;
; Misc OS Functions
; =================================================================

; ------------------------------------------------------------------
; os_pause -- Delay execution for specified 110ms chunks
; IN: AX = 100 millisecond chunks to wait (max delay is 32767,
;     which multiplied by 55ms = 1802 seconds = 30 minutes)

os_pause:
	pusha
	cmp ax, 0
	je .time_up			; If delay = 0 then bail out

	mov cx, 0
	mov [.counter_var], cx		; Zero the counter variable

	mov bx, ax
	mov ax, 0
	mov al, 2			; 2 * 55ms = 110mS
	mul bx				; Multiply by number of 110ms chunks required 
	mov [.orig_req_delay], ax	; Save it

	mov ah, 0
	int 1Ah				; Get tick count	

	mov [.prev_tick_count], dx	; Save it for later comparison

.checkloop:
	mov ah,0
	int 1Ah				; Get tick count again

	cmp [.prev_tick_count], dx	; Compare with previous tick count

	jne .up_date			; If it's changed check it    		
	jmp .checkloop			; Otherwise wait some more

.time_up:
	popa
	ret

.up_date:
	mov ax, [.counter_var]		; Inc counter_var
	inc ax
	mov [.counter_var], ax

	cmp ax, [.orig_req_delay]	; Is counter_var = required delay?
	jge .time_up			; Yes, so bail out

	mov [.prev_tick_count], dx	; No, so update .prev_tick_count 

	jmp .checkloop			; And go wait some more


	.orig_req_delay		dw	0
	.counter_var		dw	0
	.prev_tick_count	dw	0


; -----------------------------------------------------------------
; os_get_api_version -- Return current version of Blue Jy API
; IN: Nothing; OUT: AL = API version number

os_get_api_version:
	mov al, BJ_API_VER
	ret


; -----------------------------------------------------------------
; os_get_int_handler -- Get the segment:offset of an interrupt handler
; IN: AX = int number; OUT: ES:BX = contents of handler location

os_get_int_handler:
	push ax				; A pusha won't allow parameter return
	push cx
	push ds

	and ax, 0FFh			; Ensure number is within range
	mov cl, 4			; Beginning address = base + 4 * number
	mul cl				; Base = 0000, 4 bytes per entry
	mov si, ax

	xor ax, ax			; Interrupt table is in segment 0
	mov ds, ax

	mov bx, [ds:si]			; Get interrupt service address
	mov ax, [ds:si+2]		; Get interrupt service segment
	mov es, ax

	pop ds
	pop cx
	pop ax

	ret


; -----------------------------------------------------------------
; os_modify_int_handler -- Change location of interrupt handler
; IN: CX = int number, SI = handler location

os_modify_int_handler:
	pusha

	cli

	mov dx, es			; Store original ES

	xor ax, ax			; Clear AX for new ES value
	mov es, ax

	mov al, cl			; Move supplied int into AL

	mov bl, 4			; Multiply by four to get position
	mul bl				; (Interrupt table = 4 byte sections)
	mov bx, ax

	mov [es:bx], si			; First store offset
	add bx, 2

	mov ax, 0x2000			; Then segment of our handler
	mov [es:bx], ax

	mov es, dx			; Finally, restore data segment

	sti

	popa
	ret


; -----------------------------------------------------------------
; os_fatal_error -- Display error message, take keypress, and restart OS
; IN: AX = error message string location

os_fatal_error:
	mov bx, ax			; Store string location for now

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	pusha
	mov ah, 09h			; Draw red bar at top
	xor bh, bh
	mov cx, 240
	mov bl, 01001111b
	mov al, ' '
	int 10h
	popa

	mov dh, 0
	mov dl, 0
	call os_move_cursor

	mov si, .msg_inform		; Inform of fatal error
	call os_print_string

	mov si, bx			; Program-supplied error message
	call os_print_string

	call os_print_newline

	mov si, .msg_prompt		; Restart prompt
	call os_print_string

	xor ax, ax
	mov ah, 00			; BIOS call to wait for key
	int 16h

	jmp os_int_reboot


	.msg_inform		db '>>> FATAL OPERATING SYSTEM ERROR', 13, 10, 0
	.msg_prompt		db 'Press a key to restart Blue Jay...', 0


; -----------------------------------------------------------------
; os_get_api_ver_string -- Return current version of Blue Jay API
; version in a string format
; IN: Nothing; OUT: SI = API version number

os_get_api_ver_string:
	mov si, .api_msg
	ret

.api_msg	db BJ_API_VER2, 0