	org	0x6000
	use16

	call os_memory_free
	mov ax,bx
	call os_print_4hex
	mov dx,1
	call os_memory_allocate
	push bx
	mov ax,bx
	call os_print_4hex
	call os_memory_free
	mov ax,bx
	call os_print_4hex
	pop bx
	push bx
	mov si,data
	call os_memory_write
	pop bx
	call os_memory_release
	call os_memory_free
	mov ax,bx
	call os_print_4hex
	
	mov ax,0x4C00
	int	0x21
	
	data:
	times 512/2 db 'DJ'
	
%include 'mikedev.inc'