jmp os_text_mode				; 0000h
jmp os_graphics_mode				; 0003h
jmp os_set_pixel				; 0006h
jmp os_get_pixel				; 0009h
jmp os_draw_line				; 000Ch
jmp os_draw_rectangle				; 000Fh
jmp os_draw_polygon				; 0012h
jmp os_clear_graphics				; 0015h
jmp os_memory_allocate				; 0018h
jmp os_memory_release				; 001Bh
jmp os_memory_free				; 001Eh
jmp os_memory_reset				; 0021h
jmp os_memory_read				; 0024h
jmp os_memory_write				; 0027h
jmp os_speaker_freq				; 002Ah
jmp os_speaker_tone				; 002Dh
jmp os_speaker_off				; 0030h
jmp os_draw_border				; 0033h
jmp os_draw_horizontal_line			; 0036h
jmp os_draw_vertical_line			; 0039h
jmp os_move_cursor				; 003Ch
jmp os_draw_block				; 003Fh
jmp os_mouse_setup				; 0042h
jmp os_mouse_locate				; 0045h
jmp os_mouse_move				; 0048h
jmp os_mouse_show				; 004Bh
jmp os_mouse_hide				; 004Eh
jmp os_mouse_range				; 0051h
jmp os_mouse_wait				; 0054h
jmp os_mouse_anyclick				; 0057h
jmp os_mouse_leftclick				; 005Ah
jmp os_mouse_middleclick			; 005Dh
jmp os_mouse_rightclick				; 0060h
jmp os_input_wait				; 0063h
jmp os_mouse_scale				; 0066h
jmp os_wait_for_key				; 0069h
jmp os_check_for_key				; 006Ch
jmp os_seed_random				; 006Fh
jmp os_get_random				; 0072h
jmp os_bcd_to_int				; 0075h
jmp os_long_int_negate				; 0078h
jmp os_port_byte_out				; 007Bh
jmp os_port_byte_in				; 007Eh
jmp os_serial_port_enable			; 0081h
jmp os_send_via_serial				; 0084h
jmp os_get_via_serial				; 0087h
jmp os_square_root				; 008Ah
jmp os_check_for_extkey				; 008Dh
jmp os_draw_circle				; 0090h
jmp os_add_custom_icons				; 0093h
jmp os_boot_start				; 0096h
jmp os_load_file				; 0099h
jmp os_get_file_list				; 009Ch
jmp os_write_file				; 009Fh
jmp os_file_exists				; 00A2h
jmp os_create_file				; 00A5h
jmp os_remove_file				; 00A8h
jmp os_rename_file				; 00ABh
jmp os_get_file_size				; 00AEh
jmp os_file_selector				; 00B1h
jmp os_list_dialog				; 00B4h
jmp os_pause					; 00B7h

os_return:
	pushf
	pop word [gs:flags_tmp]

	cmp byte [gs:internal_call], 1
	jge .internal_return
	
	mov word [gs:return_ax_tmp], ax
		
	mov ax, fs
	mov ds, ax
	mov es, ax
 
	pop ax
	push 0x2000
	push ax
	
	mov ax, [gs:return_ax_tmp]
	
	push word [gs:flags_tmp]
	popf
	
	retf

	.internal_return:
		ret

flags_tmp			dw 0
internal_call			dw 0		; cancels os_return
return_ax_tmp			dw 0

%INCLUDE 'constants/api.asm'
%INCLUDE 'constants/buffer.asm'
%INCLUDE 'constants/bootmsg.asm'
%INCLUDE 'constants/diskbuf.asm'
%INCLUDE 'constants/colours.asm'
%INCLUDE 'constants/config.asm'
%INCLUDE 'constants/defaults.asm'
%INCLUDE 'constants/osdata.asm'

%INCLUDE 'features/debug.asm'

%INCLUDE 'features/zkernel/boot.asm'
%INCLUDE 'features/zkernel/graphics.asm' 
%INCLUDE 'features/zkernel/memory.asm'
%INCLUDE 'features/zkernel/sound.asm'
%INCLUDE 'features/zkernel/screen.asm'
%INCLUDE 'features/zkernel/mouse.asm'
%INCLUDE 'features/zkernel/keyboard.asm'
%INCLUDE 'features/zkernel/math.asm'
%INCLUDE 'features/zkernel/ports.asm'
%INCLUDE 'features/zkernel/disk.asm'
%INCLUDE 'features/zkernel/misc.asm'
%INCLUDE 'features/string.asm'
%INCLUDE 'features/screen.asm'
%INCLUDE 'constants/menuicons.asm'

