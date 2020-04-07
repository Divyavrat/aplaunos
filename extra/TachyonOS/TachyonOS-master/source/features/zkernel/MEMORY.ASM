; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; EXTENDED MEMORY HANDLING ROUTINES
; ==================================================================
  
  
  ; Memory Data
  allocation_map			times 128 db 0			; a memory map showing which blocks are owned by which handles
  memory_handles_used			times 128 db 0 			; marks if a handle number is allocated, 1 for used, 0 for free

 ; os_memory_reset
 ; Reset memory allocation and clear all memory
 ; IN/OUT: none
 os_memory_reset:
	pusha
	
	mov ax, 0x1000
	mov es, ax
	
	; reset memory blocks
	mov di, allocation_map
	mov cx, 128
	mov al, 0
	rep stosb
	
	; reset memory handles
	mov di, memory_handles_used
	mov cx, 128
	mov al, 0
	rep stosb	
	
	popa
	jmp os_return
	
; os_memory_free
; Returns the amount of free memory blocks
; IN: none
; OUT: BX = number of free blocks
os_memory_free:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	mov si, allocation_map
	mov bx, 0
	mov cx, 128

.find_free_blocks:
	lodsb
	
	cmp al, 0					; find unallocated
	je .found_free_block
	
	loop .find_free_blocks

.finished:
	mov word [.tmp], bx
	popa
	mov bx, [.tmp]
	jmp os_return
	
.found_free_block:
	inc bx
	
	loop .find_free_blocks
	
	jmp .finished
	
	.tmp						dw 0
	
; Allocate a block of memory
; IN: DX = number of 512b blocks
; OUT: BH = Memory Handle, CF = set if not enough memory, otherwise cleared
os_memory_allocate:
	pusha
	 
	mov ax, 0x1000
	mov ds, ax
	mov es, ax
	
	inc byte [internal_call]
	
; =============================
; Verify there is enough memory
; =============================
	call os_memory_free				; make sure the number of blocks requested if less than or equal to that available
	cmp dx, bx
	jle .sufficient_memory
	
.not_enought_memory:
	popa						; if there is not enough memory return failure
	mov bh, 0
	stc
	jmp os_return
	

; =================================
; Find the first free memory handle
; =================================
.sufficient_memory:
	mov si, memory_handles_used
	mov cx, 128					; there are the same number of handles as blocks, so we should never run out of handles

.find_memory_handle:
	lodsb
	
	cmp al, 0
	je .found_memory_handle

	loop .find_memory_handle
	
	jmp .not_enought_memory				; just in case something messes up
	
; ==========================
; Allocate the memory handle
; ==========================
.found_memory_handle:
	mov di, si
	dec di
	mov al, 1
	stosb
	
	sub si, memory_handles_used
	mov cx, si
	
; =============================
; Allocate memory to the handle
; =============================
	mov si, allocation_map

.allocate_memory:
	lodsb						; check if byte is allocated
	cmp al, 0
	je .allocate_block				; if free allocate it
	
	jmp .allocate_memory				; otherwise check the next byte

.allocate_block:
	mov [si - 1], cl				; store the handle number as the block owner
	
	dec dx						; check if we have allocated all the blocks we need, otherwise continue
	cmp dx, 0
	jne .allocate_memory
	
	mov byte [.memory_handle], cl			; return success and the new memory handler number
	popa
	mov byte bh, [.memory_handle]
	dec byte [internal_call]
	clc
	jmp os_return
	
	.memory_handle					db 0
	
; os_memory_release
; Release a memory handle and free it's memory blocks
; IN: BH = handle
; OUT: none
os_memory_release:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	mov es, ax
	
	mov si, allocation_map
	mov cx, 128
	
.find_blocks:
	lodsb
	
	cmp al, bh
	je .free_block
	
	loop .find_blocks
	
	jmp .free_handle
	
.free_block:
	mov di, si
	dec di
	mov al, 0
	stosb
	
	loop .find_blocks

.free_handle:
	mov si, memory_handles_used
	mov ax, 0
	mov al, bh
	add si, ax
	dec si
	mov byte [si], 0
	
	popa
	jmp os_return
	
; os_memory_read
; Read memory handle to program space
; IN: BH = handle, ES:DI = output locations
os_memory_read:
	pusha
	
	mov ax, 0x1000
	mov ds, ax
	
	mov si, allocation_map
	mov cx, 128
	mov dx, 0
	
.find_blocks:
	lodsb
	
	cmp al, bh
	je .read_block
	
	inc dx
	loop .find_blocks
	
	jmp .finished
	
.read_block:
	push si
	push cx
	push ds
	
	; copy 512b block from 0x4000:Block*512 to ES:DI
	
	mov ax, 0x4000
	mov ds, ax
	
	mov si, dx
	shl si, 9
	mov cx, 512
	rep movsb
	
	pop ds
	pop cx
	pop si
	
	inc dx
	loop .find_blocks
	
.finished:
	popa
	jmp os_return
	
; os_memory_write
; Write memory handle from program space
; IN: BH = handle, DS:SI = source locations
os_memory_write:
	pusha
	
	mov dx, ds
	
	mov ax, 0x1000
	mov ds, ax
	mov ax, 0x4000
	mov es, ax
	
	mov word [.source_segment], dx
	mov word [.source_address], si
	
	mov si, allocation_map
	mov cx, 128
	mov dx, 0
	
.find_blocks:
	lodsb
	
	cmp al, bh
	je .write_block
	
	inc dx
	loop .find_blocks
	
	jmp .finished
	
.write_block:
	push si
	push cx
	push ds
	
	mov si, [.source_address]
	mov ax, [.source_segment]
	mov ds, ax
	
	mov cx, 512
	mov di, dx
	shl di, 9
	rep movsb
	
	pop ds
	mov word [.source_address], si
	pop cx
	pop si
	
	inc dx
	loop .find_blocks
	
.finished:
	popa
	jmp os_return
	
.source_segment						dw 0
.source_address						dw 0