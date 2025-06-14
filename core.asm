; OS kernel
; 
; Goal: Write a complete kernel in x86 Assembly that handles:
; - File handling: open, read, write, close basic file system interaction (FAT12)
; - Library methods: include reusable procedures for string manipulation, I/O, math, etc.
; - App loading: load and execute external application binaries from disk into memory
; 
; System: 16-bit Real Mode
; Boot sector loads kernel at 0x0500, kernel handles disk access via BIOS interrupts
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
APPS_BUFFER    equ 0x1000  ; Buffer for apps

; FAT12 specific constants
SECTORS_PER_TRACK equ 18
HEADS_PER_CYLINDER equ 2
BYTES_PER_SECTOR equ 512
ROOT_ENTRIES    equ 224
FAT_SIZE        equ 9
RESERVED_SECTORS equ 1

; Terminal interface
; Constants for terminal
PROMPT_STRING db '> ', 0
CMD_BUFFER_SIZE equ 80
CMD_BUFFER times CMD_BUFFER_SIZE db 0
CURRENT_DIR db 'A:\', 0

; Command table
CMD_TABLE:
    db 'ls', 0, 0, 0, 0, 0, 0, 0, 0    ; ls command
    dw cmd_ls
    db 'cd', 0, 0, 0, 0, 0, 0, 0, 0    ; cd command
    dw cmd_cd
    db 'mkdir', 0, 0, 0, 0, 0, 0       ; mkdir command
    dw cmd_mkdir
    db 'cp', 0, 0, 0, 0, 0, 0, 0, 0    ; cp command
    dw cmd_cp
    db 'mv', 0, 0, 0, 0, 0, 0, 0, 0    ; mv command
    dw cmd_mv
    db 'del', 0, 0, 0, 0, 0, 0, 0, 0   ; del command
    dw cmd_del
    db 'run', 0, 0, 0, 0, 0, 0, 0, 0   ; run command
    dw cmd_run
    db 0                               ; End of table

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

; Terminal main loop
terminal:
    pusha
.terminal_loop:
    ; Display prompt
    mov si, PROMPT_STRING
    call print_string
    
    ; Get command
    mov di, CMD_BUFFER
    call get_command
    
    ; Parse and execute command
    call parse_command
    
    jmp .terminal_loop
    popa
    ret

; Print string
; Input: DS:SI = string
print_string:
    pusha
    mov ah, 0x0E
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    popa
    ret

; Get command from user
; Input: ES:DI = buffer
get_command:
    pusha
    mov cx, CMD_BUFFER_SIZE
    xor bx, bx
.loop:
    mov ah, 0x00           ; Get key
    int 0x16
    
    cmp al, 0x0D           ; Enter
    je .done
    cmp al, 0x08           ; Backspace
    je .backspace
    
    ; Store character
    mov [es:di + bx], al
    inc bx
    
    ; Echo character
    mov ah, 0x0E
    int 0x10
    
    loop .loop
    jmp .done
    
.backspace:
    test bx, bx
    jz .loop
    dec bx
    mov byte [es:di + bx], 0
    
    ; Erase character
    mov ah, 0x0E
    mov al, 0x08
    int 0x10
    mov al, ' '
    int 0x10
    mov al, 0x08
    int 0x10
    
    jmp .loop
    
.done:
    mov byte [es:di + bx], 0
    
    ; Print newline
    mov ah, 0x0E
    mov al, 0x0D
    int 0x10
    mov al, 0x0A
    int 0x10
    
    popa
    ret

; Parse command
parse_command:
    pusha
    mov si, CMD_BUFFER
    mov di, CMD_TABLE
    
.parse_loop:
    ; Check if end of table
    cmp byte [di], 0
    je .unknown_command
    
    ; Compare command
    push si
    push di
    mov cx, 8              ; Max command length
.compare_loop:
    mov al, [si]
    mov ah, [di]
    cmp al, ah
    jne .next_command
    test al, al
    jz .command_found
    inc si
    inc di
    loop .compare_loop
    
.command_found:
    pop di
    pop si
    add di, 8              ; Skip command name
    call word [di]         ; Call command handler
    jmp .done
    
.next_command:
    pop di
    pop si
    add di, 10             ; Skip command name and handler
    jmp .parse_loop
    
.unknown_command:
    mov si, .unknown_msg
    call print_string
    jmp .done
    
.done:
    popa
    ret
.unknown_msg db 'Unknown command.', 0x0D, 0x0A,'Current commands are ls, cd, mkdir, cp, mv, del, run.', 0x0D, 0x0A, 0

; Command handlers
cmd_ls:
    pusha
    call list_directory
    popa
    ret

cmd_cd:
    pusha
    mov si, CMD_BUFFER + 3  ; Skip 'cd '
    mov di, CURRENT_DIR
    mov cx, 8              ; Max directory name length
    rep movsb
    mov byte [di], 0
    popa
    ret

cmd_mkdir:
    pusha
    mov si, CMD_BUFFER + 6  ; Skip 'mkdir '
    call create_directory
    popa
    ret

cmd_cp:
    pusha
    mov si, CMD_BUFFER + 3  ; Skip 'cp '
    mov di, si
.loop:
    lodsb
    cmp al, ' '
    jne .loop
    mov byte [si-1], 0
    push si                 ; Save destination
    call find_file
    test ax, ax
    jz .error
    
    ; Read source file
    mov bx, DISK_BUFFER
    call read_file
    
    ; Create destination
    pop si                  ; Restore destination
    mov di, si
    call create_file
    test ax, ax
    jz .error
    
    ; Write file
    mov bx, DISK_BUFFER
    mov cx, 512            ; Assuming max file size
    call write_file
    jmp .done
    
.error:
    mov si, .error_msg
    call print_string
.done:
    popa
    ret
.error_msg db 'Error copying file', 0x0D, 0x0A, 0

cmd_mv:
    pusha
    mov si, CMD_BUFFER + 3  ; Skip 'mv '
    mov di, si
.loop:
    lodsb
    cmp al, ' '
    jne .loop
    mov byte [si-1], 0
    push si                 ; Save destination
    
    ; Copy file
    call cmd_cp
    
    ; Delete original
    pop si
    mov di, si
    call delete_file
    
    popa
    ret

cmd_del:
    pusha
    mov si, CMD_BUFFER + 4  ; Skip 'del '
    call delete_file
    popa
    ret

cmd_run:
    pusha
    mov si, CMD_BUFFER + 4  ; Skip 'run '
    call find_file
    test ax, ax
    jz .error
    
    ; Load and execute program
    mov bx, APPS_BUFFER         ; Load address
    call read_file
    
    ; Execute program
    call KERNEL_SEGMENT:0000
    jmp .done
    
.error:
    mov si, .error_msg
    call print_string
.done:
    popa
    ret
.error_msg db 'Error running program', 0x0D, 0x0A, 0

; Create new file
; Input: DS:SI = filename
; Output: AX = cluster number (0 if error)
create_file:
    pusha
    mov di, ROOT_BUFFER
    mov cx, ROOT_ENTRIES
.search_loop:
    mov al, [di]
    test al, al
    jz .found_empty
    cmp al, 0xE5
    je .found_empty
    add di, 32
    loop .search_loop
    jmp .error
    
.found_empty:
    ; Copy filename
    push di
    mov cx, 11
    rep movsb
    
    ; Set file attributes
    pop di
    mov byte [di + 11], 0x20  ; Archive
    
    ; Find free cluster
    call find_free_cluster
    test ax, ax
    jz .error
    
    ; Set cluster in directory entry
    mov [di + 26], ax
    
    ; Write root directory
    mov ax, RESERVED_SECTORS + FAT_SIZE * 2
    mov bx, ROOT_BUFFER
    mov cx, (ROOT_ENTRIES * 32 + BYTES_PER_SECTOR - 1) / BYTES_PER_SECTOR
    call write_sectors
    
    jmp .done
    
.error:
    xor ax, ax
.done:
    mov [.cluster], ax
    popa
    mov ax, [.cluster]
    ret
.cluster dw 0

; Find free cluster in FAT
; Output: AX = cluster number (0 if none free)
find_free_cluster:
    pusha
    mov di, FAT_BUFFER
    mov cx, 0xFF8          ; Max clusters
    mov ax, 2              ; Start from cluster 2
.search_loop:
    push ax
    call get_fat_entry
    test ax, ax
    jz .found
    pop ax
    inc ax
    loop .search_loop
    xor ax, ax
    jmp .done
    
.found:
    pop ax
.done:
    mov [.cluster], ax
    popa
    mov ax, [.cluster]
    ret
.cluster dw 0

; Get FAT entry
; Input: AX = cluster number
; Output: AX = FAT entry
get_fat_entry:
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

; Write FAT entry
; Input: AX = cluster number, BX = value
write_fat_entry:
    pusha
    
    ; Calculate FAT offset
    mov cx, ax
    mov cl, 3
    mul cl
    mov cl, 2
    div cl
    
    ; Write FAT entry
    mov di, FAT_BUFFER
    add di, ax
    mov ax, [di]
    
    ; Adjust for odd/even cluster
    test byte [.odd], 1
    jz .even
    and ax, 0x000F
    shl bx, 4
    or ax, bx
    jmp .write
.even:
    and ax, 0xF000
    and bx, 0x0FFF
    or ax, bx
.write:
    mov [di], ax
    
    ; Write FAT to disk
    mov ax, RESERVED_SECTORS
    mov bx, FAT_BUFFER
    mov cx, FAT_SIZE
    call write_sectors
    
    popa
    ret
.odd db 0

; End of kernel
times 512-($-$$) db 0      ; Pad to 512 bytes
