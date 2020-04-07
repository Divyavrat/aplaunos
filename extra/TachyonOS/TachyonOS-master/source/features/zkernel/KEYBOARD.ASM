; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Based on the MikeOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; KEYBOARD HANDLING ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_wait_for_key -- Waits for keypress and returns key
; IN: Nothing; OUT: AX = key pressed, other regs preserved
os_wait_for_key:
	pusha
	sti
	
.wait_for_key:
	mov ax, 0			; check for extended keypress
	mov ah, 11h
	int 16h
	
	jz .no_key			; if there is no key halt to save power until something happens
	
	mov ax, 0			; if there is one, find the key and return it
	mov ah, 10h
	int 16h
	
	mov [gs:.tmp_key], ax
	popa
	mov ax, [gs:.tmp_key]
	jmp os_return
	
.no_key:
	hlt

	jmp .wait_for_key
	
	.tmp_key			dw 0

; ------------------------------------------------------------------
; os_check_for_key -- Scans keyboard for input, but doesn't wait
; IN: Nothing; OUT: AX = 0 if no key pressed, otherwise scan code

os_check_for_key:
	pusha

	mov ax, 0
	mov ah, 1			; BIOS call to check for key
	int 16h

	jz .nokey			; If no key, skip to end

	mov ax, 0			; Otherwise get it from buffer
	int 16h

	mov [gs:.tmp_buf], ax		; Store resulting keypress

	popa				; But restore all other regs
	mov ax, [gs:.tmp_buf]
	jmp os_return

.nokey:
	popa
	mov ax, 0			; Zero result if no key pressed
	jmp os_return


	.tmp_buf	dw 0

	
; ------------------------------------------------------------------
; os_check_for_extkey -- Similar to os_check_for_key but gets extended key presses
; IN: Nothing; OUT: AX = 0 if no key pressed, otherwise scan code

os_check_for_extkey:
	pusha

	mov ah, 11h			; BIOS call to check for key
	int 16h

	jz .nokey			; If no key, skip to end

	mov ax, 10h			; Otherwise get it from buffer
	int 16h

	mov [gs:.tmp_buf], ax		; Store resulting keypress

	popa				; But restore all other regs
	mov ax, [gs:.tmp_buf]
	jmp os_return

.nokey:
	popa
	mov ax, 0			; Zero result if no key pressed
	jmp os_return


	.tmp_buf	dw 0

; ==================================================================

