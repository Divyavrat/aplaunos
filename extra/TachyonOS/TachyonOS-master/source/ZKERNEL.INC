; Pointers from extended kernel to regular kernel.

; Disk API calls
ptr_load_file			equ	0099h
ptr_get_file_list		equ	009Ch
ptr_write_file			equ	009Fh
ptr_file_exists			equ	00A2h
ptr_create_file			equ	00A5h
ptr_remove_file			equ	00A8h
ptr_rename_file			equ	00ABh
ptr_get_file_size		equ	00AEh

; Graphics API calls
ptr_text_mode			equ	0000h
ptr_graphics_mode		equ	0003h
ptr_set_pixel			equ	0006h
ptr_get_pixel			equ	0009h
ptr_draw_line			equ	000Ch
ptr_draw_rectangle		equ	000Fh
ptr_draw_polygon		equ	0012h
ptr_clear_graphics		equ	0015h
ptr_draw_border			equ	0033h
ptr_draw_horizontal_line	equ	0036h
ptr_draw_vertical_line		equ	0039h
ptr_move_cursor			equ	003Ch
ptr_draw_block			equ	003Fh
ptr_draw_circle			equ	0090h

; Memory API calls
ptr_memory_allocate		equ	0018h
ptr_memory_release		equ	001Bh
ptr_memory_free			equ	001Eh
ptr_memory_reset		equ	0021h
ptr_memory_read			equ	0024h
ptr_memory_write		equ	0027h

; Sound API calls

ptr_speaker_freq		equ	002Ah
ptr_speaker_tone		equ	002Dh
ptr_speaker_off			equ	0030h

; Mouse API calls
ptr_mouse_setup			equ	0042h
ptr_mouse_locate		equ	0045h
ptr_mouse_move			equ	0048h
ptr_mouse_show			equ	004Bh
ptr_mouse_hide			equ	004Eh
ptr_mouse_range			equ	0051h
ptr_mouse_wait			equ	0054h
ptr_mouse_anyclick		equ	0057h
ptr_mouse_leftclick		equ	005Ah
ptr_mouse_middleclick		equ	005Dh
ptr_mouse_rightclick		equ	0060h
ptr_input_wait			equ	0063h
ptr_mouse_scale			equ	0066h

; Keyboard API calls
ptr_wait_for_key		equ	0069h
ptr_check_for_key		equ	006Ch
ptr_check_for_extkey		equ	008Dh

; Math API calls
ptr_seed_random			equ	006Fh
ptr_get_random			equ	0072h
ptr_bcd_to_int			equ	0075h
ptr_long_int_negate		equ	0078h
ptr_square_root			equ	008Ah

; Port API calls
ptr_port_byte_out		equ	007Bh
ptr_port_byte_in		equ	007Eh
ptr_serial_port_enable		equ	0081h
ptr_send_via_serial		equ	0084h
ptr_get_via_serial		equ	0087h

; Screen API calls
ptr_file_selector		equ	00B1h
ptr_list_dialog			equ	00B4h

; Other API calls
ptr_add_custom_icons		equ	0093h
ptr_pause			equ	00B7h

; Data

program_stack			equ	0xE000
aap_file			equ	0xF000

; API Pointers for kernel internals

os_text_mode			equ	00D5h
os_graphics_mode		equ	00DAh
os_set_pixel			equ	00DFh
os_get_pixel			equ	00E4h
os_draw_line			equ	00E9h
os_draw_rectangle		equ	00EEh
os_draw_polygon			equ	00F3h
os_clear_graphics		equ	00F8h
os_memory_allocate		equ	00FDh
os_memory_release		equ	0102h
os_memory_free			equ	0107h
os_memory_reset			equ	010Ch
os_memory_read			equ	0111h
os_memory_write			equ	0116h
os_speaker_freq			equ	011Bh
os_speaker_tone			equ	0120h
os_speaker_off			equ	0125h
os_draw_border			equ 	012Ah
os_draw_horizontal_line		equ 	012Fh
os_draw_vertical_line		equ 	0134h
os_move_cursor			equ	0139h
os_draw_block			equ	013Eh
os_mouse_setup			equ	0143h
os_mouse_locate			equ	0148h
os_mouse_move			equ	014Dh
os_mouse_show			equ	0152h
os_mouse_hide			equ	0157h
os_mouse_range			equ	015Ch
os_mouse_wait			equ	0161h
os_mouse_anyclick		equ	0166h
os_mouse_leftclick		equ	016Bh
os_mouse_middleclick		equ	0170h
os_mouse_rightclick		equ	0175h
os_input_wait			equ	017Ah
os_mouse_scale			equ	017Fh
os_wait_for_key			equ	0184h
os_check_for_key		equ	0189h
os_seed_random			equ	018Eh
os_get_random			equ	0193h
os_bcd_to_int			equ	0198h
os_long_int_negate		equ	019Dh
os_port_byte_out		equ	01A2h
os_port_byte_in			equ	01A7h
os_serial_port_enable		equ	01ACh
os_send_via_serial		equ	01B1h
os_get_via_serial		equ	01B6h
os_square_root			equ	01BBh
os_check_for_extkey		equ	01C0h
os_draw_circle			equ	01C5h
os_add_custom_icons		equ	01CAh
os_load_file			equ	01CFh
os_get_file_list		equ	01D4h
os_write_file			equ	01D9h
os_file_exists			equ	01DEh
os_create_file			equ	01E3h
os_remove_file			equ	01E8h
os_rename_file			equ	01EDh
os_get_file_size		equ	01F2h
os_file_selector		equ	01F7h
os_list_dialog			equ	01FCh
os_pause			equ	0201h
