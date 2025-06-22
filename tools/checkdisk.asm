
; Filesystem error codes
fs_error_codes:
.no_error:       db 0
.disk_full:      db 1
.bad_cluster:    db 2
.fat_corrupt:    db 3
.dir_full:       db 4
.io_error:       db 5

; Error messages table
fs_error_msgs:
	dw .msg0, .msg1, .msg2, .msg3, .msg4, .msg5
.msg0: db 'No error', 0
.msg1: db 'Disk full', 0
.msg2: db 'Bad cluster found', 0
.msg3: db 'FAT corruption detected', 0
.msg4: db 'Directory full', 0 
.msg5: db 'I/O error', 0


; Initialize disk information structure
; Must be called after disk parameters are loaded
init_disk_info:
	pusha
	
	; Calculate FAT size in sectors
	xor ax, ax
	mov al, [bpbNumberOfFATs]
	mul word [bpbSectorsPerFAT]
	mov [diskinfo.fat_size], ax      ; Size of each FAT in sectors
	
	; Calculate root directory size in bytes
	mov ax, 32                       ; 32 bytes per entry
	mul word [bpbRootEntries]
	mov [diskinfo.root_size], ax     ; Size of root directory in bytes
	
	; Calculate sector offsets for different regions
	mov ax, [bpbReservedSectors]     ; Reserved sectors
	mov [diskinfo.fat_begin_lba], ax ; First FAT starts after reserved sectors
	
	mov al, [bpbNumberOfFATs]        ; Calculate root dir start
	mul word [bpbSectorsPerFAT]      ; Multiply by sectors per FAT
	add ax, [bpbReservedSectors]     ; Add reserved sectors
	mov [diskinfo.root_begin_lba], ax; Root directory starts after FATs
	
	push ax                          ; Save root_begin_lba
	mov ax, [diskinfo.root_size]     ; Convert root dir size to sectors
	add ax, 511                      ; Round up to next sector
	shr ax, 9                        ; Divide by 512 (bytes per sector)
	pop bx                           ; Restore root_begin_lba
	add ax, bx                       ; Data area starts after root dir
	mov [diskinfo.data_begin_lba], ax    ; Store data area start
	
	; Calculate total number of clusters
	mov ax, [bpbTotalSectors]
	sub ax, [diskinfo.data_begin_lba]  ; Get sectors in data area
	xor dx, dx
	div word [bpbSectorsPerCluster]    ; Convert to clusters
	mov [diskinfo.total_clusters], ax   ; Store total clusters
	
	; Calculate last cluster and total entries
	add ax, 1                          ; Add first data cluster (2)
	mov [diskinfo.last_cluster], ax    ; Store last valid cluster
	
	; Calculate total FAT entries
	mov ax, [diskinfo.fat_size]        ; Get sectors per FAT
	mov dx, 512                        ; Bytes per sector
	mul dx                             ; Get total bytes
	mov cx, 3                          ; Each FAT entry is 12 bits (1.5 bytes)
	mul cx                             ; 
	mov cx, 2                          ; Divide by 2 to get number of entries
	div cx
	mov [diskinfo.fat_entries], ax     ; Store number of FAT entries
	
	; Determine FAT type based on total clusters
	mov ax, [diskinfo.total_clusters]
	cmp ax, 4085                       ; FAT12 = up to 4085 clusters
	jb .fat12
	mov byte [diskinfo.fat_type], 16   ; FAT16 if >= 4085 clusters
	jmp .done
.fat12:
	mov byte [diskinfo.fat_type], 12   ; FAT12 if < 4085 clusters
.done:
	popa
	clc                                ; Clear carry on success
	ret


; Last filesystem error
fs_last_error: db 0

; Log filesystem error
; IN: AL = error code
log_fs_error:
	pusha
	mov [fs_last_error], al    ; Store error code
	
	; Get error message
	xor ah, ah
	shl ax, 1                  ; Multiply by 2 for word offset
	add ax, ax                     ; Multiply by 2 for word offset
	mov si, fs_error_msgs
	add si, ax                   ; Add offset to array base
	mov si, [si]                ; Get message pointer

	; Print error message	
	push si
	mov si, fs_error_prefix
	call os_print_string          ; Print prefix
	pop si
	call os_print_string          ; Print message
	call os_print_newline
	
.done:
	popa
	ret

fs_error_prefix: db 'Filesystem Error: ', 0
debug_flags:     db 0

; Check filesystem consistency
; Returns: Carry set if errors found
check_filesystem:
	pusha
	
	; Verify FAT copies match
	call verify_fat_copies
	jc .error
	
	; Check for cross-linked clusters
	call check_cluster_chains
	jc .error
	
	; Verify directory entries
	call verify_directories
	jc .error
	
	popa
	clc                     ; No errors found
	ret
	
.error:
	popa 
	stc                     ; Errors detected
	ret

; =================================================================
; verify_dir.asm -- Directory verification routines
; =================================================================

; ------------------------------------------------------------------
; verify_directories -- Verify all directory entries in filesystem
; OUT: Carry clear if OK, set if errors found

verify_directories:
    pusha
    
    ; First verify root directory entries
    mov ax, [bpbRootEntries]
    call check_dir_entries
    jc .error
    
    ; Now check all subdirectories
    call check_subdirs
    jc .error
    
    popa
    clc                     ; No errors found
    ret
    
.error:
    popa
    stc                     ; Errors detected
    ret

; ------------------------------------------------------------------
; check_dir_entries -- Check directory entries at current position
; IN: AX = number of directory entries to check
; OUT: Carry set if errors found
check_dir_entries:
    pusha
    
.next_entry:
    ; Check if entry is used
    mov al, [es:di]
    cmp al, 0              ; End of directory
    je .done
    cmp al, 0xE5          ; Deleted entry
    je .skip_entry
    
    ; Check attributes
    mov al, [es:di+11]
    cmp al, 0x0F          ; Long filename entry
    je .skip_entry
    test al, 0x08         ; Volume label
    jnz .skip_entry
    
    ; Get starting cluster
    mov ax, [es:di+26]    ; First cluster number
    test ax, ax           ; Zero is valid for empty files
    jz .skip_entry
    
    ; Verify cluster is in valid range
    cmp ax, 0xFF7         ; Bad cluster
    je .error
    cmp ax, 0xFF8         ; End of chain
    jae .error
    
    ; Check cluster chain if directory
    mov al, [es:di+11]    ; Get attributes
    test al, 0x10         ; Is it a directory?
    jz .skip_entry
    
    push di
    mov di, ax            ; Get cluster chain
    call check_cluster_chain
    pop di
    jc .error
    
.skip_entry:
    add di, 32            ; Next directory entry
    dec word [bp-2]       ; Counter
    jnz .next_entry
    
.done:
    popa
    clc
    ret
    
.error:
    popa
    stc
    ret

; ------------------------------------------------------------------
; check_subdirs -- Check all subdirectories recursively
; OUT: Carry set if errors found
check_subdirs:
    pusha
    
    call read_root_dir    ; Start with root directory
    
.next_subdir:
    ; Get next subdirectory
    mov al, [es:di+11]    ; Get attributes
    cmp al, 0x10          ; Is it a directory?
    jne .skip
    
    ; Skip . and .. entries
    mov al, [es:di]
    cmp al, '.'
    je .skip
    
    ; Found subdirectory, verify it
    mov ax, [es:di+26]    ; First cluster
    push di
    
    ; Read subdirectory contents
    call read_subdir
    jc .error
    
    ; Verify entries in this subdirectory
    mov ax, [dirsize]     ; Number of entries
    call check_dir_entries
    jc .error
    
    pop di
    
.skip:
    add di, 32            ; Next entry
    dec word [bp-2]       ; Counter
    jnz .next_subdir

    popa
    clc
    ret
    
.error:
    pop di               ; Clean up stack
    popa
    stc
    ret

; ------------------------------------------------------------------
; Helper functions

; Read sector containing subdirectory starting at cluster AX
read_subdir:
    pusha
    
    ; Convert cluster to sector
    sub ax, 2              ; First data cluster is 2
    mov bx, [bpbSecPerClus]
    mul bx                 ; AX = sectors from start of data
    add ax, [datasector]   ; Add start of data area
    
    ; Read sectors into buffer
    call disk_convert_l2hts
    mov bx, buffer
    mov ah, 2              ; Read sectors
    mov al, [bpbSecPerClus]
    stc
    int 13h
    jc .error
    
    popa
    clc
    ret
    
.error:
    popa 
    stc
    ret


; Verify FAT copies match
verify_fat_copies:
	pusha
	
	; Read first FAT
	mov ax, [bpbReservedSectors]
	mov bl, [bpbSectorsPerFAT]
	mov dx, [dir_seg]
	mov es, dx
	mov bx, [loc3]
	call ReadSectors
	jc .read_error
	
	; Read second FAT to compare
	push bx                     ; Save FAT1 location
	add bx, [bpbSectorsPerFAT] ; Point to FAT2
	mov ax, [bpbReservedSectors]
	add ax, [bpbSectorsPerFAT] ; Start of FAT2
	call ReadSectors
	pop si                     ; Restore FAT1 ptr to SI
	jc .read_error
	
	; Compare FATs
	mov cx, [bpbSectorsPerFAT]
	shl cx, 9                  ; Convert sectors to bytes
	mov di, bx                 ; FAT2 location in DI
	repe cmpsb
	jne .mismatch
	
	popa
	clc
	ret

.read_error:
	mov al, [fs_error_codes.io_error]
	call log_fs_error
	popa
	stc
	ret
	
.mismatch:
	mov al, [fs_error_codes.fat_corrupt]
	call log_fs_error
	popa
	stc
	ret

; Check cluster chains for cross-links
check_cluster_chains:
	pusha
	
	; Initialize cluster usage map
	mov di, cluster_map
	mov cx, [diskinfo.fat_entries]
	xor ax, ax
	rep stosb
	
	; Start from root directory
	mov ax, [bpbRootEntries]
	call check_dir_clusters
	jc .error
	
	popa
	clc
	ret
	
.error:
	popa
	stc
	ret

; Check clusters used by a directory
; IN: AX = number of directory entries
check_dir_clusters:
	pusha
	
.next_entry:
	; Check if entry is used
	mov al, [es:di]
	cmp al, 0                  ; End of directory
	je .done
	cmp al, 0xE5              ; Deleted entry
	je .skip_entry
	
	; Get starting cluster
	mov ax, [es:di+26]        ; First cluster
	test ax, ax               ; Skip if no clusters
	jz .skip_entry
	
	; Follow cluster chain
	call check_cluster_chain
	jc .error
	
.skip_entry:
	add di, 32                ; Next directory entry
	dec word [bp-2]           ; Counter
	jnz .next_entry
	
.done:
	popa
	clc
	ret
	
.error:
	popa
	stc
	ret

; Check a single cluster chain for validity
; IN: AX = starting cluster
check_cluster_chain:
	push ax
	
.next_cluster:
	; Validate cluster number
	cmp ax, 2
	jb .bad_cluster
	cmp ax, [diskinfo.last_cluster]
	ja .bad_cluster
	
	; Check if cluster already used
	mov bx, ax
	mov cl, bl
	and cl, 7                  ; Bit offset
	shr bx, 3                  ; Byte offset
	mov dl, 1
	shl dl, cl                ; Bit mask
	test [cluster_map+bx], dl  ; Test if bit set
	jnz .cross_linked
	or [cluster_map+bx], dl    ; Mark cluster used
	
	; Get next cluster
	call get_cluster_data
	cmp dx, 0xFF8             ; End marker?
	jae .done
	
	mov ax, dx                 ; Load next cluster
	jmp .next_cluster
	
.done:
	pop ax
	clc
	ret
	
.bad_cluster:
	mov al, [fs_error_codes.bad_cluster]
	call log_fs_error
	pop ax
	stc
	ret
	
.cross_linked:
	mov al, [fs_error_codes.fat_corrupt]
	call log_fs_error
	pop ax
	stc
	ret


; FAT filesystem information structure
diskinfo:
	.fat_size         dw 0        ; Size of FAT in sectors
	.root_size        dw 0        ; Size of root directory in bytes
	.fat_begin_lba    dw 0        ; Starting LBA of first FAT
	.root_begin_lba   dw 0        ; Starting LBA of root directory
	.data_begin_lba   dw 0        ; Starting LBA of data area
	.total_clusters   dw 0        ; Total number of clusters
	.last_cluster     dw 0        ; Last valid cluster number
	.fat_type         db 0        ; FAT type (12 for FAT12, 16 for FAT16)
	.fat_entries      dw 0        ; Number of entries in FAT


; Cluster usage bitmap
cluster_map: times 1152 db 0   ; Support up to 9216 clusters (12-bit FAT)
