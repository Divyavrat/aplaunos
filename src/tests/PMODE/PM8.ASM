								; pm8.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	pm8.asm - protected-mode demo code
;	Christopher Giese <geezer[AT]execpc.com>
;
;	Release date 9/28/98. Distribute freely. ABSOLUTELY NO WARRANTY.
;	Assemble with NASM:	nasm -o pm8.com pm8.asm
;
; Demonstrates:
;	- Two ring 0 tasks preemptively multitasked via timer interrupt.
; Fixes/changes:
;	- IDT now contains true interrupt gates (type 0x8E) instead
;	  of trap gates (type 0x8F)
;	- Gave task1 its own stack and enlarged stacks to prevent task1
;	  dying (XXX - one task still dies when run on 486SX system).
;	- Byte 6 of descriptors (flags/limit 19:16) changed from
;	  0xFC to 0xCF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[SECTION .text]
org 0x6000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit real mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
; set base of code/data descriptors to CS<<4/DS<<4 (CS=DS)
	xor ebx,ebx
	mov bx,cs		; EBX=segment
	shl ebx,4		;	<< 4
	lea eax,[ebx]		; EAX=linear address of segment base
	mov [gdt2 + 2],ax
	mov [gdt3 + 2],ax
	mov [gdt4 + 2],ax
	mov [gdt5 + 2],ax
	shr eax,16
	mov [gdt2 + 4],al
	mov [gdt3 + 4],al
	mov [gdt4 + 4],al
	mov [gdt5 + 4],al
	mov [gdt2 + 7],ah
	mov [gdt3 + 7],ah
	mov [gdt4 + 7],ah
	mov [gdt5 + 7],ah
; fix up TSS entries, too
	lea eax,[ebx + stss]	; EAX=linear address of stss
	mov [gdt6 + 2],ax
	shr eax,16
	mov [gdt6 + 4],al
	mov [gdt6 + 7],ah
	lea eax,[ebx + utss1]	; EAX=linear address of utss1
	mov [gdt7 + 2],ax
	shr eax,16
	mov [gdt7 + 4],al
	mov [gdt7 + 7],ah
	lea eax,[ebx + utss2]	; EAX=linear address of utss2
	mov [gdt8 + 2],ax
	shr eax,16
	mov [gdt8 + 4],al
	mov [gdt8 + 7],ah
; point gdtr to the gdt, idtr to the idt
	lea eax,[ebx + gdt]	; EAX=linear address of gdt
	mov [gdtr + 2],eax
	lea eax,[ebx + idt]	; EAX=linear address of idt
	mov [idtr + 2],eax
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
	mov ds,ax
	mov ss,ax
	nop
	mov es,ax
	mov fs,ax
	mov gs,ax
; load task register. All registers from this task will be dumped
; into SYS_TSS after executing the CALL USERx_TSS:0
	mov ax,SYS_TSS
	ltr ax
; print starting msg
	lea esi,[st_msg]
	call wrstr
; initialize user TSSes
	lea eax,[user1]
	mov [utss1_eip],eax
	lea eax,[esp - 512]
	mov [utss1_esp],esp	; task1 stack 512 bytes below system
	lea eax,[user2]
	mov [utss2_eip],eax
	lea eax,[esp - 1024]	; task2 stack 1K bytes below system
	mov [utss2_esp],esp
; shut off interrupts at the 8259 PIC, except for timer interrupt.
; The switch to user task will enable interrupts at the CPU.
	mov al,0xFE
	out 0x21,al
; 18 times...
mov ecx,18
;mov ecx,65537
	mov al,0x20
sched:
	jmp USER1_TSS:0
; timer interrupt returns us here. Reset 8259 PIC:
	out 0x20,al
; clear busy bit of user1 task
	mov [gdt7 + 5],byte 0x89

	jmp USER2_TSS:0
; timer interrupt returns us here. Reset 8259 PIC:
	out 0x20,al
; clear busy bit of user1 task
	mov [gdt8 + 5],byte 0x89

	loop sched
; print ending msg
	lea esi,[end_msg]
	call wrstr
; switch to 16-bit protected mode on your way to real mode
	jmp REAL_CODE_SEL:do_16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	user tasks
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
user1:	lea esi,[hi1_msg]
	call wrstr
	mov ecx,0xFFFFF
	loop $
	jmp user1		; infinite loop (until timer interrupt)

user2:	lea esi,[hi2_msg]
	call wrstr
	mov ecx,0xFFFFF
	loop $
	jmp user2		; infinite loop (until timer interrupt)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	character-output video routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wrch:	pushf			; save IF bit
	push gs
	push ecx
	push ebx
	push eax
		cli		; disable interrupts
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
	popf			; re-enable interrupts (if they were enabled)
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
	mov ax,SYS_DATA_SEL
	mov ss,ax
	mov ds,ax
	mov es,ax
	mov fs,ax
	lea esi,[unhand_msg]
	call wrstr
	jmp $
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
; re-enable interrupts (at CPU and at 8259).
; XXX - read old irq mask from port 0x21, save it, restore it here
	sti
	mov al,0xB8
	out 0x21,al
; exit to DOS with errorlevel 0
	mov ax,0x4C00
	int 0x21
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CsrX:	db 0
CsrY:	db 0

st_msg:	db "Scheduler starting. ", 0

hi1_msg:db "Hello from task 1. ", 0

hi2_msg:db "Greetings from task 2. ", 0

end_msg:db " Scheduler done.", 0

unhand_msg:
	db " Unhandled interrupt!", 0
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
gdt2:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
	db 0xCF
	db 0
; data segment descriptor
SYS_DATA_SEL	equ	$-gdt
gdt3:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
	db 0xCF
	db 0
; code segment descriptor that is 'appropriate' for real mode
; (16-bit, limit=0xFFFF)
REAL_CODE_SEL	equ	$-gdt
gdt4:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
	db 0			; byte-granular, 16-bit
	db 0
; data segment descriptor that is 'appropriate' for real mode
; (16-bit, limit=0xFFFF)
REAL_DATA_SEL	equ	$-gdt
gdt5:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, code, non-conforming, readable
	db 0			; byte-granular, 16-bit
	db 0
; system TSS
SYS_TSS		equ	$-gdt
gdt6:	dw 103
	dw 0			; set to stss
	db 0
	db 0x89			; present, ring 0, 32-bit available TSS
	db 0
	db 0
; user TSS 1
USER1_TSS	equ	$-gdt
gdt7:	dw 103
	dw 0			; set to utss1
	db 0
	db 0x89			; present, ring 0, 32-bit available TSS
	db 0
	db 0
; user TSS 2
USER2_TSS	equ	$-gdt
gdt8:	dw 103
	dw 0			; set to utss2
	db 0
	db 0x89			; present, ring 0, 32-bit available TSS
	db 0
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

;	dw unhand
;	dw SYS_CODE_SEL
;	db 0
;	db 0x8E
;	dw 0
; INT 8 is IRQ0 (timer interrupt). The 8259's can (and should) be
; reprogrammed to assign the IRQs to higher INTs, since the first
; 32 INTs are Intel-reserved. Didn't IBM or Microsoft RTFM?
	dw 0
	dw SYS_TSS
	db 0
	db 0x85			; Ring 0 task gate
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
idt_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	task state segments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
stss:	dw 0, 0			; back link
	dd 0			; ESP0
	dw 0, 0			; SS0, reserved
	dd 0			; ESP1
	dw 0, 0			; SS1, reserved
	dd 0			; ESP2
	dw 0, 0			; SS2, reserved
	dd 0, 0, 0		; CR3, EIP, EFLAGS
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw 0, 0			; ES, reserved
	dw 0, 0			; CS, reserved
	dw 0, 0			; SS, reserved
	dw 0, 0			; DS, reserved
	dw 0, 0			; FS, reserved
	dw 0, 0			; GS, reserved
	dw 0, 0			; LDT, reserved
	dw 0, 0			; debug, IO perm. bitmap

utss1:	dw 0, 0			; back link
	dd 0			; ESP0
	dw 0, 0			; SS0, reserved
	dd 0			; ESP1
	dw 0, 0			; SS1, reserved
	dd 0			; ESP2
	dw 0, 0			; SS2, reserved
	dd 0			; CR3
utss1_eip:
	dd 0, 0x200		; EIP, EFLAGS (EFLAGS=0x200 for ints)
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
utss1_esp:
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw SYS_DATA_SEL, 0	; ES, reserved
	dw SYS_CODE_SEL, 0	; CS, reserved
	dw SYS_DATA_SEL, 0	; SS, reserved
	dw SYS_DATA_SEL, 0	; DS, reserved
	dw SYS_DATA_SEL, 0	; FS, reserved
	dw SYS_DATA_SEL, 0	; GS, reserved
	dw 0, 0			; LDT, reserved
	dw 0, 0			; debug, IO perm. bitmap

utss2:	dw 0, 0			; back link
	dd 0			; ESP0
	dw 0, 0			; SS0, reserved
	dd 0			; ESP1
	dw 0, 0			; SS1, reserved
	dd 0			; ESP2
	dw 0, 0			; SS2, reserved
	dd 0			; CR3
utss2_eip:
	dd 0, 0x200		; EIP, EFLAGS (EFLAGS=0x200 for ints)
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
utss2_esp:
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw SYS_DATA_SEL, 0	; ES, reserved
	dw SYS_CODE_SEL, 0	; CS, reserved
	dw SYS_DATA_SEL, 0	; SS, reserved
	dw SYS_DATA_SEL, 0	; DS, reserved
	dw SYS_DATA_SEL, 0	; FS, reserved
	dw SYS_DATA_SEL, 0	; GS, reserved
	dw 0, 0			; LDT, reserved
	dw 0, 0			; debug, IO perm. bitmap
end:
