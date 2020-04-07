; ----------------------------------------------------------------------------
; powers.asm
;
; Displays powers of 2 from 2^0 to 2^31, one per line, to standard output.
;
; Assembler: NASM
; OS: Any Win32-based OS
; Other libraries: Use gcc's C runtime library
; Assemble with "nasm -fwin32 powers.asm"
; Link with "gcc powers.obj" (C runtime library linked automatically)
; ----------------------------------------------------------------------------

        extern _printf
		extern _getch
        global _main

        section .text
_main:
        push    esi                     ; callee-save registers
        push    edi

        mov     esi, 1                  ; current value
        mov     edi, 31                 ; counter
L1:
        push    esi                     ; push value to print
        push    format                  ; push address of format string
        call    _printf
		
        add     esp, 8                  ; pop off parameters passed to printf
        add     esi, esi                ; double value
        dec     edi                     ; keep counting
        jne     L1
		call _getch
        pop     edi
        pop     esi
        ret

format: db      '%d', 10, 0