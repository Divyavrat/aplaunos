								; pm11.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	pm11.asm - protected-mode demo code
;	Christopher Giese <geezer[AT]execpc.com>
;
;	Release date 9/28/98. Distribute freely. ABSOLUTELY NO WARRANTY.
;	Assemble with NASM:	nasm -o pm11.com pm11.asm
;
; Demonstrates:
;	- Reprogramming the 8259-compatible interrupt controllers to
;	  assign hardware IRQs to different interrupts.
; Fixes/changes:
;	- Byte 6 of descriptors (flags/limit 19:16) changed from
;	  0xFC to 0xCF
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[SECTION .text]
org 0x6000
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit real mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
; point code/data descriptors to CS<<4 (=DS<<4 for .COM file)
	xor ebx,ebx
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
; print starting msg
	lea esi,[st_msg]
	call wrstr
; set up scheduler (36 timer interrupts=2 seconds)
; load ECX with 65536 to test-run this code for exactly one hour
	mov ecx,36
	lea ebx,[regsA]		; point to user regs
; SAVE KERNEL REGS
sched:	push ebx
	push ecx
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
; fault/exception/interrupt (except int 0x1F) brings us back here
; *** CAUTION ***: a fault in Ring 0 will not stack SS and ESP.
; Faults other than hardware interrupts may stack an extra error code.
; Either of these situations will mess up the stack.
; user EIP, CS, EFLAGS, ESP, SS left on stack -- complete the stack frame
fault:
fault2:		push gs
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
		mov edi,[esp + 72]	; saved kernel EBX -> user regs
		mov ecx,17		; 17 dwords worth (68 bytes)
		rep movsd
		add esp,68
; LOAD KERNEL REGS
	pop ecx
	pop ebx
; reschedule
	cmp ebx,regsA
	je next
	lea ebx,[regsA]
	jmp again
next:	lea ebx,[regsB]
again:	loop sched
; print ending msg
	lea esi,[end_msg]
	call wrstr

	jmp $
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	32-bit protected mode, ring 3 (task A)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
taskA:	lea esi,[hi_msgA]
	int 0x30		; wrstr syscall
	mov ecx,0x7FFFF		; delay
	loop $
	jmp taskA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	32-bit protected mode, ring 3 (task B)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
taskB:	lea esi,[hi_msgB]
	int 0x30		; wrstr syscall
	mov ecx,0x7FFFF		; delay
	loop $
	jmp taskB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	fault handlers (EIP -> offending instruction)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr0:	mov bl,0
	jmp fault		; zero divide
isr5:	mov bl,5
	jmp fault		; BOUND
isr6:	mov bl,6
	jmp fault		; invalid opcode
isr7:	mov bl,7
	jmp fault		; coprocessor not available
isr10:	mov bl,0x10
	jmp fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	aborts (EIP -> ???)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr9:	mov bl,9		; coprocessor segment overrun
	jmp fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	fault handlers w/ error code (EIP -> offending instruction)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr0A:	mov bl,0x0A
	jmp fault2		; bad TSS
isr0B:	mov bl,0x0B
	jmp fault2		; segment not present
isr0C:	mov bl,0x0C
	jmp fault2		; stack fault
isr0D:	mov bl,0x0D
	jmp fault2		; GPF
isr0E:	mov bl,0x0E
	jmp fault2		; page fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	aborts w/ error code (EIP = garbage)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr8:	mov bl,8		; double fault
	jmp fault2
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	traps (EIP -> beyond offending instruction)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr1:	mov bl,1
	jmp fault		; debug (XXX - may be fault or trap)
isr2:	mov bl,2
	jmp fault		; non-maskable interrupt
isr4:	mov bl,4
	jmp fault		; INTO
isr3:	mov bl,3
	jmp fault		; INT3
isr0F:	mov bl,0x0F
	jmp fault		; coprocessor error
isr11:	mov bl,0x11
	jmp fault		; alignment check
isr12:	mov bl,0x12
	jmp fault
isr13:	mov bl,0x13
	jmp fault
isr14:	mov bl,0x14
	jmp fault
isr15:	mov bl,0x15
	jmp fault
isr16:	mov bl,0x16
	jmp fault
isr17:	mov bl,0x17
	jmp fault
isr18:	mov bl,0x18
	jmp fault
isr19:	mov bl,0x19
	jmp fault
isr1A:	mov bl,0x1A
	jmp fault
isr1B:	mov bl,0x1B
	jmp fault
isr1C:	mov bl,0x1C
	jmp fault
isr1D:	mov bl,0x1D
	jmp fault
isr1E:	mov bl,0x1E
	jmp fault
isr1F:	mov bl,0x1F
	jmp fault
isr20:	mov bl,0x20
	jmp fault
isr21:	mov bl,0x21
	jmp fault
isr22:	mov bl,0x22
	jmp fault
isr23:	mov bl,0x23
	jmp fault
isr24:	mov bl,0x24
	jmp fault
isr25:	mov bl,0x25
	jmp fault
isr26:	mov bl,0x26
	jmp fault
isr27:	mov bl,0x27
	jmp fault
isr28:	mov bl,0x28
	jmp fault
isr29:	mov bl,0x29
	jmp fault
isr2A:	mov bl,0x2A
	jmp fault
isr2B:	mov bl,0x2B
	jmp fault
isr2C:	mov bl,0x2C
	jmp fault
isr2D:	mov bl,0x2D
	jmp fault
isr2E:	mov bl,0x2E
	jmp fault
isr2F:	mov bl,0x2F
	jmp fault
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	interrupt 0x30 service routine
;	The interrupt gate pointing to this function is a Ring 3 gate
;	so this code can be called from Ring 3. Other interrupts/
;	exceptions have Ring 0 gates, and cause GPF (interrupt 0x0D)
;	instead, when called from Ring 3.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
isr30:	pusha
	push gs
	push fs
	push es
	push ds
; though possibly called from Ring 3, this code runs at Ring 0,
; and can use SYS_DATA_SEL and LINEAR_SEL
		mov ax,SYS_DATA_SEL
		mov ds,ax
		mov es,ax
		mov fs,ax
		mov gs,ax
		call wrstr
	pop ds
	pop es
	pop fs
	pop gs
	popa
	iret
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
;	data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CsrX:	db 0
CsrY:	db 0

st_msg:	db "(Scheduler starts.) ", 0

hi_msgA:db "Hello from task A. ", 0

hi_msgB:db "Greetings from task B. ", 0

end_msg:db "(Scheduler done.)   ", 0
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
regsA2:	dd taskA			; EIP
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
regsB2:	dd taskB
	dw USER_CODE_SEL, 0
	dd 0x200
	dd stackB
	dw USER_DATA_SEL, 0
regsB3:

end:
