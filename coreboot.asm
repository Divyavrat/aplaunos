use16
org 0

jmp start
nop

; FAT12 BIOS Parameter Block (essential fields only)
bpbOEM          db "Aplaun  " ; Disk label
bpbBytesPerSector:      DW 512
bpbSectorsPerCluster:   DB 1
bpbReservedSectors:     DW 1
bpbNumberOfFATs:        DB 2
bpbRootEntries:         DW 224
bpbTotalSectors:        DW 2880
bpbMedia:               DB 0xF0
bpbSectorsPerFAT:       DW 9
bpbSectorsPerTrack:     DW 18
bpbHeadsPerCylinder:    DW 2
bpbHiddenSectors:   DD 0 ; Number of hidden sectors
bpbTotalSectorsBig:     DD 0 ; Number of LBA sectors
bsDriveNumber:          DB 0
bsUnused:       DB 0
bsExtBootSignature:     DB 0x29;0x41 ; Drive signature: 41 for floppy
bsSerialNumber:         DD 0xa0a1a2a3 ; Volume ID: any number
bsVolumeLabel:          DB "MOS FLOPPY " ; Volume Label: any 11 chars
bsFileSystem:           DB "FAT12   " ; File system type: don't change!


start:
    ; Set up segments and stack
    mov [bsDriveNumber], dl
    cli
    mov ax, 0x07C0
    mov ds, ax
    mov es, ax
    mov ax, 0x9000 ; Stack segment
    mov ss, ax
    mov sp, 0xFFFF
    sti

    ; Calculate root directory location
    ; root_dir_sector = reserved_sectors + (num_fats * sectors_per_fat)
    mov al, [bpbNumberOfFATs]
    mov ah, 0
    mov cx, [bpbSectorsPerFAT]
    mul cx
    add ax, [bpbReservedSectors]
    mov [root_dir_sector], ax

    ; Calculate root directory size in sectors
    ; root_dir_size = (root_entries * 32) / bytes_per_sector
    mov ax, [bpbRootEntries]
    mov bx, 32
    mul bx
    div word [bpbBytesPerSector]
    mov [root_dir_size], ax

    ; Load root directory into memory at 0x7E00 (just after bootloader)
    mov si, [root_dir_sector]
    mov cx, [root_dir_size]
    mov bx, 0x0200 ; es:bx = 07C0:0200 = 0x7E00
read_root_loop:
    call read_sector
    add bx, [bpbBytesPerSector]
    inc si
    loop read_root_loop

    call print_char_al
    mov al, '1'
    call print_char_al

    ; Search for CORE.COM in the root directory
    mov di, 0x0200 ; Start of root directory in memory
    mov cx, [bpbRootEntries]
search_file_loop:
    push di
    mov si, filename
    push cx
    mov cx, 11
    repe cmpsb
    pop cx
    je file_found
    pop di
    add di, 32 ; Next directory entry
    loop search_file_loop
    jmp failure ; Hang if not found

file_found:
    pop di
    mov ax, [di + 26] ; First cluster of the file
    mov [cluster], ax

    mov al, '2'
    call print_char_al

    ; Load FAT into memory at 0x8000
    ; FAT location = reserved_sectors
    mov si, [bpbReservedSectors]
    mov cx, [bpbSectorsPerFAT]
    mov bx, 0x0400 ; es:bx = 07C0:0400 = 0x8000
read_fat_loop:
    call read_sector
    add bx, [bpbBytesPerSector]
    inc si
    loop read_fat_loop

    mov al, '3'
    call print_char_al

    ; Load the kernel file into memory at 0x0500
    mov bx, 0x0500 ; Load address
load_file_loop:
    mov ax, [cluster]
    add ax, 31 ; First data sector = root_dir_sectors + fat_sectors*num_fats + reserved_sectors - 2 clusters
               ; Simplified: cluster + 31 for standard 1.44MB floppy
    push es
    xor ax, ax
    mov es, ax ; es:bx = 0000:0500
    call read_sector
    pop es
    add bx, [bpbBytesPerSector]

    ; Calculate next cluster from FAT
    mov ax, [cluster]
    mov cx, 3
    mul cx
    mov cx, 2
    div cx
    mov si, 0x0400 ; FAT is at 07C0:0400
    add si, ax
    mov ax, [si]
    test dx, dx
    jz .even_cluster
    shr ax, 4
.even_cluster:
    and ax, 0x0FFF
    mov [cluster], ax
    cmp ax, 0x0FF8 ; Check for end-of-file marker
    jb load_file_loop

    mov al, '4'
    call print_char_al

    ; Jump to the loaded kernel
    jmp 0x0000:0x0500

failure:
    jmp $ ; Infinite loop on failure

print_char_al:
    mov ah, 0x0E
    int 0x10
    ret

read_sector:
    ; ax = LBA, es:bx = buffer
    pusha
    mov bp, 3 ; Retry count
.retry:
    ; Convert LBA to CHS
    push ax
    xor dx, dx
    mov ax, si
    div word [bpbSectorsPerTrack]
    mov cl, dl
    inc cl
    xor dx, dx
    div word [bpbHeadsPerCylinder]
    mov ch, al
    mov dh, dl
    mov ah, 0x02
    mov al, 1
    mov dl, [bsDriveNumber]
    int 0x13
    jnc .success
    ; Reset disk and retry
    mov ah, 0x00
    int 0x13
    pop ax
    mov si, ax
    dec bp
    jnz .retry
    jmp failure
.success:
    pop ax
    popa
    ret

; --- Data ---
cluster dw 0
root_dir_sector dw 0
root_dir_size dw 0
filename db 'CORE    COM'

times 510-($-$$) db 0
dw 0xAA55
