; +---------------------------------+
; | API Macros - Used for API calls |
; +---------------------------------+
	
	%MACRO API_START 0					; Begin API call
		push es
		push ds
		pusha
		inc word [gs:internal_call]
	%ENDMACRO
	
	%MACRO API_END 0					; End API call (without returning anything)
		dec word [gs:internal_call]
		popa
		pop ds
		pop es
		jmp os_return
	%ENDMACRO
	
	%MACRO API_RETURN 1					; End API call (return one value)
		dec word [gs:internal_call]
		mov [gs:%%tmp], %1
		popa
		mov %1, [gs:%%tmp]
		pop ds
		pop es
		jmp os_return
		%%tmp			dw 0
	%ENDMACRO
	
	%MACRO API_END_SC 0					; End API call (without returning anything)
		dec word [gs:internal_call]
		popa
		pop ds
		pop es
		stc
		jmp os_return
	%ENDMACRO
	
	%MACRO API_RETURN_SC 1					; End API call (return one value)
		dec word [gs:internal_call]
		mov [gs:%%tmp], %1
		popa
		mov %1, [gs:%%tmp]
		pop ds
		pop es
		stc
		jmp os_return
		%%tmp			dw 0
	%ENDMACRO
	
	%MACRO API_END_NC 0					; End API call (without returning anything)
		dec word [gs:internal_call]
		popa
		pop ds
		pop es
		clc
		jmp os_return
	%ENDMACRO
	
	%MACRO API_RETURN_NC 1					; End API call (return one value)
		dec word [gs:internal_call]
		mov [gs:%%tmp], %1
		popa
		mov %1, [gs:%%tmp]
		pop ds
		pop es
		clc
		jmp os_return
		%%tmp			dw 0
	%ENDMACRO
	
	%MACRO API_SEGMENTS 0					; Set the kernel segments
		push ax
		mov ax, gs
		mov ds, ax
		mov es, ax
		pop ax
	%ENDMACRO
	
