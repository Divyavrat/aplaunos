								; pm9.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	pm9.asm - protected-mode demo code
;	Christopher Giese <geezer[AT]execpc.com>
;
;	Release date 9/28/98. Distribute freely. ABSOLUTELY NO WARRANTY.
;	Assemble with NASM:	nasm -o pm9.com pm9.asm
;
; Demonstrates:
;	- Ring 3 task called from Ring 0.
;
; Fixes/changes:
;	- Removed stss, SYS_TSS, gdt6 because only one TSS is needed
;	- IDT now contains true interrupt gates (type 0x8E) instead
;	  of trap gates (type 0x8F)
;	- spin: loop spin changed to loop $
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
	mov [gdt8 + 2],ax
	mov [gdt9 + 2],ax
	shr eax,16
	mov [gdt2 + 4],al
	mov [gdt3 + 4],al
	mov [gdt4 + 4],al
	mov [gdt5 + 4],al
	mov [gdt8 + 4],al
	mov [gdt9 + 4],al
	mov [gdt2 + 7],ah
	mov [gdt3 + 7],ah
	mov [gdt4 + 7],ah
	mov [gdt5 + 7],ah
	mov [gdt8 + 7],ah
	mov [gdt9 + 7],ah
; fix up TSS entries, too
	lea eax,[ebx + utss]	; EAX=linear address of utss
	mov [gdt7 + 2],ax
	shr eax,16
	mov [gdt7 + 4],al
	mov [gdt7 + 7],ah
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
; save real-mode CS
	mov [RealCS],cs
; set PE [protected mode enable] bit and go
	mov eax,cr0
	or al,1
	mov cr0,eax
	jmp SYS_CODE_SEL:do_pm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	32-bit protected mode, ring 0 (kernel/system mode)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 32]
do_pm:	mov ax,SYS_DATA_SEL
	mov ds,ax
	mov ss,ax
	nop
	mov es,ax
	mov fs,ax
	mov ax,LINEAR_SEL	; crock
	mov gs,ax
; load task register.
	mov ax,USER_TSS
	ltr ax
; print starting msg
	lea esi,[st_msg]
	call wrstr
; initialize user TSS
	mov [utss_esp0],esp	; ring 0 task uses system stack
	lea eax,[esp - 256]
	mov [utss_esp],eax	; ring 3 task stack is 256 bytes lower
; move_to_user_mode, from Linux 0.01 (linux/include/asm/system.h):
	mov eax,esp
	push dword USER_DATA_SEL ; SS
	push eax		; ESP
	push dword 0x00		; EFLAGS
	push dword USER_CODE_SEL ; CS
	lea eax,[ring3]
	push eax		; EIP
	iret			; jumps to ring3
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	32-bit protected mode, ring 3 (user mode)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ring3:	mov ax,USER_DATA_SEL
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov ax,ULINEAR_SEL	; crock
	mov gs,ax
; print CS register to prove we're in Ring 3
	lea esi,[cs_msg]
	call wrstr
	xor eax,eax
	mov ax,cs
	call hexout
; JUMP to user task
	jmp USER_TSS:0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	user task
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
user:	lea esi,[hi_msg]
	call wrstr
	mov ecx,0xFFFFF
	loop $
; trap to kernel mode (ring0). Any exception should work.
	int 0x18
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	32-bit protected mode, ring 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
ring0:	mov ax,SYS_DATA_SEL
	mov ds,ax
	mov es,ax
	mov fs,ax
	mov ax,LINEAR_SEL	; crock
	mov gs,ax
	lea esi,[end_msg]
	call wrstr
; print CS register to prove it
	lea esi,[cs_msg]
	call wrstr
	xor eax,eax
	mov ax,cs
	call hexout
; switch to 16-bit protected mode on your way to real mode
	jmp REAL_CODE_SEL:do_16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	character-output video routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wrch:	push gs
	push ecx
	push ebx
	push eax
		;mov ax,LINEAR_SEL
		;mov gs,ax
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
;	hex value output routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
hexout:	push eax
		shr eax,16
		call hexo2
	pop eax
hexo2:	push eax
		mov al,ah
		call hexo3
	pop eax
hexo3:	push eax
		shr al,4
		call hexo4
	pop eax
hexo4:	and al,0x0F
	add al,'0'
	cmp al,'9'
	jbe hexo5
	add al,7
hexo5:	call wrch
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	16-bit protected mode, ring 0
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
; switch to 16-bit stack and data
do_16:	mov ax,REAL_DATA_SEL
	mov ds,ax
	mov ss,ax
	nop
; push real-mode CS:IP
	mov bx,[RealCS]
	push bx
	lea bx,[do_rm]
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
RealCS:	dw 0

st_msg:	db "(Scheduler starts. )", 0

cs_msg:	db "(      CS=0x", 0

hi_msg:	db "(Hello from task 1 )", 0

end_msg:db "(Scheduler done.   )", 0
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
; user TSS
USER_TSS	equ	$-gdt
gdt7:	dw 103
	dw 0			; set to utss
	db 0
	db 0xE9			; present, ring 3, 32-bit available TSS
	db 0
	db 0
; code segment descriptor
USER_CODE_SEL	equ	$-gdt+3
gdt8:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0xFA			; present, ring 3, code, non-conforming, readable
	db 0xCF
	db 0
; data segment descriptor
USER_DATA_SEL	equ	$-gdt+3
gdt9:	dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0xF2			; present, ring 3, data, expand-up, writable
	db 0xCF
	db 0
; linear data segment descriptor
ULINEAR_SEL	equ	$-gdt
	dw 0xFFFF		; limit 0xFFFFF
	dw 0			; base for this one is always 0
	db 0
	db 0xF2			; present, ring 3, data, expand-up, writable
	db 0xCF			; page-granular, 32-bit
	db 0
gdt_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	interrupt descriptor table (IDT)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 32 reserved interrupts:
idt:	dw ring0		; entry point 15:0
	dw SYS_CODE_SEL		; selector
	db 0			; word count
	db 0x8E			; type (32-bit Ring 0 interrupt gate)
	dw 0			; entry point 31:16 (XXX - ring0 >> 16)

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0

	dw ring0
	dw SYS_CODE_SEL
	db 0
	db 0x8E
	dw 0
idt_end:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	task state segments
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
utss:	dw 0, 0			; back link
utss_esp0:
	dd 0			; ESP0
	dw SYS_DATA_SEL, 0	; SS0, reserved
	dd 0			; ESP1
	dw 0, 0			; SS1, reserved
	dd 0			; ESP2
	dw 0, 0			; SS2, reserved
	dd 0			; CR3
	dd 0, 0			; EIP, EFLAGS (EFLAGS=0x200 for ints)
	dd 0, 0, 0, 0		; EAX, ECX, EDX, EBX
utss_esp:
	dd 0, 0, 0, 0		; ESP, EBP, ESI, EDI
	dw USER_DATA_SEL, 0	; ES, reserved
	dw USER_CODE_SEL, 0	; CS, reserved
	dw USER_DATA_SEL, 0	; SS, reserved
	dw USER_DATA_SEL, 0	; DS, reserved
	dw USER_DATA_SEL, 0	; FS, reserved
	dw ULINEAR_SEL, 0	; GS, reserved
	dw 0, 0			; LDT, reserved
	dw 0, 0			; debug, IO perm. bitmap
end:
