								; pm1.asm
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	pm1.asm - protected-mode demo code
;	Christopher Giese <geezer[AT]execpc.com>
;	http://www.execpc.com/~geezer/os
;
;	Release date 10/7/98. Distribute freely. ABSOLUTELY NO WARRANTY.
;	Assemble with NASM:	nasm -o pm1.com pm1.asm
;
;	Run this program in "raw" MS-DOS mode, not a Windows DOS box. Do not
;	load EMM386 or other memory managers. Do not load HIMEM.SYS (see
;	below). Clear the screen and hit Enter a few times before running it.
;
;	What you should see:
;	"012345                                           !"
;	" still in real mode!"
;	"  ES,DS still real mode!"
;	"   Finally in protected mode!"
;	"    ES,DS still protected mode!"
;	"     back to BORING old real mode"
;
;	Running the program puts a 4G limit in the segment descriptor
;	cache for ES. This makes 32-bit addresses legal in real mode,
;	when used with ES. Running the program a second time will add
;	an 'R' to the top line.
;
;	If you see the 'R' instead of the '!' the first time you run it,
;	it is because a previous protected-mode program has munged the
;	segment descriptor cache for ES. The most likely culprit is
;	HIMEM.SYS, which is loaded silently and automatically by DOS 7.
;
;	This code was tested with NASM version 0.93 and NASM version 0.97.
;	Please let me know if you have problems with other versions.
;
;	This code was tested on an Intel 486SX-based system and an Intel
;	Pentium-based system. Please let me know of possible problems with
;	other CPUs, especially the 386 or 386SX.
;
;	Though I have tried to be as clear and accurate as possible, there
;	may be errors. Constructive criticism is welcome.
;
; Demonstrates:
;	- Basic 32-bit protected mode.
;	- Linear (flat) memory.
;	- Access to text-mode video memory.
;	- Return to real mode.
;	- "Unreal" mode (flat real, big real).
;	- Effects of the segment descriptor cache.
; See other tutorials for:
;	- Interrupts/exceptions
;	- Virtual 8086 mode
;	- CPU detection (>= 386)
;	- Local Descriptor Tables (LDTs)
;	- Running code in XMS
;	- A20 gate
;	- Multitasking
;	- Task state segments (TSSes)
;	- Privilege
;	- Gates
; Sources:
;   INTEL 80386 PROGRAMMER'S REFERENCE MANUAL 1986
;	http://www.execpc.com/~geezer/os/386intel.zip
;       ftp://ftp.cdrom.com/.20/demos/code/hardware/cpu/386intel.zip
;       http://www.intercom.net/user/jeremyfo/SamOS/Files/386intel.zip
;   Robert Collins' "Intel Secrets" web site:
;       http://www.x86.org
;
;[ORG 0x100]
org 0x6000
BITS 16
;
;
; If you want to skip this commentary and go directly to the code,
; search for the label "start:"
;
; How to get into protected mode? First, you need a GLOBAL DESCRIPTOR
; TABLE (GDT). There is one at the end of this file, at address "gdt:"
; The GDT contains 8-byte DESCRIPTORS for each protected-mode segment.
; Each descriptor contains a 32-bit segment base address, a 20-bit segment
; limit, and 12 bits describing the segment type. The descriptors look
; like this:
;
;           MSB    bit 6   bit 5   bit 4   bit 3   bit 2   bit 1   LSB
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 0  | bit 7<---------------- segment limit------------------->bit 0 |
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 1  |bit 15<---------------- segment limit------------------->bit 8 |
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 2  | bit 7<---------------- segment base-------------------->bit 0 |
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 3  |bit 15<---------------- segment base-------------------->bit 8 |
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 4  |bit 23<---------------- segment base-------------------->bit 16|
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 5  |   P   |      DPL      | <----------- segment type ----------> |
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
; P is the Segment Present bit. It should always be 1.
;
; DPL is the DESCRIPTOR PRIVILEGE LEVEL. For simple code like this, these
; two bits should always be zeroes.
;
; Segment Type (again, for simple code like this) is hex 12 for data
; segments, hex 1A for code segments.
;
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 6  |   G   |   B   |   0   | avail | bit 19<-- seg limit--->bit 16 |
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
; G is the Limit Granularity. If zero, the segment limit is in bytes
; (0 to 1M, in 1-byte increments). If one, the segment limit is in 4K PAGES
; (0 to 4G, in 4K increments). For simple code, set this bit to 1, and
; set the segment limit to its highest value (FFFFF hex). You now have
; segments that are 4G in size! The Intel CPUs can address no more than
; 4G of memory, so this is like having no segments at all. No wonder
; protected mode is popular.
;
; B is the Big bit; also called the D (Default) bit. For code segments,
; all instructions will use 32-bit operands and addresses by default
; (BITS 32, in NASM syntax, USE32 in Microsoft syntax) if this bit is set.
; 16-bit protected mode is not very interesting, so set this bit to 1.
;
; None of these notes apply to the NULL descriptor. All of its bytes
; should be set to zero.
;
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;byte 7  |bit 31<---------------- segment base------------------->bit 24 |
;        +-------+-------+-------+-------+-------+-------+-------+-------+
;
; Build a simple GDT with four descriptors: NULL (all zeroes), linear data
; (lets you use 32-bit addresses), code, and data/stack. (An extra
; descriptor or two is needed to return to real mode.) For simplicity,
; the limits of all descriptors (except NULL and the real-mode descriptors)
; are FFFFF hex, the largest possible limit.
;
; In a real-mode .COM file, CS=DS. To make addressing identical in real
; mode and protected mode, we set the base of the code and data descriptors
; to DS * 16. This number is computed at run-time; the other numbers in
; the GDT can be done at assemble-time.
;
start:	xor ebx,ebx
	mov bx,ds                       ; BX=segment
	shl ebx,4                       ; BX="linear" address of segment base
	mov eax,ebx
	mov [gdt2 + 2],ax               ; set base address of 32-bit segments
	mov [gdt3 + 2],ax
	mov [gdt4 + 2],ax               ; set base address of 16-bit segments
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
;
; Now we have a valid GDT. The CPU has a 48-bit register (GDTR) which must
; contain the base address of the GDT, and its limit. We will put those
; values at the address "gdtr", then load the GDTR register from that
; address. The GDT limit is a fixed value:
;       number of descriptors * 8 - 1
; This code uses 5 descriptors (null, linear, code, data, real-mode),
; so the GDT limit is 39. (If you look at the code after "gdtr:", you
; will see that it can accommodate more or fewer descriptors
; "automatically".)
;
; What about the GDT base? This won't work:
;
;       lea eax,[gdt]			; This address is relative to
;       mov [gdtr + 2],eax		; the segment base.
;
; The address of the GDT base (the address to be loaded into the GDTR
; register) is a PHYSICAL address, one that is not translated by
; segmentation. So, we do the translation ourselves, by adding the
; 32-bit segment base address that we put in EBX:
;
        lea eax,[gdt + ebx]             ; EAX=PHYSICAL address of gdt
        mov [gdtr + 2],eax
;
; That's a bit confusing, but eventually you'll get it. (I have been
; hacking at protected mode for over a year, and it STILL confuses me.)
;
; This demo code neither demonstrates nor supports interrupts.
; Shut them off. (My thanks to John Fine for pointing out that INT 0Dh
; is also IRQ 5, and his suggestion that I move the 'cli' here.)
;
	cli
;
; Before entering pmode, we will try to use 32-bit addressing while still
; in real mode. To do this, we have to take over the vector for INT 0Dh
; (the "pseudo GPF").
;
	xor ax,ax
	mov es,ax
	mov edx,[es:0x0D * 4]		; INT 0Dh vector -> EDX
	mov [es:0x0D * 4 + 2],cs
	lea ax,[trap]
	mov [es:0x0D * 4],ax
;
; Try using a 32-bit address in real mode. Depending on "where the CPU's
; been", this may or may not cause interrupt 0Dh.
;
	mov ebx,0xB809A			; ES still 0
	mov byte [es:ebx],'R'		; 'R' in upper right corner of screen
;
; Did it work? There's more info on 32-bit addressing in real mode below.
; Note: the second 'mov' above is 5 bytes long. Modify the 'trap' routine
; below if the 'mov' changes.
;
; If we want to return to real mode when we're done, we must save the
; contents of the CS register. To simplify the return to real mode,
; we also store the return-to-real-mode address, do_rm.
;
	mov ax,cs
	mov [RealModeCS],ax
	lea ax,[do_rm]
	mov [RealModeIP],ax
;
; To (literally) see this code in action, we need a way to access
; text-mode video memory. This memory is at real-mode address B800:0000
; (hex). Let's put the segment for this memory in ES:
;
	mov ax,0xB800
	mov es,ax
;
; Load the GDTR with the base address and limit of the GDT.
;
	lgdt [gdtr]
;
; Set the PE [protected mode enable] bit in register CR0 to begin the
; switch to protected mode.
;
	mov eax,cr0
	or al,1
	mov cr0,eax
;
; We are not yet in full protected mode! Section 10.3 of the INTEL
; 80386 PROGRAMMER'S REFERENCE MANUAL 1986 states:
;
;; Immediately after setting the PE flag, the initialization code must flush
;; the processor's instruction prefetch queue by executing a JMP instruction.
;; The 80386 fetches and decodes instructions and addresses before they are
;; used; however, after a change into protected mode, the prefetched
;; instruction information (which pertains to real-address mode) is no longer
;; valid. A JMP forces the processor to discard the invalid information.
;
; It isn't really necessary to do the JMP right away, as this implies.
; It simply means that protected mode doesn't "kick in" until the segment
; registers are reloaded. Above, we set the ES segment register to 0xB800.
; This is the real-mode segment of the text video memory. With the PE bit
; still set, let's copy a message from the real-mode data segment (DS) to
; the video memory (ES).
;
        lea si,[msg0]                   ; -> "still in real mode!"
        mov di,(80 * 1 + 2) * 2         ; row 1, column 2
        mov cx,38
        cld
        rep movsb
;
; The code above won't work in protected mode. It's there just to
; prove that setting the PE bit is not enough to enter protected mode.
;
; Now do a far jump. This reloads the CS register and flushes the
; real-mode instructions from the prefetch queue. CS is the segment
; register used for instruction fetches, so this is where the switch
; from 16-bit instructions (real-mode) to 32-bit instructions
; (protected-mode) takes place.
;
; But what goes into CS? In real mode, we use the segment address. In
; protected mode, we use a SELECTOR:
;
; MSB  b14  b13  b12  b11  b10   b9   b8   b7   b6   b5   b4   b3   b2   b1   LSB
;+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;|                                index                           | L  |   RPL   |
;+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+----+
;
; index is a 13-bit index into the GDT. It selects one of the possible 8192
; descriptors in the table. (Note: 8192 descriptors/table, 8 bytes/descriptor.
; The GDT is no larger than 64K.)
;
; If the L bit is set, this selector selects a descriptor from one of the
; LOCAL DESCRIPTOR TABLES (LDT), instead of the GDT. For simple code (like
; this code) or code that doesn't use LDTs, set this bit to 0.
;
; RPL is a 2-bit REQUESTOR PRIVILEGE LEVEL. For simple code: set these bits
; to zero.
;
; Here, we load the hex value 10 into CS. In binary, this is
; 0000 0000 0001 0000. The top thirteen bits are 0000000000010.
; This selector choses descriptor #2 in the GDT (the code segment
; descriptor).
;
	jmp SYS_CODE_SEL:do_pm          ; jumps to do_pm
;
; Real-mode interrupt 0Dh handler:
;
trap:	mov ax,0xB800
	mov fs,ax
	mov byte [fs:0x9C],'!'
	pop ax				; point stacked IP beyond...
	add ax,5			; ...the offending instruction
	push ax
	iret
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Alert! Now in 32-bit protected mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
[BITS 32]
do_pm:
;
; Now we are in 32-bit protected mode -- or are we? Besides CS, all of the
; segment registers still contain real-mode values. Let's try using real-
; mode addressing to put another message on the screen.
;
; Here's a potential problem: addressing is still 16-bit real-mode (oops,
; I gave it away!), but instructions are 32-bit. The rep movsb used below
; will read from DS:ESI and write to ES:EDI. We can either make sure the
; top 16 bits of ESI and EDI are zeroed, or use an 16-bit address size
; override prefix with 'rep movsb'.
;
        xor edi,edi
        xor esi,esi

	lea si,[msg1]                   ; -> "ES, DS still real mode!"
        mov di,(80 * 2 + 3) * 2         ; row 2, column 3
        mov ecx,46
        cld
        rep movsb
;
; ARRGH, it works :) Real-mode addressing hangs on.
;
; To enable full protected-mode addressing, we must put valid protected-
; mode selectors in the DS and SS registers:
;
	mov ax,SYS_DATA_SEL
	mov ds,ax
	mov ss,ax
;
; Can we now print out a message to let the world know we've made it?
;
;       mov ax,0xB800
;       mov es,ax
;       mov byte [es:0],'@'
;
; This won't work (which is why it's commented out). Remember, the
; segment registers contain selectors when in protected mode. Looking
; at the GDT, we see four descriptors (and their associated selectors):
;
;       NULL                    0
;       linear data             8       =LINEAR_SEL
;       code                    10 hex  =SYS_CODE_SEL
;       data/stack              18 hex  =SYS_DATA_SEL
;
; Use of the NULL segment/selector/descriptor is forbidden. Trying to
; access video memory via the code segment/selector/descriptor might
; work, but it is a poor programming practice, and will almost certainly
; cause problems down the road. What about SYS_DATA_SEL?
;
;       mov ax,SYS_DATA_SEL
;       mov es,ax
;       mov byte [es:0],'@'
;
; As you may have guessed, that won't work either. It writes to the lowest
; byte of the data/stack segment. Above, we set the base of the data/stack
; segment descriptor to DS * 16. Since this is a .COM file, CS=DS, and
; we end up scribbling on memory 256 bytes before the address "start".
; None of these work, either:
;
;       mov ax,SYS_DATA_SEL
;       mov es,ax
;       mov byte [es:0xB800],'@'        ; writes unknown byte at offset
;                                       ; B800 hex of data segment
;
;       mov ax,SYS_DATA_SEL
;       mov es,ax
;       mov byte [es:0xB8000],'@'       ; writes unknown byte at offset
;                                       ; B8000 hex of data segment
;
; OK, I've beaten the point to death. The answer lies in LINEAR_SEL.
; In real mode, the address of the text-mode video memory is B800:0000
; As a "flat" ("linear"), 32-bit address, this would be 000B8000.
; Because the descriptor referred to by LINEAR_SEL has a base segment
; address of zero, we can simply use the linear address 000B8000 with
; LINEAR_SEL to get at the video memory:
;
	mov ax,LINEAR_SEL
	mov es,ax
;
; Here's a useful debug tip: once you have basic pmode running, with a
; linear selector like this, you can poke single bytes into video memory
; after each questionable piece of code, to see how far the code got:
;
	; questionable PM code here
	mov byte [es:dword 0xB8000],'0'

	; more questionable PM code here
	mov byte [es:dword 0xB8002],'1'

	; still more questionable PM code here
	mov byte [es:dword 0xB8004],'2'

	; (you get the picture)
	mov byte [es:dword 0xB8006],'3'
;
; Because we've chosen the base address of the data segment so that
; addressing works the same in real mode and protected mode, we can
; refer to an address like "msg2" without grief or confusion:
;
	lea esi,[msg2]                  ; -> "Finally in protected mode!"
;
; (though we now use 32-bit registers ESI, EDI, and ECX, instead of 16-bit
; SI, DI, and CX).
;
; With LINEAR_SEL, the screen starts at address B8000 hex. We need to
; add that value to whatever address we compute for a given cursor
; location. Notes:
; - 32-bit addresses like this are ILLEGAL in real mode (but see below)
; - We could've set the base of LINEAR_SEL to B8000 hex (and possibly
;   called it VIDEO_SEL) to avoid this step. A segment with base 0,
;   however, lets us easily get at other "interesting" areas of memory
;   e.g. the ROMs.
;
	mov edi,0xB8000 + (80 * 3 + 4) * 2      ; row 3, column 4
	mov ecx,52
	cld
	rep movsb
;
; OK, enough of protected mode. Can we return to real-mode DOS without
; things crashing and burning? We'll try. Section 14.5 of the INTEL
; 80386 PROGRAMMER'S REFERENCE MANUAL 1986 states:
;
;;  2.  Transfer control to a segment that has a limit of 64K (FFFFH). This
;;      loads the CS register with the limit it needs to have in real mode.
;
; This is not enough! It implies that you could run with a 32-bit protected
; mode segment that is page-granular and has limit 16 (16 * 4K = 64K). The
; segment must also be a 16-bit segment (Default/Big bit set to zero).
; Essentially, we must switch (briefly) to 16-bit protected mode before
; going on to real mode. Fortunately, if the necessary descriptor is
; provided, that's easy to do:
;
	jmp REAL_CODE_SEL:do_16
[BITS 16]
do_16:
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Now in 16-bit protected mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; Going back to real mode with the data and stack segments having a limit
; of 4G (0xFFFFF and page granular) can cause problems. Referring again to
; Section 14.5 of the INTEL 80386 PROGRAMMER'S REFERENCE MANUAL 1986:
;
;;  3.  Load segment registers SS, DS, ES, FS, and GS with a selector that
;;      points to a descriptor containing the following values, which are
;;      appropriate to real mode:
;;
;;      þ  Limit = 64K   (FFFFH)
;;      þ  Byte granular (G = 0)
;;      þ  Expand up     (E = 0)
;;      þ  Writable      (W = 1)
;;      þ  Present       (P = 1)
;;      þ  Base = any value
;
; So, we fix that here:
;
	mov ax,REAL_DATA_SEL
	mov ss,ax
	mov ds,ax			; leave ES alone
;
; The rest of the procedure to return to real mode is somewhat like the
; the procedure to enter protected mode. Zero the PE bit in register CR0:
;
	mov eax,cr0
	and al,0xFE
	mov cr0,eax
;
; Now put the real-mode CS value back into CS. There are relatively
; few instructions that change the CS register:
;       jmp (far)       retf            iret		(probably some more)
;
; jmp (far) works:
;
	jmp far [RealModeIP]
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;       Back in 16-bit real mode.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
[BITS 16]
;
; We've shut off the PE bit and put a real-mode value back into CS.
; Above, we saw how real-mode addressing hung on even after setting
; the PE bit and jumping to a 32-bit protected-mode code segment.
; Is the reverse true? Can we use 32-bit addressing while in real mode?
;
do_rm:	mov byte [es:dword 0xB8008],'4'
;
; It looks like we can! This is called UNREAL MODE (or "flat real",
; "big real", etc.). Among other uses, unreal mode is useful for bootloaders,
; as you can use INT 13h to load a kernel from disk to conventional memory,
; then use unreal mode to copy it to extended memory.
;
; Each segment register in the x86 CPU has an associated 8-byte descriptor
; register, also in the CPU. This is called the SEGMENT DESCRIPTOR
; CACHE. Loading a selector into a segment register while in protected
; mode reloads the entire cache entry for that segment register. Loading
; a value into a segment register in real mode sets only the base address
; of the cache entry. The segment limit and flag bits are not changed.
;
; This means that we CAN reload the segment register after returning to
; real mode, and we'll still be able to use 32-bit addresses (as long as
; a suitably high segment limit was set while in protected mode).
;
	xor ax,ax
	mov es,ax
	mov byte [es:dword 0xB800A],'5'
;
; Like protected mode in general, unreal mode is very subtle. This code
; fragment, for example, will not work:
;
	lea esi,[msg3]			; -> "ES, DS still protected mode!"
	mov edi,0xB8000 + (80 * 4 + 5) * 2      ; row 4, column 5
	mov ecx,56
	cld
	;rep movsb
;
; The 'rep movsb' is commented out, because that's where the code fails.
; Though addressing is still 32-bit, the code itself is 16-bit. This means
; that 'rep movsb' will use the 16-bit SI, DI, and CX registers. Since
; the value in EDI is at least 0xB8000, the message won't be written to
; video memory, but to some other location.
;
; This behavior is easily fixed with an address size override prefix:
;
	a32				; same as 'db 0x67'
	rep movsb
;
; Before returning to DOS, put real-mode compatible values in the
; segment registers:
;
	mov ax,cs
	mov ds,ax
	mov ss,ax
	mov ax,0xB800
	mov es,ax
;
; Home again:
;
	lea si,[msg4]                   ; -> "back to BORING old real mode"
	mov di,(80 * 5 + 6) * 2         ; row 5, column 6
	mov cx,56
	cld
	rep movsb
;
; Restore the INT 0D interrupt vector:
;
	xor ax,ax
	mov es,ax
	mov [es:0x0D * 4],edx		; EDX -> INT 0x0D vector
;
; Protected mode is no more. It is now safe to re-enable interrupts.
;
	sti
;
; Exit to DOS with errorlevel 0
;
	mov ax,0x4C00
	int 0x21
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; data
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RealModeIP:
        dw 0

RealModeCS:
	dw 0
;
; The alternating spaces are treated as attribute bytes by the video
; hardware. This makes the messages an eye-catching black on green.
;
msg0:   db "s t i l l   i n   r e a l   m o d e ! "
msg1:   db "E S ,   D S   s t i l l   r e a l   m o d e ! "
msg2:   db "F i n a l l y   i n   p r o t e c t e d   m o d e ! "
msg3:	db "E S ,   D S   s t i l l   p r o t e c t e d   m o d e ! "
msg4:   db "b a c k   t o   B O R I N G   o l d   r e a l   m o d e "

gdtr:	dw gdt_end - gdt - 1	; GDT limit
	dd gdt                  ; (GDT base gets set above)
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
        db 0xCF                 ; page-granular, 32-bit
	db 0

; code segment descriptor
SYS_CODE_SEL	equ	$-gdt
gdt2:   dw 0xFFFF               ; limit 0xFFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
        db 0xCF                 ; page-granular, 32-bit
	db 0

; data segment descriptor
SYS_DATA_SEL	equ	$-gdt
gdt3:   dw 0xFFFF               ; limit 0xFFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
        db 0xCF                 ; page-granular, 32-bit
	db 0

; a code segment descriptor that is 'appropriate' for real mode
; (16-bit, byte-granular, limit=0xFFFF)
REAL_CODE_SEL	equ	$-gdt
gdt4:   dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x9A			; present, ring 0, code, non-conforming, readable
	db 0			; byte-granular, 16-bit
	db 0

; a data segment descriptor that is 'appropriate' for real mode
; (16-bit, byte-granular, limit=0xFFFF)
REAL_DATA_SEL	equ	$-gdt
gdt5:   dw 0xFFFF
	dw 0			; (base gets set above)
	db 0
	db 0x92			; present, ring 0, data, expand-up, writable
	db 0			; byte-granular, 16-bit
	db 0

gdt_end:
