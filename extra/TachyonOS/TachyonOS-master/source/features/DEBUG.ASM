
	%MACRO DEBUG 0
		%defstr %%linenum __LINE__
		%defstr %%filename __FILE__
		
		pushf
		push ds
		push es
		pusha
		
		mov ax, 0x2000
		mov ds, ax
		mov es, ax
		
		mov si, %%msg
		call os_print_string
		
		popa
		pop es
		pop ds
		popf
		
		jmp %%jumpover
	
		%%msg db ">>> Debug point in file: ", %%filename, " at line: ", %%linenum, " <<<", DOS_NEWLINE, 0
		
		%%jumpover:
	%ENDMACRO
	
	%MACRO DEBUGK 0
		%defstr %%linenum __LINE__
		%defstr %%filename __FILE__
		
		pushf
		push ds
		push es
		pusha
		
		mov ax, 0x2000
		mov ds, ax
		mov es, ax
		
		mov si, %%msg
		call os_print_string
		call os_wait_for_key

		popa
		pop es
		pop ds
		popf
		
		jmp %%jumpover
	
		%%msg db ">>> Debug point in file: ", %%filename, " at line: ", %%linenum, " <<<", DOS_NEWLINE, "Press any key to continue...", DOS_NEWLINE, 0
		
		%%jumpover:
	%ENDMACRO
	
	%MACRO DEBUGR 0
		%defstr %%linenum __LINE__
		%defstr %%filename __FILE__
		
		pushf
		push ds
		push es
		
		push ax
		mov ax, 0x2000
		mov ds, ax
		mov es, ax
		pop ax
		
		push si
		mov si, %%msg
		call os_print_string
		pop si

		call os_dump_registers
		
		pop es
		pop ds
		popf
		
		jmp %%jumpover
	
		%%msg db ">>> Debug point in file: ", %%filename, " at line: ", %%linenum, " <<<", 0
		
		%%jumpover:
	%ENDMACRO
	
	%MACRO DEBUGS 1
		%defstr %%linenum __LINE__
		%defstr %%filename __FILE__
		
		pushf
		push ds
		push es
		
		push ax
		mov ax, 0x2000
		mov ds, ax
		mov es, ax
		pop ax
		
		push si
		mov si, %%msg
		call os_print_string
		pop si
		
		push si
		mov si, %1
		call os_print_string
		pop si
		
		call os_print_newline
		
		pop es
		pop ds
		popf
		
		jmp %%jumpover
	
		%%msg db ">>> Debug point in file: ", %%filename, " at line: ", %%linenum, " <<<", DOS_NEWLINE, "Debug String: ", 0
		
		%%jumpover:
	%ENDMACRO
	
	%MACRO BREAKPOINT 0
		pusha
		mov ax, 0x2000
		mov ds, ax
		mov es, ax
		popa
		
		call os_dump_registers
		
		mov si, %%msg
		call os_print_string
		cli
		hlt
		%%msg db '>>> OPERATING SYSTEM HALTED <<<', 0
	%ENDMACRO
	
