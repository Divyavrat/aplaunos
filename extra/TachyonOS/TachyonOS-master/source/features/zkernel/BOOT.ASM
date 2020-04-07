; ===========================
; Entry point from bootloader
; ===========================

os_boot_start:
	; Setup a stack at 0x0000:FFFFh 
	cli					; Prevent interrupts while setting the stack!
	mov ax, 0
	mov ss, ax
	mov sp, 0FFFFh
	sti
	
	; The string direction is expected to be upwards to increasing memory addresses
	cld
	
	mov ax, 1000h
	mov bx, 2000h
	
	; Setup segment model
	; -------------------
	; DS - Current Segment (we are starting in kernel space)
	; ES - Current Segment
	; FS - User Segment
	; GS - Kernel Segment
	mov ds, ax
	mov es, ax
	mov fs, bx
	mov gs, ax
		
	; Set the meaning of the attribute bit (highest bit) of a colour number to
	; intensity rather than blinking.
	mov ax, 1003h
	mov bx, 0
	int 10h

	; Tell kernel functions they are being called from kernel space
	inc byte [internal_call]
	
	; Display the first boot message
	call os_clear_screen
	mov ax, 1
	call os_print_horiz_line
	mov si, .boot_msg
	call os_print_string
	call os_print_horiz_line
	mov si, .osinfo_msg
	call os_print_string
	
	; Seed the random number generator --- this only needs to be done once
	BOOTMSG 'Generating random seed'
	call os_seed_random
	BOOTOK
	
	; Remember the boot device number
	mov [bootdev], dl
		
	; Get the parameters for the boot disk
	BOOTMSG 'Getting boot disk parameters'
	push es
	mov ah, 8
	int 13h
	pop es
	
	; Interpreter the parameters
	and cx, 003Fh				; Remove the bits for 'Number of Cylinders' (bits 6-15)
	mov [SecsPerTrack], cx			; Leave the 'Sectors Per Track' (bits 0-5)
	
	movzx dx, dh				; 'Maximum Head Number' is in DH and starts at zero
	add dx, 1				; Add one to find the number of heads
	mov [Sides], dx
	BOOTOK
			
	; Load the local kernel into the first byte of userspace
	push es
	BOOTMSG 'Loading userspace kernel'
	mov ax, 0x2000
	mov es, ax
	mov ax, .kernel_filename
	mov cx, 0
	call os_load_file
	pop es
	BOOTFATAL_IFCARRY 'Cannot load userspace kernel'
	BOOTOK
	
	; Tell kernel functions all future calls will be from userspace
	dec byte [internal_call]
	
	; Continue the bootloader from userspace
	
	mov ax, 0x2000
	mov ds, ax
	mov es, ax
	jmp 0x2000:0

	.boot_msg				db "Relativity Bootloader", DOS_NEWLINE, 0
	.osinfo_msg				db OS_BOOT_MSG, DOS_NEWLINE, 0
	.kernel_filename			db OS_KERNEL_FILENAME, 0

	
BOOT_DATA_BLOCK