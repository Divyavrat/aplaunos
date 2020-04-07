bits 16
org 32768
%include 'tachyonos.inc'

call os_show_cursor
call os_graphics_mode

call test

mov ax, 0x1111
mov bl, 0
int 0x10
call test

mov ax, 0x1112
mov bl, 0
int 0x10
call test

mov ax, 0x1114
mov bl, 0
int 0x10
call test

call os_text_mode

mov ax, 0x1111
mov bl, 0
int 0x10
call test2

mov ax, 0x1112
mov bl, 0
int 0x10
call test2

mov ax, 0x1114
mov bl, 0
int 0x10
call test2

mov ax, 0x1114
mov bl, 1
int 0x10
call test2

mov ax, 0x1114
mov bl, 2
int 0x10
call test2

mov ax, 0x1114
mov bl, 3
int 0x10
call test2

ret

test:
	jmp test2
	mov bl, 0
	call os_clear_graphics
	mov si, msg
	call os_print_string
	call os_wait_for_key
	ret

test2:
	call os_clear_screen
	mov si, msg
	call os_print_string
	call os_wait_for_key
	ret

msg db 'Testing testing:', 13, 10, '1...2...3..', 0

