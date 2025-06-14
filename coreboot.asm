[BITS 16]           ; Tell assembler this is 16-bit code
[ORG 0x7C00]        ; BIOS loads bootloader at this address

; Initialize segment registers
cli                 ; Disable interrupts
mov ax, 0x0000      ; Set up segments
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7C00      ; Set up stack pointer
sti                 ; Enable interrupts

; Save boot drive number
mov [boot_drive], dl

; Load FAT12 root directory
mov ax, 19          ; Root directory starts at sector 19
mov bx, 0x1000      ; Load root directory at 0x1000
call read_sector

; Search for kernel.com in root directory
mov di, 0x1000      ; Start of root directory
mov cx, 224         ; Number of root directory entries
search_kernel:
    push cx
    mov cx, 11      ; Filename length
    mov si, kernel_filename
    push di
    repe cmpsb      ; Compare filename
    pop di
    je kernel_found
    add di, 32      ; Next directory entry
    pop cx
    loop search_kernel
    jmp kernel_not_found

kernel_found:
    ; Get first cluster number
    mov ax, [di + 26]    ; First cluster is at offset 26
    mov [cluster], ax

    ; Load FAT
    mov ax, 1            ; FAT starts at sector 1
    mov bx, 0x2000       ; Load FAT at 0x2000
    call read_sector

    ; Load kernel at 0x0500
    mov bx, 0x0500       ; Load kernel at 0x0500
load_kernel:
    mov ax, [cluster]
    add ax, 31           ; Convert cluster to sector number
    call read_sector
    add bx, 512          ; Next sector

    ; Get next cluster
    mov ax, [cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx               ; ax = cluster * 3 / 2
    mov si, 0x2000
    add si, ax
    mov ax, [si]
    test dx, dx
    jz even_cluster
    shr ax, 4
even_cluster:
    and ax, 0x0FFF
    mov [cluster], ax
    cmp ax, 0x0FF8      ; End of file?
    jb load_kernel

    ; Jump to kernel at 0x0500
    jmp 0x0000:0x0500

kernel_not_found:
    mov si, error_msg
    call print_string
    jmp $

read_sector:
    push bx
    mov ah, 0x02        ; BIOS read sector function
    mov al, 1           ; Number of sectors to read
    mov ch, 0           ; Cylinder number
    mov cl, 1           ; Sector number
    mov dh, 0           ; Head number
    mov dl, [boot_drive] ; Drive number
    pop bx              ; Buffer address
    int 0x13
    jc disk_error
    ret

disk_error:
    mov si, disk_error_msg
    call print_string
    jmp $

print_string:
    mov ah, 0x0E    ; BIOS teletype function
.loop:
    lodsb           ; Load byte from SI into AL
    test al, al     ; Check if end of string
    jz .done        ; If zero, we're done
    int 0x10        ; Print character
    jmp .loop       ; Repeat for next character
.done:
    ret

; Data
boot_drive db 0
cluster dw 0
kernel_filename db 'CORE    COM'  ; FAT12 filename format
error_msg db 'Kernel not found', 0
disk_error_msg db 'Disk error', 0

times 510-($-$$) db 0   ; Pad remaining bytes with 0
dw 0xAA55               ; Boot signature