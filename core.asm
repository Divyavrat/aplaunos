; OS kernel
; 
; Goal: Write a complete kernel in x86 Assembly that handles:
; - File handling: open, read, write, close basic file system interaction (FAT12)
; - Library methods: include reusable procedures for string manipulation, I/O, math, etc.
; - App loading: load and execute external application binaries from disk into memory
; 
; System: 16-bit Real Mode
; Boot sector loads kernel at 0x7C00, kernel handles disk access via BIOS interrupts
; Include basic error handling, register preservation, and comments for each routine
;

org 0x0500
use16

; Constants
KERNEL_SEGMENT equ 0x0500
STACK_SEGMENT  equ 0x9000
STACK_POINTER  equ 0xFFFF
DISK_BUFFER    equ 0x1000  ; Buffer for disk operations
FAT_BUFFER     equ 0x2000  ; Buffer for FAT
ROOT_BUFFER    equ 0x3000  ; Buffer for root directory

; FAT12 specific constants
SECTORS_PER_TRACK equ 18
HEADS_PER_CYLINDER equ 2
BYTES_PER_SECTOR equ 512
ROOT_ENTRIES    equ 224
FAT_SIZE        equ 9
RESERVED_SECTORS equ 1

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
    ; Load FAT
    call load_fat
    ; Load root directory
    call load_root
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

; Load FAT into memory
load_fat:
    pusha
    mov ax, RESERVED_SECTORS
    mov bx, FAT_BUFFER
    mov cx, FAT_SIZE
    call read_sectors
    popa
    ret

; Load root directory into memory
load_root:
    pusha
    mov ax, RESERVED_SECTORS + FAT_SIZE * 2
    mov bx, ROOT_BUFFER
    mov cx, (ROOT_ENTRIES * 32 + BYTES_PER_SECTOR - 1) / BYTES_PER_SECTOR
    call read_sectors
    popa
    ret

; Read sectors from disk
; Input: AX = starting sector, BX = buffer address, CX = number of sectors
read_sectors:
    pusha
    mov di, 5              ; Number of retries
.retry:
    push ax
    push bx
    push cx
    
    ; Convert LBA to CHS
    mov dx, 0
    div word [sectors_per_track]
    mov cl, dl             ; Sector number
    inc cl
    mov dx, 0
    div word [heads_per_cylinder]
    mov ch, al             ; Cylinder number
    mov dh, dl             ; Head number
    
    mov ah, 0x02           ; Read sectors
    mov al, cl             ; Number of sectors to read
    mov dl, 0x80           ; Drive number
    pop cx
    pop bx
    pop ax
    
    int 0x13
    jnc .done              ; If no error, we're done
    
    dec di
    jz .error              ; If no retries left, error
    xor ah, ah             ; Reset disk
    int 0x13
    jmp .retry
    
.error:
    call handle_error
.done:
    popa
    ret

; Find file in root directory
; Input: DS:SI = filename (11 chars, space-padded)
; Output: AX = cluster number (0 if not found)
find_file:
    pusha
    mov di, ROOT_BUFFER
    mov cx, ROOT_ENTRIES
.search_loop:
    push cx
    push di
    mov cx, 11
    repe cmpsb
    pop di
    pop cx
    je .found
    
    add di, 32             ; Next directory entry
    loop .search_loop
    
    xor ax, ax             ; Not found
    jmp .done
    
.found:
    mov ax, [di + 26]      ; Get cluster number
.done:
    mov [.cluster], ax
    popa
    mov ax, [.cluster]
    ret
.cluster dw 0

; Read file
; Input: AX = cluster number, ES:BX = buffer
; Output: None
read_file:
    pusha
    mov [.cluster], ax
    mov [.buffer], bx
    
.read_cluster:
    ; Convert cluster to sector
    mov ax, [.cluster]
    sub ax, 2
    mov cl, 1              ; Sectors per cluster
    mul cl
    add ax, RESERVED_SECTORS + FAT_SIZE * 2 + (ROOT_ENTRIES * 32 + BYTES_PER_SECTOR - 1) / BYTES_PER_SECTOR
    
    ; Read cluster
    mov bx, [.buffer]
    mov cx, 1
    call read_sectors
    
    ; Get next cluster
    mov ax, [.cluster]
    call get_next_cluster
    mov [.cluster], ax
    
    ; Check if end of file
    cmp ax, 0xFF8
    jae .done
    
    ; Move buffer pointer
    add word [.buffer], BYTES_PER_SECTOR
    jmp .read_cluster
    
.done:
    popa
    ret
.cluster dw 0
.buffer dw 0

; Get next cluster from FAT
; Input: AX = current cluster
; Output: AX = next cluster
get_next_cluster:
    push bx
    push cx
    push dx
    
    ; Calculate FAT offset
    mov bx, ax
    mov cl, 3
    mul cl
    mov cl, 2
    div cl
    
    ; Read FAT entry
    mov bx, FAT_BUFFER
    add bx, ax
    mov ax, [bx]
    
    ; Adjust for odd/even cluster
    test byte [.odd], 1
    jz .even
    shr ax, 4
    jmp .done
.even:
    and ax, 0x0FFF
.done:
    pop dx
    pop cx
    pop bx
    ret
.odd db 0

; List directory contents
; Input: None
; Output: None (prints to screen)
list_directory:
    pusha
    mov di, ROOT_BUFFER
    mov cx, ROOT_ENTRIES
.list_loop:
    ; Check if entry is valid
    mov al, [di]
    test al, al
    jz .done               ; End of directory
    cmp al, 0xE5
    je .next_entry         ; Deleted entry
    
    ; Print filename
    push cx
    push di
    mov cx, 11
    mov ah, 0x0E
.print_loop:
    mov al, [di]
    int 0x10
    inc di
    loop .print_loop
    
    ; Print newline
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    
    pop di
    pop cx
    
.next_entry:
    add di, 32
    loop .list_loop
.done:
    popa
    ret

; Delete file
; Input: DS:SI = filename (11 chars)
; Output: CF = 1 if error
delete_file:
    pusha
    call find_file
    test ax, ax
    jz .error
    
    ; Mark as deleted in root directory
    mov di, ROOT_BUFFER
    mov cx, ROOT_ENTRIES
.search_loop:
    push cx
    push di
    mov cx, 11
    repe cmpsb
    pop di
    pop cx
    je .found
    
    add di, 32
    loop .search_loop
    jmp .error
    
.found:
    mov byte [di], 0xE5    ; Mark as deleted
    
    ; Write root directory back to disk
    mov ax, RESERVED_SECTORS + FAT_SIZE * 2
    mov bx, ROOT_BUFFER
    mov cx, (ROOT_ENTRIES * 32 + BYTES_PER_SECTOR - 1) / BYTES_PER_SECTOR
    call write_sectors
    jmp .done
    
.error:
    call handle_error
.done:
    popa
    ret

; Write sectors to disk
; Input: AX = starting sector, BX = buffer address, CX = number of sectors
write_sectors:
    pusha
    mov di, 5              ; Number of retries
.retry:
    push ax
    push bx
    push cx
    
    ; Convert LBA to CHS
    mov dx, 0
    div word [sectors_per_track]
    mov cl, dl             ; Sector number
    inc cl
    mov dx, 0
    div word [heads_per_cylinder]
    mov ch, al             ; Cylinder number
    mov dh, dl             ; Head number
    
    mov ah, 0x03           ; Write sectors
    mov al, cl             ; Number of sectors to write
    mov dl, 0x80           ; Drive number
    pop cx
    pop bx
    pop ax
    
    int 0x13
    jnc .done              ; If no error, we're done
    
    dec di
    jz .error              ; If no retries left, error
    xor ah, ah             ; Reset disk
    int 0x13
    jmp .retry
    
.error:
    call handle_error
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

; Data section
sectors_per_track dw SECTORS_PER_TRACK
heads_per_cylinder dw HEADS_PER_CYLINDER

; End of kernel
times 512-($-$$) db 0      ; Pad to 512 bytes
