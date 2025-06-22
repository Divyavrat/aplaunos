use16           ; Tell assembler this is 16-bit code
ORG 0        ; BIOS loads bootloader at this address
start:	jmp main
nop

; ------------------------------------------------------------------
; Disk description table, to make it a valid floppy
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette

; BPB and root dir variables for USB/FAT16
bpbOEM          db "Aplaun  " ; Disk label
bpbBytesPerSector:      DW 512 ; Bytes per sector
bpbSectorsPerCluster:   DB 1 ; Sectors per cluster
bpbReservedSectors:     DW 1 ; Reserved sectors for boot record
bpbNumberOfFATs:    DB 2 ; Number of copies of the FAT
bpbRootEntries:     DW 224 ; Number of entries in root dir
; (224 * 32 = 7168 = 14 sectors to read)
bpbTotalSectors:    DW 2880 ; Number of logical sectors
bpbMedia:       DB 0xf0  ;; 0xF1 ; Medium descriptor byte
bpbSectorsPerFAT:   DW 9 ; Sectors per FAT
bpbSectorsPerTrack:     DW 18 ; Sectors per track (36/cylinder)
bpbHeadsPerCylinder:    DW 2 ; Number of sides/heads
bpbHiddenSectors:   DD 0 ; Number of hidden sectors
bpbTotalSectorsBig:     DD 0 ; Number of LBA sectors
bsDriveNumber:          DB 0 ; Drive No: 0
bsUnused:       DB 0
bsExtBootSignature:     DB 0x29;0x41 ; Drive signature: 41 for floppy
bsSerialNumber:         DD 0xa0a1a2a3 ; Volume ID: any number
bsVolumeLabel:          DB "MOS FLOPPY " ; Volume Label: any 11 chars
bsFileSystem:           DB "FAT12   " ; File system type: don't change!
root_dir_sector        dw 0
root_dir_size          dw 0

main:

; Save boot drive number
mov [boot_drive], dl    ; Save boot drive number (BIOS puts it in DL)

; Initialize segment registers
cli                 ; Disable interrupts
mov ax, 0x07C0      ; Set up segments
mov ds, ax
mov es, ax
mov fs, ax
mov gs, ax
mov ax, 0x0000      ; set the stack
mov ss, ax
mov sp, 0xFFFF
sti                 ; Enable interrupts

; Read BPB from boot sector (0x7C00)
mov ax, 0x07C0
mov ds, ax
mov ax, [0x0B]      ; bytes per sector
mov [bpbBytesPerSector], ax
mov al, [0x0D]      ; sectors per cluster
mov [bpbSectorsPerCluster], al
mov ax, [0x0E]      ; reserved sectors
mov [bpbReservedSectors], ax
mov al, [0x10]      ; number of FATs
mov [bpbNumberOfFATs], al
mov ax, [0x11]      ; root entries
mov [bpbRootEntries], ax
mov ax, [0x13]      ; total sectors
mov [bpbTotalSectors], ax
mov al, [0x15]      ; media descriptor
mov [bpbMedia], al
mov ax, [0x16]      ; sectors per FAT
mov [bpbSectorsPerFAT], ax

; Calculate root directory sector
mov al, [bpbNumberOfFATs]
mov ah, 0
mov cx, [bpbSectorsPerFAT]
mul cx                  ; ax = num_fats * sectors_per_fat
add ax, [bpbReservedSectors] ; ax = reserved_sectors + (num_fats * sectors_per_fat)
mov [root_dir_sector], ax

; Calculate root directory size (in sectors)
mov ax, [bpbRootEntries]
mov bx, 32
mul bx                  ; ax = root_entries * 32
div word [bpbBytesPerSector] ; ax = size in sectors
mov [root_dir_size], ax


; text mode
mov ah, 0x0E            ; BIOS Teletype Output function
mov ax, 3
mov bx, 0
int 10h
mov ax, 1003h
int 10h
mov si, bpbOEM
call print_string

; Load FAT16 root directory
mov si, [root_dir_sector]
mov cx, [root_dir_size]
mov bx, 0x1000      ; Load root directory at 0x1000

read_root_dir_loop:
    mov ax, si
    call read_sector
    add bx, [bpbBytesPerSector]
    inc si
    loop read_root_dir_loop

; Search for kernel.com in root directory
mov di, 0x1000      ; Start of root directory
mov cx, [bpbRootEntries]         ; Number of root directory entries
search_kernel_loop:
    push di             ; Save pointer to the start of the current entry
    
    ; Compare filename
    mov si, kernel_filename
    push cx             ; Save the outer loop counter
    mov cx, 11          ; Filename is 11 bytes long
    repe cmpsb          ; Compare bytes
    pop cx              ; Restore the outer loop counter
    je kernel_found     ; If they match, we found it!

    pop di              ; Restore pointer to the current entry
    add di, 32          ; Move to the next 32-byte directory entry
    loop search_kernel_loop ; Loop until all entries are checked

    jmp kernel_not_found; If loop finishes, kernel was not found

kernel_found:
    pop di              ; Clean up the stack (from the push di before the jump)
    ; Get first cluster number
    mov ax, [di + 26]    ; First cluster is at offset 26 in the directory entry
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
    ; ax = LBA, bx = buffer address
    push cx              ; Save for calculations
    push dx              ; Save for calculations

    ; temp = LBA / SPT; sector = (LBA % SPT) + 1
    xor dx, dx
    mov cx, [bpbSectorsPerTrack] ; cx = 18
    div cx               ; ax = temp (LBA/18), dx = sector-1
    mov cl, dl
    inc cl               ; cl = sector

    ; ax has temp
    ; cylinder = temp / HPC; head = temp % HPC
    xor dx, dx
    mov cx, [bpbHeadsPerCylinder] ; cx = 2
    div cx               ; ax = cylinder, dx = head
    
    mov ch, al           ; ch = cylinder
    mov dh, dl           ; dh = head
    
    ; Combine high cylinder bits if necessary (not for floppy)
    
    mov ah, 2            ; Read function
    mov al, 1            ; Read 1 sector
    mov dl, [boot_drive]
    ; cx has cylinder/sector, dx has head
    ; bx has buffer address (wasn't touched)
    int 0x13
    
    pop dx
    pop cx
    jc disk_error
    ret

print_hex_word:
    push ax
    mov al, ah
    call print_hex_byte
    pop ax
print_hex_byte:
    push ax
    shr al, 4
    call print_hex_digit
    pop ax
print_hex_digit:
    and al, 0x0F
    add al, '0'
    cmp al, '9'
    jbe .done
    add al, 'A' - '9' - 1
.done:
    mov ah, 0x0E
    int 0x10
    ret

print_registers:
    push ax
    call print_hex_word
    mov ax,bx
    call print_hex_word
    mov ax,cx
    call print_hex_word
    mov ax,dx
    call print_hex_word
    pop ax
    ret

disk_error:
    push ax
    mov si, disk_error_msg
    call print_string
    pop ax
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
kernel_filename db 'CORE    COM',0; FAT12 filename format
error_msg db 'N/A', 0
disk_error_msg db 'Error', 0
filename_buffer:
times 12 db 0    ; Buffer for temporary filename storage
times 510-($-$$) db 0   ; Pad remaining bytes with 0
dw 0xAA55               ; Boot signature