; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Based on the MikeOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXTs
;
; PC SPEAKER SOUND ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_speaker_freq -- Play a specified frequency throught the PC Speaker until os_speaker_off
; IN: AX = note frequency; OUT: Nothing (registers preserved)

os_speaker_freq:
	pusha
	
	mov bx, ax
	
	cmp ax, 20			; don't play if the input frequency is not too low (causing divide errors)
	jl .skip_sound
	
	mov dx, 18			; frequency of the PIT is 1,193,182 Hz, load into DX:AX
	mov ax, 13534	
	div bx				; divide by requested frequency to get the divisor
	mov bx, ax
	
	mov al, 182			; tell the PIT we're about to send a new divisor
	out 43h, al
	
	mov ax, bx			; send the divisor we got, low byte then high byte
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; connect the PC speaker
	or al, 03h
	out 61h, al

.skip_sound:
	popa
	jmp os_return


; ------------------------------------------------------------------
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency; OUT: Nothing (registers preserved)

os_speaker_tone:
	pusha

	mov cx, ax			; Store note value for now

	mov al, 182
	out 43h, al
	mov ax, cx			; Set up frequency
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; Switch PC speaker on
	or al, 03h
	out 61h, al

	popa
	jmp os_return


; ------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN/OUT: Nothing (registers preserved)

os_speaker_off:
	pusha

	in al, 61h
	and al, 0FCh
	out 61h, al

	popa
	jmp os_return


; ==================================================================

