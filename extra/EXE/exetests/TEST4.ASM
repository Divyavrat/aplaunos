; ----------------------------------------------------------------------------
; Assembler: NASM
; OS: Any Win32-based OS
; Other libraries: Use gcc's C runtime library
; Assemble with "nasm -fwin32 powers.asm"
; Link with "gcc powers.obj" (C runtime library linked automatically)
; ----------------------------------------------------------------------------

        global _main

        section .text
_main:
        push    esi                     ; callee-save registers
        push    edi

        mov ax,0x0e42
		int 0x10
		mov ah,0x00
		int 0x16
				
        pop     edi
        pop     esi
        ret