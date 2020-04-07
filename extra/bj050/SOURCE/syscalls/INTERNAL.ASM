; =================================================================
; Blue Jay -- The Mike Operating System kernel
; Copyright (C) 2011 - 2012 Blue Jay Developers -- see LICENSE.TXT
; Copyright (C) 2006 - 2012 MikeOS Developers -- see LICENSE.TXT
;
; Internal OS Routines -- Not accessible to user programs
; =================================================================

; -----------------------------------------------------------------
; os_execute_program -- Run code loaded at 100h in RAM (current CS)
; IN: BX = 1 if screen is to be cleared first, otherwise 0
; OUT: Nothing (registers may be corrupt)

os_execute_program:
	cmp bx, 1
	jne .run_program

	call os_clear_screen


.run_program:

	; The following four lines set up a very basic Program Segment Prefix,
	; aka PSP, which provides some information for DOS programs. For
	; instance, CD 20 = 'int 20h', or 'return to DOS' -- a program can
	; use this code to quit

	mov byte [0], 0xCD		; int 20h
	mov byte [1], 0x20
	mov byte [2], 0xA0		; Always 0xA000 for COM executables
	mov byte [3], 0x00


	pusha                           ; Save all registers and stack pointer
	push ds
	push es
	mov [.mainstack], sp
	xor ax, ax			; Clear registers to be DOS compatible
	xor bx, bx
	xor cx, cx
	xor dx, dx
	xor si, si
	xor di, di
	xor bp, bp
	mov byte [now_run_a_program], 1

	call 0x0100			; Jump to newly-loaded program!

.end_the_program:			; End of the program run
	mov byte [now_run_a_program], 0
	mov sp, [.mainstack]		; Restore stack, segment and
	pop es				; common registers
	pop ds
	popa
	clc

	ret


        .mainstack dw 0
         now_run_a_program db 0



; =================================================================
; INTERNAL OS ROUTINES -- Not accessible to user programs

; -----------------------------------------------------------------
; Reboot machine via keyboard controller

os_int_reboot:
	; XXX -- We should check that keyboard buffer is empty first
	mov al, 0xFE
	out 0x64, al


; -----------------------------------------------------------------
; Reset floppy drive

os_int_reset_floppy:
	push ax
	push dx
	xor ax, ax
	mov dl, 0
	stc
	int 13h
	pop dx
	pop ax
	ret


; -----------------------------------------------------------------
; Convert floppy sector from logical to physical

os_int_l2hts:		; Calculate head, track and sector settings for int 13h
			; IN: AX = logical sector; OUT: correct regs for int 13h
	push bx
	push ax

	mov bx, ax			; Save logical sector

	xor dx, dx			; First the sector
	div word [.sectors_per_track]
	add dl, 01h			; Physical sectors start at 1
	mov cl, dl			; Sectors belong in CL for int 13h
	mov ax, bx

	xor dx, dx			; Now calculate the head
	div word [.sectors_per_track]
	xor dx, dx
	div word [.sides]
	mov dh, dl			; Head/side
	mov ch, al			; Track

	pop ax
	pop bx

	mov dl, 0			; Boot device = 0

	ret


	.sectors_per_track	dw 18	; Floppy disc info
	.sides			dw 2


; =================================================================

