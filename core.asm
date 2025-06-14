; OS kernel
; 
; Goal: Write a complete kernel in x86 Assembly that handles:
; - File handling: open, read, write, close basic file system interaction (FAT12 or FAT32)
; - Library methods: include reusable procedures for string manipulation, I/O, math, etc.
; - App loading: load and execute external application binaries from disk into memory
; 
; System: 16-bit Real Mode / 32-bit Protected Mode (as needed)
; Boot sector loads kernel at 0x7C00, kernel handles disk access via BIOS interrupts or custom driver
; Include basic error handling, register preservation, and comments for each routine
;

org 0x0500
use16

; Constants
KERNEL_SEGMENT equ 0x0500
STACK_SEGMENT  equ 0x9000
STACK_POINTER  equ 0xFFFF

; Entry point
start:
    ; Set up segments and stack
    cli                     ; Disable interrupts
    mov ax, KERNEL_SEGMENT
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, STACK_POINTER
    sti                     ; Enable interrupts

    ; Initialize system
    call init_system
    jmp main_loop

; System initialization
init_system:
    pusha
    ; Initialize video mode
    mov ax, 0x0003         ; 80x25 text mode
    int 0x10
    ; Initialize disk system
    call init_disk
    popa
    ret

; Main system loop
main_loop:
    call handle_input
    jmp main_loop

; Disk initialization
init_disk:
    pusha
    mov ah, 0x00           ; Reset disk system
    mov dl, 0x80           ; First hard disk
    int 0x13
    popa
    ret

; File system routines
; Open file
; Input: DS:SI = filename
; Output: AX = file handle (0 if error)
open_file:
    push bx
    push cx
    push dx
    mov ah, 0x3D           ; Open file
    mov al, 0              ; Read only
    int 0x21
    jc .error
    jmp .done
.error:
    xor ax, ax
.done:
    pop dx
    pop cx
    pop bx
    ret

; Read file
; Input: BX = file handle, CX = bytes to read, DS:DX = buffer
; Output: AX = bytes read
read_file:
    push bx
    mov ah, 0x3F           ; Read file
    int 0x21
    pop bx
    ret

; Write file
; Input: BX = file handle, CX = bytes to write, DS:DX = buffer
; Output: AX = bytes written
write_file:
    push bx
    mov ah, 0x40           ; Write file
    int 0x21
    pop bx
    ret

; Close file
; Input: BX = file handle
; Output: AX = status (0 if success)
close_file:
    push bx
    mov ah, 0x3E           ; Close file
    int 0x21
    pop bx
    ret

; String manipulation routines
; String length
; Input: DS:SI = string
; Output: CX = length
strlen:
    push ax
    push di
    mov di, si
    xor cx, cx
.loop:
    lodsb
    test al, al
    jz .done
    inc cx
    jmp .loop
.done:
    mov si, di
    pop di
    pop ax
    ret

; String compare
; Input: DS:SI = string1, ES:DI = string2
; Output: ZF = 1 if equal
strcmp:
    push ax
    push cx
.loop:
    mov al, [si]
    mov cl, [di]
    cmp al, cl
    jne .done
    test al, al
    jz .done
    inc si
    inc di
    jmp .loop
.done:
    pop cx
    pop ax
    ret

; Application loading
; Load and execute application
; Input: DS:SI = filename
; Output: None
load_app:
    pusha
    ; Open file
    call open_file
    test ax, ax
    jz .error
    
    mov bx, ax             ; File handle
    mov cx, 0x1000         ; Load size
    mov dx, 0x1000         ; Load address
    call read_file
    
    ; Close file
    call close_file
    
    ; Execute application
    call 0x1000:0000
    jmp .done
.error:
    ; Handle error
.done:
    popa
    ret

; Input handling
handle_input:
    pusha
    mov ah, 0x00           ; Get key press
    int 0x16
    ; Process key in AL
    popa
    ret

; Error handling
handle_error:
    pusha
    ; Display error message
    mov ah, 0x0E           ; Teletype output
    mov al, 'E'
    int 0x10
    popa
    ret

; End of kernel
times 512-($-$$) db 0      ; Pad to 512 bytes
