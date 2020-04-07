; ---------------------------------

mouse_wait_0:
	mov cx, 65000
	mov dx, 0x64
.wait:
	in al, dx
	bt ax, 0
	jc .okay
	loop .wait
.okay:
	ret
	
; ---------------------------------

mouse_wait_1:
	mov cx, 65000
	mov dx, 0x64
.wait:
	in al, dx
	bt ax, 1
	jnc .okay
	loop .wait
.okay:
	ret
	
; -----------------------------------------------------
; mouse_write --- write a value to the mouse controller
; IN: AH = byte to send

mouse_write:
	; Wait to be able to send a command
	call mouse_wait_1
	; Tell the mouse we are sending a command
	mov al, 0xD4
	out 0x64, al
	; Wait for the final part
	call mouse_wait_1
	; Finally write
	mov al, ah
	out 0x60, al
	ret
	
; -----------------------------------------------------
; mouse_read --- read a value from the mouse controller
; OUT: AL = value

mouse_read:
	; Get the response from the mouse
	call mouse_wait_0
	in al, 0x60
	ret
	
; -----------------------------------------------------
; os_mouse_setup --- setup the mouse driver
; IN/OUT: none

os_mouse_setup:
	pusha
	
	; Enable the auxiliary mouse device
	call mouse_wait_1
	mov al, 0xA8
	out 0x64, al
	
	; Enable the interrupts
	call mouse_wait_1
	mov al, 0x20
	out 0x64, al
	call mouse_wait_0
	in al, 0x60
	or al, 0x02
	mov bl, al
	call mouse_wait_1
	mov al, 0x60
	out 0x64, al
	call mouse_wait_1
	mov al, bl
	out 0x60, al
	
	; Tell the mouse to use default settings
	mov ah, 0xF6
	call mouse_write
	call mouse_read		; Acknowledge
	
	; Enable the mouse
	mov ah, 0xF4
	call mouse_write
	call mouse_read		; Acknowledge
	
	; Setup the mouse handler
	cli
	push es
	mov ax, 0x0000
	mov es, ax
	mov word [es:0x01D0], mouse_handler
	mov word [es:0x01D2], 0x1000
	pop es
	sti
	
	popa
	jmp os_return

	
; ----------------------------------------
; TachyonOS Mouse Driver
	
mouse_handler:
	cli

	pusha
	push ds
	
	mov ax, 0x1000
	mov ds, ax

	cmp byte [.number], 0
	je .data_byte
	
	cmp byte [.number], 1
	je .x_byte
	
	cmp byte [.number], 2
	je .y_byte

.data_byte:
	in al, 0x60
 	mov [mouse_data], al
 	
;  	bt ax, 3
;  	jc .alignment
 	
 	mov byte [.number], 1
 	jmp .finish
 	
.alignment:
	mov byte [.number], 0
	jmp .finish
 	
.x_byte:
	in al, 0x60
	mov [mouse_delta_x], al
	mov byte [.number], 2
	jmp .finish
	
.y_byte:
	in al, 0x60
	mov [mouse_delta_y], al
	mov byte [.number], 0

; Now we have the entire packet it is time to process its data.
; We want to figure out the new X and Y co-ordinents and which buttons are pressed.
	
.process_packet:
	mov ax, 0
	mov bx, 0
	mov bl, [mouse_data]
	test bx, 0x00C0			; If x-overflow or y-overflow is set ignore packet
	jnz .finish

	; Mark there has been a change in mouse position
	mov byte [mouse_changed], 1
	
	; Get the movement values
	mov cx, 0
	mov cl, [mouse_delta_x]
	mov dx, 0
	mov dl, [mouse_delta_y]
	
	; Check data byte for the X sign flag
	bt bx, 4
	jc .negative_delta_x

	; Add the movement speed to the raw position
	add [mouse_x_raw], cx
	jmp .scale_x
	
.negative_delta_x:
	xor cl, 0xFF
	inc cl

	cmp cx, [mouse_x_raw]
	jg .zero_x
	
	sub [mouse_x_raw], cx
	
.scale_x:
	; Scale raw position to find the cursor position
	mov cx, [mouse_x_raw]
	
	mov ax, cx
	mov cl, [mouse_x_scale]
	shr ax, cl
	mov cx, ax
	mov [mouse_x_position], cx
	
.check_x_boundries:
	cmp cx, [mouse_x_minimum]
	jl .fix_x_minimum
	
	cmp cx, [mouse_x_limit]
	jg .fix_x_limit
	
.find_y_position:
	bt bx, 5			; Check data byte for the Y sign flag
	jc .negative_delta_y
	
	cmp dx, [mouse_y_raw]
	jg .zero_y
	
	sub [mouse_y_raw], dx
	jmp .scale_y
	
.negative_delta_y:
	xor dl, 0xFF
	inc dl
		
	add [mouse_y_raw], dx
	
.scale_y:
	mov dx, [mouse_y_raw]
	
	mov cl, [mouse_y_scale]
	shr dx, cl
	mov [mouse_y_position], dx
	
.check_y_boundries:
	cmp dx, [mouse_y_minimum]
	jl .fix_y_minimum
	
	cmp dx, [mouse_y_limit]
	jg .fix_y_limit
	
.check_buttons:
	bt bx, 0
	jc .left_mouse_pressed
	
	mov byte [mouse_button_left], 0
	
	bt bx, 2
	jc .middle_mouse_pressed
	
	mov byte [mouse_button_middle], 0
	
	bt bx, 1
	jc .right_mouse_pressed
	
	mov byte [mouse_button_right], 0
	
.finish:
	mov al, 0x20			; End Of Interrupt (EOI) command
	out 0x20, al			; Send EOI to master PIC
	out 0xa0, al			; Send EOI to slave PIC
	
	pop ds
	popa
	sti
	iret
	
	.number				db 0
	
.zero_x:
	mov word [mouse_x_raw], 0
	jmp .scale_x
	
.fix_x_minimum:
	mov cx, [mouse_x_minimum]
	mov [mouse_x_position], cx
	
	mov ax, cx
	mov cl, [mouse_x_scale]
	shl ax, cl
	mov [mouse_x_raw], ax

	jmp .find_y_position
	
.fix_x_limit:
	mov cx, [mouse_x_limit]
	mov [mouse_x_position], cx
	
	mov ax, cx
	mov cl, [mouse_x_scale]
	shl ax, cl
	mov [mouse_x_raw], ax
	
	jmp .find_y_position
	
.zero_y:
	mov word [mouse_y_raw], 0
	jmp .scale_y
	
.fix_y_minimum:
	mov dx, [mouse_y_minimum]
	mov [mouse_y_position], dx
	
	mov cl, [mouse_y_scale]
	shl dx, cl
	mov [mouse_y_raw], dx
	
	jmp .check_buttons
	
.fix_y_limit:
	mov dx, [mouse_y_limit]
	mov [mouse_y_position], dx
	
	mov cl, [mouse_y_scale]
	shl dx, cl
	mov [mouse_y_raw], dx
	
	jmp .check_buttons
	
.left_mouse_pressed:
	mov byte [mouse_button_left], 1
	
	bt bx, 2
	jc .middle_mouse_pressed
	
	mov byte [mouse_button_middle], 0
	
	bt bx, 1
	jc .right_mouse_pressed
	
	mov byte [mouse_button_right], 0
	
	jmp .finish
	
.middle_mouse_pressed:
	mov byte [mouse_button_middle], 1
	
	bt bx, 1
	jc .right_mouse_pressed
	
	mov byte [mouse_button_right], 0
	
	jmp .finish
	
.right_mouse_pressed:
	mov byte [mouse_button_right], 1
	
	jmp .finish
	
	
; --------------------------------------------------
; os_mouse_locate -- return the mouse co-ordinents
; IN: none
; OUT: CX = Mouse X, DX = Mouse Y
	
os_mouse_locate:
	mov cx, [gs:mouse_x_position]
	mov dx, [gs:mouse_y_position]
	
	jmp os_return

	
; --------------------------------------------------
; os_mouse_move -- set the mouse co-ordinents
; IN: CX = Mouse X, DX = Mouse Y
; OUT: none

os_mouse_move:
	pusha
	
	mov ax, cx
	mov [gs:mouse_x_position], ax
	mov [gs:mouse_y_position], dx
	
	mov cl, [gs:mouse_x_scale]
	shl ax, cl
	mov [gs:mouse_x_raw], ax
	
	mov cl, [gs:mouse_y_scale]
	shl dx, cl
	mov [gs:mouse_y_raw], dx
	
	popa
	jmp os_return


; --------------------------------------------------
; os_mouse_show -- shows the cursor at current position
; IN: none
; OUT: none

os_mouse_show:
	push ax
	mov ax, 0x1000
	mov ds, ax
	
	cmp byte [mouse_cursor_on], 1
	je .already_on
	
	mov ax, [mouse_x_position]
	mov [mouse_cursor_x], ax
	
	mov ax, [mouse_y_position]
	mov [mouse_cursor_y], ax
	
	call mouse_toggle
	
	mov byte [mouse_cursor_on], 1
	
	pop ax
	
.already_on:
	jmp os_return
	

; --------------------------------------------------
; os_mouse_hide -- hides the cursor
; IN: none
; OUT: none
	
os_mouse_hide:
	push ax
	mov ax, 0x1000
	mov ds, ax
	pop ax

	cmp byte [mouse_cursor_on], 0
	je .already_off
	
	call mouse_toggle
	
	mov byte [mouse_cursor_on], 0
	
.already_off:
	jmp os_return
	

mouse_toggle:
	pusha
	
	; Move the cursor into mouse position
	mov ah, 02h
	mov bh, 0
	mov dh, [mouse_cursor_y]
	mov dl, [mouse_cursor_x]
	int 10h
	
	; Find the colour of the character
	mov ah, 08h
	mov bh, 0
	int 10h
	
	; Invert it to get its opposite
	not ah
	
	; Display new character
	mov bl, ah
	mov ah, 09h
	mov bh, 0
	mov cx, 1
	int 10h
	
	popa
	ret

; --------------------------------------------------
; os_mouse_range -- sets the range maximum and 
;	minimum positions for mouse movement
; IN: AX = min X, BX = min Y, CX = max X, DX = max Y
; OUT: none

os_mouse_range:
	mov [gs:mouse_x_minimum], ax
	mov [gs:mouse_y_minimum], bx
	mov [gs:mouse_x_limit], cx
	mov [gs:mouse_y_limit], dx
	
	jmp os_return
	
	
; --------------------------------------------------
; os_mouse_wait -- waits for a mouse event
; IN: none
; OUT: none

os_mouse_wait:
	mov byte [gs:mouse_changed], 0
	
.wait:
	hlt
	cmp byte [gs:mouse_changed], 1
	je .done
	
	jmp .wait

.done:
	jmp os_return

	
; --------------------------------------------------
; os_mouse_anyclick -- check if any mouse button is pressed
; IN: none
; OUT: none

os_mouse_anyclick:
	cmp byte [gs:mouse_button_left], 1
	je .click
	
	cmp byte [gs:mouse_button_middle], 1
	je .click
	
	cmp byte [gs:mouse_button_right], 1
	je .click
	
	clc
	jmp os_return
	
.click:
	stc
	jmp os_return
	

; --------------------------------------------------
; os_mouse_leftclick -- checks if the left mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

os_mouse_leftclick:
	cmp byte [gs:mouse_button_left], 1
	je .pressed
	
	clc
	jmp os_return
	
.pressed:
	stc
	jmp os_return


; --------------------------------------------------
; os_mouse_middleclick -- checks if the middle mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

os_mouse_middleclick:
	cmp byte [gs:mouse_button_middle], 1
	je .pressed
	
	clc
	jmp os_return
	
.pressed:
	stc
	jmp os_return
	
	
; --------------------------------------------------
; os_mouse_rightclick -- checks if the right mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

os_mouse_rightclick:
	cmp byte [gs:mouse_button_right], 1
	je .pressed
	
	clc
	jmp os_return
	
.pressed:
	stc
	jmp os_return
	
	
; ------------------------------------------------------------------
; os_input_wait -- waits for mouse or keyboard input
; IN: none
; OUT: CF = set if keyboard, clear if mouse

os_input_wait:
	push ax
	
	mov byte [gs:mouse_changed], 0
	
.input_wait:
	; Check with BIOS if there is a keyboard key available
	mov ah, 11h
	int 16h
	jnz .keyboard_input
	
	; Check with mouse driver if the mouse has sent anything
	cmp byte [gs:mouse_changed], 1
	je .mouse_input
	
	hlt
	
	jmp .input_wait
	
.keyboard_input:
	pop ax
	stc
	jmp os_return
	
.mouse_input:
	pop ax
	clc
	jmp os_return
	
	
; ------------------------------------------------------------------
; os_mouse_scale -- scale mouse movment speed as 1:2^X
; IN: DL = mouse X scale, DH = mouse Y scale

os_mouse_scale:
	mov [gs:mouse_x_scale], dl
	mov [gs:mouse_y_scale], dh
	jmp os_return


mouse_data				db 0
mouse_delta_x				db 0
mouse_delta_y				db 0
mouse_x_raw				dw 0
mouse_y_raw				dw 0
mouse_x_scale				db 0
mouse_y_scale				db 0
mouse_x_position			dw 0
mouse_y_position			dw 0
mouse_x_minimum				dw 0
mouse_x_limit				dw 0
mouse_y_minimum				dw 0
mouse_y_limit				dw 0
mouse_button_left			db 0
mouse_button_middle			db 0
mouse_button_right			db 0
mouse_cursor_on				db 0
mouse_cursor_x				dw 0
mouse_cursor_y				dw 0
mouse_changed				db 0