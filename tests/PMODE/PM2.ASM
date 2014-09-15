								; pm2.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	pm2.asm - protected-mode demo code
;	Christopher Giese <geezer[AT]execpc.com>
;
;	Release date 9/28/98. Distribute freely. ABSOLUTELY NO WARRANTY.
;	Assemble with NASM:	nasm -o pm2.com pm2.asm
;
; Demonstrates:
;	- Interrupts/exceptions in protected mode
; Fixes/changes:
;	- IDT now contains true interrupt gates (type 0x8E) instead
;	  of trap gates (type 0x8F)
;	- spin: jmp spin changed to jmp $
;	- Byte 6 of descriptors (flags/limit 19:16) changed from
;	  0xFC to 0xCF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[SECTION .text]
;[ORG 0x100]
org 0x6000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit real mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
; set base of code/data descriptors to CS<<4/DS<<4 (CS=DS)
start:	xor ebx,ebx
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
	mov ax,LINEAR_SEL
	mov gs,ax
; write to text video memory starting at linear address 0xB8000
; (upper left corner of screen)
	mov byte [gs:0xB8000],'H'
	mov byte [gs:0xB8002],'e'
	mov byte [gs:0xB8004],'l'
	mov byte [gs:0xB8006],'l'
	mov byte [gs:0xB8008],'o'
; try an interrupt
	int 0x20
; switch to 16-bit protected mode on your way to real mode
	jmp REAL_CODE_SEL:do_16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	default handler for interrupts/exceptions
;	just puts '!' in upper right corner of screen and freezes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
unhand:	cli
	mov ax,LINEAR_SEL
	mov gs,ax
	mov byte [gs:0xB809E],'!'
	jmp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	handler for INT 0x20
;	prints '20' on second line of screen and returns
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr20:	pusha
	push gs
		mov ax,LINEAR_SEL
		mov gs,ax
		mov byte[gs:0xB80A0],'2'
		mov byte[gs:0xB80A2],'0'
	pop gs
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
	dw 0			; base 0
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
