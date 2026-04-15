								; pm12a.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	pm12a.asm - protected-mode demo code
;	Christopher Giese <geezer[AT]execpc.com>
;
;	Release date 9/28/98. Distribute freely. ABSOLUTELY NO WARRANTY.
;	Assemble pm12a.asm with NASM:
;				nasm -f aout -o pm12a.o pm12a.asm
;	Compile pm12c.c with DJGPP:
;				gcc -c -O2 -o pm12c.o pm12c.c
;	Link with DJGPP ld, using pm12.scr linker script:
;				ld -o pm12.com -Tpm12.scr pm12a.o pm12c.o
;	or just type:
;				make -f pm12.mak
;
; Demonstrates:
;	- Interface and linking to C-language code.
;	- The beginnings of a libc (standard C library).
;	- More elaborate syscalls and error-handling.
;	- Scrolling video; moving cursor in putch().
; Fixes/changes:
;	- Byte 6 of descriptors (flags/limit 19:16) changed from
;	  0xFC to 0xCF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[SECTION .text]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit real mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
[GLOBAL _start]			; DJGPP needs the underbars
; point code/data descriptors to CS<<4 (=DS<<4 for .COM file)
_start:	xor ebx,ebx
	mov bx,cs		; EBX=segment
	shl ebx,4		; EBX=segment << 4
	lea eax,[ebx]		; =linear address of segment base
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
; point tss descriptor to tss
	lea eax,[ebx + tss]	; EAX=linear address of tss
	mov [gdt6 + 2],ax
	shr eax,16
	mov [gdt6 + 4],al
	mov [gdt6 + 7],ah
; point gdtr to the gdt, idtr to the idt
	lea eax,[ebx + gdt]	; EAX=linear address of gdt
	mov [gdtr + 2],eax
	lea eax,[ebx + idt]	; EAX=linear address of idt
	mov [idtr + 2],eax
; clear NT bit (so iret does normal iret, instead of task-switch),
; set IOPL=00, and set IF=0 (disable interrupts)
	push dword 0
	popfd
; load GDT and IDT for full protected mode
	lgdt [gdtr]
	lidt [idtr]
; set PE [protected mode enable] bit and go
	mov eax,cr0
	or al,1
	mov cr0,eax
	jmp SYS_CODE_SEL:do_pm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	32-bit protected mode, ring 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]
[GLOBAL do_pm]
do_pm:	mov ax,SYS_DATA_SEL
	mov ds,ax
	mov ss,ax
	nop
	mov es,ax
	mov fs,ax
	mov gs,ax
; reprogram 8259-compatible interrupt controllers to use INT 20h through
; INT 2Fh for the 16 hardware interrupts. Code from Josh McDonald's OS/2000
; <http://www.effect.net.au/os-dev/> and from Linux.
	mov al,0x11		; put both 8259s in init mode
	out 0x20,al
	out 0xA0,al
	mov al,0x20		; IRQ0-IRQ7 -> interrupts 0x20-0x27
	out 0x21,al
	add al,8
	out 0xA1,al		; IRQ8-IRQ15 -> interrupts 0x28-0x2F
	mov al,4
	out 0x21,al
	mov al,2
	out 0xA1,al
	mov al,1
	out 0x21,al
	out 0xA1,al
; enable IRQs at these chips [ints still disabled at CPU]
	mov al,0xFE		; IRQ0 [timer]
	out 0x21,al
	mov al,0xFF		; none
	out 0xA1,al
; load task register. We don't use the x86 task switch mechanism, but
; we still need the TSS to specify the locations of the system-mode
; (Ring 0) and user-mode (Ring 3) stacks
	mov ax,USER_TSS
	ltr ax
; set up scheduler
	lea ebx,[regsA]		; point to user regs
; SAVE KERNEL REGS
sched:	push ebx
; save current ESP in TSS
		mov [tss_esp0],esp
; LOAD USER REGS
		lea esp,[ebx]
; pop EAX, EBX, ECX, EDX, EBP, ESI, EDI...
		popa
; ...DS, ES, FS, GS...
		pop ds
		pop es
		pop fs
		pop gs
; ...EIP, CS, EFLAGS, ESP, SS (jumps to user task)
		iret
; timer interrupt (IRQ0 = int 0x30) brings us back here
; XXX - how to validate hardware IRQ?
; user EIP, CS, EFLAGS, ESP, SS left on stack -- complete the stack frame
isr20:		push gs
		push fs
		push es
		push ds
		pusha
; reset 8259 interrupt controller
		mov al,0x20
		out 0x20,al
; SAVE USER REGS
		mov ax,ss
		mov ds,ax
		mov es,ax
		mov fs,ax
		mov gs,ax
		lea esi,[esp]
		mov edi,[esp + 68]	; saved kernel EBX -> user regs
		mov ecx,17		; 17 dwords worth (68 bytes)
		rep movsd
		add esp,68
; LOAD KERNEL REGS
	pop ebx
; reschedule
	cmp ebx,regsA
	je next
	lea ebx,[regsA]
	jmp sched
next:	lea ebx,[regsB]
	jmp sched
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	fault handlers (EIP -> offending instruction)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr0:	push dword 0
		jmp fault	; zero divide
isr5:	push dword 5
		jmp fault	; BOUND
isr6:	push dword 6
		jmp fault	; invalid opcode
isr7:	push dword 7
		jmp fault	; coprocessor not available
isr10:	push dword 0x10
		jmp fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	aborts (EIP = garbage)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr9:	push dword 9		; coprocessor segment overrun

fault:		mov ax,ss
		mov ds,ax
		mov es,ax
		mov fs,ax
		mov gs,ax
[EXTERN _unhand]
		call _unhand
		jmp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	fault handlers w/ error code (EIP -> offending instruction)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr0A:	push dword 0x0A
		jmp fault2	; bad TSS
isr0B:	push dword 0x0B
		jmp fault2	; segment not present
isr0C:	push dword 0x0C
		jmp fault2	; stack fault
isr0D:	push dword 0x0D
		jmp fault2	; GPF
isr0E:	push dword 0x0E
		jmp fault2	; page fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	aborts w/ error code (EIP = garbage)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr8:	push dword 8		; double fault

fault2:		mov ax,ss
		mov ds,ax
		mov es,ax
		mov fs,ax
		mov gs,ax
[EXTERN _unhand2]
		call _unhand2
		jmp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	traps (EIP -> beyond offending instruction)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr1:	push dword 1
		jmp fault	; debug (XXX - may be fault or trap)
isr2:	push dword 2
		jmp fault	; non-maskable interrupt
isr4:	push dword 4
		jmp fault	; INTO
isr3:	push dword 3
		jmp fault	; INT3
isr0F:	push dword 0x0F
		jmp fault	; coprocessor error
isr11:	push dword 0x11
		jmp fault	; alignment check
isr12:	push dword 0x12
		jmp fault
isr13:	push dword 0x13
		jmp fault
isr14:	push dword 0x14
		jmp fault
isr15:	push dword 0x15
		jmp fault
isr16:	push dword 0x16
		jmp fault
isr17:	push dword 0x17
		jmp fault
isr18:	push dword 0x18
		jmp fault
isr19:	push dword 0x19
		jmp fault
isr1A:	push dword 0x1A
		jmp fault
isr1B:	push dword 0x1B
		jmp fault
isr1C:	push dword 0x1C
		jmp fault
isr1D:	push dword 0x1D
		jmp fault
isr1E:	push dword 0x1E
		jmp fault
isr1F:	push dword 0x1F
		jmp fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	hardware interrupts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; isr20 (timer interrupt) handled above
isr21:	push dword 0x21
		jmp fault
isr22:	push dword 0x22
		jmp fault
isr23:	push dword 0x23
		jmp fault
isr24:	push dword 0x24
		jmp fault
isr25:	push dword 0x25
		jmp fault
isr26:	push dword 0x26
		jmp fault
isr27:	push dword 0x27
		jmp fault
isr28:	push dword 0x28
		jmp fault
isr29:	push dword 0x29
		jmp fault
isr2A:	push dword 0x2A
		jmp fault
isr2B:	push dword 0x2B
		jmp fault
isr2C:	push dword 0x2C
		jmp fault
isr2D:	push dword 0x2D
		jmp fault
isr2E:	push dword 0x2E
		jmp fault
isr2F:	push dword 0x2F
barf:		jmp fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	syscall interrupt
; 	Works when called from Ring 0 code or from Ring 3.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr30:	pusha
	push gs
	push fs
	push es
	push ds
; though possibly called from Ring 3, this code runs at Ring 0,
; and can use SYS_DATA_SEL and LINEAR_SEL
		mov bx,SYS_DATA_SEL
		mov ds,bx
		mov es,bx
		mov fs,bx
		mov gs,bx
; did we arrive here because of an INT 0x30 instruction?
		mov ebx,[48+esp]
		cmp word [ebx - 2],0x30CD
	;	push dword 0x30	; XXX - this validation doesn't work
; no, treat as unhandled interrupt
	;	jne barf
; yes, print char in al
		push eax
[EXTERN _putch]
			call _putch
		pop eax
	pop ds
	pop es
	pop fs
	pop gs
	popa
	iret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[GLOBAL _CsrX]
_CsrX:	db 0
[GLOBAL _CsrY]
_CsrY:	db 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit limit/32-bit linear base address of GDT and IDT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
gdtr:	dw gdt_end - gdt - 1	; GDT limit
	dd gdt			; linear, physical address of GDT

idtr:	dw idt_end - idt - 1	; IDT limit
	dd idt			; linear, physical address of IDT
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
; code segment descriptor
USER_CODE_SEL	equ	$-gdt+3
gdt4:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0xFA			; present, ring 3, code, non-conforming, readable
	db 0xCF
	db 0
; data segment descriptor
USER_DATA_SEL	equ	$-gdt+3
gdt5:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0xF2			; present, ring 3, data, expand-up, writable
	db 0xCF
	db 0
; user TSS
USER_TSS	equ	$-gdt
gdt6:	dw 103
	dw 0			; set to tss
	db 0
	db 0xE9			; present, ring 3, 32-bit available TSS
	db 0
	db 0
gdt_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	interrupt descriptor table (IDT)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 32 reserved interrupts:
idt:	dw isr0			; entry point 15:0
	dw SYS_CODE_SEL		; selector
	db 0			; word count
	db 0x8E			; type (32-bit Ring 0 interrupt gate)
	dw 0			; entry point 31:16 (XXX - isr0 >> 16)

	dw isr1
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr2
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr3
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr4
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr5
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr6
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr7
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr8
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr9
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr0A
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr0B
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr0C
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr0D
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr0E
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr0F
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr10
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr11
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr12
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr13
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr14
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr15
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr16
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr17
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr18
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr19
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr1A
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr1B
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr1C
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr1D
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr1E
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr1F
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr20
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr21
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr22
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr23
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr24
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr25
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr26
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr27
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr28
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr29
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr2A
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr2B
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr2C
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr2D
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr2E
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr2F
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw isr30
	dw SYS_CODE_SEL
	db 0
	db 0xEE			; Ring 3 interrupt gate
	dw 0
idt_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	task state segment
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
tss:	dw 0, 0			; back link
tss_esp0:
	dd 0			; ESP0
	dw SYS_DATA_SEL, 0	; SS0, reserved
	dd 0			; ESP1
	dw 0, 0			; SS1, reserved
	dd 0			; ESP2
	dw 0, 0			; SS2, reserved
	dd 0			; CR3
	dd 0, 0			; EIP, EFLAGS (EFLAGS=0x200 for ints)
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
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	taskA data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	times 63 dd 0
stackA:	dd 0
; regs popped by popa (ESP is popped and discarded)
regsA:	dd 0, 0, 0, 0, 0, 0, 0, 0	; EDI, ESI, EBP, EBX, EDX, ECX, EDX
; regs popped by pop ds, etc.
regsA1:	dw USER_DATA_SEL, 0		; DS
	dw USER_DATA_SEL, 0		; ES
	dw USER_DATA_SEL, 0		; FS
	dw USER_DATA_SEL, 0		; GS
; regs popped by iret
[EXTERN _taskA]
regsA2:	dd _taskA			; EIP
	dw USER_CODE_SEL, 0		; CS
	dd 0x200			; EFLAGS (0x200 enables ints)
	dd stackA			; ESP
	dw USER_DATA_SEL, 0		; SS
regsA3:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	taskB data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	times 63 dd 0
stackB:	dd 0
regsB:	dd 0, 0, 0, 0, 0, 0, 0, 0
regsB1:	dw USER_DATA_SEL, 0
	dw USER_DATA_SEL, 0
	dw USER_DATA_SEL, 0
	dw USER_DATA_SEL, 0
[EXTERN _taskB]
regsB2:	dd _taskB
	dw USER_CODE_SEL, 0
	dd 0x200
	dd stackB
	dw USER_DATA_SEL, 0
regsB3:
