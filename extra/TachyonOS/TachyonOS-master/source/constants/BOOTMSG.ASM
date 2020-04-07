; +--------------------------+
; | Boot time message macros |
; +--------------------------+


%macro BOOTMSG 1
	mov si, %%msg
	call os_print_string
	jmp %%over_msg
	
	%%msg db %1, '...', 0
	%%over_msg:
%endmacro

%macro BOOTOK 0
	pusha
	call os_get_cursor_pos
	mov dl, 70
	
	mov ax, 1301h
	mov bh, 0
	mov bl, 2
	mov cx, 7
	mov bp, boot_data_block.ok_msg
	int 10h
	popa
	
	call os_print_newline
%endmacro

%macro BOOTFAIL 0
	pusha
	call os_get_cursor_pos
	mov dl, 70

	mov ax, 1301h
	mov bh, 0
	mov bl, 4
	mov cx, 6
	mov bp, boot_data_block.fail_msg
	int 10h
	popa

	call os_print_newline
%endmacro

%macro BOOTFATAL 1
	BOOTFAIL
	mov si, boot_data_block.fatal_msg
	call os_print_string
	mov si, %%msg
	call os_print_string
%%stop:
	cli
	hlt
	jmp %%stop
	%%msg	db %1, 0
%endmacro
	
%macro BOOTFATAL_IFCARRY 1
	jnc %%okay
	BOOTFATAL %1
	%%okay:
%endmacro

%macro BOOT_DATA_BLOCK 0
	boot_data_block:
		.ok_msg					db "SUCCESS"
		.fail_msg				db "FAILED"
		.fatal_msg				db "Boot process halted with error: ", 0
%endmacro
 
