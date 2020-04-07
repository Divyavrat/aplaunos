; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Based on the MikeOS Kernel
; Copyright (C) 2006 - 2012 MikeOS Developers -- see doc/MikeOS/LICENSE.TXT
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; FAT12 FLOPPY DISK ROUTINES
; ==================================================================

	

; ------------------------------------------------------------------
; Call: os_get_file_list
; Description: Create a list of files 
; IN: AX = location to store list
; OUT: none (list stored)

os_get_file_list:
	API_START
	API_SEGMENTS
	
	mov word di, ax
	
	call func_examine_disk			; Read the disk parameters
	jc .failed
	
	call func_examine_curr_dir		; Read the current directory
	jc .failed
	
.get_filename:
	call func_read_dir_entry		; Collect a directory entry
	jc .finish				; If there are no more entries
	
	call func_copy_string_g2f		; Copy the filename to user segments
	
	mov ax, si				; Move the list pointer past the filename
	call os_string_length
	add di, ax
	
	mov si, .comma_string
	call func_copy_string_g2f
	
	inc di
	
	jmp .get_filename
	
.finish:	
	dec di
	mov si, .comma_string + 1
	call func_copy_string_g2f
	
	API_END
	
.failed:
	mov si, .comma_string + 1
	call func_copy_string_g2f
	
	API_END
	
	.comma_string				db ',', 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_load_file
; Description: Load a file into memory
; IN: AX = pointer to filename, ES:CX = load location
; OUT: BX = file size, CF = set if load failed, otherwise clear

os_load_file:
	API_START
	mov dx, es				; Remember extra segment for output address
	API_SEGMENTS
	
	mov [.load_loc], cx

	call func_examine_disk			; Read all the data needed: disk parameters, FAT and directory; bailout if any of these reads fail
	jc .failed
	
	call func_read_fat
	jc .failed
	call func_examine_curr_dir
	jc .failed
	
	mov si, ax				; Copy the filename for the program buffer to a local buffer
	mov di, .filename
	call func_copy_string_f2g

	mov di, .filename			; Search the directory for the specified file entry
	call func_find_file
	jc .failed				; Bailout if failure, otherwise we have the parameters to read the file
	
	mov [.filesize], ax			; Remember the size given by the file entry
	
	mov ax, bx				; Use the first entry to create a list of clusters
	call func_read_fat_chain
	mov di, si
	
	mov si, [.load_loc]			; Cluster will be read to DX:SI
	
.read_clusters:
	mov ax, [di]				; Get a cluster number from the list and try to read it
	call func_read_cluster
	jc .failed				; Bailout if one of the reads fail
	
	add si, 512
	add di, 2				; Otherwise, move onto the next cluster
	loop .read_clusters
	
	mov bx, [.filesize]
	clc
	API_RETURN_NC bx			; Return the file size
	
.failed:
	stc
	API_END_SC
	
.filename					__FILENAME_BUFFER__
.filesize					dw 0
.load_loc					dw 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_write_file
; Description: Writes a file to the disk
; IN: AX = filename pointer, ES:BX = file location, CX = file size
; OUT: CF = set if failed, otherwise clear

os_write_file:
	API_START
	mov dx, es
	API_SEGMENTS
	
	mov [.file_loc], bx
	mov [.file_size], cx
	mov [.file_segment], dx
	
	mov si, ax
	mov di, .file_name
	call func_copy_string_f2g
	call func_examine_disk			; Read the disk information
	jc .failed
	call func_read_fat
	jc .failed
	
	cmp word [.file_size], 0
	je .empty_file
	
	mov ax, [.file_size]
	shr ax, 9
	inc ax
	mov [.clusters], ax
	
	jmp .find_file
	
.empty_file:
	; This will prevent a cluster chain being created later
	mov word [.clusters], 0

.find_file:	
	call func_examine_curr_dir		; Read the current directory and scan for the file
	jc .failed
	mov di, .file_name
	call func_find_file
	jnc .failed				; Bailout if it already exists (was found)
	
	mov ax, [.clusters]			; Create a new FAT cluster chain for the file
	call func_create_fat_chain
	mov [.first_cluster], ax
	
	call func_reset_dir			; Create a directory entry
	mov ax, [.file_size]
	mov bx, [.first_cluster]
	mov cl, 0
	mov si, .file_name
	call func_new_dir_entry
	
	mov ax, [.first_cluster]		; Now write to the clusters listed in the new chain
	call func_read_fat_chain
	mov di, si
	mov si, [.file_loc]
	mov dx, [.file_segment]
	
.write_clusters:
	mov ax, [di]				; AX = sector number, DX:SI = cluster data, DI = cluster list pointer
	xchg bx, bx
	call func_write_cluster
	jc .failed				; Bailout if a write fails
	
	add si, 512				; Move to the next sector of the file and the next entry in the file list
	add di, 2

	loop .write_clusters			; Keep writing sectors from the list until it is finished
	
	call func_write_fat			; Write the new FAT and directory contents back to the disk
	jc .failed
	call func_write_curr_dir
	jc .failed
	
	clc
	API_END_NC

.failed:
	API_END_SC
	
	.file_name				__FILENAME_BUFFER__
	.file_size				dw 0
	.file_loc				dw 0
	.file_segment				dw 0
	.clusters				dw 0
	.first_cluster				dw 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_file_exists
; Description: Checks if a file exists on the disk
; Input: AX = pointer to filename string
; Output: CF = set if not found, otherwise clear

os_file_exists:
	API_START
	API_SEGMENTS
	
	mov si, ax
	mov di, .filename
	call func_copy_string_f2g
	
	call func_examine_disk			; Read needed information from the disk
	jc .failed				; Report failure on a read error
	call func_examine_curr_dir
	jc .failed
	
	call func_find_file			; Search the current directory, this will set or clear the carry flag correctly
	API_END
	
.failed:
	stc
	API_END
	
	.filename					__FILENAME_BUFFER__
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_create_file
; Description: Creates a blank file
; Input: AX = pointer to filename string
; Output: CF = set if failed, otherwise clear

os_create_file:
	API_START
	API_SEGMENTS
	
	mov si, ax
	mov di, .filename
	call func_copy_string_f2g
	
	call func_examine_disk			; Load required data, bailout if error
	jc .failed
	call func_examine_curr_dir
	jc .failed
	
	mov ax, 0				; Create a new filename with zero file size, cluster zero and no attributes and current filename
	mov bx, 0
	mov cl, 0
	mov si, .filename
	call func_new_dir_entry
	jc .failed
	
	call func_write_curr_dir		; Write the directory we just edited
	jc .failed
	
	API_END
	
.failed:
	API_END
	
	.filename				__FILENAME_BUFFER__
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_remove_file
; Description: Deletes a file from a disk
; Input: AX = pointer to filename string
; Output: CF = set if failed, otherwise clear

os_remove_file:
	API_START
	API_SEGMENTS
	
	mov si, ax
	mov di, .filename
	call func_copy_string_f2g
	
	call func_examine_disk
	jc .failed
	call func_examine_curr_dir
	jc .failed
	
	call func_find_file			; Find the directory entry and remove it
	jc .failed
	call func_remove_dir_entry
	
	call func_write_curr_dir		; Write the changes to the disk
	jc .failed
	
	API_END
	
.failed:
	API_END
	
	.filename				__FILENAME_BUFFER__
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_rename_file
; Description: Changes the name of a file.
; Input: AX = source filename pointer, BX = new filename pointer
; Output: CF = set if failed, otherwise clear

os_rename_file:
	API_START
	API_SEGMENTS
	
	mov si, ax
	mov di, .source_filename
	call func_copy_string_f2g
	
	mov si, bx
	mov di, .new_filename
	call func_copy_string_f2g
	
	call func_examine_disk
	jc .failed
	call func_examine_curr_dir
	jc .failed
	
	mov di, .source_filename
	call func_find_file			; Find the file entry in the directory
	jc .failed
	mov si, .new_filename			; Store it back in the directory with the new name
	call func_edit_dir_entry
	
	call func_write_curr_dir		; Write back changes

	API_END
	
.failed:
	API_END

	.source_filename			__FILENAME_BUFFER__
	.new_filename				__FILENAME_BUFFER__
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_get_file_size
; Description: Returns the size of a file.
; Input: AX = filename pointer
; Output: CF = set if file not found, otherwise clear and BX = file size

os_get_file_size:
	API_START
	API_SEGMENTS
	
	mov si, ax
	mov di, .filename
	call func_copy_string_f2g
	
	call func_examine_disk
	jc .failed
	call func_examine_curr_dir
	jc .failed
	
	call func_find_file			; Find the file entry, this will return 
	jc .failed
	
	mov bx, ax
	API_RETURN_NC bx
	
.failed:
	API_END_SC
	
	.filename				__FILENAME_BUFFER__
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: os_enter_directory
; Description: Enter a subdirectory of the current directory.
; Input: AX = directory name
; Output: CF = set if error, otherwise clear

os_enter_directory:
	API_START
	API_SEGMENTS 

	mov si, ax
	mov di, .filename
	call func_copy_string_f2g

	call func_examine_disk
	jc .failed
	call func_examine_curr_dir
	jc .failed

	call func_find_directory
	jc .failed

	call func_enter_subdirectory

	API_END_NC

.failed:
	API_END_SC

.filename 					__FILENAME_BUFFER__


; ------------------------------------------------------------------



; ==================================================================



; ==================================================================
; FAT12 Subsystem - Low level file system operations
; ==================================================================

; ------------------------------------------------------------------
; Call: func_disk_reset
; Description: Resets the floppy disk
; IN/OUT: CF = set if failed, otherwise clear

func_disk_reset:	
	push ax
	push dx
	
	mov ah, 00h				; BIOS disk function 0 - reset disk
	mov dl, [bootdev]			; Device number is boot device
	stc
	int 13h
	
	pop dx
	pop ax
	ret
; ------------------------------------------------------------------




; ------------------------------------------------------------------
; Call: func_calculate_chs
; Description: Converts sector numbers into CHS values
; IN: AX = logical sector
; OUT: memory bytes diskinfo.cylinder, diskinfo.sector 
; 	and diskinfo.head bytes set to correct values

func_calculate_chs:
	pusha
	
	mov dx, 0				; Sector = (logical % (sectors per track)) + 1
	div word [SecsPerTrack]
	mov cx, ax				; Remember (logical / (sectors per track)) for the next two calculations
	inc dl
	mov [diskinfo.sector], dl
	
	mov dx, 0				; Head = (logical / (sectors per track)) % (Sides)
	mov ax, cx
	div word [Sides]
	mov [diskinfo.head], dl
	
	mov dx, 0				; Cylinder = (logical / (sectors per track)) / (Sides)
	mov ax, cx
	div word [Sides]
	mov [diskinfo.cylinder], al
	
	popa
	ret
	
	
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_sectors
; Description: Reads sectors from the floppy disk
; IN: AX = first sector, BL = amount to read, DX:SI = output address
; OUT: CF = set if read failed, clear on success

func_read_sectors:
	push es
	pusha
	
	mov byte [.retries], DISK_RETRIES
	call func_calculate_chs			; Convert the logical sector into CHS format
	
	mov es, dx				; Set ES (used by BIOS Disk Functions) to the required segment	
	
.retry:
	mov ah, 02h				; BIOS Disk function 2 - read sectors
	mov al, bl				; Number of sectors to read
	mov bx, si				; Memory location to store
	mov ch, [diskinfo.cylinder]		; Use the CHS values we just got
	mov cl, [diskinfo.sector]
	mov dh, [diskinfo.head]
	mov dl, [bootdev]			; Use the boot drive as the device
	stc					; Some old BIOS's don't set the carry flag properly
	int 13h
	jc .read_error				; The carry flag is set of a read error
	
.finish:
	popa					; If there's no error then we're done!
	pop es
	ret
	
.read_error:
	call func_disk_reset			; If there's a read error then reset the disk and try again
	jc .finish				; If the reset failed then bailout
	
	dec byte [.retries]
	cmp byte [.retries], 0
	jne .retry
	
	stc
	jmp .finish
	
.retries					db 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_sectors
; Description: Writes sectors from the floppy disk
; IN: AX = first sector, BL = amount to write, DX:SI = buffer address
; OUT: CF = set if write failed, clear on success

func_write_sectors:
	push es
	pusha
	
	call func_calculate_chs
	
	mov es, dx
	
	mov ah, 03h				; BIOS Disk Function 3 - Write Sectors
	mov al, bl				; Number of sectors to write
	mov bx, si				; Memory locate to write from
	mov ch, [diskinfo.cylinder]		; Use the CHS values we just got
	mov cl, [diskinfo.sector]
	mov dh, [diskinfo.head]
	mov dl, [bootdev]			; Use the boot drive as the device
	stc
	int 13h

	popa
	pop es
	
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_fat
; Description: Read the FAT from the disk and store it in the disk buffer
; IN/OUT: none

func_read_fat:
	pusha
	
	cmp byte [diskinfo.fat_cached], 1
	je .already_cached

	mov ax, [diskinfo.first_fat_sector]	; If the FAT is not in cache read all FAT sectors
	mov bl, [diskinfo.fat_size]
	mov dx, DISK_SEGMENT
	mov si, FIRST_FAT
	call func_read_sectors

	jc .failed
	
	mov byte [diskinfo.fat_cached], 1	; Mark the FAT is now in the cache
	
.already_cached:
	popa					; If the FAT is already cached don't read it, just return success
	clc
	ret
	
.failed:
	popa
	ret	
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_fat
; Description: Write the FAT to the disk from disk buffer
; IN/OUT: none

func_write_fat:
	cmp byte [diskinfo.fat_cached], 0
	je .not_cached

	pusha
	
	mov ax, [diskinfo.first_fat_sector]	; Write the FAT sectors from cache
	mov bl, [diskinfo.fat_size]
	mov dx, DISK_SEGMENT
	mov si, FIRST_FAT
	call func_write_sectors
	
	popa
	ret
	
.not_cached:
	stc					; Fail if the FAT has not been read
	ret
; ------------------------------------------------------------------

	
	
; ------------------------------------------------------------------
; Call: func_get_fat_entry
; Description: Read a 12-bit entry from the FAT
; IN: AX = entry number
; OUT: AX = entry value
; Note: Make sure the FAT has been read first

func_get_fat_entry:
	pusha
	push es
	
	mov dx, DISK_SEGMENT
	mov es, dx	
	
	mov si, FIRST_FAT
	mov cx, ax
	
	mov bx, ax			; Get AX * 1.5 by adding half of it to itself
	shr bx, 1
	add ax, bx
	add si, ax
	
	bt cx, 0			; Test the least significent bit to see if it is odd or even
	jnc .even
	
.odd:
	mov bx, [es:si]			; Shift out the first four bits, these belong to the next entry
	shr bx, 4			; i.e. 0x1234 to 0x0123
	jmp .finish
	
.even:
	mov bx, [es:si]			; Clear last four bits collected, these belong to the previous entry
	and bx, 0x0FFF			; i.e. 0x1234 to 0x0234
	
.finish:
	mov [.tmp], bx
	pop es
	popa
	mov ax, [.tmp]
	ret
	
.tmp					dw 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_set_fat_entry
; Description: Set a 12-bit entry in the FAT
; IN: AX = entry number, BX = value
; OUT: none
; Note: Make sure the FAT has been read first
;	Maximum value is 0x0FFF/4095

func_set_fat_entry:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	and ax, 0x0FFF			; Make sure the top bits aren't set (12-bit max)
	
	mov si, FIRST_FAT
	
	mov dx, ax			; Multiply the entry number by 1.5
	shr dx, 1
	add ax, dx
	add si, ax
	
	bt ax, 0
	jc .even
	
.odd:
	mov dx, [es:si]			; Read the word containing the entry
	shl bx, 4			; Shift the entry to set to match it's position
	and dx, 0x000F			; Clear the bits to set, leave the bits for the old entry
	or dx, bx			; Combine the bits of the other entry with the one to set
	mov [es:si], dx			; Replace the word containing the entry
	jmp .finish
	
.even:
	mov dx, [es:si]			; Read the word containing the entry
	and dx, 0xF000			; The first four bits belong to another entry, so keep them but clear the rest
	or dx, bx			; Combine the other entry's bits to the ones to set
	mov [es:si], dx			; Replace the word containing the entry
	
.finish:
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_root_dir
; Description: Reads the root directory from the disk
;	and places it in the disk buffer.
; IN/OUT: none

func_read_root_dir:
	cmp byte [directory.cached], 1		; Is there any directory cached at all?
	jne .read_directory
	
	cmp word [directory.cluster], 0		; Is the directory the root directory (0)?
	jne .read_directory
	
	clc					; If the root directory is cached then don't read it.
	ret
	
.read_directory:
	pusha
	
	mov ax, [diskinfo.root_dir_sector]	; Read root directory
	mov bl, [diskinfo.root_dir_size]
	mov dx, DISK_SEGMENT
	mov si, ACTIVE_DIRECTORY
	call func_read_sectors
	jc .failed
	
	mov byte [directory.cached], 1		; If the write succeeded, mark that the root directory is cached
	mov word [directory.cluster], 0
	
	popa
	ret
	
.failed:
	popa
	ret
	
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_root_dir
; Description: Writes the root directory to the disk
;	from the disk buffer.
; IN/OUT: none

func_write_root_dir:
	cmp byte [directory.cached], 0		; Make sure the root directory has been read
	je .not_cached
	
	cmp word [directory.cluster], 0
	jne .not_cached
	
	pusha
	
	mov ax, [diskinfo.root_dir_sector]	; Write root directory
	mov bl, [diskinfo.root_dir_size]
	mov dx, DISK_SEGMENT
	mov si, ACTIVE_DIRECTORY
	call func_write_sectors
	
	popa
	ret
	
.not_cached:
	stc					; Return immediently with failure if the directory has not been read
	ret
	
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_filename_s2d
; Description: Converts a filename from string to disk format
; 	i.e. 'FOO.BAR' to 'FOO     BAR'
; IN: SI = filename pointer
; OUT: SI = output buffer pointer
; Note: A disk filename is a fixed 11 characters in length
;	and is NOT zero-terminated.

func_filename_s2d:
	pusha
	
	mov ax, si				; make sure the filename is in uppercase to match the disk format
	call os_string_uppercase
	
	mov cx, 11				; pad disk filename with spaces
	mov di, .filename
.pad_filename:
	mov byte [di], ' '
	inc di
	loop .pad_filename
	
	mov cx, 8
	mov di, .filename
	
.copy_name:
	mov al, [si]				; copy characters from the string until the start of the extention, end of name, or eight characters
	inc si
	
	cmp al, 0
	je .finished_extention
	
	cmp al, '.'
	je .start_extention
	
	mov [di], al
	inc di
	
	loop .copy_name
	
.start_extention:
	mov cx, 3
	mov di, .extention
	
.copy_extention:
	mov al, [si]				; copy character from the string until the end of the filename or three characters
	inc si
	
	cmp al, 0
	je .finished_extention
	
	mov [di], al
	inc di
	
	loop .copy_extention
	
.finished_extention:
	popa
	mov si, .filename
	ret
	
	.filename				times 8 db 0
	.extention				times 3 db 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_filename_d2s
; Description: converts a filename from disk to string format
; 	i.e. 'FOO     BAR' to 'FOO.BAR'
; IN: SI = filename pointer
; OUT: SI = output buffer pointer

func_filename_d2s:
	pusha
	
	mov cx, 8
	mov di, .filename
	
.copy_filename:
	mov al, [si]
	inc si
	
	cmp al, ' '
	je .skip_spaces
	
	mov [di], al
	inc di
	
	loop .copy_filename
	
.start_extention:
	mov byte [di], '.'		; Place a dot before the extention
	inc di
	
	mov cx, 3
	
.copy_extention:
	mov al, [si]
	inc si
	
	mov [di], al
	inc di
	
	loop .copy_extention
	
.finish_filename:
	mov byte [di], 0		; Terminate the filename string
	inc di
	
	popa
	mov si, .filename
	ret
	
.skip_spaces:
	dec cx
	cmp cx, 0
	jne .copy_filename

;	loop .copy_filename		; Just skip over spaces until we're up to the extention
	jmp .start_extention
	
.filename				times 13 db 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_examine_root_dir
; Description: Starts a list of root directory entries
; IN/OUT: none

func_examine_root_dir:
	push ax
	
	call func_read_root_dir
	mov word [directory.start], ACTIVE_DIRECTORY
	mov word [directory.pointer], ACTIVE_DIRECTORY
	
	mov ax, [diskinfo.root_dir_entries]
	mov word [directory.remaining], ax
	mov word [directory.entries], ax
	
	pop ax
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_dir_entry
; Description: Reads a concutive directory entry and returns it's information
; IN: none
; OUT: AX = file size, BX = first cluster, CL = attributes
;	SI = filename pointer, CF = set if past end
; Note: Examine a directory before reading entries

func_read_dir_entry:	
	push es
	push dx
	push di
	push cx
	
	inc word [gs:internal_call]
	
	mov dx, DISK_SEGMENT
	mov es, dx

.try_again:	
	cmp word [directory.remaining], 0	; make sure there are entries left
	je .past_end

	
	; The first character of a filename can indicate a special meaning
	
	mov si, [directory.pointer]
	mov al, [es:si]
	
	cmp al, 0x00				; 0x00 = usused
	je .next_entry
	
	cmp al, 0xE5				; 0xE5 = deleted file
	je .next_entry
	
	cmp al, 0x2E				; 0x2E = 'dot' entry, '.' or '..'
	je .next_entry
	
	cmp al, 0x05				; 0x05 = first character actually is 0xE5 (but not a deleted file)
	je .start_special
	
.check_attributes:
	; The attribute byte could indicate a special type
	
	mov al, [es:si+11]
	
	cmp al, 0x0F				; value 0x0F = long filename entry
	je .next_entry
	
	test al, 0x08				; bit 0x08 = volume label
	jnz .next_entry
	
	test al, 0x10				; bit 0x10 = directory entry
	jnz .next_entry
	
	mov dl, al				; seems to be okay, save attributes and continue
	
	mov di, .filename			; copy filename to buffer
	mov cx, 11
	
.get_filename:
	mov al, [es:si]
	mov [ds:di], al
	inc si
	inc di
	loop .get_filename
	
	mov si, .filename			; convert filename into a string, then copy is back into the same buffer
	call func_filename_d2s
	mov di, .filename
	call os_string_copy
	
	mov si, [directory.pointer]
	mov ax, [es:si+28]			; load AX with a 16-bits size value
	mov bx, [es:si+26]			; load BX with the first cluster
	
	add word [directory.pointer], 32	; move pointer to next entry
	dec word [directory.remaining]
	
	mov si, .filename
	
	pop cx
	
	mov cl, dl
	
	dec word [gs:internal_call]
	pop di
	pop dx
	pop es
	clc
	ret
	
.past_end:
	dec word [gs:internal_call]
	pop cx
	pop di				; If the there are no entries to read, set carry and exit
	pop dx
	pop es
	
	stc
	ret
	
.next_entry:
	dec word [directory.remaining]
	add word [directory.pointer], 32
	jmp .try_again
	

.start_special:
	mov byte [es:si], 0xE5
	jmp .check_attributes
	
.filename				times 13 db 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_edit_dir_entry
; Description: Sets new data for the last directory entry read
; IN: AX = file size, BX = first cluster, CL = attributes, SI = filename pointer
; OUT: none
; Note: Requires entry to be last read with 'func_read_dir_entry'

func_edit_dir_entry:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	sub word [directory.pointer], 32	; back to the previous directory entry
	
	mov dl, cl
	
	call func_filename_s2d			; converts filename string given to disk format
	mov cx, 11
	mov di, [directory.pointer]

.copy_filename:					; copy the 11 byte disk name to the directory entry
	mov al, [ds:si]
	mov [es:di], al
	inc si
	inc di
	loop .copy_filename
	
	mov si, [directory.pointer]
	mov [es:si+11], dl			; file attributes
	mov [es:si+28], ax			; file size
	mov [es:si+26], bx			; first cluster
	
	add word [directory.pointer], 32	; restore entry pointer
	
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_remove_dir_entry
; IN/OUT: none
; Note: Requires entry to be last read with 'func_read_dir_entry'

func_remove_dir_entry:
	push es
	push dx
	push si
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	sub word[directory.pointer], 32		; set last entry
	
	mov byte al, [es:si]			; save first letter for undelete utilities
	mov byte [es:si+13], al
	
	mov si, [directory.pointer]
	mov byte [es:si], 0xE5			; mark entry as deleted
	
	add word [directory.pointer], 32	; restore current entry
	
	pop si
	pop dx
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_new_dir_entry
; IN: AX = file size, BX = first cluster, CL = attributes, SI = filename pointer
; OUT: CF = set if directory full, otherwise clear
; Note: Examine a directory first

func_new_dir_entry:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	mov dl, cl			; save parameters
	mov [.file_size], ax
	mov [.first_cluster], bx
	
.find_free:
	cmp word [directory.remaining], 0
	je .full_directory
	
	mov di, [directory.pointer]

	mov al, [es:di]
	
	cmp al, 0x00			; unused entry
	je .found_free
	
	cmp al, 0xE5			; deleted entry, should work just as well
	je .found_free
	
	dec word [directory.remaining]	; if used, try next entry
	add word [directory.pointer], 32
	jmp .find_free
	
.found_free:
	call func_filename_s2d		; convert given filename into disk format
	
	mov cx, 11			; copy file to the new entry
	mov di, [directory.pointer]
	
.copy_filename:
	mov al, [ds:si]
	mov [es:di], al
	inc si
	inc di
	loop .copy_filename
	
	mov ax, [.file_size]
	mov bx, [.first_cluster]
	mov di, [directory.pointer]	; now set all the file information
	
	mov byte [es:di+11], cl		; Attributes
	mov byte [es:di+12], 0		; Windows NT information
	mov byte [es:di+13], 0		; Creation Seconds - don't worry about time values for now
	mov byte [es:di+14], 0		; Creation Time
	mov word [es:di+16], 0		; Creation Date
	mov word [es:di+18], 0		; Last access date
	mov word [es:di+20], 0		; Upper 16-bits of cluster number - always zero for FAT12
	mov word [es:di+22], 0		; Last Modifcation Time
	mov word [es:di+24], 0		; Last Modification Date
	mov word [es:di+26], bx		; Lower 16-bits of the cluster number - first cluster
	mov word [es:di+28], ax		; File size (byte)
	mov word [es:di+30], 0		; Upper half of file size
	
	popa
	pop es
	clc				; Report success
	ret
	
.full_directory:
	popa
	pop es
	stc				; Report failure
	ret
	
.file_size				dw 0
.first_cluster				dw 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_reset_dir
; Description: Resets a directory to the first entry
; IN/OUT: none

func_reset_dir:
	push ax
	
	mov ax, [directory.start]
	mov [directory.pointer], ax
	
	mov ax, [directory.entries]
	mov [directory.remaining], ax
	
	pop ax
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_cluster
; Description: Reads data from a FAT cluster on the disk
; IN: AX = cluster number, DX:SI = data address
; OUT: CF = set to on failure, otherwise cleared

func_read_cluster:
	push ax
	push bx
	
	cmp ax, 0				; Cluster zero is used for empty files
	je .read_finished
	
	cmp ax, 1				; FAT clusters begin at two
	je .read_failed
	
	cmp ax, [diskinfo.last_cluster]		; Make sure the sector is on disk
	jg .read_failed
	
	add ax, [diskinfo.cluster_offset]	; Cluster = Logical Sector + Cluster Offset
	sub ax, 2				; First cluster is number two
	mov bl, 1				; Read only one sector
	call func_read_sectors
	jc .read_failed				; Check if sector operation failed
	
.read_finished:
	pop bx
	pop ax
	clc
	ret
	
.read_failed:
	pop bx
	pop ax
	stc
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_cluster
; Description: Writes data to a FAT cluster on the disk
; IN: AX = cluster number, DX:SI = data address
; OUT: CF = set on failure, otherwise cleared

func_write_cluster:
	push ax
	push bx
	
	cmp ax, 0				; Cluster zero is used for empty files
	je .write_finished
	
	cmp ax, 1				; FAT clusters begin at two
	je .write_failed
	
	cmp ax, [diskinfo.last_cluster]		; Make sure the sector is on the disk
	jg .write_failed
	
	add ax, [diskinfo.cluster_offset]
	sub ax, 2				; First cluster is number two
	mov bl, 1
	call func_write_sectors
	jc .write_failed

.write_finished:	
	pop bx
	pop ax
	clc
	ret
	
.write_failed:
	pop bx
	pop ax
	stc
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_create_fat_chain
; Description: Creates a new FAT cluster chain of the specified length
; IN: AX = length
; OUT: AX = first cluster
; Note: Make sure the FAT is read first

func_create_fat_chain:
	cmp ax, 0
	je .empty_chain
	
	pusha
	
	mov [.chain_length], ax
	
	mov word [.previous_cluster], 0
	
	mov dx, 2				; Clusters start a two
	mov cx, [diskinfo.fat_entries]		; Check for all valid FAT entries
	sub cx, 2

.find_free_clusters:
	mov ax, dx				; Loop through the FAT and find free entries to allocate out to the chain
	call func_get_fat_entry			; Get a 12-bit FAT entry
	
	cmp ax, 0x000				; Allocate out only empty clusters
	je .allocate_cluster
	
	inc dx
	
	loop .find_free_clusters

	jmp .disk_full
	
.allocate_cluster:
	cmp word [.previous_cluster], 0		; If this is the first cluster in the chain, don't write to if yet
	je .start_of_chain

	dec word [.chain_length]		; Check if this is the last cluster to write
	cmp word [.chain_length], 0
	je .end_of_chain
	
	mov ax, [.previous_cluster]		; Set the last cluster value to the current cluster number
	mov bx, dx
	call func_set_fat_entry
	
	mov [.previous_cluster], dx		; Remember the last cluster we wrote to
	
	loop .find_free_clusters
	
	jmp .disk_full				; If all clusters have been checked and not enough have been found then the disk is full, report failure
	
.start_of_chain:
	mov [.first_cluster], dx

	dec word [.chain_length]		; If the chain length is one then just write an end of cluster to the first free cluster
	cmp word [.chain_length], 0
	je .finish_chain
	
	mov [.previous_cluster], dx		; Otherwise, remember this first cluster and start a chain
	
	loop .find_free_clusters
	
	jmp .disk_full
	
.end_of_chain:
	mov ax, [.previous_cluster]
	mov bx, dx
	call func_set_fat_entry

.finish_chain:	
	mov ax, dx
	mov bx, 0x0FF8
	call func_set_fat_entry
	
	popa
	mov ax, [.first_cluster]
.empty_chain:
	clc
	ret
	
.disk_full:
	popa					; If there are not enough free clusters on the disk then report failure
	stc
	ret

.previous_cluster				dw 0
.chain_length					dw 0
.first_cluster					dw 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_fat_chain
; Description: Copies the cluster list into a buffer
; IN: AX = first cluster
; OUT: CX = number of clusters, SI = list address
; Note: Cluster entries will be saved as a list of 16-bit values format

func_read_fat_chain:
	pusha
	
	mov si, .list_buffer
	mov byte [.length], 0
	
	cmp ax, 0x000			; Start sector zero indicates the file is empty - there are no clusters
	je .end_of_chain
	
	inc byte [.length]
	mov [si], ax
	add si, 2
	
	mov dx, ax
	
.find_entries:
	mov ax, dx			; Load a 12-bit FAT entry
	call func_get_fat_entry
	
	cmp ax, 0x001			; Is it the next entry address or the end of the chain?
	jle .end_of_chain
	
	cmp ax, 0xFF7
	jge .end_of_chain
	
	mov [si], ax			; If there's more, write the entry to the list
	add si, 2
	
	inc byte [.length]
	
	mov dx, ax			; Set the entry 
	jmp .find_entries
	
.end_of_chain:	
	popa
	
	mov cx, 0
	mov cl, [.length]
	mov si, .list_buffer
	
	ret
	
.length					db 0
.list_buffer				times 128 dw 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_delete_fat_chain
; Description: Frees all entries in a FAT chain
; IN: AX = first cluster
; OUT: none
; Note: Make sure the FAT is read first

func_delete_fat_chain:
	pusha
	
	mov dx, ax
	
.clear_entries:
	mov ax, dx			; Read entry
	call func_get_fat_entry
	mov cx, ax
	
	cmp ax, 0x0001			; In case of a disk messup, these should be end of chain
	jle .end_of_chain
	
	cmp ax, 0x0FF7			; Stop at bad clusters
	je .bad_cluster
	
	cmp ax, 0x0FF8			; 'End of Chain' marker
	jge .end_of_chain
	
	mov ax, dx			; If the chain continues, set the last entry read as an unused entry
	mov bx, 0x0000
	call func_set_fat_entry
	
	mov dx, cx			; Set the old value of the current entry to the next entry number
	
	jmp .clear_entries

.end_of_chain:
	mov ax, dx			; Mark end of chain as 'unused' and finish
	mov bx, 0x0000
	call func_set_fat_entry
	
	popa
	ret
	
.bad_cluster:
	popa				; Don't free up a bad cluster
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_second_fat
; Description: Read the second FAT and store it in the disk buffer
; IN: none
; OUT: CF = set on failure, otherwise clear

func_read_second_fat:
	pusha
	
	mov ax, [diskinfo.second_fat_sector]
	mov bl, [diskinfo.fat_size]
	mov dx, DISK_SEGMENT
	mov si, SECOND_FAT
	call func_read_sectors
	
	popa
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_second_fat
; Description: Write the second FAT from the disk buffer
; IN: none
; OUT: CF = set on failure, otherwise clear

func_write_second_fat:
	pusha
	
	mov ax, [diskinfo.second_fat_sector]
	mov bl, [diskinfo.fat_size]
	mov dx, DISK_SEGMENT
	mov si, SECOND_FAT
	call func_write_sectors
	
	popa
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_examine_disk
; Description: Finds the media parameters for a floppy disk
; IN: none
; OUT: CF = set on failure (probably no media), otherwise cleared

func_examine_disk:
	push es
	pusha
	
	inc word [gs:internal_call]
	
	call func_disk_reset
	jc .failed
	
	mov ax, DISK_SEGMENT
	mov es, ax
	
	cmp byte [diskinfo.first_call], 1
	je .first
	
	mov ah, 15h				; Check to see if the disk "change-line" is supported
	mov dl, [bootdev]			; This determines which disk change detection to use
	int 13h
	
	cmp ah, 1
	je .use_serial
	
	cmp ah, 2
	je .use_changeline
	
	jmp .failed
	
.use_changeline:
	mov ah, 16h				; DiskBIOS function 16h - Detect Media Change
	mov dl, [bootdev]			; If the change-line is supported, test if it is set
	int 13h
	jc .failed
	
	cmp ah, 0				; If the change-line is not set skip this routines as this disk has not changed
	je .same_disk
	
	cmp ah, 6				; If the change-line is set, a new disk has been inserted *or* the drive is empty, run the new disk routine
	je .changeline_set
	
	jmp .failed				; All other values are an error
	
.changeline_set:
	mov byte [diskinfo.bpb_cached], 0	; Flush BPB buffers
	jmp .get_parameters

.use_serial:
	mov byte [diskinfo.bpb_cached], 0	; Refresh the BPB to find the current serial
	call func_read_bpb
	jc .failed
	
	mov ax, [es:si+39]			; Check if the disk serial number is the same as the one in memory
	mov bx, [es:si+41]			; If there serial is the same, it's the same disk, otherwise it's a new disk
	cmp ax, [diskinfo.lower_serial]
	jne .different_serial
	cmp bx, [diskinfo.upper_serial]
	jne .different_serial
	jmp .same_disk

.different_serial:
	mov [diskinfo.lower_serial], ax		; Remember current disk serial number
	mov [diskinfo.upper_serial], bx
	
	mov ax, 0x0000				; Generate a new serial number for the disk
	mov bx, 0xFFFF				
	call os_get_random
	mov dx, cx
	call os_get_random
	
	mov [es:si+39], cx			; Put the new serial number into the cache and try to write the BPB back to the disk
	mov [es:si+41], dx
	call func_write_bpb
	jc .get_parameters			; If the write fails the disk is read-only so no change to the serial number
	
	mov [diskinfo.lower_serial], cx		; Otherwise remember the new serial number
	mov [diskinfo.upper_serial], dx
	
.get_parameters:
	call func_read_bpb			; Read the BIOS Parameter Block
	jc .failed
	
	mov byte [diskinfo.fat_cached], 0	; Invalidate buffers
	mov byte [directory.cached], 0
	mov byte [otherdir.cached], 0
	mov word [diskinfo.curr_dir_sector], 0	; Reset directory to root
	
	mov si, BIOS_PARAMETER_BLOCK
	
	mov ax, [es:si+14]			; Reserved Sectors - sectors before first FAT
	mov bh, [es:si+16]			; Number of FATs - usually two, we'll ignore any others
	mov cx, [es:si+17]			; Number of root directory entries - must be in sector groups of sixteen (32 bytes each)
	mov dx, [es:si+19]			; Total number of sectors
	mov di, [es:si+22]			; Sectors per FAT
	
	push ax					; Remember reserved sectors
	mov [diskinfo.first_fat_sector], ax	; First FAT Sector = Reserved Sectors
	add ax, di				; Second FAT Sector = First FAT Sector + Sectors Per FAT
	mov [diskinfo.second_fat_sector], ax
	
	push dx					; DX (Number of Sectors) must be preserved after multiplication instructions
	mov ax, 0				; Root Directory Sector = (Number of FATs * Sectors Per FAT) + Reserved Sector
	mov al, bh
	mul di
	mov bx, ax
	pop dx
	pop ax
	add bx, ax
	mov [diskinfo.root_dir_sector], bx
	
	mov [diskinfo.fat_size], di		; FAT size = Sectors Per FAT
	mov [diskinfo.root_dir_entries], cx
	shr cx, 4				; Root Directory Size = Number of Entries / 16
	mov [diskinfo.root_dir_size], cx
	
	push dx
	shl di, 9				; FAT entries = (Sectors Per Fat * Sector Size * 2) / 3
	mov dx, 0
	mov ax, di
	mov cx, 3
	div cx
	pop dx
	mov [diskinfo.fat_entries], ax
	
	add bx, [diskinfo.root_dir_size]	; Cluster Offset = Root Directory Sector + Root Directory Size
	mov [diskinfo.cluster_offset], bx
	
	sub dx, bx				; Last Cluster = Number of Sectors - Cluster Offset
	mov [diskinfo.last_cluster], dx
	
	mov ax, 0x0000				; Work around buggy BIOSes
	mov es, ax
	mov di, 0
	
	mov ah, 08h				; Collect disk parameters for CHS translation
	mov dl, [bootdev]
	stc
	int 13h
	jc .failed
	
	and cx, 0x003F				; Use only the first six bits (Sectors per Track)
	mov [SecsPerTrack], cx
	xchg dh, dl
	mov dh, 0
	inc dl					; Sides start at zero
	mov [Sides], dx

.same_disk:
	dec word [gs:internal_call]
	popa
	pop es
	clc
	ret
	
.failed:
	dec word [gs:internal_call]
	popa
	pop es
	stc
	ret
	
.first:
	mov byte [diskinfo.first_call], 0
	jmp .get_parameters
	
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_dir_sub
; Description: Reads subdirectory entries from a directory
; IN: none
; OUT: SI = directory name, AX = first cluster

func_read_dir_sub:
	push es
	push di
	push cx
	
	inc word [gs:internal_call]
	
	mov ax, DISK_SEGMENT
	mov es, ax

.retry:
	cmp word [directory.remaining], 0	; Make sure there are still entries remaining
	je  .no_entries_left

	mov si, [directory.pointer]
	
.check_first_char:
	mov al, [es:si]				; Test the first character of the filename for a special meaning
	
	cmp al, 0x00				; Unused entry - ignore
	je .next_entry
	
	cmp al, 0xE5				; Deleted entry - ignore
	je .next_entry
	
	cmp al, 0x2E				; Dot entry, '.' or '..'
	je .dot_entry
	
	cmp al, 0x05				; Entry starting with a literal 0xE5
	je .special_start
	
.check_attributes:
	mov al, [es:si+11]
	
	cmp al, 0x0F				; Long filename - ignore
	je .next_entry
	
	test al, 0x08				; Volume label - ignore
	jnz .next_entry
	
	test al, 0x10				; Make sure the entry is a directory!
	jz .next_entry
	
	cmp byte [.dot_entry], 1
	je .no_translate
	
	; Seems to be okay, copy the filename into our buffer
	push si
	mov di, .filename
	mov cx, 11
.copy_filename:
	mov al, [es:si]
	mov [ds:di], al
	inc si
	inc di
	loop .copy_filename
	
	mov si, .filename			; Convert it from disk format into a string, then copy back to the buffer
	call func_filename_d2s
	mov di, .filename
	call os_string_copy
	
	pop si					; Restore the pointer to the start of the directory entry
	
.no_translate:
	mov ax, [es:si+26]			; Fetch cluster number
	mov si, .filename			; Set filename pointer
	
	dec word [directory.remaining]		; Increase entry
	add word [directory.pointer], 32
	
	dec word [gs:internal_call]
	
	pop cx
	pop di
	pop es
	ret
	
.next_entry:
	dec word [directory.remaining]
	add word [directory.pointer], 32
	
	jmp .retry
	
.special_start:
	mov byte [es:si], 0xE5
	jmp .check_attributes
	
.dot_entry:
	mov byte [.dot_entry], 1

	cmp byte [es:si+1], 0x2E
	je .double_dot
	
	mov byte [.filename], 0x2E
	mov byte [.filename+1], 0x00
	
.double_dot:
	mov byte [.filename], 0x2E
	mov byte [.filename+1], 0x2E
	mov byte [.filename+2], 0x00
	
	jmp .check_attributes
	
.no_entries_left:
	dec word [gs:internal_call]
	
	pop cx
	pop di
	pop es
	ret
	
.filename					times 13 db 0
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_edit_dir_sub
; Description: Edits the data of a subdirectory entry
; IN: AX = start sector, SI = filename
; OUT: none
; Note: Edits the last subdirectory read

func_edit_dir_sub:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	mov dx, ax

	sub word [directory.pointer], 32
	
	call func_filename_s2d
	mov di, [directory.pointer]
	mov cx, 11
	
.copy_filename:
	mov al, [ds:si]
	mov [es:di], al
	inc si
	inc di
	jmp .copy_filename
	
	mov si, [directory.pointer]
	mov [es:si+26], ax
	
	add word [directory.pointer], 32
	
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_remove_dir_sub
; Description: Removes a subdirectory entry
; IN/OUT: none
; Note: Uses the last entry read

func_remove_dir_sub:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	mov dx, ax
	
	sub word [directory.pointer], 32		; select previously read entry
	
	mov al, [es:si]					; backup first character for undeletion
	mov byte [es:si+11], al
	
	mov byte [es:si], 0xE5				; mark entry as deleted
	
	add word [directory.pointer], 32		; restore previous entry
	
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_create_dir_sub
; Description: Creates a new subdirectory entry
; IN: AX = start sector, SI = filename
; OUT: CF = set if directory full, otherwise clear
; Note: Examine a directory first

func_create_dir_sub:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	mov dx, ax
	
.find_free:
	mov di, [directory.pointer]
	cmp word [directory.remaining], 0
	je .full_dir
	
	mov al, [es:di]				; check first character to find entry status
	
	cmp al, 0x00				; free entry - usable
	je .found_entry
	
	cmp al, 0xE5				; deleted entry - usable
	je .found_entry
	
	dec word [directory.remaining]
	add word [directory.pointer], 32
	
	jmp .find_free
	
.found_entry:
	cmp byte [si], 0x2E			; Check if the entry is a 'dot' entry
	je .dot_entry

	call func_filename_s2d			; Convert the filename to disk format and write it onto the first 11 bytes of the entry
	mov di, [directory.pointer]
	mov cx, 11
	
.copy_filename:
	mov al, [ds:si]
	mov byte [es:di], al
	inc si
	inc di
	loop .copy_filename
	
.format_entry:
	mov si, [directory.pointer]
	
	mov byte [es:si+11], 0x10		; Attributes, just set the directory flag
	mov byte [es:si+12], 0x00		; Windows NT byte, leave this blank
	mov byte [es:si+13], 0x00		; Ignore time entries for now
	mov word [es:si+14], 0x0000
	mov word [es:si+16], 0x0000
	mov word [es:si+18], 0x0000
	mov word [es:si+20], 0x0000		; Higher part of first cluster - irrelevent for FAT12
	mov word [es:si+22], 0x0000		; More time entries
	mov word [es:si+24], 0x0000
	mov word [es:si+26], dx			; Lower part of first cluster, set to the specified value
	mov word [es:si+28], 0x0000		; File size lower and higher parts, set these to zero for directories
	mov word [es:si+30], 0x0000
	
	popa
	pop es
	clc
	ret
	
.full_dir:
	popa
	pop es
	stc
	ret
	
.dot_entry:
	mov di, [directory.pointer]
	mov cx, 9
	
	cmp byte [si+1], 0x2E		; Is it a double dot entry?
	je .double_dot
	
	mov byte [es:di+0], 0x2E
	mov byte [es:di+1], 0x20
	
	inc di
	
	jmp .pad_entry
	
.double_dot:
	mov byte [es:di+0], 0x2E
	mov byte [es:di+1], 0x2E
	
	inc di
	
.pad_entry:
	inc di
	mov byte [es:di], 0x20
	loop .pad_entry
	
	jmp .format_entry
	
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_subdirectory
; Description: Reads a subdirectory off the disk into the directory buffer
; IN: AX = first cluster
; OUT: CF = set if failed, otherwise clear
; Note: Uses the last subdirect entry read

func_read_subdirectory:
	cmp byte [directory.cached], 0
	je .read_directory
	
	cmp word [directory.cluster], ax
	je .read_directory
	
	jmp .already_cached
	
.read_directory:
	pusha
	
	mov bx, ax
	
	call func_read_fat_chain		; Load the directory's cluster chain
	mov di, si
	
	mov dx, DISK_SEGMENT
	mov si, ACTIVE_DIRECTORY
	
.load_clusters:
	mov word ax, [di]			; Read all clusters in the directory and place then in the directory buffer
	call func_read_cluster
	jc .read_failed
	
	add si, 512
	add di, 2
	
	loop .load_clusters
	
	mov byte [directory.cached], 0		; Mark the sector is cached
	mov word [directory.cluster], bx
	
	popa
	clc
	ret
	
.read_failed:
	popa
	stc
	ret
	
.already_cached:
	clc					; If the directory is already cached, just ignore the read request and report success
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_subdirectory
; Description: Writes the subdirectory to the disk from the directory buffer
; IN: AX = first cluster
; OUT: CF = set if failed, otherwise clear

func_write_subdirectory:
	cmp byte [directory.cached], 0
	je .not_cached
	
	cmp word [directory.cluster], ax
	jne .not_cached
	
	pusha
	
	call func_read_fat_chain
	mov di, si
	
	mov dx, DISK_SEGMENT
	mov si, ACTIVE_DIRECTORY
	
.load_cluster:
	mov word ax, [di]			; Write all sectors in the list but bailout is any fail
	call func_write_cluster
	jc .write_failed
	
	mov si, 512
	mov di, 2
	
	loop .load_cluster
	
	popa
	clc
	ret
	
.write_failed:
	popa
	stc
	ret
	
.not_cached:
	stc					; Ignore the write request and return failure if the directory has not been read
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_examine_subdirectory
; Description: Enters a subdirectory entry
; IN: none
; OUT: CF = set if failed to load, otherwise clear
; Note: Uses the last entry read

func_examine_subdirectory:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	sub word [directory.pointer], 32	; Locate last directory entry
	
	mov si, [directory.pointer]		; Find the size by finding the first cluster and following the cluster chain
	mov ax, [es:si+26]
	call func_read_fat_chain
	mov dx, cx				; Entries = Number of Sectors * 16
	shl dx, 4
	
	mov si, [directory.pointer]		; Find the first cluster again
	mov ax, [es:si+26]
	call func_read_subdirectory		; Load directory from disk to the directory buffer
	
	mov word [directory.start], ACTIVE_DIRECTORY	; Setup directory data
	mov word [directory.pointer], ACTIVE_DIRECTORY
	mov [directory.remaining], dx
	mov [directory.entries], dx
	
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_backup_fat
; Description: Copies data from the first FAT buffer to the second
; IN/OUT: none
; Note: Use 'func_write_second_fat' to write the buffer to the disk

func_backup_fat:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	mov si, FIRST_FAT			; Set the locations of both FATs
	mov di, SECOND_FAT
	mov cx, [diskinfo.fat_size]		; Get FAT size in sectors and convert it to bytes
	shr cx, 9
	
.copy_data:
	mov al, [es:si]	
	mov [es:di], al
	inc si
	inc di
	loop .copy_data
	
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_restore_fat
; Description: Copies data from the second FAT buffer to the first
; IN/OUT: none
; Note: Use 'func_read_second_fat' to read the buffer from the disk

func_restore_fat:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	mov si, FIRST_FAT
	mov di, SECOND_FAT
	mov cx, [diskinfo.fat_size]
	shr cx, 9
	
.copy_data:
	mov al, [es:di]
	mov [es:si], al
	inc si
	inc di
	loop .copy_data
	
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_swap_directories
; Description: Exchanges data and state information between the 'active' and 'other' directory buffers
; IN/OUT: none

func_swap_directories:
	push es
	pusha
	
	mov dx, DISK_SEGMENT
	mov es, dx
	
	mov ax, [directory.start]		; Swap all state data
	mov bx, [directory.pointer]
	mov cx, [otherdir.start]
	mov dx, [otherdir.pointer]
	
	mov [directory.start], cx
	mov [directory.pointer], dx
	mov [otherdir.start], ax
	mov [otherdir.pointer], bx
	
	mov ax, [directory.entries]
	mov bx, [directory.remaining]
	mov cx, [otherdir.entries]
	mov dx, [otherdir.remaining]
	
	mov [directory.entries], cx
	mov [directory.remaining], dx
	mov [otherdir.entries], ax
	mov [otherdir.remaining], bx
	
	mov ah, [directory.cached]
	mov al, [otherdir.cached]
	mov bx, [directory.cluster]
	mov cx, [otherdir.cluster]
	
	mov [directory.cached], al
	mov [otherdir.cached], ah
	mov [directory.cluster], cx
	mov [otherdir.cluster], bx
	
	mov si, ACTIVE_DIRECTORY		; Set locations of both buffers
	mov di, OTHER_DIRECTORY
	mov cx, 16384				; Length of the directory buffer
	
.swap_data:
	mov ah, [es:si]				; Swap all directory data
	mov al, [es:di]
	
	mov [es:si], al
	mov [es:di], ah
	
	inc si
	inc di
	
	loop .swap_data
	
	popa
	pop es
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_copy_string_f2g
; Description: Copies a filename from the OS segment to the kernel segment
; IN: FS:SI = source filename, GS:DI = destination filename
; OUT: none

func_copy_string_f2g:
	cmp word [gs:internal_call], 1
	jg .local_copy
	
	pusha
	
.copy_string:
	mov al, [fs:si]
	mov [gs:di], al
	inc si
	inc di
	
	cmp al, 0
	je .finished
	
	jmp .copy_string
	
.finished:
	popa
	ret
	
.local_copy:
	call os_string_copy
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_copy_string_g2f
; Description: Copies a filename from the kernel segment to the OS segment
; IN: GS:SI = source, FS:DI = destination filename

func_copy_string_g2f:
	cmp word [gs:internal_call], 1
	jg .local_copy

	pusha
	
.copy_string:
	mov al, [gs:si]
	mov [fs:di], al
	inc si
	inc di
	
	cmp al, 0
	je .finished
	
	jmp .copy_string
	
.finished:
	popa
	ret
	
.local_copy:
	call os_string_copy
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_read_bpb
; Description: Reads the BIOS Parameter Block from the disk
; IN/OUT: none

func_read_bpb:
	cmp byte [diskinfo.bpb_cached], 1	; Don't read the parameter block if it is already cached
	je .cached
	
	cmp word [SecsPerTrack], 0		; Return failed immediently if the CHS values are not sane, this could lock up the OS
	je .failed
	
	pusha
	
	mov ax, 0				; If not cached, read the first sector on the disk
	mov bl, 1
	mov dx, DISK_SEGMENT
	mov si, BIOS_PARAMETER_BLOCK

	call func_read_sectors
	jc .failed
	
	mov byte [diskinfo.bpb_cached], 1
	
	popa
.cached:
	clc
	ret
	
.failed:
	popa
	stc
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_bpb
; Description: Write the BIOS Parameter Block to the disk
; IN/OUT: none

func_write_bpb:
	cmp byte [diskinfo.bpb_cached], 0	; Don't write the BPB if it is not in cache
	je .failed
	
	pusha
	
	mov ax, 0
	mov bl, 1
	mov dx, DISK_SEGMENT
	mov si, BIOS_PARAMETER_BLOCK
	call func_write_sectors
	jc .failed
	
	popa
	clc
	ret
	
.failed:
	popa
	stc
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_find_file
; Description: Search current directory for a file
; IN: DI = filename
; OUT: CF = set if not found, otherwise clear and AX = file size, BX = first cluster, CL = attributes
; Note: Examine a directory first

func_find_file:
	push si
	inc word [gs:internal_call]
	
	push ax
	mov ax, di
	call os_string_uppercase
	pop ax
	
.search:
	call func_read_dir_entry
	jc .not_found
	
	call os_string_compare
	jc .found_file
	
	jmp .search
	
.not_found:
	dec word [gs:internal_call]
	pop si
	stc
	ret
	
.found_file:
	dec word [gs:internal_call]
	pop si
	clc
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_find_directory
; Description: Search current directory for a subdirect
; IN: DI = subdirectory name
; OUT: CF = set if not found, otherwise, AX = first cluster
; Note: Examine a directory first

func_find_directory:
	push si
	inc word [gs:internal_call]
	
.search:
	call func_read_dir_sub
	jc .not_found
	
	call os_string_compare
	jc .found_sub
	
	jmp .search
	
.not_found:
	dec word [gs:internal_call]
	pop si
	stc
	ret
	
.found_sub:
	dec word [gs:internal_call]
	pop si
	clc
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_examine_curr_dir
; Description: Examine the last directory loaded
; IN: none
; OUT: CF = set if failed to read directory, otherwise clear
; Note: Read FAT first

func_examine_curr_dir:
	cmp word [diskinfo.curr_dir_sector], 0	; If the current directory is zero (root) then examine use func_examine_root_dir instead
	je func_examine_root_dir

	pusha
	
	call func_read_curr_dir
	jc .failed
	
	mov word [directory.start], ACTIVE_DIRECTORY
	mov word [directory.pointer], ACTIVE_DIRECTORY
	
	mov ax, [diskinfo.curr_dir_sector]	; find the directory entries (directory clusters * 16)
	call func_fat_chain_length	
	shl cx, 4
	
	mov [directory.entries], ax
	mov [directory.remaining], ax
	
	popa
	clc
	ret
	
.failed:
	popa
	stc
	ret
; ------------------------------------------------------------------
	

	
; ------------------------------------------------------------------
; Call: func_read_curr_dir
; Description: Reads the current directory contents
; IN: none
; OUT: CF = set if failed, otherwise clear

func_read_curr_dir:
	pusha
	
	cmp word [diskinfo.curr_dir_sector], 0
	je .root_dir
	
	mov ax, [diskinfo.curr_dir_sector]
	call func_read_subdirectory
	
	jmp .finish
	
.root_dir:	
	call func_read_root_dir
	
.finish:
	popa
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_write_curr_dir
; Description: Writes the current directory contents
; IN: none
; OUT: CF = set if failed, otherwise clear

func_write_curr_dir:
	pusha
	
	cmp word [diskinfo.curr_dir_sector], 0
	je .root_dir
	
	mov ax, [diskinfo.curr_dir_sector]
	call func_write_subdirectory
	
	jmp .finish
	
.root_dir:
	call func_write_root_dir
	
.finish:
	popa
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_enter_subdirectory
; Description: Set the current directory
; IN: AX = subdirectory cluster or zero for root
; OUT: none

func_enter_subdirectory:
	cmp word [diskinfo.curr_dir_sector], ax
	ret
; ------------------------------------------------------------------



; ------------------------------------------------------------------
; Call: func_fat_chain_length
; Description: Find the length of the FAT chain
; IN: AX = first cluster
; OUT: CX = cluster length
; Note: Read the FAT first

func_fat_chain_length:
	pusha
	
	mov word [.length], 0
	
	cmp ax, 0
	je .finished
	
	mov dx, ax
	
.follow_chain:
	mov ax, dx
	call func_get_fat_entry
	inc word [.length]
	
	cmp ax, 0x001
	jle .finished

	cmp ax, 0xFF7
	jge .finished
	
	mov dx, ax
	
	jmp .follow_chain
	
.finished:
	popa
	mov cx, [.length]
	ret
	
.length						dw 0
; ------------------------------------------------------------------



	
;func_flush_buffers

;flush buffers
;build buffers
	
	
Sides 						dw 2
SecsPerTrack 					dw 18
bootdev 					db 0
	
diskinfo:
	.first_fat_sector			dw 0	; Logical sector of the primary File Allocation Table
	.second_fat_sector			dw 0	; Logical sector of the secondard FAT
	.root_dir_sector			dw 0	; Logical sector of the root directory
	.cluster_offset				dw 0	; Logical sector of the first cluster
	
	.fat_size				dw 0	; Size of each FAT in sectors
	.root_dir_size				dw 0	; Size of the root director in sectors
	
	.fat_entries				dw 0	; Number of 12-bit FAT entries
	.root_dir_entries			dw 0	; Number of 32-byte root directory entries
	
	.last_cluster				dw 0	; Last addressable cluster
	
	.readonly				db 0	; Marks if the current disk is read only
	
	.curr_dir_sector			dw 0	; The sector of the current directory, zero if root

	.bpb_cached				db 0	; Marks if the first sector is valid and in it's buffer
	.fat_cached				db 0	; Marks if the FAT is valid and in it's buffer

	.lower_serial				dw 0	; Volume serial number, to detect disk changes
	.upper_serial				dw 0
	
	.cylinder				db 0	; Logical sectors to CHS translation results
	.head					db 0
	.sector					db 0
	
	.first_call				db 1
	
directory:
	.cached					db 0 	; Zero if invalid, one if valid data
	.cluster				dw 0	; Directory cluster number (zero if root directory)
	.start					dw 0	; Memory address of the buffer
	.pointer				dw 0	; Pointer to next entry to read
	.remaining				dw 0	; Directory entries left to read
	.entries				dw 0	; Number of entries in the directory
	
otherdir:
	.cached					db 0 	; Zero if invalid, one if valid data
	.cluster				dw 0	; Directory cluster number (zero if root directory)
	.start					dw 0	; Memory address of the buffer
	.pointer				dw 0	; Pointer to next entry to read
	.remaining				dw 0	; Directory entries left to read
	.entries				dw 0	; Number of entries in the directory
; ==================================================================
