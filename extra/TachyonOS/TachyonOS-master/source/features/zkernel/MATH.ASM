; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Based on the MikeOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; MATH ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_seed_random -- Seed the random number generator based on clock
; IN: Nothing; OUT: Nothing (registers preserved)

os_seed_random:
	push bx
	push ax

	mov bx, 0
	mov al, 0x02			; Minute
	out 0x70, al
	in al, 0x71

	mov bl, al
	shl bx, 8
	mov al, 0			; Second
	out 0x70, al
	in al, 0x71
	mov bl, al

	mov [gs:os_random_seed], bx	; Seed will be something like 0x4435 (if it
					; were 44 minutes and 35 seconds after the hour)
	pop ax
	pop bx
	jmp os_return


	os_random_seed	dw 0


; ------------------------------------------------------------------
; os_get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer

os_get_random:
	push dx
	push bx
	push ax

	sub bx, ax			; We want a number between 0 and (high-low)
	call .generate_random
	mov dx, bx
	add dx, 1
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax			; Add the low offset back
	jmp os_return


.generate_random:
	push dx
	push bx

	mov ax, [gs:os_random_seed]
	mov dx, 0x7383			; The magic number (random.org)
	mul dx				; DX:AX = AX * DX
	mov [gs:os_random_seed], ax

	pop bx
 	pop dx
	ret


; ------------------------------------------------------------------
; os_bcd_to_int -- Converts binary coded decimal number to an integer
; IN: AL = BCD number; OUT: AX = integer value

os_bcd_to_int:
	pusha

	mov bl, al			; Store entire number for now

	and ax, 0Fh			; Zero-out high bits
	mov cx, ax			; CH/CL = lower BCD number, zero extended

	shr bl, 4			; Move higher BCD number into lower bits, zero fill msb
	mov al, 10
	mul bl				; AX = 10 * BL

	add ax, cx			; Add lower BCD to 10*higher
	mov [gs:.tmp], ax

	popa
	mov ax, [gs:.tmp]		; And return it in AX!
	jmp os_return


	.tmp	dw 0


; ------------------------------------------------------------------
; os_long_int_negate -- Multiply value in DX:AX by -1
; IN: DX:AX = long integer; OUT: DX:AX = -(initial DX:AX)

os_long_int_negate:
	neg ax
	adc dx, 0
	neg dx
	jmp os_return


; ------------------------------------------------------------------
; os_square_root
; IN: AX = source number
; OUT: AX = square root of source

os_square_root:
	cmp ax, 0			; If the number is zero don't change anything
	je .zero
	
	cmp ax, 32765			; Maximum reliable number
	jge .zero
	
	pusha

	mov [.tmp], ax
	
	mov bx, 1			; Start trying at one

.division:
	mov dx, 0			; Load the number into DX:AX
	mov ax, [.tmp]
	div bx				; Divide by the guess number
	
	cmp bx, ax			; If the result is the same as the dividend we have found the square root
	je .found_root

	add ax, 2			; If an inexact number then the result will be off by one or two, so return the closest integer root i.e, 17 / 5 = 4
	cmp ax, bx
	jle .found_inexact
	
	inc bx				; If not increase the guess and try again
	jmp .division
	
.found_root:
	mov [.tmp], ax
	popa
	mov ax, [.tmp]
	jmp os_return
	
.found_inexact:
	dec bx
	mov [.tmp], ax
	popa
	mov ax, [.tmp]
	jmp os_return
	
.zero:
	jmp os_return
	
.tmp					dw 0

	
	
	
; ==================================================================

