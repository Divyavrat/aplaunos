								; pm4.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	pm4.asm - protected-mode demo code
;	Christopher Giese <geezer[AT]execpc.com>
;
;	Release date 9/28/98. Distribute freely. ABSOLUTELY NO WARRANTY.
;	Assemble with NASM:	nasm -o pm4.com pm4.asm
;
; Demonstrates:
;	- CPU detection (386 or better)
;	- Validation in software interrupt handler
;Fixes/changes:
;	- IDT now contains true interrupt gates (type 0x8E) instead
;	  of trap gates (type 0x8F)
;	- spin: jmp spin changed to jmp $
;	- Byte 6 of descriptors (flags/limit 19:16) changed from
;	  0xFC to 0xCF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[SECTION .text]
org 0x6000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit real mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
; check for protected or V86 mode. Code from Freedows '98 ldr_asm.asm
; Copyright (C) 1997 Joachim Breitsprecher <j.breitsprecher@schwaben.de>
start:	smsw ax
	test al,1		; look at PE bit of MSW (CR0)
	je cpu_chk
	mov ax,0x4C01		; exit to DOS with error code 1
	int 0x21

; determine CPU type. Code from Freedows '98 ldr_asm.asm
; Copyright (C) 1997 Joachim Breitsprecher <j.breitsprecher@schwaben.de>
; I (Chris Giese) have not tested this code with 8088/'286 systems.
cpu_chk:cli
	pushf
		pushf
		pop ax
		mov bx,ax	; ax=bx=flags
		and ax,0x0FFF	; ax=flags & 0x0FFF
		or bx,0x7000	; bx=flags | 0x7000
		push ax		; try clearing b15:b12 of flags
		popf
		pushf
		pop ax		; ax=result
		push bx		; try setting b14:b12 of flags
		popf
		pushf
		pop bx		; bx=result
	popf
	and ax,0xF000
	cmp ax,0xF000
	je not_386		; 80(1)86/88 sets b15:b12
	test bx,0x7000		; 80286 clears b14:b12
	jne start2
not_386:mov ax,0x4C02		; exit to DOS with error code 2
	int 0x21

; set base of code/data descriptors to CS<<4/DS<<4 (CS=DS)
start2:	xor ebx,ebx
	mov bx,cs		; BX=segment
	shl ebx,4		; EBX=linear address of segment base
	mov eax,ebx
	mov [gdt1 + 2],ax
	mov [gdt2 + 2],ax
	mov [gdt3 + 2],ax
	shr eax,16
	mov [gdt1 + 4],al
	mov [gdt2 + 4],al
	mov [gdt3 + 4],al
	mov [gdt1 + 7],ah
	mov [gdt2 + 7],ah
	mov [gdt3 + 7],ah
; point gdtr to the gdt, point idtr to the idt
	add ebx,gdt		; EBX=linear address of gdt
	mov [gdtr + 2],ebx
	add ebx,idt - gdt	; EBX=linear address of idt
	mov [idtr + 2],ebx
; disable interrupts
	cli
; load GDT and IDT for full protected mode
	lgdt [gdtr]
	lidt [idtr]
; save real-mode CS in BP
	mov bp,cs
; set PE [protected mode enable] bit and go
	mov eax,cr0
	or al,1
	mov cr0,eax
	jmp SYS_CODE_SEL:do_pm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	32-bit protected mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]
do_pm:	mov ax,SYS_DATA_SEL
	mov ds,ax		; not segments anymore: SELECTORS
	mov ss,ax
	nop
	mov es,ax
	mov fs,ax
	mov gs,ax
; say hello!
	lea esi,[hi_msg]
	call wrstr
; try an interrupt
	int 0x20
; switch to 16-bit protected mode on your way to real mode
	jmp REAL_CODE_SEL:do_16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	character-output video routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wrch:	push gs
	push ecx
	push ebx
	push eax
		mov ax,LINEAR_SEL
		mov gs,ax
; (Y * 80 + X) * 2 --> EAX
		movzx eax,byte [CsrY]
		mov cl,80
		mul cl
		add al,[CsrX]
		adc ah,0
		shl eax,1
; EAX + 0xB8000 --> EBX; store char
		lea ebx,[eax + 0xB8000]
		pop eax
		push eax
		mov [gs:ebx],al
; advance cursor
		mov cx,[CsrX]
		inc cl
		cmp cl,80	; cursor off right side of screen?
		jb wrch2
		xor cl,cl	; yes, wrap to left side...
		inc ch		; ...and down one line
		cmp ch,25	; cursor off bottom of screen?
		jb wrch2
		xor ch,ch	; yes, wrap to top left corner (no scroll)
wrch2:		mov [CsrX],cx
	pop eax
	pop ebx
	pop ecx
	pop gs
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	string-output video routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wrstr:	push esi
	push eax
		cld
		jmp wrstr2
wrstr1:		call wrch
wrstr2:		lodsb
		or al,al
		jne wrstr1
	pop eax
	pop esi
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	default handler for interrupts/exceptions
;	prints " Unhandled interrupt!"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
unhand:	cli
	lea esi,[unhand_msg]
	call wrstr
	jmp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	handler for INT 0x20
;	validates interrupt and prints " Hey, INT 0x20 occured!"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr20:	pusha
		mov ebx,[32+esp]	; get stacked EIP
; did we get here because of INT 0x20 instruction?
		cmp word [ebx - 2],0x20CD
		jne unhand		; no, goto unhand
		lea esi,[isr20_msg]	; yes, print a message and return
		call wrstr
	popa
	iret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit protected mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
; switch to 16-bit stack and data
do_16:	mov ax,REAL_DATA_SEL
	mov ds,ax
	mov ss,ax
	nop
; push real-mode CS:IP
	lea bx,[do_rm]
	push bp
	push bx
; clear PE [protected mode enable] bit and return to real mode
		mov eax,cr0
		and al,0xFE
		mov cr0,eax
		retf		; jumps to do_rm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit real mode again
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; restore real-mode segment register values
do_rm:	mov ax,cs
	mov ds,ax
	mov ss,ax
	nop
	mov es,ax
	mov fs,ax
	mov gs,ax
; point to real-mode IDTR
	lidt [ridtr]
; re-enable interrupts
	sti
; exit to DOS with errorlevel 0
	mov ax,0x4C00
	int 0x21
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CsrX:	db 0
CsrY:	db 0

hi_msg:	db "Hello, how's it going?", 0

unhand_msg:
	db " Unhandled interrupt!", 0

isr20_msg:
	db " Hey, INT 0x20 occured!", 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit limit/32-bit linear base address of GDT and IDT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gdtr:	dw gdt_end - gdt - 1	; GDT limit
	dd gdt			; linear, physical address of GDT

idtr:	dw idt_end - idt - 1	; IDT limit
	dd idt			; linear, physical address of IDT

; an IDTR 'appropriate' for real mode
ridtr:	dw 0xFFFF		; limit=0xFFFF
	dd 0			; base=0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	global descriptor table (GDT)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; null descriptor
gdt:	dw 0			; limit 15:0
	dw 0			; base 15:0
	db 0			; base 23:16
	db 0			; type
	db 0			; limit 19:16, flags
	db 0			; base 31:24
; linear data segment descriptor
LINEAR_SEL	equ	$-gdt
	dw 0xFFFF		; limit 0xFFFFF
	dw 0			; base for this one is always 0
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
	db 0xCF			; page-granular, 32-bit
	db 0
; code segment descriptor
SYS_CODE_SEL	equ	$-gdt
gdt1:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
	db 0xCF
	db 0
; data segment descriptor
SYS_DATA_SEL	equ	$-gdt
gdt2:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
	db 0xCF
	db 0
; code segment descriptor that is 'appropriate' for real mode
; (16-bit, limit=0xFFFF)
REAL_CODE_SEL	equ	$-gdt
gdt3:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
	db 0			; byte-granular, 16-bit
	db 0
; data segment descriptor that is 'appropriate' for real mode
; (16-bit, limit=0xFFFF)
REAL_DATA_SEL	equ	$-gdt
gdt4:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
	db 0			; byte-granular, 16-bit
	db 0
gdt_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	interrupt descriptor table (IDT)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 32 reserved interrupts:
idt:	dw unhand		; entry point 15:0
	dw SYS_CODE_SEL		; selector
	db 0			; word count
	db 0x8E			; type (32-bit Ring 0 interrupt gate)
	dw 0			; entry point 31:16 (XXX - unhand >> 16)

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw unhand
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0
; user interrupt handler
	dw isr20
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0
idt_end:
