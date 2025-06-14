;===============================
;
;	Aplaun OS
;
; Portable Operating System
; with lots of Applications
; Games, Compilers, Editors
;
; Best Assembled with FASM
; fasm kernel.asm kernel.com
;
; or NASM
; nasm kernel.ASM -O1 -o kernel.COM
; Do not use MASM
;
;===============================

org 0x0500
use16

;system calls:
jmp start			; 0000h -- Called from bootloader
jmp os_print_string		; 0003h
jmp os_move_cursor		; 0006h
jmp os_clear_screen		; 0009h
jmp os_print_horiz_line		; 000Ch
jmp os_print_newline		; 000Fh
jmp os_wait_for_key		; 0012h
jmp os_check_for_key		; 0015h
jmp os_int_to_string		; 0018h
jmp os_speaker_tone		; 001Bh
jmp os_speaker_off		; 001Eh
jmp os_load_file		; 0021h
jmp os_pause			; 0024h
jmp os_fatal_error		; 0027h
jmp os_draw_background		; 002Ah
jmp os_string_length		; 002Dh
jmp os_string_uppercase		; 0030h
jmp os_string_lowercase		; 0033h
jmp os_input_string		; 0036h
jmp os_string_copy		; 0039h
jmp os_dialog_box		; 003Ch
jmp os_string_join		; 003Fh
jmp os_get_file_list		; 0042h
jmp os_string_compare		; 0045h
jmp os_string_chomp		; 0048h
jmp os_string_strip		; 004Bh
jmp os_string_truncate		; 004Eh
jmp os_bcd_to_int		; 0051h
jmp os_get_time_string		; 0054h
jmp os_get_api_version		; 0057h
jmp os_file_selector		; 005Ah
jmp os_get_date_string		; 005Dh
jmp os_send_via_serial		; 0060h
jmp os_get_via_serial		; 0063h
jmp os_find_char_in_string	; 0066h
jmp os_get_cursor_pos		; 0069h
jmp os_print_space		; 006Ch
jmp os_dump_string		; 006Fh
jmp os_print_digit		; 0072h
jmp os_print_1hex		; 0075h
jmp os_print_2hex		; 0078h
jmp os_print_4hex		; 007Bh
jmp os_long_int_to_string	; 007Eh
jmp os_long_int_negate		; 0081h
jmp os_set_time_fmt		; 0084h
jmp os_set_date_fmt		; 0087h
jmp os_show_cursor		; 008Ah
jmp os_hide_cursor		; 008Dh
jmp os_dump_registers		; 0090h
jmp os_string_strincmp		; 0093h
jmp os_write_file		; 0096h
jmp os_file_exists		; 0099h
jmp os_create_file		; 009Ch
jmp os_remove_file		; 009Fh
jmp os_rename_file		; 00A2h
jmp os_get_file_size		; 00A5h
jmp os_input_dialog		; 00A8h
jmp os_list_dialog		; 00ABh
jmp os_string_reverse		; 00AEh
jmp os_string_to_int		; 00B1h
jmp os_draw_block		; 00B4h
jmp os_get_random		; 00B7h
jmp os_string_charchange	; 00BAh
jmp os_serial_port_enable	; 00BDh
jmp os_sint_to_string		; 00C0h
jmp os_string_parse		; 00C3h
jmp os_run_basic		; 00C6h
jmp os_port_byte_out		; 00C9h
jmp os_port_byte_in		; 00CCh
jmp os_string_tokenize		; 00CFh
jmp os_text_mode				; 00D2h
jmp os_graphics_mode				; 00D5h
jmp os_set_pixel				; 00D8h
jmp os_get_pixel				; 00DBh
jmp os_draw_line				; 00DEh
jmp os_draw_rectangle				; 00E1h
jmp os_draw_polygon				; 00E4h
jmp os_clear_graphics				; 00E7h
jmp os_memory_allocate				; 00EAh
jmp os_memory_release				; 00EDh
jmp os_memory_free				; 00F0h
jmp os_memory_reset				; 00F3h
jmp os_memory_read				; 00F6h
jmp os_memory_write				; 00F9h
jmp os_speaker_freq				; 00FCh
jmp os_draw_border				; 00FFh
jmp os_draw_horizontal_line			; 0102h
jmp os_draw_vertical_line			; 0105h
jmp os_mouse_setup				; 0108h
jmp os_mouse_locate				; 010Bh
jmp os_mouse_move				; 010Eh
jmp os_mouse_show				; 0111h
jmp os_mouse_hide				; 0114h
jmp os_mouse_range				; 0117h
jmp os_mouse_wait				; 011Ah
jmp os_mouse_anyclick				; 011Dh
jmp os_mouse_leftclick				; 0120h
jmp os_mouse_middleclick			; 0123h
jmp os_mouse_rightclick				; 0126h
jmp os_input_wait				; 0129h
jmp os_mouse_scale				; 012Ch
jmp os_seed_random				; 012Fh
;jmp os_bcd_to_int				; 0132h
jmp os_long_int_negate				; 0132h
jmp os_square_root				; 0135h
jmp os_check_for_extkey				; 0138h
jmp os_draw_circle				; 013Bh
jmp os_get_api_ver_string	;013Eh	; IN: Nothing; OUT: SI = API version number

; ===========================
;	Main Code
; ===========================
start:

;Registers

cli
	xor	ax, ax
	mov	ds, ax
	mov	es, ax
	mov fs, ax
    mov gs, ax
	mov	ax, 0x9000
	mov	ss, ax
	mov	sp, 0xFFFF
sti

; mov word [SECTORS_PER_TRACK],ax
; mov word [NUMBER_OF_DRIVES],bx
; mov word [NUMBER_OF_HEADS],cx
; mov [DRIVE_TYPE],dh
;mov [drive],dl
;mov word [currentdir],0x0013
mov byte [drive],0
; Drive Setup
cmp dl, 0
	je .no_change
	mov [drive], dl		; Save boot device number
	push es
	mov ah, 8			; Get drive parameters
	int 13h
	pop es
	and cx, 3Fh			; Maximum sector number
	mov [bpbSectorsPerTrack], cx		; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [bpbHeadsPerCylinder], dx
	.no_change:

; Unreal mode
push ds
lgdt [gdtinfo]
mov eax,cr0
or al,1
mov cr0,eax

jmp $+2
mov bx,0x08
mov ds,bx
and al,0xFE
mov cr0,eax
pop ds

;Display Setup

; mov ax,0x0003
; int 10h

; mov ah,33
; int 0x33
; mov ah,1
; int 0x33

;mov bx,0x0f01
;mov eax,0x0b8000
;mov [ds:eax],bx

;Initialization

;mov di,found
call os_reset
	; mov ax,1
	; mov bx,0xff
	; call os_get_random
	; mov bl,cl	
; mov ax,'WC'	;Mark Test
; cmp ax,[welcome_mark]
; jne .skip_welcome
; call welcome
; .skip_welcome:
mov si,autorunstr
call store_pipe_command

kernel:
;---------------------------
;; Main Loop of the complete OS
; Checks for all commands
; and the returning point for programs
;---------------------------

cmp byte [kernelreturnflag],0xf0
je kerneldone
mov byte [step_flag],0x0f

call newline
call color_switch
mov si,prompt
call prnstr
call color_switch

;Recieve the given command
;form Input Stream
command_line:
call chkkey	;If input is found
jnz .continue_command

;Else execute idle kernel module

mov ah,0x02 ;Get current time
int 0x1a
cmp dh,[.idle_time_current] ; Check if a second has passed
je command_line ; Else return to input loop
mov [.idle_time_current],dh	;Update current counter
inc byte [.idle_time_elapsed] ;Increment time counter
mov al,[.idle_time_elapsed]
cmp al,[idle_kernel_waittime]
jl command_line

mov byte [.idle_time_elapsed],0 ;Reset Counter
; What to execute if kernel is idle
mov si,idle_kenel_commandstr
call store_pipe_command
jmp command_line

;If a special key is found
.continue_command:
mov byte [.idle_time_elapsed],0 ;Reset Counter
cmp ah,0x48
je previous_comm
cmp ah,0x0f
je page_change_key
cmp ah,0x3b
je help_key
cmp ah,0x3c
je setting_key
jmp command_start
.idle_time_current:
db 0
.idle_time_elapsed:
db 0

help_key:
call getkey
call newline
mov byte [found],'h'
mov byte [found+1],0
call command
jmp kernel

kerneldone:
mov byte [kernelreturnflag],0x0f
jmp word [kernelreturnaddr]

setting_key:
call getkey
call newline
jmp c_setting_f

previous_comm:
call getkey
mov si,found
call prnstr
mov di,si
dec di
mov si,found
call getstr.loop
jmp command_received

page_change_key:
jmp page_change

command_start:	;Receiving command
mov di,found
call getstr
; mov ax,found
; mov bx,prompt
; call os_input_dialog
command_received:
cmp byte [found],0	;Checking for empty command
;cmp al,0
je kernel

mov si,found
mov al,0x20
call os_string_tokenize
mov [argument_position],di
;mov si,di
;call os_print_string
cmp byte [echo_flag],0x0f
je .skip
call newline
.skip:

;; Matching command against all known commands

mov si,found
; Received command to match

mov di,c_load
call cmpstr
jc load_f

mov di,c_save
call cmpstr
jc save_f

mov di,c_execute
call cmpstr
jc execute

mov di,c_batch
call cmpstr
jc batch

mov di,c_text
call cmpstr
jc text

mov di,c_code
call cmpstr
jc text

mov di,c_print
call cmpstr
jc text


;mov di,c_video
;call cmpstr
;jc video
;
;mov di,c_vedit
;call cmpstr
;jc vedit
; 
; mov di,c_frame
; call cmpstr
; jc c_frame_f
mov di,c_wall
call cmpstr
jc c_wall_f

mov di,c_clock
call cmpstr
jc clock

mov di,c_run
call cmpstr
jc run

mov di,c_runa
call cmpstr
jc runa

mov di,c_drive
call cmpstr
jc c_drive_f

mov di,c_drive2
call cmpstr
jc c_drive2_f

mov di,c_loc
call cmpstr
jc c_loc_f

mov di,c_loc2
call cmpstr
jc c_loc2_f

mov di,c_loc3
call cmpstr
jc c_loc3_f

mov di,c_dataseg
call cmpstr
jc c_dataseg_f

mov di,c_setdir
call cmpstr
jc c_setdir_f

mov di,c_addpath
call cmpstr
jc c_addpath_f

mov di,c_addpathc
call cmpstr
jc c_addpathc_f

mov di,c_dir
call cmpstr
jc c_dir_f

mov di,c_htod
call cmpstr
jc c_htod_f

mov di,c_dtoh
call cmpstr
jc c_dtoh_f

mov di,c_reset
call cmpstr
jc c_reset_f

mov di,c_cls
call cmpstr
jc c_cls_f

mov di,c_prompt
call cmpstr
jc c_prompt_f

mov di,c_alias
call cmpstr
jc c_alias_f

mov di,c_border
call cmpstr
jc c_border_f

mov di,c_color
call cmpstr
jc c_color_f

mov di,c_color2
call cmpstr
jc c_color2_f

mov di,c_typemode
call cmpstr
jc c_typemode_f

mov di,c_videomode
call cmpstr
jc c_videomode_f

; mov di,c_memsize
; call cmpstr
; jc c_memsize_f

mov di,c_reboot
call cmpstr
jc c_reboot_f

mov di,c_restart
call cmpstr
jc c_restart_f

mov di,c_page
call cmpstr
jc c_page_f

; mov di,c_star
; call cmpstr
; jc c_star_f_link

mov di,c_sound
call cmpstr
jc c_sound_f

mov di,c_fhlt
call cmpstr
jc c_fhlt_f

; mov di,c_jmp
; call cmpstr
; jc c_jmp_f

mov di,c_paint
call cmpstr
jc c_paint_f

 
; mov di,c_score
; call cmpstr
; jc c_score_f
; 
; mov di,c_play
; call cmpstr
; jc c_play_f_link

mov di,c_calc
call cmpstr
jc c_calc_f

mov di,c_size
call cmpstr
jc c_size_f
mov di,c_fsize
call cmpstr
jc c_fsize_f

mov di,c_scrollmode
call cmpstr
jc c_scrollmode_f

mov di,c_slowmode
call cmpstr
jc c_slowmode_f

mov di,c_debug
call cmpstr
jc debug

mov di,c_driveinfo
call cmpstr
jc c_driveinfo_f

mov di,c_settime
call cmpstr
jc c_settime_f

mov di,c_setdate
call cmpstr
jc c_setdate_f

mov di,c_install
call cmpstr
jc c_install_f

mov di,c_head
call cmpstr
jc c_head_f

mov di,c_track
call cmpstr
jc c_track_f

 
; mov di,c_point
; call cmpstr
; jc c_point_f
; 
; mov di,c_icon
; call cmpstr
; jc c_icon_f
; 
; mov di,c_length
; call cmpstr
; jc c_length_f

mov di,c_rollcolor
call cmpstr
jc c_rollcolor_f

mov di,c_scrolllen
call cmpstr
jc c_scrolllen_f
; 
; mov di,c_difficulty
; call cmpstr
; jc c_difficulty_f

mov di,c_doc
call cmpstr
jc doc

; mov di,c_read
; call cmpstr
; jc read

mov di,c_edit
call cmpstr
jc edit

mov di,c_type
call cmpstr
jc c_type_f

mov di,c_fname
call cmpstr
jc fname

mov di,c_nm
call cmpstr
jc fname

mov di,c_autosize
call cmpstr
jc c_autosize_f

mov di,c_advanced
call cmpstr
jc c_advanced_f

mov di,c_completeload
call cmpstr
jc c_completeload_f

mov di,c_idle_time
call cmpstr
jc c_idle_time_f

mov di,c_idle_command
call cmpstr
jc c_idle_command_f

mov di,c_fnew
call cmpstr
jc filenew_link

mov di,c_fsave
call cmpstr
jc filesave_link

mov di,c_rename
call cmpstr
jc rename_link

mov di,c_copy
call cmpstr
jc copy_link

mov di,c_del
call cmpstr
jc del_link

mov di,c_cd
call cmpstr
jc cd_link

mov di,c_cddot
call cmpstr
jc cddot_link

mov di,c_roam
call cmpstr
jc roam_link

mov di,c_alarm
call cmpstr
jc alarm

mov di,c_alarmtext
call cmpstr
jc alarmtext

mov di,c_autostart
call cmpstr
jc autostart

mov di,c_setting
call cmpstr
jc c_setting_f

mov di,c_pipe
call cmpstr
jc pipe

mov di,c_micro
call cmpstr
jc c_micro_f
; 
; mov di,c_multi
; call cmpstr
; jc c_multi_f

mov di,c_cursor
call cmpstr
jc c_cursor_f

mov di,c_echo
call cmpstr
jc c_echo_f

mov di,c_help
call cmpstr
jc c_help_f

mov di,c_exit
call cmpstr
jc c_exit_f2

mov di,c_step
call cmpstr
jc step_f

mov di,c_newdir
call cmpstr
jc dirnew_link

mov di,c_q
call cmpstr
jc fdir_link

mov di,c_a
call cmpstr
jc fdir_link

mov di,c_z
call cmpstr
jc roam_link

;; Command is not known
; Hence checking for a program with same name
call microkernel
;microkernel_kernel_loop:

;; Finally checking for one-character mints
mov ax,[found]
push ax
call command ;; Checking for mints
cmp byte [echo_flag],0x0f
je .done
pop ax
cmp ax,[found]
jne .done
call print_error
.done:
jmp kernel ;Return to main loop

c_type_f:
;mov si,c_text
;call pipespace2enter
;mov si,c_text
;call pipestore
;mov ax,0x1C0D
;call keybsto
mov ax,0x0100
call keybsto
jmp text

c_advanced_f:
not byte [advanced_flag]
jmp kernel

c_autosize_f:
not byte [autosize_flag]
jmp kernel

c_completeload_f:
not byte [completeload_flag]
jmp kernel

c_idle_time_f:
mov si,kernel_idle_time_str
call prnstr
call colon
call getno
mov [idle_kernel_waittime],al
jmp kernel

c_idle_command_f:
mov si,kernel_idle_command_str
call prnstr
call colon
mov di,idle_kenel_commandstr
call getstr
;mov byte [di-1],0x20
mov byte [di-1],0x0D
mov byte [di],0
jmp kernel

c_wall_f:
mov ah,0x50
int 0x61
jmp kernel

c_echo_f:
not byte [echo_flag]
jmp kernel

c_help_f:
mov ax,0x3b00
call keybsto
jmp kernel

c_exit_f2:
mov byte [found],'e'
mov byte [found+1],' '
call command
jmp kernel

dirnew_link:
mov word [size],1
mov word [filesize],512
mov byte [command_tempchar],'d'
call filenew
jmp kernel

filenew_link:
mov byte [command_tempchar],'f'
call filenew
jmp kernel

filesave_link:
mov bx,[loc]
call filesave_c
jmp kernel

rename_link:
mov byte [command_tempchar],'r'
call filenew
jmp kernel

copy_link:
mov ax,tempstr2
mov bx,new_file_str
call os_input_dialog

	mov ax, ImageName
	;mov bx, tempstr
	mov cx, 36864
	call os_load_file

	;cmp bx, 28672				; Is file to copy bigger than 28K?
	;jg .error

	; For Multi Drive Copy
cmp byte [advanced_flag],0x0f
je .skip_drive
push bx
	mov ax,c_drive
	mov bx,drive
	call os_get_int_dialog
pop bx
.skip_drive:
	mov cx, bx				; Otherwise write out the copy
	mov bx, 36864
	mov ax, tempstr2
	call os_write_file
	jc .error
	jmp kernel

	.error:
	call newline
	call print_error
	jmp kernel

del_link:
mov byte [command_tempchar],'x'
call filenew
jmp kernel

cd_link:
mov si,[argument_position]
cmp si,0
je .cd_name_not_given
mov di,ImageName
call os_string_copy
;call getstr
.cd_name_recieved:
call checkfname
mov byte [command_tempchar],'q'
jmp fdir
.cd_name_not_given:
mov di,ImageName
call getstr
jmp .cd_name_recieved

cddot_link:
mov di,ImageName
mov al,'.'
stosb
stosb
mov al,0x20
mov cx,9
rep stosb
mov byte [command_tempchar],'q'
jmp fdir

fdir_link:
mov al,[found]
mov [command_tempchar],al
jmp fdir

roam_link:
mov byte [command_tempchar],'r'
jmp fdir

load_f:
call getno
mov ah,0x02
jmp drive_comm

save_f:
call getno
mov ah,0x03
jmp drive_comm

c_dir_f:
mov byte [command_tempchar],'q'
jmp fdir

runa:
mov si,argstr
call prnstr
mov di,found
call getstr
mov si,found
cmp byte [found],0
jne run
mov si,0
run:

;push ds
;push es

;Fix compatibility with DOS programs
; mov byte [0], 0xCD		; int 20h
; mov byte [1], 0x20
; mov byte [2], 0xA0		; Always 0xA000 for COM executables
; mov byte [3], 0x00

	; Clear registers to be DOS compatible
	;xor ax, ax
	xor bx, bx
	xor cx, cx
	xor dx, dx
	;xor si, si ;Arguments are provided using this
	xor di, di
	xor bp, bp

mov ax,[data_seg]
mov ds,ax
mov es,ax
mov ax,[loc]
call word [loc]	;;Jump to execution

mov ax,0 ;[kernel_seg]
mov ds,ax
mov es,ax
;pop es
;pop ds

call reg_int	;;TODO fix replacement of calls
jmp kernel
;mov word bx,0x0001
;push bx
;mov word bx,[loc]
;push bx
;sub bx,0x0500
;retf
;jmp kernel

; EXELOADADDR    equ 0x00006000
; ;; _IMAGE_DOS_HEADER.e_magic: Should be "MZ"
; sigMZ         equ esi
; ;; _IMAGE_DOS_HEADER.e_lfanew: Offset into file where PE header is
; PEheaderOffset   equ esi+60
; ;; _IMAGE_NT_HEADERS.Signature: Should be "PE\0\0"
; sigPE         equ esi
; ;; _IMAGE_NT_HEADERS.FileHeader.NumberOfSections: Self explanatory
; NumSections      equ esi+6
; ;; _IMAGE_NT_HEADERS.IMAGE_OPTIONAL_HEADERS.BaseOfCode: Where the code section should go
; BaseOfCode      equ esi+52
; ;; _IMAGE_NT_HEADERS.IMAGE_OPTIONAL_HEADERS.AddressOfEntryPoint: Offset, relative to load address, of the entry point
; EntryAddressOffset   equ esi+40
; ;; sizeof(_IMAGE_NT_HEADERS.IMAGE_OPTIONAL_HEADERS) + sizeof(_IMAGE_NT_HEADERS.FileHeader): to get to the section directory
; SizeOfNT_HEADERS   equ 248

; SectionSize      equ esi+8

; SectionBase      equ esi+12

; SectionFileOffset   equ esi+20

; SizeOfSECTION_HEADER   equ 40

   ; ;; Now, let's map in the PE file and run it!
; execute:
   ; mov esi, EXELOADADDR
   ; mov eax, [sigMZ]
   ; ;; Compare the first signature
   ; cmp ax, 0x5A4D
   ; jnz badPE
   ; ;; If we got here, it's a 'valid' exe.
   ; ;; Let's get the offset to the PE header:
   ; mov eax, [PEheaderOffset]
   
   ; add esi, eax
   ; mov eax, [sigPE]
   ; ;; Now the second
   ; cmp eax, 0x00004550
   ; jnz badPE2
   
   ; ;; let us assume (for now) that the PE is for the x86 platform,
   ; ;;  and not, say, ARM or something...
   
   ; xor edx, edx
   ; mov dx, [NumSections]
   ; mov eax, [BaseOfCode]
   ; mov ebx, [EntryAddressOffset]
   
   ; ;; Add the base of the code to the entry point offset
   ; ;; to get the function pointer
   ; add ebx, eax
   ; ;; ebx now equals loader's entry point, so let's save it
   ; push ebx
   
   ; ;; skip the PE header, since we don't need the rest for this simple loader
   ; add esi, SizeOfNT_HEADERS

; .loadloop:
   ; ;; eax still contains BaseOfCode
   ; ;; and dx still contains the number of sections

   ; ;; Get the size of the section
   ; mov ecx, [SectionSize]
   ; ;; Get the relative address of the section
   ; mov edi, [SectionBase]
   ; ;; calculate the actual address of the section
   ; add edi, eax
   ; ;; now get the file offset of the section
   ; mov ebx, [SectionFileOffset]
   ; ;; and add the load address to get the memory location of the section
   ; add ebx, EXELOADADDR
   
   ; ;; save where we are in the file
   ; push esi
   
   ; ;; and copy the section data
   ; mov esi, ebx
   ; rep movsb
   
   ; ;; restore our location...
   ; pop esi
   ; ;; and skip to the next section
   ; add esi, SizeOfSECTION_HEADER
   
   ; ;; That's one more section down
   ; dec edx
   ; ;; Are we done yet?
   ; or edx, edx
   ; jnz .loadloop

   ; ;; Yes we are! Let's get the entry function pointer and go there!
   ; pop ebx
   ; jmp ebx

; badPE:
   ; ;call cls32
   ; mov si, fbLoaderBad
   ; call prnstr
   ; ;cli
   ; ;hlt
   ; jmp kernel

; badPE2:
   ; ;call cls32
   ; mov si, fbLoaderBad2
   ; call prnstr
   ; ;cli
   ; ;hlt
   ; jmp kernel

; fbLoaderBad:
   ; db "Not valid exe.",0

; fbLoaderBad2:
   ; db "Not Win32/Firebird exe.",0

execute:
mov si,[loc]
lodsw
cmp ax,0x5A4D	;MZ
je .ok
cmp ax,0x4D5A	;ZM
je .ok
jmp .quit
.ok:
add si,4
lodsw
mov [.exereloc],ax
lodsw
mov [.exehead],ax

add si,10
lodsw
mov [.exeip],ax
lodsw
mov [.execs],ax
lodsw
mov [.exereloctable],ax

;Program Location
mov bx,[.exereloc]
imul bx,4
mov ax,[loc]
add ax,bx
mov cx,16
mov dx,0
div cx
mov cx,[.execs]
add cx,ax

add cx,[.exehead]
;mov ax,[.exehead]
;imul ax,16
;mov di,ax

push cx
mov [.loaded_progseg],cx
imul cx,0x10
mov [.load_module],cx
mov di,[.exeip]
push di
mov [.loaded_progaddr],di

; mov cx,0x00
; mov ds,cx
; mov cx,0x01
; mov es,cx
; mov di,0
; mov si,[loc]
; mov cl,[size]
; mov ch,0x00
; imul cx,0x0200
; .loop:
; mov al,[ds:si]
; mov [es:di],al
; inc si
; inc di
; loop .loop

;Relocation
mov cx,[.exereloc]
cmp cx,0
je .skipreloc
mov si,[.exereloctable]
add si,[loc]
mov dx,[.loaded_progseg]
.relocloop:
push cx
; mov ax,[bx]
; add bx,2
; mov es,[bx]
; mov cx,0
; lodsw
; call printwordh
; call colon
lodsw
mov bx,ax
lodsw
imul ax,0x10
add bx,ax
add bx,[.load_module]
add [bx],dx
pop cx
loop .relocloop
.skipreloc:

mov ax,[.loaded_progseg]
mov ds,ax
mov es,ax
retf

.quit:
mov si,.notmzstr
call prnstr
jmp kernel
.notmzstr:
db "!EXE",0
.exereloc:
dw 0
.exehead:
dw 0
.exeip:
dw 0
.execs:
dw 0
.exereloctable:
dw 0

.loaded_progseg:
dw 0
.loaded_progaddr:
dw 0
.load_module:
dw 0

buffer_clear:
call chkkey
jz .clear
call getkey
jmp buffer_clear
.clear:
ret

;Shell function
;batch executes each line in file
;All command combinations are supported
batch:
mov si,[loc]
mov [var_e],si

batchset:
call buffer_clear
call newline
mov si,[var_e]
;add di,[var_e]
cmp byte [si],0x00
je kernel
mov al,[si]
mov [.batch_command],al

mov di,.batch_end
mov ax,di
call os_string_length
mov cx,ax
call cmpstr_s
jc kernel

mov di,found
cmp byte [.batch_command],'#'
je .shell_command
cmp byte [.batch_command],'*'
je .skipcommand
cmp byte [.batch_command],'@'
je .skipcommand
jmp .batchloop
.skipcommand:
inc word [var_e]
inc si
.batchloop:
lodsb
inc word [var_e]
cmp al,0x00 ;End of string
je .end
cmp al,0x0D ;Newline
je .end
cmp al,0x0A ;Newline
je .skip
cmp al,0x20 ;Space
je .get_argument
stosb
jmp .batchloop
.end:
cmp byte [si],0x0A
jne .skip
inc word [var_e]
.skip:
xor al,al
stosb
;add word [var_e],2
jmp .batch_stored

.get_argument:
mov al,0
stosb
mov di,tempstr
.get_argument_loop:
lodsb
inc word [var_e]
cmp al,0x00 ;End of string
je .get_argument_done
cmp al,0x0D ;Newline
je .get_argument_done
cmp al,0x0A ;Newline
je .get_argument_done
stosb
jmp .get_argument_loop

.get_argument_done:
;cmp byte [.batch_command],'*'
;je .skip_end_character
mov al,0x0D
stosb
;.skip_end_character:
mov al,0
stosb
;Stores interpreted string in input buffer
cmp byte [.batch_command],'*'
je .store_as_it_is
mov si,tempstr
call pipespace2enter
.store_as_it_is:
mov si,tempstr
call pipestore
mov byte [getstr.end],0x20
jmp .end

.batch_stored:
;Sets kernel return point to create loop
mov byte [kernelreturnflag],0xf0
mov word [kernelreturnaddr],batchset

cmp byte [.batch_command],'@'
je .echo_off
cmp byte [echo_flag],0x0F
je .echo_off
pusha
mov si,found
call prnstr
; mov si,tempstr
; call prnstr
; call getkey
; call keybsto
; call slow
popa
.echo_off:

;Execute
;jmp command_start
jmp command_received

.batch_command: db 0
.batch_end: db 'end',0
.batch_high: db 'high',0

.shell_command:
inc si
inc word [var_e]

mov di,.batch_high
mov ax,di
call os_string_length
mov cx,ax
call cmpstr_s
jc .batch_high_f

.shell_done:
mov si,[var_e]
.shell_done_loop:
lodsb
cmp al,0x0A
je .shell_done_end
jmp .shell_done_loop
.shell_done_end:
mov [var_e],si
jmp batchset

.batch_high_f:
mov cx,[filesize] ;Amount of data to copy
mov di,0xffff ;End of current segment
sub di,cx ;How back to start copy
push di
mov si,[loc] ;Source File
rep movsb ; Copy to higher memory
pop di
mov si,[loc] ;Current Start
sub [var_e],si ; Absolute offset
add [var_e],di ; New Start
jmp .shell_done ; Continue

;Getting arguments if space key is found
;Arguments is stored at the standard 0x81 location
;In 0x81 the number of characters is stored

; DOS-Compatible arguments
; argument:
; mov si,0
; mov byte [0x80],0
; mov di,[argument_position]
; cmp [di],0
; je .run
; mov si,di
; mov di,0x81
; call os_string_copy
; mov si,0x81
; .run:
; ret

storename:
mov si,ImageName
mov di,ImageNameTemp
mov cx,0x000B
rep movsb
ret
restorename:
mov si,ImageNameTemp
mov di,ImageName
mov cx,0x000B
rep movsb
ret
store_HTS:
mov dl,[absoluteSector]
mov [var_j],dl
mov dl,[absoluteHead]
mov [var_k],dl
mov dl,[absoluteTrack]
mov [var_l],dl
ret
restore_HTS:
mov dl,[var_j]
mov [absoluteSector],dl
mov dl,[var_k]
mov [absoluteHead],dl
mov dl,[var_l]
mov [absoluteTrack],dl
ret

microkernel:

;; Searches for file with command as name
; From a list of directories in the path list
mov ax,[currentdir]
mov [currentdirtemp],ax
call store_HTS
call storename
mov word [var_d],0
cmp byte [micro],0xf0
je .enabled
ret
.microsearch_done:
mov ax,[currentdirtemp]
mov [currentdir],ax
call restore_HTS
ret
.start_search:
mov si,path_list
mov cx,0
.start_loop:
lodsw
inc cx
cmp ax,0
je .microsearch_done
cmp word [var_d],10
jg .microsearch_done
cmp word cx,[var_d]
jl .start_loop
mov [currentdir],ax
.enabled:

mov si,found
mov di,ImageName
mov cx,0x0008
;call memcpys
repnz movsb
call checkfname

;mov si,.extension_com
mov si,coms
call microkernel_findfile
jnc .find_bin
jmp .run_program
; .extension_com:
; db 'COM'

.find_bin:

mov si,.extension_bin
call microkernel_findfile
jnc .find_exe

.run_program:
call microkernel_restoredata
pop ax
;call argument
mov si,[argument_position]
jmp run
.extension_bin:
db 'BIN'

.find_exe:

mov si,.extension_exe
call microkernel_findfile
jnc .find_bat

call microkernel_restoredata
pop ax
jmp execute
.extension_exe:
db 'EXE'

.find_bat:

mov si,.extension_bat
call microkernel_findfile
jnc .find_pcx

call microkernel_restoredata
pop ax
jmp batch
.extension_bat:
db 'BAT'

.find_pcx:

mov si,.extension_pcx
call microkernel_findfile
jnc .extra_search

call microkernel_restoredata
pop ax
jmp c_paint_f
.extension_pcx:
db 'PCX'

;Searches for more extensions
;that can be supported in a file
.extra_search:

;Check if given filename exists
mov ax,found
call get_name

mov ax,ImageName
call os_file_exists
jc .fail

; when list is loaded,
; parse the list to check
mov ax,[dir_seg]
mov es,ax
mov si,[loc4]
mov [.extra_pos],si
.extra_loop:
; push ds
; mov dx,[dir_seg]
; mov ds,dx
; mov al,0
; repne scasb
; pop ds

mov si,[.extra_pos]
mov di,tempstr2
mov cx,3
call memcpy_far_dir
mov byte [di],0
add word [.extra_pos],3

mov si,ImageName+8
mov di,tempstr2
mov cx,3
call cmpstr_s
jnc .not_equal

;If extension is found
.space_loop:
mov bx,[.extra_pos]
mov al,[es:bx]
inc word [.extra_pos]
cmp al,0
je .end_loop
cmp al,0x20
jne .space_loop

mov si,[.extra_pos]
call .extra_enter_loop
mov di,tempstr2
sub bx,si
dec bx
mov cx,bx
add word [.extra_pos],cx
call memcpy_far_dir
mov byte [di],0

pop ax
mov ax,[kernel_seg]
mov es,ax

mov si,tempstr2
call pipespace2enter
; mov si,tempstr2
; call prnstr
; call space

mov si,found
mov di,ImageName
call os_string_copy

; mov si,ImageName
; call prnstr

; mov ax,tempstr2
; call os_string_length
; mov si,tempstr2
; mov di,found
; mov cx,ax
; rep movsb

mov si,[argument_position]
cmp si,0
je .no_arguments
mov di,tempstr
call memcpy
.no_arguments:

mov si,tempstr2
mov di,found
call memcpy
dec di
mov al,0x20
stosb
;mov byte [getstr.end],0x20
mov si,ImageName
call memcpy
; mov cx,0x000C
; rep movsb

mov si,[argument_position]
cmp si,0
je .no_arguments2
dec di
mov al,0x20
stosb
mov si,tempstr
call memcpy
.no_arguments2:
; call pipestore
; mov ax,0x1C0D
; call keybsto

mov si,found
call prnstr

jmp command_received
; jmp kernel

;If extension not same
.not_equal:

;.enter_loop:
call .extra_enter_loop
jmp .extra_loop

.extra_enter_loop:
mov bx,[.extra_pos]
mov al,[es:bx]
inc word [.extra_pos]
pop dx
cmp al,0
je .end_loop
push dx
cmp al,0xA
jne .extra_enter_loop
ret
.extra_pos: dw 0xA000

;loop .extra_loop
;jmp .end_loop
.end_loop:
mov ax,[kernel_seg]
mov es,ax
jmp .fail

;File Name of the extension list
.extra_file_name:
db "progs.txt",0

.fail:
inc word [var_d]
call restorename
jmp microkernel.start_search
;jmp microkernel_kernel_loop
;pop ax
;jmp kernel

;Carry set if file found
microkernel_findfile:
mov di,ImageName+8
;si pointing to extension
mov cx,0x003
rep movsb
call checkfname

mov word [comm],0x0f0f
mov byte [command_tempchar],'c'
mov bx,.return_address
mov [extra],bx
jmp fdir
.return_address:

mov dx,[comm]
cmp dx,0xf0f0
jne .fail

stc
ret
.fail:
clc
ret

microkernel_restoredata:
call restorename
mov ax,[currentdirtemp]
mov [currentdir],ax
call restore_HTS
ret

text.move_right:
call getpos
inc dl
call setpos
inc word [var_a]
jmp text.text_control

text.move_down:
call getpos
inc dh
call setpos
add word [var_a],80
jmp text.text_control

text:
;mov cx,0x0000
;call getpos
;push dx
mov al,[found]
mov [command_tempchar],al
mov cx,0x0200
mov [var_a],cx
mov es,[data_seg]
mov si,[loc]
.text_loop:
;lodsb
mov al,[es:si]
inc si
cmp byte [command_tempchar],'c'
je .code_show
cmp byte [command_tempchar],'p'
je .print_file
call printf
jmp .text_loop_check
.code_show:
call printh
jmp .text_loop_check
.print_file:
xor ah,ah
xor dx,dx
int 0x17
.text_loop_check:
loop .text_loop
;mov cx,0x200
;pop dx
;call setpos
jmp .text_shown
.text_exit:
mov dx,[kernel_seg]
mov es,dx
jmp kernel
.text_shown:
cmp byte [found],'c'
je code_control
cmp byte [found],'p'
je .text_exit
.text_control:
mov ah,0x00
int 0x16
cmp ah,0x01
je .text_exit
cmp ah,0x29
je .text_exit
cmp ah,0x48
je .move_up
cmp ah,0x4B
je .move_left
cmp ah,0x4D
je .move_right
cmp ah,0x50
je .move_down
cmp ah,0x3b
je .text_help
cmp ah,0x3d
je .text_copy
cmp ah,0x3e
je .text_paste
cmp ah,0x3f
je .text_spec
cmp ah,0x40
je .text_clear
cmp ah,0x52
je .text_paste

mov bx,[loc]
add bx,[var_a]
mov [es:bx],al
call printf
inc word [var_a]
jmp .text_control
.text_help:
mov dx,doc_helpstr
xor ah,ah
int 61h
jmp .text_control
.text_copy:
mov bx,[loc]
add bx,[var_a]
;inc bx
mov si,bx
jmp .text_control
.text_paste:
lodsb
mov bx,[loc]
add bx,[var_a]
mov [es:bx],al
call printf
inc word [var_a]
jmp .text_control
.text_spec:
call show_details
jmp .text_control
.text_clear:
mov bx,[loc]
add bx,[var_a]
mov byte [es:bx],0
call printf
inc word [var_a]
jmp .text_control

.move_up:
call getpos
dec dh
call setpos
sub word [var_a],80
jmp .text_control

.move_left:
call getpos
dec dl
call setpos
dec word [var_a]
jmp .text_control

code_control:
;mov word cx,[player_x]
call getkey

;call chkkey
;jz code_control

cmp ah,0x01
je text.text_exit
cmp ah,0x29
je text.text_exit
cmp ah,0x3b
je .code_help
cmp ah,0x3d
je .code_copy
cmp ah,0x3e
je .code_paste
cmp ah,0x3f
je .code_spec
cmp ah,0x40
je .code_clear

push ax
call getpos
pop ax
cmp ah,0x48
je code_move_up
cmp ah,0x4B
je code_move_left
cmp ah,0x4D
je code_move_right
cmp ah,0x50
je code_move_down

call keybsto
call gethex
mov bx,[loc]
add bx,[var_a]
mov [es:bx],al
inc word [var_a]
jmp code_control

.code_help:
mov dx,doc_helpstr
xor ah,ah
int 0x61
jmp code_control
.code_copy:
mov bx,[loc]
add bx,[var_a]
mov si,bx
jmp code_control
.code_paste:
lodsb
mov bx,[loc]
add bx,[var_a]
mov byte [bx],al
call printh
inc word [var_a]
jmp code_control
.code_spec:
call show_details
jmp code_control
.code_clear:
mov bx,[loc]
add bx,[var_a]
mov byte [bx],0
call printh
inc word [var_a]
jmp code_control

show_details:
mov ah,0x49
mov bx,c_loc
mov dx,[loc]
add dx,[var_a]
mov cx,0x0005
int 0x61
ret

code_move_up:
dec dh
call setpos
sub word [var_a],40
jmp code_control

code_move_left:
sub dl,2
call setpos
dec word [var_a]
jmp code_control

code_move_right:
add dl,2
call setpos
inc word [var_a]
jmp code_control

code_move_down:
inc dh
call setpos
add word [var_a],40
jmp code_control

c_drive_f:
mov si,drive
call change
jmp kernel

c_drive2_f:
mov si,drive2
call change
jmp kernel

c_loc_f:
mov bx,loc
cmp byte [getstr.end],0x20
jne .get
mov al,'F'
call printf
call colon
call getno
call newline

imul ax,2
mov bx,loc
add bx,ax
.get:
jmp getwordh_j

c_loc2_f:
mov bx,loc2
jmp getwordh_j

c_loc3_f:
mov bx,loc3
jmp getwordh_j

c_dataseg_f:
mov bx,data_seg
jmp getwordh_j

c_setdir_f:
mov bx,currentdir
jmp getwordh_j

c_addpathc_f:
mov dx,[currentdir]
mov [currentdirtemp],dx
call c_addpath_f_call
jmp kernel

c_addpath_f:
mov bx,currentdirtemp
call getwordh
push kernel

c_addpath_f_call:
mov cx,1
mov si,path_list
.loop:
lodsw
inc cx
cmp cx,10
jg .done
cmp ax,[currentdirtemp]
je .done
cmp ax,0
jne .loop
.done:
sub si,2
mov ax,[currentdirtemp]
mov [si],ax
ret

os_reset:
mov ah,0x00
mov al,[mode]
int 0x10
call clear_screen
;call newline

;;TODO causing problems in some PCs
;;call os_mouse_setup

call os_memory_reset
call os_seed_random
	
mov ax, 0
mov bx, 0
mov cx, 79
mov dx, 24
call os_mouse_range
	
mov dh, 3
mov dl, 2
call os_mouse_scale
call reg_int
mov word [currentdir],0x0013
call buffer_clear

call storename
;Check if extension list exists
mov ax,microkernel.extra_file_name
call os_file_exists
;jc .fail ; exit if file not found
jc .skip_loading ; skip loading if file not found

;Load the file to directory segment
push es
mov ax,[dir_seg]
mov es,ax
call calculate_size
mov cx,ax
push cx
mov ax,[cluster]
call ClusterLBA
pop cx
mov bx,[loc4]
call ReadSectors
pop es
call restorename

.skip_loading:
ret

c_reset_f:

cli
	xor	ax, ax
	mov	ds, ax
	mov	es, ax
	mov	ax, 0x9000
	mov	ss, ax
	mov	sp, 0xFFFF
sti

push ds
lgdt [gdtinfo]
mov eax,cr0
or al,1
mov cr0,eax

jmp $+2
mov bx,0x08
mov ds,bx
and al,0xFE
mov cr0,eax
pop ds

call os_reset
jmp kernel

; c_reset_c:
; mov ah,0x00
; mov al,[mode]
; int 10h
; ret

c_cls_f:
call clear_screen
xor dx,dx
call setpos
jmp kernel

c_prompt_f:
mov di,prompt
call getstr
jmp kernel

c_color_f:
mov si,color
call change
jmp kernel

c_color2_f:
mov si,color2
call change
jmp kernel

color_switch:
mov dx,[color]
xchg dh,dl
mov [color],dx
ret

c_typemode_f:
not byte [teletype]
jmp kernel

os_graphics_mode:
; Put the operating system in graphical mode (mode 13h)
push ax
mov ax,0x0013
int 0x10
pop ax
ret

c_videomode_f:
mov si,mode
call change
xor ah,ah
int 0x10
jmp kernel

printf_c:
pusha
mov bh,[page]
mov ah,0x09
cmp byte [teletype],0xf0
je .tele
mov bl,[color]
jmp .set
.tele:
mov bl,[color2]
.set:
mov cx,0x0001
int 0x10
popa
ret

; printf_b:
; pusha
; call printf_c
; call getpos
; inc dl
; call setpos_c
; popa
; ret

printf:

cmp byte [teletype],0xf0
je printt

pusha
mov bh,[page]
mov ah,0x09
mov bl,[color]
mov cx,0x0001
int 0x10
call update_pos
popa
ret

printt:
pusha
mov ah,0x0e
mov bh,[color2]
mov bl,[page]
int 10h
popa
ret

readchar:
mov ah,0x08
int 10h
ret

getpos:
mov ah,0x03
mov bh,[page]
int 0x10
ret

setpos:
cmp dl,[border_min_x]
jl update_pos_c_z
cmp dh,[border_min_y]
jl update_pos_r_z
cmp dh,[border_max_y]
jg update_pos_r
cmp dl,[border_max_x]
jg update_pos_c
jmp update_pos_e
update_pos_r_z:
;xor dh,dh
mov dh,[border_min_y]
;add dh,[border_max_y]
jmp setpos
update_pos_c_z:
add dl,[border_max_x]
dec dl
dec dh
jmp setpos
update_pos_c:
inc dh
sub dl,[border_max_x]
add dl,[border_min_x]
dec dl
jmp setpos
update_pos_r:
cmp byte [scrollmode],0x0f
je update_scroll_off
call scroll_down
mov dh,[border_max_y]
inc dh
sub dh,[scrolllength]
jmp setpos
update_scroll_off:
call clear_screen
xor dh,dh
jmp setpos
update_pos_e:
setpos_c:
mov ah,0x02
mov bh,[page]
int 0x10
ret

clearline:
mov al,0x20
mov cx,0x4f
.loop:
call printf
dec cx
cmp cx,0
jge .loop
;call color_switch
call printf_c
;call color_switch
call getpos
sub dl,0x50
call setpos
ret

clear_screen:
pusha
cmp byte [wall_flag],0xf0
je .wall_on
mov ax,0x0600
call clear_bios_function
.done:
mov	ax,1003h
xor	bx,bx
int	10h
popa
ret
.wall_on:
call restorescreen
jmp .done

clear_bios_function:
mov ch,[border_min_y]
mov cl,[border_min_x]
mov dl,[border_max_x]
mov dh,[border_max_y]
mov bh,[color]
cmp byte [teletype],0xf0
jne .clear_screen_tele
mov bh,[color2]
.clear_screen_tele:
cmp byte [rollcolor],0xf0
jne .clear_screen_rolloff
rol bh,4
.clear_screen_rolloff:
int 10h
ret

clean_screen:
mov ax,0x0600
mov ch,[border_min_y]
mov cl,[border_min_x]
mov dl,[border_max_x]
mov dh,[border_max_y]
mov bh,0x00
int 10h
ret

scroll_down:
pusha
mov ah,0x06
mov al,[scrolllength]
call clear_bios_function
popa
ret

update_pos:
call getpos
inc dl
call setpos
ret

itoa:
mov dx,ax
xor ax,ax
push ax
.loop:
mov ax,dx
xor dx,dx
mov cx,10
div cx
xchg ax,dx
add ax,0x30
push ax
cmp dx,0
jg .loop
.printloop:
pop ax
cmp ax,0
je .done
stosb
jmp .printloop
.done:
xor ax,ax
stosb
ret

;printn_big:
printn:
mov edx,eax
xor eax,eax
push ax
.loop:
mov eax,edx
xor edx,edx
mov ecx,10
div ecx
xchg eax,edx
add eax,0x30
push ax
cmp edx,0
jg .loop
.printloop:
pop ax
cmp ax,0
je .done
call printf
jmp .printloop
.done:
ret

; printn:
; mov dx,ax
; xor ax,ax
; push ax
; .loop:
; mov ax,dx
; xor dx,dx
; mov cx,10
; div cx
; xchg ax,dx
; add ax,0x30
; push ax
; cmp dx,0
; jg .loop
; .printloop:
; pop ax
; cmp ax,0
; je .done
; call printf
; jmp .printloop
; .done:
; ret

printnb:
mov bl,'A'
push bx
mov bh,al
.reverse:
mov al,bh
mov bl,10
mov ah,0
div bl
mov bh,al
mov al,ah
add al,48
push ax
cmp bh,0
jg .reverse
.printne:
pop ax
cmp al,'A'
jne .printnf
jmp .printnq
.printnf:
call printf
jmp .printne
.printnq:
ret

os_print_1hex:
pusha
ror al,4
shr al,4
cmp al,10
sbb al,69h
das
call printf
popa
ret

os_print_2hex:
printh:
pusha
shr al,4
cmp al,10
sbb al,69h
das
call printf
popa
pusha
ror al,4
shr al,4
cmp al,10
sbb al,69h
das
call printf
popa
ret

os_print_4hex:
printwordh:
push ax
mov al,ah
call printh
pop ax
call printh
ret

printdwordh:
push ax
mov ax,dx
call printwordh
pop ax
call printwordh
ret

printdwordh_full:
ror eax,16
call printwordh
ror eax,16
call printwordh
ret

gethex:
call getkey
call printf
call atohex
shl al,4
mov [comm],al

call getkey
call printf
call atohex
mov ah,[comm]
add al,ah
ret

atohex:
cmp al,0x3a
jle hex_num_found
cmp al,0x5a
jg hex_small_found
add al,0x20
hex_small_found:
sbb al,0x28
hex_num_found:
sbb al,0x2f
ret

getwordh_j:
push kernel
getwordh:
inc bx
call gethex
mov byte [bx],al
dec bx
call gethex
mov byte [bx],al
ret

; inttobcd:
; ;sbb al,0x99
; push ax
; shr al,4
; sbb al,0x99
; das
; mov dl,al
; pop ax
; ror al,4
; shr al,4
; sbb al,0x99
; das
; add dl,al
; mov al,dl
; ret

prnstr:
lodsb
or al,al
jz .prnend
call printf
jmp prnstr
.prnend:
ret

print_error:
mov si, imsge
call prnstr
ret

prnstr_dos:
lodsb
cmp al,0
je .prnend
cmp al,'$'
je .prnend
cmp al,0x0D
je .enter
cmp al,0x0A
je .enter2

call printf
jmp prnstr_dos
.prnend:
ret
.enter:
inc si
jmp .done
.enter2:
cmp byte [si],0x0D
jne .done
inc si
.done:
call newline
jmp prnstr_dos

chkkey:
mov ah,0x11
;mov ah,1
int 0x16
ret

getkey:
; call chkkey
; jz getkey

mov ah,0x10
;mov ah,0
;xor ah,ah
int 0x16
;cmp ah,0x0F
;je .skip
;cmp ah,0x44
;je .skip
cmp ah,0x0F
je .pagekey
cmp ah,0x44
je .quitkey
cmp ah,0x85
je .debugkey
ret
.pagekey:
call page_change_c.skip_key
ret
.quitkey:
pop ax
jmp kernel
.debugkey:
call debug
jmp getkey

directgetkey:
; call chkkey
; jz directgetkey
mov ah,0x10
;xor ah,ah
int 0x16
ret

; getkeyflag:
; mov ah,0x12
; int 16h
; ret

;IN: SI-string
;OUT: ax-converted integer
atoi:
push bx
push cx
push dx
xor bx,bx
.getno_loop:
lodsb
cmp al,0
je .getno2e
cmp al,0x0D
je .getno2e
cmp al,0x0A
je .getno2e
cmp al,0x20
je .getno2e
sub al,0x30
mov cl,al
mov ax,bx
mov dx,0x000a
mul dx
mov bx,ax
xor ch,ch
add bx,cx
jmp .getno_loop
.getno2e:
mov ax,bx
pop dx
pop cx
pop bx
ret

getno:
push bx
push cx
push dx
xor ebx,ebx
.getno_loop:
call getkey
call printf
cmp al,0x0D
je .getno2e
cmp al,0x08
je .back
sub al,0x30
mov cl,al
mov eax,ebx
mov ebx,0xa
mul ebx
mov ebx,eax
mov al,cl
xor ecx,ecx
mov cl,al
add ebx,ecx
jmp .getno_loop
.getno2e:
mov eax,ebx
pop dx
pop cx
pop bx
ret
.back:
pusha
call eraseback
call eraseback
popa
mov eax,ebx
xor edx,edx
mov ecx,0x000a
div ecx
mov ebx,eax
jmp .getno_loop

getstr:
mov si,di
mov byte [.end],0
.loop:
call getkey
call printf
cmp al,0x0d
je .string_found
cmp ah,0x01
je .string_end
cmp ah,0x0e
je .string_backpace
cmp ah,0x20
je .strspace
stosb
jmp .loop
.strspace:
mov byte [.end],0x20
stosb
jmp .loop
.string_backpace:
cmp si,di
jge .noback
dec di
cmp byte [teletype],0xf0
je .teleback
call eraseback
call eraseback
jmp .loop
.teleback:
mov al,0x20
call printf_c
jmp .loop
.string_found:
mov ax,0x0000
stosb
ret
.string_end:
mov byte [si],0
ret
.noback:
cmp byte [teletype],0xf0
je .telenoback
call eraseback
jmp .loop
.telenoback:
call getpos
inc dl
call setpos
mov al,0x20
call printf_c
jmp .loop
.end:
db 0

getstr_dos:
call getkey
call printf
dec cx
inc byte [bx]
cmp al,0x0d
je .strf
cmp ah,0x01
je .strf
cmp ah,0x0e
je .strb
cmp cx,0
je .strf
stosb
jmp getstr_dos
.strb:
cmp si,di
jge .noback
dec di
cmp byte [teletype],0xf0
je .teleback
call eraseback
call eraseback
jmp getstr_dos
.teleback:
mov al,0x20
call printf_c
jmp getstr_dos
.strf:
mov al,'$'
stosb
ret
.noback:
cmp byte [teletype],0xf0
je .telenoback
call eraseback
jmp getstr_dos
.telenoback:
call getpos
inc dl
call setpos
mov al,0x20
call printf_c
jmp getstr_dos

; getarg:
; mov si,di
; .loop:
; call getkey
; cmp byte [echo_flag],0x0F
; je .skip
; call printf
; .skip:
; cmp al,0x20
; je .argf
; cmp al,0x0d
; je .argf
; cmp ah,0x01
; je .arge
; cmp ah,0x0e
; je .argb
; stosb
; jmp .loop
; .argb:
; cmp si,di
; jge .noback
; dec di
; cmp byte [teletype],0xf0
; je .teleback
; call eraseback
; call eraseback
; jmp .loop
; .teleback:
; mov al,0x20
; call printf_c
; jmp .loop
; .argf:
; mov [.end],al
; mov ax,0x0000
; stosb
; ret
; .arge:
; mov byte [found],0x00
; ret
; .noback:
; cmp byte [teletype],0xf0
; je .telenoback
; call eraseback
; jmp .loop
; .telenoback:
; call getpos
; inc dl
; call setpos
; mov al,0x20
; call printf_c
; jmp .loop
; .end: db 0

eraseback:
call getpos
dec dl
call setpos
mov al,0x20
call printf_c
ret

storeline:
pusha
mov cx,80 ;0x0050
mov di,[temploc]
.loop:
push cx
call readchar
xchg ah,al
stosw
call update_pos
pop cx
dec cx
cmp cx,0
ja .loop
popa
ret

restoreline:
pusha
mov cx,80;0x0050
mov si,[temploc]
;sub si,0x0500
.loop:
lodsw
mov [color],al
mov al,ah
call printf
dec cx
cmp cx,0
ja .loop
popa
ret

memcpysave:
mov bx,0xB800
mov es,bx
xor bx,bx
;mov si,[loc]
;add si,ax
mov cx,0x07D0
.loop:
;cmp [es:bx],ax
;je .skip
mov ax,[es:bx]
;stosw
mov [ds:di],ax
add di,2
;.skip:
add bx,2
loop .loop
xor bx,bx
mov es,bx
ret

storescreen:
mov di,[locf2]
call memcpysave
ret
restorescreen:
mov si,[locf2]
call memcpyprint
ret

; storescreen:
; pusha
; call getpos
; push dx
; xor dx,dx
; call setpos
; mov cx,0x07CF
; mov di,[locf2]
; .loop:
; push cx
; call readchar
; stosw
; call update_pos
; pop cx
; dec cx
; cmp cx,0
; jg .loop
; pop dx
; call setpos
; popa
; ret

; restorescreen:
; pusha
; call getpos
; push dx
; xor bh,bh
; mov bl,[color]
; mov di,bx
; xor dx,dx
; call setpos
; mov cx,0x07CF
; mov si,[locf2]
; ;sub si,0x0500
; .loop:
; lodsw
; mov [color],ah
; call printf
; dec cx
; cmp cx,0
; jg .loop
; mov bx,di
; mov [color],bl
; pop dx
; call setpos
; popa
; ret

cmpstr_s:
mov byte [cmpstr.mode],1
os_string_compare:
cmpstr:
pusha
;cmp byte [si],0
;je .nequal
;cmp byte [di],0
;je .nequal
.loop:
lodsb
mov bl,[di]
inc di
cmp byte [.mode],0
je .skip
dec cx
cmp cx,0
je .cmpend
.skip:
cmp al,bl
jne .nequal
;cmp al,dh
;je .cmpend
cmp al,0
je .cmpend
jmp .loop
.nequal:
mov byte [.mode],0
popa
clc
ret
.cmpend:
mov byte [.mode],0
popa
stc
ret
.mode: db 0

os_print_newline:
newline:
pusha
call getpos
;xor dl,dl
mov  dl,[border_min_x]
inc dh
call setpos
popa
ret

drive_comm:
pusha
mov cl,al
mov bx,ds
mov es,bx

mov ch,[track]
mov dh,[head]
mov byte dl,[drive]
;xchg bx,ax
;call calculate_size
;mov ah,bh
mov word bx,[loc]
mov al,[size]
int 13h
jnc .success
call print_error
.success:
popa
jmp kernel
; .loop:
; pusha
; stc
; mov al,1
; int 13h

; jnc .success
; mov si,imsge
; call prnstr
; .success:
; popa
; dec al
; cmp al,1
; jge .loop

timer:
;mov ah,0x00
xor ah,ah
int 0x1a
mov al,ch
call printnb
call colon
mov al,cl
call printnb
call colon
mov al,dh
call printnb
call colon
mov al,dl
call printnb
ret

date:
mov ah,0x04
int 0x1a
mov al,dl
call printh
call colon
mov al,dh
call printh
call colon
mov al,ch
call printh
;call colon
mov al,cl
call printh
ret

command:

mov bx,found
mov al,'d'
cmp [bx],al
je c_date_f
mov al,'t'
cmp [bx],al
je c_time_f
mov al,'c'
cmp [bx],al
je c_timer_f
mov al,'i'
cmp [bx],al
je c_char_f
mov al,'I'
cmp [bx],al
je c_string_f
mov al,'h'
cmp [bx],al
je c_help_mint
mov al,'v'
cmp [bx],al
je c_ver_f
;mov al,'i'
;cmp [bx],al
;je c_install_f_link
; mov al,'m'
; cmp [bx],al
; je c_mousemode_c_link
mov al,'s'
cmp [bx],al
je c_space_f
mov al,'p'
cmp [bx],al
je c_pause_f
mov al,'l'
cmp [bx],al
je c_line_f
mov al,'e'
cmp [bx],al
je c_exit_f
ret

c_ver_f:
mov si,verstring
call prnstr
mov si,found
call strshift
jmp command

c_time_f:
call printf
call colon
call time
mov si,found
call strshift
jmp command

c_date_f:
call printf
call colon
mov ax,6
out 0x70,ax ; CMOS weekday register
in ax,0x71
cmp ax,8
jge .weekday_skip
imul ax,3
add ax,weekdays_list
mov bx,ax
mov cx,3
call reload_words
call space
.weekday_skip:
call date
mov si,found
call strshift
jmp command
weekdays_list:
db "SunMonTueWedThrFriSat"

c_timer_f:
call printf
call colon
call timer
mov si,found
call strshift
jmp command

c_char_f:
mov si,found
call strshift
mov al,[found]
call printf
mov si,found
call strshift
jmp command

c_string_f:
mov si,found
call strshift
mov si,found
call prnstr
ret

; Shutdown the computer
c_exit_f:
call printf

	mov ax, 5301h				; Connect to the APM
	xor bx, bx
	int 15h
	je near .connection		; Pass if connected
	cmp ah, 2
	je near .connection		; Pass if already connected
	jc .error				; Bail if fail
	
.connection:
	mov ax, 530Eh				; Check APM Version
	xor bx, bx
	mov cx, 0102h				; v1.2 Required
 	int 15h
	jc .error				; Bail if wrong version
	
	mov ax, 5307h				; Shutdown
	mov bx, 0001h
	mov cx, 0003h
	int 15h
.error:

mov ax,0x5307
mov bx,0x0001
mov cx,0x0003
int 0x15

mov si,found
call strshift
jmp command

c_pause_f:
call getkey
mov si,found
call strshift
jmp command

c_line_f:
call newline
mov si,found
call strshift
jmp command

c_space_f:
call space
mov si,found
call strshift
jmp command

c_help_mint:
mov si,main_list
call prnstr
call newline
mov si,editor_list
call prnstr
call newline
; mov si,setting_list
; call prnstr
; call newline
; mov si,setting2_list
; call prnstr
; call newline
; mov si,showsetting_list
; call prnstr
; call newline
; mov si,misc_list
; call prnstr
; call newline
; mov si,advanced_cmd
; call prnstr
; call newline
; mov si,common_control
; call prnstr
call newline
mov si,loc_command
call prnstr
; call newline
; mov si,experimental
; call prnstr
call newline
mov si,file_command
call prnstr
call newline
mov si,dir_command
call prnstr
; call newline
; mov si,interrupt_api
; call prnstr
; call newline
; mov si,interrupt2_api
; call prnstr
call newline
mov si,mint_list
call prnstr
call newline
mov si,all_command_str
call prnstr
mov cx,c_end-c_start
mov bx,c_start
call reload_words
mov si,found
call strshift
jmp command

c_install_f:

mov ax,ds
mov es,ax

mov ah,0x02
mov al,[.os_size]
mov bx,[loc]
mov cx,0x0001
mov dh,0x00
mov byte dl,[drive]
int 0x13
jnc .c_install_hwri
jmp .c_installend_f
.c_install_hwri:
; xor ax,ax
; mov es,ax
mov cx,0x0001
mov dh,00h
mov byte dl,[drive2]
mov bx,[loc]
mov ah,0x03
mov al,[.os_size]
int 13h
jc .c_installend_f
;xor ax,ax
;mov es,ax
;mov cx,0x0002
;mov dh,00h
;mov byte dl,[drive2]
;mov bx,1000h
;mov ax,0x030d
;int 13h
;jc c_installend_f
mov si,successstr
call prnstr
jmp kernel
.c_installend_f:
call print_error
jmp kernel
;mov si,found
;call strshift
;jmp command
; jmp kernel
.os_size:
;db 0x01
db 0x46

time:
mov ah,0x02	;Get CMOS time
int 0x1a	;through BIOS interrupt
mov al,ch	;Hours
call printh
call colon
mov al,cl	;Minutes
call printh
call colon
mov al,dh	;Seconds
call printh
ret

c_fhlt_f:
mov si,shutdownstr
call prnstr
.loop:
cli
hlt
jmp .loop

; c_jmp_f:
; mov word bx,[loc]
; jmp bx

c_reboot_f:
mov byte dl,[drive]
int 0x19
mov word [472h],1234h
jmp 0FFFFh:0
jmp kernel

c_restart_f:
in al,0x64
cmp al,0x02
je c_restart_f
mov al,0xfe
out 0x64,al
jmp kernel

c_page_f:
mov si,page
call change
mov byte al,[page]
mov ah,0x05
int 10h
jmp kernel

c_sound_f:
mov ax,0x0e07
int 0x10

mov si,[loc]
.loop:
lodsw
cmp ax,0
je .exitloop
call os_speaker_tone
call delay
call chkkey
jz .loop
.exitloop:
call os_speaker_off
jmp kernel
; ;Beep:     PROC USES AX BX CX
    ; IN AL, 61h  ;Save state
    ; PUSH AX 
    ; MOV BX, 6818; 1193180/175
    ; MOV AL, 6Bh  ; Select Channel 2, write LSB/BSB mode 3
    ; OUT 43h, AL 
    ; MOV AX, BX 
    ; ;OUT 24h, AL  ; Send the LSB
	; OUT 42h, AL  ; Send the LSB
    ; MOV AL, AH
    ; OUT 42h, AL  ; Send the MSB
    ; IN AL, 61h   ; Get the 8255 Port Contence
    ; OR AL, 3h
    ; OUT 61h, AL  ;End able speaker and use clock channel 2 for input
    ; MOV CX, 03h ; High order wait value
    ; MOV DX, 0D04h; Low order wait value
    ; MOV AX, 86h;Wait service
    ; INT 15h
    ; POP AX;restore Speaker state
    ; OUT 61h, AL
    ; ;RET
; jmp kernel

;call ProgramPIT
in al,0x61
mov ah,al
or al,3
cmp ah,al
je .done
out 0x61,al
.done:
;jmp kernel
;call PlayWAV
;call calculate_size
mov ah,0x80
mov al,[size]
int 0x1a
mov cx,0xffff
.sound_loop:
dec cx
mov al,0x1
out 0x61,al
cmp cx,0x0000
je .sound_loop
jmp kernel

; PC SPEAKER SOUND ROUTINES
; ==================================================================

; ------------------------------------------------------------------
; os_speaker_tone -- Generate PC speaker tone (call os_speaker_off to turn off)
; IN: AX = note frequency; OUT: Nothing (registers preserved)

os_speaker_tone:
	pusha

	mov cx, ax			; Store note value for now

	mov al, 182
	out 43h, al
	mov ax, cx			; Set up frequency
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; Switch PC speaker on
	or al, 03h
	out 61h, al

	popa
	ret


; ------------------------------------------------------------------
; os_speaker_off -- Turn off PC speaker
; IN/OUT: Nothing (registers preserved)

os_speaker_off:
	pusha

	in al, 61h
	and al, 0FCh
	out 61h, al

	popa
	ret

; ------------------------------------------------------------------
; os_speaker_freq -- Play a specified frequency throught the PC Speaker until os_speaker_off
; IN: AX = note frequency; OUT: Nothing (registers preserved)

os_speaker_freq:
	pusha
	
	mov bx, ax
	
	cmp ax, 20			; don't play if the input frequency is not too low (causing divide errors)
	jl .skip_sound
	
	mov dx, 18			; frequency of the PIT is 1,193,182 Hz, load into DX:AX
	mov ax, 13534	
	div bx				; divide by requested frequency to get the divisor
	mov bx, ax
	
	mov al, 182			; tell the PIT we're about to send a new divisor
	out 43h, al
	
	mov ax, bx			; send the divisor we got, low byte then high byte
	out 42h, al
	mov al, ah
	out 42h, al

	in al, 61h			; connect the PC speaker
	or al, 03h
	out 61h, al

.skip_sound:
	popa
	ret
	
c_rollcolor_f:
not byte [rollcolor]
jmp kernel

c_scrollmode_f:
not byte [scrollmode]
jmp kernel

c_slowmode_f:
not byte [slowmode]
jmp kernel

c_size_f:
call getno
mov [size],ax
jmp kernel

c_fsize_f:
call getno
mov [filesize],ax
mov word [filesize+2],0
jmp kernel

debug_int:
mov word [starting_reg.return_address],.debug_second
jmp starting_reg

.debug_second:
mov si,ips
call prnstr
call colon
pop bx
pop ax
push ax
push bx
mov [var_i],ax
call printwordh
call space

mov word [ending_reg.return_address],.debug_end
jmp ending_reg

.debug_end:
ret

debug:
mov word [starting_reg.return_address],.debug_second
jmp starting_reg

.debug_second:

mov si,ips
call prnstr
call colon
call .ip
.ip:
pop ax
mov [var_i],ax
call printwordh
call space

mov word [ending_reg.return_address],.debug_end
jmp ending_reg

.debug_end:
jmp kernel

starting_reg:
pusha

mov si,dis
call prnstr
call colon
pop ax
call printwordh
call space

mov si,sis
call prnstr
call colon
pop ax
call printwordh
call space

mov si,bps
call prnstr
call colon
pop ax
call printwordh
call space

mov si,sps
call prnstr
call colon
pop ax
;add ax,0x08
call printwordh
call space

mov si,bxs
call prnstr
call colon
pop ax
call printwordh
call space

mov si,dxs
call prnstr
call colon
pop ax
call printwordh
call space

mov si,cxs
call prnstr
call colon
pop ax
call printwordh
call space

mov si,axs
call prnstr
call colon
pop ax
mov [var_x],ax
mov [var_y],bx
call printwordh
call newline
jmp word [.return_address]
.return_address: dw 0

ending_reg:
mov si,flags
call prnstr
call colon
pushf
pop ax
call printwordh
call space

mov si,dss
call prnstr
call colon
mov ax,ds
call printwordh
call space

mov si,ess
call prnstr
call colon
mov ax,es
call printwordh
call space

mov si,sss
call prnstr
call colon
mov ax,ss
call printwordh
call space

mov si,css
call prnstr
call colon
mov ax,cs
call printwordh
;call space
mov ax,[var_x]
mov bx,[var_y]
jmp word [.return_address]
.return_address: dw 0

c_alias_f:
mov si,oldstr
call prnstr
mov si,commandstr
call prnstr
mov di,tempstr
call getstr
call newline

mov si,c_start
.findloop:
push si
mov di,tempstr
call cmpstr
pop si
jc .foundmatch
call strlen
;add si,ax
cmp si,c_end
jl .findloop
mov si,notfoundstr
call prnstr
jmp kernel

.foundmatch:
push si
mov di,si
;call strlen
mov cx,0xffff
mov al,0
repne scasb
repe scasb
sub di,si
dec di
push di
mov si,newstr
call prnstr
mov si,commandstr
call prnstr
mov di,tempstr2
call getstr
call newline
mov si,tempstr2
call strlen
pop bx
pop di
cmp bx,ax
jle .toobig
mov si,tempstr2
mov cx,ax
rep movsb
sub bx,ax
mov cx,bx
mov ax,0
rep stosb
mov si,successstr
call prnstr
jmp kernel
.toobig:
mov si,toobigstr
call prnstr
jmp kernel

c_border_f:
mov si,.min_x
call prnstr
mov si,border_str
call prnstr
call getno
mov [border_min_x],ax

call newline
mov si,.max_x
call prnstr
mov si,border_str
call prnstr
call getno
mov [border_max_x],ax

call newline
mov si,.min_y
call prnstr
mov si,border_str
call prnstr
call getno
mov [border_min_y],ax

call newline
mov si,.max_y
call prnstr
; mov si,border_str
; call prnstr
call getno
mov [border_max_y],ax
jmp kernel
.min_x:
db "Left",0
.max_x:
db "Right",0
.min_y:
db "Top",0
.max_y:
db "Bottom"
border_str:
db ' Border :',0
border_min_x:
dw 0
border_max_x:
dw 79
border_min_y:
dw 0
border_max_y:
dw 24

c_driveinfo_f:

;Find out drive CHS details
push es
mov dl,[drive]
mov di,ax
mov ah, 8
int 13h                       ; get drive parameters
pop es
mov [DRIVE_TYPE], bl
and cx, 3Fh                   ; maximum sector number
mov [SECTORS_PER_TRACK], cx
mov [NUMBER_OF_DRIVES], dl
movzx dx, dh                  ; maximum head number
add dx, 1
mov [NUMBER_OF_HEADS], dx

;Print drive type
; mov si,c_drive
; call prnstr
; call colon
; mov al,[drive]
; cmp al,0x00
; je di_imsgf
; cmp al,0x80
; je di_imsgh
; mov si,notfoundstr
; call prnstr
; jmp di_imsg_e
; di_imsgf:
; mov si,imsgf
; call prnstr
; jmp di_imsg_e
; di_imsgh:
; mov si,imsgh
; call prnstr
; ;jmp di_imsg_e
; di_imsg_e:
; mov al,[drive]
; call printh
; call colon
; mov al,[drive]
; call printnb
; call newline

;Print drive details
mov si,c_drive
call prnstr
call space
mov si,c_type
call prnstr
call colon
mov al,[DRIVE_TYPE]
call printh
call newline
mov si,numberof_str
call prnstr
mov si,c_drive
call prnstr
call colon
mov al,[NUMBER_OF_DRIVES]
call printh
call newline
mov si,drive_spt_str
call prnstr
mov al,[SECTORS_PER_TRACK]
call printwordh
call newline
mov si,numberof_str
call prnstr
mov si,c_head
call prnstr
call colon
mov al,[NUMBER_OF_HEADS]
call printwordh

;Print free memory
call newline
xor ax,ax
int 0x12
call printn
call space
mov ah,0x88
int 15h
call printn

;Calculate and print free space
call newline
mov si,freespacestr
call prnstr
call calculate_fat
mov dx,[dir_seg]
mov es,dx
mov word bx,[loc3]
call ReadSectors
call calculate_free_space
mov ax,[var_b]
call printwordh
mov al,'/'
call printf
;mov ax,9216
mov ax,[bpbTotalSectors]
call printwordh
call space
mov ax,[var_b]
mov bx,100
xor dx,dx
mul bx
;mov bx,9216
mov bx,[bpbTotalSectors]
div bx
call printn
mov al,'%'
call printf

;Print found device hardwares

call newline
mov si,foundstr
call prnstr
call colon
call space
int 0x11
bt ax,1
jnc .nomath
mov si,mathprocstr ;If math CPU is present
call os_print_string
call space
.nomath:

bt ax,2
jnc .nomouse
mov si,mousestr ;If mouse is present
call os_print_string
call space
.nomouse:

bt ax,12
jnc .nogame
mov si,gameportstr ; If gameport is present
call os_print_string
call space
.nogame:

;Print out BIOS Date
;call newline
;mov eax,0xe820
;int 15h
;call printn
;call newline
;mov eax,0xe801
;int 15h
;call printn

; call newline
; mov dx,0xf000
; mov es,dx
; mov si,0xfff5
; mov di,found
; mov cx,0x9
; ; call memcpy_far
; rep movsb
; mov dx,0x0
; mov es,dx
; mov si,.bios_date
; call prnstr
; mov si,found
; call prnstr

jmp kernel

; .bios_date:
; db "Bios Date:",0

change:
call getno
mov [si],al
ret

c_paint_f:
call os_graphics_mode
mov si,[loc]
call os_print_splash
call getkey
call os_text_mode
jmp kernel

; drawdot:
; mov ah,0x0c
; int 10h
; ret

; c_paint_f:
; mov ax,0x0013
; int 10h

; mov si,[loc]
; mov cx,0x0000
; mov dx,0x0000
; image_loop:
; lodsb
; push ax
; mov al,ah
; call drawdot
; pop ax
; call drawdot
; inc cx
; cmp cx,320
; jne image_loop
; mov cx,0x0000
; inc dx
; cmp dx,200
; jne image_loop
; mov word [player_x],20
; mov word [player_y],20
; mov word [player2_x],20
; mov word [player2_y],20
; mov word [comm],0x1914
; mov word [var_b],0x1914
; paint_draw:
; mov ch,0x00
; mov dh,0x00
; mov cl,[player_x]
; mov dl,[player_y]
; mov bh,[page]
; mov al,[color]
; call drawdot
; mov cl,[player2_x]
; mov dl,[player2_y]
; mov bh,[page]
; mov al,[color2]
; call drawdot

; call getkey
; paint_control:
; cmp ah,0x4b
; je paint_key_left
; cmp ah,0x4d
; je paint_key_right
; cmp ah,0x48
; je paint_key_up
; cmp ah,0x50
; je paint_key_down
; jmp paint2_control

; paint_key_left:
; mov cx,[player_x]
; mov dx,[player_y]
; dec cx
; dec word [comm]
; jmp paint_key_done
; paint_key_right:
; mov cx,[player_x]
; mov dx,[player_y]
; inc cx
; inc word [comm]
; jmp paint_key_done
; paint_key_up:
; mov cx,[player_x]
; mov dx,[player_y]
; dec dx
; sub word [comm],0x0140
; jmp paint_key_done
; paint_key_down:
; mov cx,[player_x]
; mov dx,[player_y]
; inc dx
; add word [comm],0x0140
; jmp paint_key_done

; paint_key_done:
; mov [player_x],cx
; mov [player_y],dx
; mov bx,[loc]
; add bx,[comm]
; mov al,[color]
; mov byte [bx],al
; jmp paint_draw

; paint2_control:
; cmp ah,0x11
; je paint_key_w
; cmp ah,0x1e
; je paint_key_a
; cmp ah,0x1f
; je paint_key_s
; cmp ah,0x20
; je paint_key_d
; jmp other_key

; paint_key_a:
; mov cx,[player2_x]
; mov dx,[player2_y]
; dec cx
; dec word [var_b]
; jmp paint2_key_done
; paint_key_d:
; mov cx,[player2_x]
; mov dx,[player2_y]
; inc cx
; inc word [var_b]
; jmp paint2_key_done
; paint_key_w:
; mov cx,[player2_x]
; mov dx,[player2_y]
; dec dx
; sub word [var_b],0x0140
; jmp paint2_key_done
; paint_key_s:
; mov cx,[player2_x]
; mov dx,[player2_y]
; inc dx
; add word [var_b],0x0140
; jmp paint2_key_done

; paint2_key_done:
; mov [player2_x],cx
; mov [player2_y],dx
; mov bx,[loc]
; add bx,[var_b]
; mov al,[color2]
; mov byte [bx],al
; jmp paint_draw

; other_key:
; cmp ah,0x3d
; je paint_copy
; cmp ah,0x52
; je paint_paste
; cmp ah,0x01
; je paint_exit
; cmp ah,0x29
; je paint_exit
; mov byte [color],ah
; mov byte [color2],al
; jmp paint_draw

; paint_copy:
; mov bx,[loc]
; add bx,[comm]
; mov si,bx
; jmp paint_draw

; paint_paste:
; mov bx,[loc]
; add bx,[comm]
; lodsb
; mov [bx],al
; mov [color],al
; inc word [comm]
; inc word [player_x]
; jmp paint_draw

; paint_exit:
; jmp kernel

; push ax
; call getpos
; push dx
; xor dx,dx
; call setpos
; pop dx
; pop ax
; push ax
; push dx
; call printh

; pop dx
; call setpos
; pop ax
; mov di,found
; .loop:
; cmp byte [di],0
; je .emptyspace
; inc di
; jmp .loop
; .emptyspace:
; mov [di],al

; play_kb:
; pusha
; in al, 0x60
; push ax

 ; call printh
 ; pop ax
 ; push ax

; cmp al,0x48
; je .up_press
; cmp al,0xC8
; je .up_rel
; cmp al,0x4B
; je .left_press
; cmp al,0xCB
; je .left_rel
; cmp al,0x4D
; je .right_press
; cmp al,0xCD
; je .right_rel
; cmp al,0x50
; je .down_press
; cmp al,0xD0
; je .down_rel
; cmp al,0xAA
; je .arrow_rel

; cmp al,0x11
; je .w_press
; cmp al,0x91
; je .w_rel
; cmp al,0x1f
; je .s_press
; cmp al,0x9f
; je .s_rel
; cmp al,0x12
; je .e_press
; cmp al,0x92
; je .e_rel

; cmp al,0x3c
; je .sw_press
; cmp al,0xbc
; je .sw_rel
; cmp al,0x3d
; je .sw_press
; cmp al,0xbd
; je .sw_rel

; cmp al,0x01
; je .exit_press
; cmp al,0x29
; je .exit_press
; .done:
; call AI_player_chance.keycheck
; pop ax

; mov al, 0x20
; out 0x20, al
; popa
; iret

; .up_press:
; mov byte [.upflag],0xf0
; jmp .done
; .up_rel:
; mov byte [.upflag],0x0f
; jmp .done
; .left_press:
; mov byte [.leftflag],0xf0
; jmp .done
; .left_rel:
; mov byte [.leftflag],0x0f
; jmp .done
; .right_press:
; mov byte [.rightflag],0xf0
; jmp .done
; .right_rel:
; mov byte [.rightflag],0x0f
; jmp .done
; .down_press:
; mov byte [.downflag],0xf0
; jmp .done
; .down_rel:
; mov byte [.downflag],0x0f
; jmp .done
; .arrow_rel:
; mov byte [.upflag],0x0f
; mov byte [.leftflag],0x0f
; mov byte [.rightflag],0x0f
; mov byte [.downflag],0x0f
; jmp .done

; .w_press:
; mov byte [.wflag],0xf0
; jmp .done
; .w_rel:
; mov byte [.wflag],0x0f
; jmp .done
; .s_press:
; mov byte [.sflag],0xf0
; jmp .done
; .s_rel:
; mov byte [.sflag],0x0f
; jmp .done
; .e_press:
; mov byte [.eflag],0xf0
; jmp .done
; .e_rel:
; mov byte [.eflag],0x0f
; jmp .done

; .sw_press:
; mov byte [.switchflag],0xf0
; jmp .done
; .sw_rel:
; mov byte [.switchflag],0x0f
; jmp .done

; .exit_press:
; mov byte [.exitflag],0xf0
; jmp .done

; .upflag db 0x0f
; .downflag db 0x0f
; .leftflag db 0x0f
; .rightflag db 0x0f
; .wflag db 0x0f
; .sflag db 0x0f
; .eflag db 0x0f
; .switchflag db 0x0f
; .exitflag db 0x0f

; c_play_f:
; cli
; mov word ax,[ds:(9*4)]
; mov word [filesize],ax
; mov word[ds:(9*4)],play_kb
; mov word ax,[ds:(9*4)+2]
; mov word [filesize+2],ax
; mov word[ds:(9*4)+2], 0
; sti

; mov byte [player_y],0x0c
; mov byte [player_x],0x00
; mov byte [player2_y],0x0c
; mov byte [player2_x],0x4f
; mov byte [ball_y],0x0c
; mov byte [ball_x],0x0c
; mov byte [down_flag],0xf0
; mov byte [right_flag],0xf0
; mov byte [AI_flag],0xf0
; mov word [var_a],0x0000
; mov word [extra],0x0000
; mov byte [play_kb.exitflag],0x0f
; mov byte al,[color]
; mov byte [color2],al
; call clean_screen
; xor dx,dx
; call setpos
; play_loop:
; ;call AI_player_chance.keycheck
; .keyreturn:
; call play2_draw
; call play_draw
; cmp byte [score],0xf0
; jne score_off
; call score_draw
; score_off:
; call ball_draw
; xor dx,dx
; call setpos_c
; cmp byte [slowmode],0xf0
; je play_slowmode_on
; call delay
; jmp play_delay_done
; play_slowmode_on:
; call slow
; play_delay_done:
; ;call clean_screen
; mov byte [color],0x00
; call ball_draw
; call play2_draw
; call play_draw
; mov byte al,[color2]
; mov byte [color],al
; call ball_update
; call setpos_c
; cmp byte [AI_flag],0xF0
; je AI_play_loop
; call AI_player_chance
; AI_play_loop:
; mov byte al,[play_chance_flag]

; cmp byte al,[difficulty]
; jle AI_player_chance.AI_on_link
; ;jg AI_player_chance
; call AI_player_chance
; jmp play_loop.keyreturn

; AI_player_chance:
; xor al,al
; mov byte [play_chance_flag],al
; xor dx,dx
; call setpos

; .keycheck:

; cmp byte [play_kb.exitflag],0xf0
; je play_exit
; cmp byte [play_kb.eflag],0xf0
; je .play_clear
; .play_clear_ret:
; cmp byte [play_kb.upflag],0xf0
; je .player1_up
; .player1_up_ret:
; cmp byte [play_kb.downflag],0xf0
; je .player1_down
; .player1_down_ret:
; ;cmp ah,0x3b
; ;je .play_help
; ;cmp ah,0x0f
; ;je .switch_AI
; cmp byte [play_kb.switchflag],0xf0
; je .switch_AI
; .switch_AI_ret:

; cmp byte [AI_flag],0xF0
; je .AI_on

; cmp byte [play_kb.wflag],0xf0
; je .player2_up
; .player2_up_ret:
; cmp byte [play_kb.sflag],0xf0
; je .player2_down
; .player2_down_ret:
; ;call getkeyflag
; ;and ax,0x0040
; ;or ax,0x0040
; ;je switch_AI
; ret

; .AI_on:
; jmp AI_play
; .AI_on_link:
; call .AI_on
; jmp play_loop.keyreturn

; .switch_AI:
; not byte [AI_flag]
; jmp .switch_AI_ret

; .player1_up:
; mov dh,[player_y]
; dec dh
; mov [player_y],dh
; jmp .player1_up_ret
; .player1_down:
; mov dh,[player_y]
; inc dh
; mov [player_y],dh
; jmp .player1_down_ret
; .player2_up:
; mov dh,[player2_y]
; dec dh
; mov [player2_y],dh
; jmp .player2_up_ret
; .player2_down:
; mov dh,[player2_y]
; inc dh
; mov [player2_y],dh
; jmp .player2_down_ret
; .play_clear:
; call clean_screen
; xor dx,dx
; call setpos
; jmp .play_clear_ret
; ;play_help:
; ;mov dx,play_helpstr
; ;xor ah,ah
; ;int 61h
; ;mov al,'e'
; ;mov ah,0x12
; ;call keybsto
; ;jmp play_loop

; AI_play:
; inc al
; mov byte [play_chance_flag],al
; mov dh,[player2_y]
; inc dh
; cmp byte [ball_y],dh
; jg AI_ball_ahead
; jl AI_ball_behind
; jmp AI_exit
; AI_ball_ahead:
; inc dh
; jmp AI_exit
; AI_ball_behind:
; dec dh
; jmp AI_exit

; AI_exit:
; dec dh
; mov byte [player2_y],dh
; ret

; play_exit:
; cli
; mov word ax,[filesize]
; mov word[ds:(9*4)],ax
; mov word ax,[filesize+2]
; mov word[ds:(9*4)+2],ax
; sti
; jmp kernel

; play_draw:
; mov cl,[length]
; mov dl,[player_x]
; mov dh,[player_y]
; play_draw_loop:
; call setpos_c
; mov al,0xdb
; call printf_c
; dec cl
; inc dh
; cmp dh,0x19
; jg play_loop_extra
; cmp dh,0x01
; jl play_loop_less
; cmp cl,0x00
; jg play_draw_loop
; jmp play_loop_exit
; play_loop_extra:
; mov dh,0x19
; sub dh,[length]
; mov [player_y],dh
; jmp play_loop
; play_loop_less:
; mov dh,0x00
; mov [player_y],dh
; jmp play_loop
; play_loop_exit:
; ret

; play2_draw:
; mov cl,[length]
; mov dl,[player2_x]
; mov dh,[player2_y]
; play2_draw_loop:
; call setpos_c
; mov al,0xdb
; call printf_c
; dec cl
; inc dh
; cmp dh,0x19
; jg play2_loop_extra
; cmp dh,0x01
; jl play2_loop_less
; cmp cl,0x00
; jg play2_draw_loop
; jmp play2_loop_exit
; play2_loop_extra:
; mov dh,0x19
; sub dh,[length]
; mov [player2_y],dh
; jmp play_loop
; play2_loop_less:
; mov dh,0x00
; mov [player2_y],dh
; jmp play_loop
; play2_loop_exit:
; ret

; ball_draw:
; mov dl,[ball_x]
; mov dh,[ball_y]
; inc dl
; call setpos_c
; mov al,0xdb
; call printf_b
; call printf_b
; mov dl,[ball_x]
; mov dh,[ball_y]
; inc dh
; call setpos_c
; mov al,0xdb
; call printf_b
; call printf_b
; call printf_b
; call printf_b

; mov dl,[ball_x]
; mov dh,[ball_y]
; add dh,2
; call setpos_c
; mov al,0xdb
; call printf_b
; call printf_b
; call printf_b
; call printf_b

; mov dl,[ball_x]
; mov dh,[ball_y]
; add dh,3
; inc dl
; call setpos_c
; mov al,0xdb
; call printf_b
; call printf_b
; ret

; ball_update:
; mov dl,[ball_x]
; mov dh,[ball_y]

; cmp byte [down_flag],0xf0
; jne ball_going_up
; inc dh
; jmp vertical_update_done
; ball_going_up:
; dec dh
; vertical_update_done:

; cmp byte [right_flag],0xf0
; jne ball_going_left
; inc dl
; jmp horizontal_update_done
; ball_going_left:
; dec dl
; horizontal_update_done:

; cmp dl,0x4b
; jg right_wall
; cmp dl,0x01
; jl left_wall
; cmp dh,0x15
; jg bottom_wall
; cmp dh,0x01
; jl top_wall

; jmp bounds_done
; left_wall:
; mov byte ah,[player_y]
; call play_check_collision
; jnc left_wall_fine
; inc word [extra]
; left_wall_fine:
; not byte [right_flag]
; jmp bounds_done
; right_wall:
; mov byte ah,[player2_y]
; call play_check_collision
; jnc right_wall_fine
; inc word [var_a]
; right_wall_fine:
; not byte [right_flag]
; jmp bounds_done
; bottom_wall:
; mov dh,0x15
; not byte [down_flag]
; jmp bounds_done
; top_wall:
; mov dh,0x00
; not byte [down_flag]
; ;jmp bounds_done
; bounds_done:
; mov byte [ball_x],dl
; mov byte [ball_y],dh
; ret

; score_draw:
; mov dx,0x1722
; call setpos
; mov word ax,[var_a]
; call printwordh
; call colon
; mov word ax,[extra]
; call printwordh
; ret

; play_check_collision:
; mov [var_m],dh
; add dh,3
; cmp dh,ah
; jge coll_end_fine
; jmp coll_detected
; coll_end_fine:
; sub dh,2
; add ah,[length]
; cmp dh,ah
; jle coll_start_fine
; jmp coll_detected
; coll_start_fine:
; mov dh,[var_m]
; clc
; ret
; coll_detected:
; mov dh,[var_m]
; stc
; ret

; Expression Calculator
c_calc_f:

;Initialization
mov eax,0
mov [.no1],eax
mov [.no2],eax
mov [.symbol],al
mov si,.enterstr ;Print prompt string
call prnstr
mov di,[locf2]
call getstr	; Receive expression string
mov si,[locf2]
.loop:
lodsb ;Next Character

;Check if input has ended
cmp al,0
je .end
cmp al,0x0D
je .end
cmp al,0x0A
je .end

;See if Operators are found
cmp al,'+'
je .sym
cmp al,'-'
je .sym
cmp al,'*'
je .sym
cmp al,'/'
je .sym
cmp al,'%'
je .sym

;Check if character is a number
cmp al,'0'
jge .num

;Ignore other characters
jmp .loop

;End Program
.end:
mov ah,0x0B
int 0x61
mov al,[.symbol]
call .endsym
mov edx,[.no2]
mov ah,0x27
int 0x61
jmp kernel ;Return

.endsym:
cmp al,'+'
je .add
cmp al,'-'
je .sub
cmp al,'*'
je .mul
cmp al,'/'
je .div
cmp al,'%'
je .rem
cmp al,0
je .empty
ret
.empty:
mov eax,[.no1]
mov [.no2],eax
ret

.sym:
push ax
mov al,[.symbol]
call .currentsym
pop ax
mov [.symbol],al
jmp .loop

.currentsym:
cmp al,'+'
je .add
cmp al,'-'
je .sub
cmp al,'*'
je .mul
cmp al,'/'
je .div
cmp al,'%'
je .rem
pop ax
pop ax
mov [.symbol],al
mov eax,[.no1]
add [.no2],eax
mov word [.no1],0
jmp .loop

.add:
mov eax,[.no1]
add [.no2],eax
mov word [.no1],0
ret
.sub:
mov eax,[.no1]
sub [.no2],eax
mov word [.no1],0
ret
.mul:
mov ecx,[.no1]
mov eax,[.no2]
xor edx,edx
mul ecx
mov [.no2],eax
mov word [.no1],0
ret
.div:
mov ecx,[.no1]
mov eax,[.no2]
xor edx,edx
div ecx
mov [.no2],eax
mov word [.no1],0
ret
.rem:
mov ecx,[.no1]
mov eax,[.no2]
xor edx,edx
div ecx
mov [.no2],edx
mov word [.no1],0
ret

.num:
cmp al,'9'
jg .loop
xor ecx,ecx
mov cl,al
sub cl,'0'
push ecx
mov eax,[.no1]
mov ebx,10
xor edx,edx
mul ebx
pop ecx
add eax,ecx
mov [.no1],eax
jmp .loop

.symbol:
db 0
.no1:
dd 0
.no2:
dd 0

.enterstr:
db 'Enter equation:',0

c_dtoh_f:
call getno
push ax
call colon
pop ax
call printdwordh_full
jmp kernel

delay:
xor ah,ah
int 1ah
mov [slow.temp],dl
delay_loop:
xor ah,ah
int 1ah
cmp [slow.temp],dl
je delay_loop
ret

slow:
mov ah,0x02
int 1ah
mov al,dh
mov byte [.temp],al
.slow_loop:
mov ah,0x02
int 0x1a
cmp byte dh,[.temp]
je .slow_loop
ret
.temp: db 0

colon:
pusha
mov al,':'
call printf
popa
ret

comma:
mov al,','
call printf
ret

os_print_space:
space:
pusha
mov al,' '
call printf
popa
ret

c_head_f:
mov si,head
call change
jmp kernel

c_track_f:
mov si,track
call change
jmp kernel

strshift:
inc si
mov al,[si]
dec si
mov [si],al
inc si
cmp al,0
jne strshift
ret

strshiftr:
pusha
call strlen
;add si,ax
inc ax
mov cx,ax
;dec si
mov di,si
push si
dec si
call memcpyr
pop si
inc si
mov byte [si],0
popa
ret

;IN: si-String
;OUT: ax-Length
strlen:
;pusha
;xor cx,cx
mov cx,0
.loop:
lodsb
inc cx
cmp al,0
jne .loop
;dec cx
mov ax,cx
;mov [.temp],cx
;popa
;mov ax,[.temp]
ret
;.temp: dw 0

os_seed_random:
	push bx
	push ax

	mov bx, 0
	mov al, 0x02			; Minute
	out 0x70, al
	in al, 0x71

	mov bl, al
	shl bx, 8
	mov al, 0			; Second
	out 0x70, al
	in al, 0x71
	mov bl, al

	mov word [os_random_seed], bx	; Seed will be something like 0x4435 (if it
					; were 44 minutes and 35 seconds after the hour)
	pop ax
	pop bx
	ret
; ------------------------------------------------------------------
; os_get_random -- Return a random integer between low and high (inclusive)
; IN: AX = low integer, BX = high integer
; OUT: CX = random integer

os_get_random:
	push dx
	push bx
	push ax

	sub bx, ax			; We want a number between 0 and (high-low)
	call .generate_random
	mov dx, bx
	add dx, 1
	mul dx
	mov cx, dx

	pop ax
	pop bx
	pop dx
	add cx, ax			; Add the low offset back
	ret


.generate_random:
	push dx
	push bx

	mov ax, [os_random_seed]
	mov dx, 0x7383			; The magic number (random.org)
	mul dx				; DX:AX = AX * DX
	mov [os_random_seed], ax

	pop bx
 	pop dx
	ret

; c_point_f:
; mov ax,0x0013
; int 10h
; mov word [comm],0
; mov si,[loc]
; point_loop:
; lodsb
; mov byte [player_x],al
; lodsb
; mov byte [player_y],al
; inc word [comm]
; xor ch,ch
; xor dh,dh
; mov cx,[player_x]
; mov dx,[player_y]
; mov byte al,[color]
; call drawdot
; cmp word [comm],512
; jl point_loop
; jmp kernel

; c_icon_f:
; mov ax,0x0013
; int 10h
; mov si,[loc]
; mov cx,100
; mov dx,50
; icon_loop:
; lodsb
; call drawdot
; inc cx
; cmp cx,132
; jl icon_loop
; mov cx,100
; inc dx
; cmp dx,66
; jl icon_loop
; jmp kernel

c_settime_f:
mov al,'H'
call printf
call colon
mov si,var_i
call change
call newline
mov al,'M'
call printf
call colon
mov si,var_j
call change
call newline
mov al,'S'
call printf
call colon
mov si,var_k
call change

mov ch,[var_i]
mov cl,[var_j]
mov dh,[var_k]
xor dl,dl
mov ah,0x03
int 0x1a
jmp kernel

c_setdate_f:
mov al,'C'
call printf
call colon
mov si,var_i
call change
call newline
mov al,'Y'
call printf
call colon
mov si,var_j
call change
call newline
mov al,'M'
call printf
call colon
mov si,var_k
call change
call newline
mov al,'D'
call printf
call colon
mov si,var_l
call change

;mov ch,[var_i]
mov ch,0x20
mov cl,[var_j]
mov dh,[var_k]
mov dl,[var_l]
mov ah,0x05
int 0x1a
jmp kernel

;************************************************;
; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
;************************************************;

ClusterLBA:
          sub     ax, 0x0002                          ; zero base cluster number
          xor     cx, cx
          mov     cl, BYTE [bpbSectorsPerCluster]     ; convert byte to word
          mul     cx
          add     ax, WORD [datasector]               ; base data sector
          ret

		  
;************************************************;
; Convert LBA to CHS
; AX=>LBA Address to convert
;
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;
;************************************************;

LBACHS:
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [bpbSectorsPerTrack]           ; calculate
          inc     dl                                  ; adjust for sector 0
          mov     BYTE [absoluteSector], dl
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [bpbHeadsPerCylinder]          ; calculate
          mov     BYTE [absoluteHead], dl
          mov     BYTE [absoluteTrack], al
          ret

;************************************************;
; Reads a series of sectors
; CX=>Number of sectors to read
; AX=>Starting sector
; ES:BX=>Buffer to read to
;************************************************;

ReadSectors:
; xor bp,bp
; mov es,bp
;call calculate_size
;mov cx,ax
;mov cx,[size]
push es
mov byte [.failflag],0x0f
     .Read_Sectors_MAIN:
          mov     di, 0x0005                          ; five retres for error
	.Read_Sectors_SECTORLOOP:
		  mov dx,0xFFFF
		  sub dx,[bpbBytesPerSector]
		  
		  cmp bx,dx
		  jb .skip_segmentchange
		  mov dx,es
		  add dx,0x0020
		  ;not bx
		  pusha
		  mov ax,dx
		  call printwordh
		  mov ax,bx
		  call printwordh
		  popa
		  sub bx,[bpbBytesPerSector]
		  ;mov es,dx;;TODO segment shift
		  ;mov cx,0
		  .skip_segmentchange:
		  
          push    ax
          push    bx
          push    cx
          call    LBACHS                              ; convert starting sector to CHS
cmp byte [.status],0xf0
jne .read
mov     ah, 0x03
jmp .set
.read:
mov     ah, 0x02
.set:
          ;mov     ah, 0x02                            ; BIOS read sector
          mov     ch, BYTE [absoluteTrack]            ; track
          mov     cl, BYTE [absoluteSector]           ; sector
          mov     dh, BYTE [absoluteHead]             ; head
;mov al,[size]
mov al,1
; pusha
; call printnb
; popa
		  ;mov     dl, BYTE [bsDriveNumber]            ; drive
mov byte dl,[drive]

; pusha
; push es
; push ds
; ;db 0xcc
; mov ax,bx
; call printwordh
; pop ds
; pop es
; popa
          int     0x13                                ; invoke BIOS
          jnc     .Read_Sectors_SUCCESS                ; test for read error
		  cmp byte [.failflag],0xf0
		  je .skip
		  call print_error
		  mov byte [.failflag],0xf0
		  .skip:
		  ;jmp .Read_Sectors_SUCCESS
          xor     ax, ax                              ; BIOS reset disk
          int     0x13                                ; invoke BIOS
          dec     di                                  ; decrement error counter
          pop     cx
          pop     bx
          pop     ax
          jnz     .Read_Sectors_SECTORLOOP             ; attempt to read again
          int     0x18
     .Read_Sectors_SUCCESS:
; cmp byte [command_tempchar],'i'
; je .callnodata
; cmp byte [command_tempchar],'c'
; je .callnodata

		  ; .callnodata:
		  ;ret
          pop     cx
          pop     bx
          pop     ax
          add     bx, WORD [bpbBytesPerSector]        ; queue next buffer
		  ;add     bx, 0x200        ; queue next buffer
; cmp bx,0xFC00
; jnb .fault_stop
		  inc     ax                                  ; queue next sector
          loop    .Read_Sectors_MAIN                   ; read next sector
		  .fault_stop:
		  ; mov     al, '.' ;;TODO better way to indicate progress
          ; call    printf
		  pop es
          ret
.failflag: db 0x0f
.status:
db 0x0f

fname:
mov di,ImageName
call getstr
call checkfname
jmp kernel

checkfname:
mov cx,0x000B
mov si,ImageName
.loop:
lodsb

cmp al,0x00
je .zero
;cmp al,0x7A
cmp al,'z'
jg .done
;cmp al,0x60
;jg .small
cmp al,'a'
jge .small
;cmp al,0x2E
cmp al,'.'
je .dot
;dec cx
.done:
loop .loop
;cmp cx,0x0000
;jg .loop
ret
.small:
;inc cx
;sub al,0x20
sub al,'a'-'A'
dec si
mov [si],al
;inc si
jmp .loop
.zero:
inc cx
dec si
mov di,si
.zeroloop:
mov al,0x20
stosb
dec cx
cmp cx,0
jg .zeroloop
ret
.dot:
cmp byte [si],'.'
je .doubledot
;add si,3
;mov [si],0
;sub si,3
dec si
push si
call strshift
pop si
push si
;mov byte [si],0x20
;inc si
mov di,ImageName
add di,0x000A
add si,2

mov al,[si]
mov byte [si],0x20
mov [di],al
dec di
dec si

mov al,[si]
mov byte [si],0x20
mov [di],al
dec di
dec si

mov al,[si]
mov byte [si],0x20
mov [di],al
pop si
mov al,0x20
.dotloop:
cmp si,di
jge .dotdone
mov [si],al
inc si
jmp .dotloop
.dotdone:
jmp checkfname
.doubledot:
mov di,si
;dec di
inc di
mov si,ImageName
add si,0x000B
mov al,0x20
.doubledotloop:
stosb
cmp di,si
jl .doubledotloop
ret

;Sets dx to 0x0f0f if carry
;Else dx to 0xf0f0
check_carry:
jc .failed
mov dx,0xf0f0
ret
.failed:
mov dx,0x0f0f
ret

save_filedata:
pusha
mov si,di
add si,0x000B
mov al,[es:si]
mov [var_x],al
add si,0x0011
;lodsw
mov ax,[es:si]
add si,2
mov [filesize],ax
;lodsw
mov ax,[es:si]
add si,2
mov [filesize+2],ax
popa
ret

;
;Commands :
;q=quickload
;a=cmpload
;l=file selector
;r=roam selector
;e=file exists
;c=call
;t=roam selector interrupt
;
fdir:
mov word [comm2],'q'
call store_HTS
;mov [var_n],sp
cmp byte [command_tempchar],'t'
je .fdir_interrupt
;cmp byte [command_tempchar],'c'
;je .fdir_interrupt
jmp .fdir_not_interrupt
;mov di,ImageName
;mov bx,di
.fdir_interrupt:
mov ax,[loc]
mov [var_a],ax
mov [loc],di
.fdir_not_interrupt:
; mov word ax,[size]
mov ax,[filesize]
mov [var_y],ax
.fdir_next:
call LOAD_ROOT
jmp fileload

calculate_root:
     
          xor     cx, cx
          xor     dx, dx
          mov     ax, 0x0020                           ; 32 byte directory entry
          mul     WORD [bpbRootEntries]                ; total size of directory
          div     WORD [bpbBytesPerSector]             ; sectors used by directory
          xchg    ax, cx
          
mov     al, BYTE [bpbNumberOfFATs]            ; number of FATs
mul     WORD [bpbSectorsPerFAT]               ; sectors used by FATs
add     ax, WORD [bpbReservedSectors]         ; adjust for bootsector
;mov ax,[currentdir]
mov     WORD [datasector], ax                 ; base of root directory
add     WORD [datasector], cx

cmp byte [advanced_flag],0x0f
je .skip_details
pusha
push ax
; cmp byte [command_tempchar],'i'
; je .callnodata
; cmp byte [command_tempchar],'c'
; je .callnodata

mov si,c_dir
call prnstr
call colon
pop ax
call printwordh
call space
; mov si,c_size
; call prnstr
; call colon
; pop ax
; call printwordh
;call space
popa
.skip_details:
mov ax,[currentdir]
ret

SAVE_ROOT:
mov byte [ReadSectors.status],0xf0
call LOAD_ROOT
mov byte [ReadSectors.status],0x0f
ret

LOAD_ROOT:
call calculate_root
mov dx,[dir_seg]
mov es,dx
mov word bx,[loc2]
;call calculate_size
;mov dx,ax
cmp word [currentdir],0x0013
jne .infolder
call    ReadSectors
mov dx,0
mov es,dx
ret
.infolder:
mov word [size],1
;mov     dx, WORD [di + 0x001A]
          ;mov     WORD [cluster], dx          
		  call calculate_fat
          mov word bx,[loc3]
          call ReadSectors
		  
		  mov word bx,[loc2]                          ; destination for image
		  push bx
		  call calculate_root
		  ;call newline
;call ReadSectors
;mov word ax,[currentdir]
sub     ax, WORD [datasector]               ; base data sector
xor dx,dx
         xor cx, cx
          mov cl, BYTE [bpbSectorsPerCluster]     ; convert byte to word
          div cx
		  add ax, 0x0002                          ; zero base cluster number

mov word [cluster],ax
mov word [var_i],ax
;mov word [xmouse],0
;jmp .skip
		  .loop:
          mov     ax, WORD [cluster]                  ; cluster to read
          pop     bx                                  ; buffer to read into
          call    ClusterLBA                          ; convert cluster to LBA
call print_HTS_details
          xor     cx, cx
          mov     cl, BYTE [bpbSectorsPerCluster]     ; sectors to read
          call    ReadSectors
		  ;inc word [xmouse]
          push    bx
          ;call calculate_next_cluster
		  ; compute next cluster

          mov si,.DONE
		  mov di,.DONE
		  mov     ax, WORD [cluster]                  ; cluster to read
		  jmp get_cluster_data
          
     .DONE:
	  mov     WORD [cluster], dx
		  ;cmp word [xmouse],4
		  ;jg .close
		  cmp     dx, 0x0FF0                          ; test for end of file
          jb .loop
.close:
pop bx
mov word [es:bx],0
mov word ax,[var_i]
mov word [cluster],ax
mov dx,[kernel_seg]
mov es,dx
ret

print_HTS_details:
cmp byte [advanced_flag],0x0f
je .done
.direct:
pusha

call newline
call space
mov al,'C'
call printf
call colon
mov ax,[cluster]
call printwordh
call space
mov si,c_loc
call prnstr
call colon
mov ax,[datasector]
add ax,[cluster]
sub ax,2
call printwordh
call space

mov al,'H'
call printf
mov al,'='
call printf
mov byte al,[absoluteHead]
call printh
call colon
mov al,'T'
call printf
mov al,'='
call printf
mov byte al,[absoluteTrack]
call printh
call colon
mov al,'S'
call printf
mov al,'='
call printf
mov byte al,[absoluteSector]
call printh

call space
mov si,c_size
call prnstr
call colon
mov ax,[filesize+2]
call printwordh
mov ax,[filesize]
call printwordh
call colon
call calculate_size
call printn

popa
.done:
ret

fileload:
          mov     cx, WORD [bpbRootEntries]
		  mov ax,[dir_seg]
		  mov es,ax
          mov di, [loc2]
cmp byte [command_tempchar],'l'
je .makelist
cmp byte [command_tempchar],'r'
je .makelist_clear
		  
		  ;mov si,filestr
		  ;call memcpyza
     .LOOP:
	      ;push    cx
          mov     si, ImageName
		  ;mov ax,[di]
		  ;cmp ax,0x0000
		  cmp word [es:di],0
		  je .exit_loop
          push    di
		  ;push cx

		  call save_filedata

; pusha
; mov bh,0xf4
; mov bl,[found]
; mov eax,0x0b8640
; mov [ds:eax],bx
; popa

; cmp byte [command_tempchar],'i'
; je .intnonameload
cmp byte [command_tempchar],'c'
je .intnonameload
cmp byte [command_tempchar],'e'
je .intnonameload
;call newline
;pop cx
;mov     cx, 0x000B
call show_name
.intnonameload:

; .create_list:
; ;list of files
; pusha
; push es
; ;push ds
; mov ax,[kernel_seg]
; mov es,ax
; ;mov ds,ax
; mov si,di
; mov di,[.list_pos]
; mov cx,0x0003
; rep movsb
; mov [.list_pos],di
; mov byte [di-1],','
; ;pop ds
; pop es
; popa

mov si,ImageName
mov cx, 0x000B
repe  cmpsb
pop di
je LOAD_FAT
;je DONE
cmp byte [command_tempchar],'q';Quick
je .intload
; cmp byte [command_tempchar],'i';Interrupt
; je .intload
cmp byte [command_tempchar],'c';Call
je .intload
cmp byte [command_tempchar],'e';Exists
je .intload
call getkey
cmp al,0x0D
je LOAD_FAT
cmp al,0x20
je LOAD_FAT
cmp ah,0x4b
je .back
cmp ah,0x48
je .back
cmp ah,0x01
je .exitloop
.intload:
          ;pop     cx
          add     di, 0x0020
		  loop .LOOP
          ;cmp cx,0
		  ;jg .LOOP
.exit_loop:
cmp byte [command_tempchar],'e'
je no_file_exists
jmp FAILURE
.back:
sub di,0x0020
mov ax,0x0702
call clear_bios_function
jmp .LOOP
.exitloop:
;mov byte [kernelreturnflag],0x0f
stc
jmp FAILURE
.makelist_clear:
call clear_screen
.makelist:
;mov word [.list_pos],found+20

;push ds
;mov di,[.list_pos]

;Recieve the file list
mov ax,0xF000;[temploc]
call os_get_file_list

;mov cx,0x200
;mov bx,found+20
;call reload_words
;jmp FAILURE

;call clear_screen
mov ax,0xF000;[temploc]
mov bx,verstring
mov cx,file_selector_str
call os_list_dialog ; Show the list selector
jc .FAILURE
dec ax
imul ax,0x20
mov word di,[loc2]
add di,ax ; Get di pointing to file data

mov dx,[dir_seg];Directory Segment
mov es,dx
mov dx,[kernel_seg]
mov ds,dx
call save_filedata

mov dl,[border_min_x]
mov dh,[border_max_y]
dec dh
call setpos
jmp LOAD_FAT

.FAILURE:
mov dl,[border_min_x]
mov dh,[border_max_y]
dec dh
call setpos
jmp FAILURE

.list_pos:
dw 0

fileselected:
mov dx,[kernel_seg]
mov es,dx
pusha
mov al,[var_x]
and al,0x10
cmp al,0x10
je .dir
jmp .done
.dir:
mov ax,[datasector]
add ax,[cluster]
sub ax,2
cmp word [cluster],0
jne .dir_child
sub ax,0x0C
.dir_child:
mov [currentdir],ax
popa
;mov sp,[var_n]
jmp fdir.fdir_next
.done:
popa
;mov sp,[var_n]
mov dx,[dir_seg]
mov es,dx
mov di,[FileSystem_DONE.selected_file]
;mov si,di
mov si,ImageName
mov cx,0x000C
.loop:
mov al,[es:di]
inc di
mov [ds:si],al
inc si
loop .loop
mov dx,0
mov es,dx
mov ax,ImageName
call os_string_uppercase
mov bx,ImageName
;pop bx
mov byte [bx+11],0
; pusha
; mov dx,ax
; xor ah,ah
; int 0x61
; popa
mov dx,[data_seg]
mov es,dx
clc
ret
fileselected_fail:
stc
mov dx,0x0f0f
mov bx,0
ret

restore_fdirdata:
mov dx,[data_seg]
mov es,dx
mov ax,[cluster]
call ClusterLBA
call LBACHS
ret

file_exists:
;mov sp,[var_n]
call restore_fdirdata
popa
clc
ret
no_file_exists:
;mov sp,[var_n]
mov dx,[os_file_exists.temp_filesize]
mov [filesize],dx
call restore_fdirdata
popa
stc
ret

     LOAD_FAT:
	 mov [FileSystem_DONE.selected_file],di
	 pusha
	 mov si,tempstr
	 add di,8
	 mov cx,0x0003
	 call memstr_copy
	 popa
	 ;push ds
	 ;pop es
; cmp byte [command_tempchar],'i'
; je .noname
; cmp byte [command_tempchar],'c'
; je .noname
	 ;call newline
	 ; .noname:
          mov     dx, WORD [es:di + 0x001A]
          mov     WORD [cluster], dx          
     call calculate_fat
mov dx,[dir_seg]
mov es,dx
mov bx,[loc3]
call ReadSectors
		  ; xor ax,ax
          ; mov es, ax                              ; destination for image
mov al,[var_y]
mov [var_i],al
; cmp byte [autosize_flag],0xf0
; jne .skip
; mov al,[var_x]
; and al,0x10
; cmp al,0x10
; je .skip
; pusha
;call calculate_size
; mov ax,[size]
; mov [var_i],ax
; cmp al,25
; jg .too_big
; mov word [size],ax
; jmp .done
; .too_big:
; mov byte al,[var_y]
; mov byte [size],al
;.done:
; popa

cmp byte [command_tempchar],'l'
je fileselected
cmp byte [command_tempchar],'e'
je file_exists
     ;----------------------------------------------------
     ; Load Stage 2
     ;----------------------------------------------------
cmp byte [completeload_flag],0x0f
je .complete_load_off
cmp byte [command_tempchar],'a'
jne .complete_load_off
		  mov word [size],1
		  .complete_load_off:
mov dx,[kernel_seg]
mov es,dx
mov ax,[cluster]
mov [var_i],ax
mov bx,[loc]                          ; destination for image
call LoadImage
jmp FileSystem_DONE

;IN:AX=cluster BX=location
LoadImage:
mov [cluster],ax
mov [.buffer_location],bx
mov dx,[data_seg]
mov [.temp_dataseg],dx

.LOAD_IMAGE_loop:
          mov     ax, WORD [cluster]                  ; cluster to read
		  ; pop     bx                                  ; buffer to read into
		  mov bx,[.buffer_location]
          call    ClusterLBA                          ; convert cluster to LBA
          xor     cx, cx
          mov     cl, BYTE [bpbSectorsPerCluster]     ; sectors to read
		  ; pusha
		  ; call newline
		  ; mov si,filestr
		  ; call prnstr
		  ; cmp byte [found],'c'
; jne .dontstop
; call getkey
; .dontstop:
		  ; popa
		  ;mov cx,[size]
mov dx,[.temp_dataseg]
;mov dx,0
mov es,dx
call    ReadSectors
mov [.buffer_location],bx
mov [.temp_dataseg],es
mov dx,[dir_seg]
; mov dx,0
mov es,dx
          ;call calculate_next_cluster
		  ; compute next cluster
     ;.loop:
          mov     ax, WORD [cluster]                  ; identify current cluster
		  ;cmp word [xmouse],0
		  ;je .skip
		  ;mov ax, WORD [xmouse]
		  ;.skip:
		  ;mov [var_b]
          
		  mov si,.DONE
		  mov di,.DONE
		  jmp get_cluster_data
          
     .DONE:
mov bx,[kernel_seg]
mov es,bx

		;debug
		cmp byte [advanced_flag],0xF0
		jne .skip_details
		  pusha
		  mov ax,[cluster]
		  call printwordh
		  popa
		  pusha
		  mov ax,dx
		  call printwordh
		  call space
		  popa
		  .skip_details:

cmp byte [completeload_flag],0xf0
je .complete_load_on
cmp byte [command_tempchar],'a'
jne .complete_load_off
.complete_load_on:
		  ;mov     WORD [xmouse], dx                  ; store new cluster
		  cmp WORD [cluster], dx
		  je .complete_load_off
		  cmp WORD [cluster],0
		  je .complete_load_off
		  ; push bx
		  ; pop bx
		  ; cmp bx,0xF500
		  ; jg .complete_load_off
		  cmp dx,0
		  je .complete_load_off
; mov al,[var_x]
; and al,0x10
; cmp al,0x10
; je complete_load_off
		  mov     WORD [cluster], dx
          cmp     dx, 0x0FF0                          ; test for end of file
		  jb .LOAD_IMAGE_loop
		  .complete_load_off:
		  ;mov word [xmouse],0
mov word ax,[var_i]
mov word [cluster],ax

mov ax,0
mov es,ax

ret
.temp_dataseg: dw 0x0000
.buffer_location: dw 0x6000

FileSystem_DONE:
;mov sp,[var_n]

;mov ax,[var_y]
;call calculate_size
;mov [size],ax
;mov [filesize],ax

;pop sp
mov bx,[loc]
add bx,[filesize]
mov ax,[var_e]
cmp ax,bx
ja .skip_return_close
mov byte [kernelreturnflag],0x0f
.skip_return_close:
clc
mov word [comm],0xf0f0
;mov dx,[comm]
cmp byte [command_tempchar],'c'
je callloaddone
; cmp byte [command_tempchar],'i'
; je intloaddone
mov si,successstr
call prnstr
call print_HTS_details

mov byte [comm2],'f'
cmp byte [command_tempchar],'r'
je .roam_on
cmp byte [command_tempchar],'t'
je .roamt_on

; cmp byte [command_tempchar],'z'
; je .dont_roam
; cmp byte [command_tempchar],'l'
; je .dont_roam

jmp .dont_roam
.roamt_on:
mov al,[var_x]
and al,0x10
cmp al,0x10
je .dont_roam
mov byte [comm2],'t'
jmp .dont_roam
.roam_on:
mov byte [comm2],'r'
; jmp .dont_roam
.dont_roam:

call newline
call filetype
call prnstr
;call file_ext_check

mov al,[var_x]
and al,0x10
cmp al,0x10
je .dir
jmp .done
.dir:
mov ax,[datasector]
add ax,[cluster]
sub ax,2
cmp word [cluster],0
jne .dir_child
sub ax,0x0C
.dir_child:
mov [currentdir],ax
cmp byte [comm2],'r'
je .dir_roam
cmp byte [comm2],'t'
je .dir_roam
jmp .done
.dir_roam:
mov al,[comm2]
mov [command_tempchar],al
jmp fdir.fdir_not_interrupt
.done:
cmp byte [comm2],'t'
je .roam_done
cmp byte [comm2],'r'
je .roam_fileselected
jmp kernel
.roam_done:
clc
mov bx,[extra]
mov ax,[loc]
mov dx,[var_a]
mov [loc],dx
jmp bx

.roam_fileselected:
mov di,[FileSystem_DONE.selected_file]
mov si,found
mov cx,0x0B
call memstr_copy

; mov si,found
; call os_string_parse
; mov si,ax
; mov di,tempstr
; call memcpy
; mov byte [di-1],'.'
; mov si,bx
; call memcpy

;Change file name to
; name.extension
;format
mov si,found
mov al,0x20
call os_string_tokenize
push di
mov di,tempstr
call memcpy ; Copy file name
mov byte [di-1],'.' ; Add dot in the end
pop si
mov al,' ' ; Remove extra spaces
call os_string_strip
call memcpy ; Add extension

;mov si,tempstr
;call os_print_string

mov si,tempstr
mov di,found
call memcpy

;mov si,tempstr
;call prnstr
; mov si,tempstr
; call pipespace2enter
; mov si,tempstr
; call pipestore
call newline
call microkernel
jmp kernel

.selected_file:
dw 0

FAILURE:
call restore_HTS
mov ax,[data_seg]
mov es,ax
;mov sp,[var_n]
mov ax,[var_y]
;mov [size],ax
mov [filesize],ax
stc
mov word [comm],0x0f0f
cmp byte [command_tempchar],'l'
je fileselected_fail
; cmp byte [command_tempchar],'e'
; je no_file_exists
; cmp byte [command_tempchar],'i'
; je intloaddone
cmp byte [command_tempchar],'c'
je callloaddone
call newline
call print_error
cmp byte [comm2],'t'
je .roam_done
jmp kernel
.roam_done:
clc
mov bx,[extra]
mov ax,[loc]
mov dx,[var_a]
mov [loc],dx
jmp bx

; intloaddone:
; mov ax,[loc]
; mov dx,[var_a]
; mov [loc],dx
; mov dx,[comm]
; clc
; iret

callloaddone:
;call newline
;mov ax,[loc]
;mov dx,[var_a]
;mov [loc],dx
mov bx,[extra]
;sub bx,0x0500
mov dx,[comm]
jmp bx
;jmp microkernel_ret

memstr_copy:
	 push si
	 push di
	 push es
	 push ds
	 mov dx,[kernel_seg]
	 mov es,dx
	 mov dx,[dir_seg]
	 mov ds,dx
	 xchg si,di
	 ;add si,8
	 ;mov di,tempstr
	 rep movsb
	 mov byte [es:di],0
	 pop ds
	 pop es
	 pop di
	 pop si
ret

; Returns size of a file in sectors
; AX=size
calculate_size:
pusha
mov dx,[filesize+2]
mov ax,[filesize]
; xchg ax,dx
mov cx,[bpbBytesPerSector]
cmp dx,0x1fff
jge .skip
cmp dx,0
jne .start
cmp ax,0
je .skip
.start:
;div cx
call division
.skip:
cmp dx,0
je .perfectsector
inc ax
.perfectsector:
mov [.temp],ax
popa
mov ax,[.temp]
ret
.temp: dw 0

;Divides dx*16+ax by cx
; OUT: dx=remainder, ax=quotient
division:
imul dx,512
add dx,ax
mov ax,0
cmp dx,cx
jg .loop
mov dx,0
jmp .small
.loop:
sub dx,cx
.small:
inc ax
cmp dx,cx
jge .loop
.quit:
ret

; Allocate a empty cluster to used
;IN/OUT: Nothing
find_next_free_cluster:

;Initialization
mov word [.starting_cluster],0
mov word [.previous_cluster],0
call calculate_size
mov [.cluster_loop],ax

mov ax,3 ;FAT allocation starts after second cluster
mov [cluster],ax
mov dx,[dir_seg] ;Set correct segment
mov es,dx

;Mainloop for finding free clusters
.loop:
mov ax,[cluster]
mov si,.check_even
mov di,.check_odd
jmp get_cluster_data ;Get cluster value
	.check_even:
	;mov dx,ax
	;and dx,0x0FFF
	cmp dx,0
	je .set_even ;if empty then allocate
	jmp .check_next

	.check_odd:
	;mov dx,ax
	;shr dx,4
	cmp dx,0
	je .set_odd ;if empty then allocate

	.check_next: ;Else check next cluster
	inc word [cluster]
	jmp .loop

;Set empty cluster
.set_even:
or dx,0x0FFF
jmp .cluster_set_done
.set_odd:
or dx,0xFFF0
.cluster_set_done:
cmp word [.cluster_loop],1
ja .set_previous_cluster_start
;If on the last cluster set to complete
mov word [es:bx],dx ;Set value to current cluster
;cmp cx,1
;jmp .ending_cluster

.set_previous_cluster_start:
mov ax,[.previous_cluster]
cmp ax,0
je .skip_previous_cluster_allocation
mov si,.set_previous_even_cluster
mov di,.set_previous_odd_cluster
jmp get_cluster_data ;Get cluster value
.set_previous_even_cluster:
mov dx,[cluster]
and dx,0x0FFF
jmp .set_previous_cluster
.set_previous_odd_cluster:
mov dx,[cluster]
shl dx,4
.set_previous_cluster:

or [es:bx],dx ;Set previous cluster for current value
.skip_previous_cluster_allocation:
mov dx,[cluster]
mov [.previous_cluster],dx ;Set current as the next to be set

.ending_cluster:

cmp word [.starting_cluster],0
jne .starting_set
mov dx,[cluster]
mov [.starting_cluster],dx
.starting_set:

inc word [cluster]
dec word [.cluster_loop]
cmp word [.cluster_loop],0
ja .loop

mov dx,[kernel_seg] ;Reset the segment
mov es,dx
mov dx,[.starting_cluster]
mov [cluster],dx
ret
.starting_cluster:
dw 0
.previous_cluster:
dw 0
.cluster_loop:
dw 0

calculate_free_space:
mov ax,2
mov [cluster],ax
xor ax,ax
mov [var_b],ax
mov dx,[dir_seg]
mov es,dx
.loop:
mov ax,[cluster]
          mov si,.compare
		  mov di,.compare
		  jmp get_cluster_data
	 .compare:
	 cmp dx,0
	 jne .not_free
	 inc word [var_b]
	 .not_free:
	 inc word [cluster]
	 ;cmp word [cluster],9216
	 mov dx,[bpbTotalSectors]
	 cmp word [cluster],dx
	 jge .done
	 jmp .loop
.done:
mov dx,0
mov es,dx
ret

; Delete a cluster chain starting at the given cluster
; IN: AX = First cluster in chain to delete
delete_cluster:
	pusha
	mov [.current], ax         ; Save start cluster

.delete_loop:
	mov ax, [.current]         ; Get current cluster
	cmp ax, 0x0002            ; Check if valid cluster
	jb .done
	cmp ax, 0xFF0             ; Check if end of chain
	jae .done

	call get_cluster_data      ; Get next cluster in chain
	jc .error                 ; Handle invalid clusters
	mov [.next], dx           ; Save next cluster
	
	; Clear current cluster entry
	mov ax, [.current]        ; Calculate FAT entry position
	mov cx, ax
	mov dx, ax
	shr dx, 1                ; Divide by 2 for FAT12 entry
	add cx, dx               ; Total offset = cluster + (cluster/2)
	
	mov bx, [loc3]           ; Get FAT base
	add bx, cx               ; Point to FAT entry
	
	mov dx, word [es:bx]     ; Get full FAT entry
	test ax, 1               ; Check if odd/even
	jz .clear_even

.clear_odd:
	and dx, 0x000F           ; Keep low 4 bits (part of next entry)
	jmp .write_entry

.clear_even:
	and dx, 0xF000           ; Keep high 4 bits (part of prev entry)

.write_entry:
	mov word [es:bx], dx     ; Write back cleared entry
	
	mov ax, [.next]          ; Move to next cluster
	mov [.current], ax
	cmp ax, 0xFF8            ; Check if end of chain
	jb .delete_loop

.done:
	popa
	clc                      ; Clear carry - success
	ret

.error:
	popa 
	stc                      ; Set carry - error
	ret

.current:    dw 0           ; Current cluster being processed
.next:       dw 0           ; Next cluster in chain

;IN: ax-Cluster number to check
;OUT: dx-Next cluster number in chain, CF set on error
get_cluster_data:
    cmp ax, 0x0002              ; First valid cluster is 2
    jb .error
    ; cmp ax, [diskinfo.last_cluster] ; Check against max cluster
    ; ja .error

    push cx                     ; Save registers
    push bx

    mov cx, ax                  ; Calculate FAT offset
    mov dx, ax                  ; Copy cluster number
    shr dx, 1                  ; Divide by 2 (each FAT entry is 12 bits)
    add cx, dx                 ; Total offset = cluster + (cluster/2)
    
    mov word bx, [loc3]        ; Get FAT base address
    add bx, cx                 ; Add offset to get FAT entry
    mov dx, word [es:bx]       ; Get FAT entry (16 bits)
    
    test ax, 1                 ; Check if cluster number is odd/even
    jz .even_cluster

.odd_cluster:
    shr dx, 4                  ; For odd clusters, use upper 12 bits
    jmp .validate

.even_cluster:
    and dx, 0x0FFF             ; For even clusters, use lower 12 bits

.validate:
    cmp dx, 0x0FF7             ; Check for bad cluster
    je .error
    cmp dx, 0x0FF8             ; Check for end of chain
    jae .end_of_chain
    
    pop bx                     ; Restore registers
    pop cx
    clc                        ; Clear carry - valid cluster
    ret

.error:
    pop bx                     ; Restore registers
    pop cx
    mov dx, 0                  ; Return 0 for error
    stc                        ; Set carry to indicate error
    ret

.end_of_chain:
    pop bx                     ; Restore registers
    pop cx
    mov dx, 0xFFF             ; Return end-of-chain marker
    clc                        ; Clear carry - valid end marker
    ret

calculate_fat:

	 ; compute size of FAT and store in "cx"

          xor     ax, ax
          mov     al, BYTE [bpbNumberOfFATs]          ; number of FATs
          mul     WORD [bpbSectorsPerFAT]             ; sectors used by FATs
          mov     cx, ax

     ; compute location of FAT and store in "ax"

          mov     ax, WORD [bpbReservedSectors]       ; adjust for bootsector
		  ret

; SAVE_ROOT:
; call calculate_root
; cmp word [currentdir],0x0013
; je .inroot
; sub     ax, WORD [datasector]               ; base data sector
; xor dx,dx
; xor cx, cx
; mov cl, BYTE [bpbSectorsPerCluster]     ; convert byte to word
; div cx
; add ax, 0x0002                          ; zero base cluster number
; mov word [cluster],ax
; call    ClusterLBA
; .inroot:
; inc ax
; xchg ax,cx
; mov word bx,[loc2]
; call save_c
; ret

save_c:
pusha
;mov dx,ds
;xor dx,dx
;mov es,dx
mov byte ah,0x03
mov byte ch,0x00
;mov byte cl,[sector]
;mov byte al,[size]
mov byte dh,0x00
mov byte dl,[drive]
;mov word bx,[loc]
int 0x13
popa
ret

SAVE_FAT:
mov word bx,[loc3]
mov dx,[dir_seg]
mov es,dx
call save_c
ret

; Direct save method
; filesave_c:
; pusha
; ;mov dx,ds
; ;xor bx,bx
; ;mov es,dx
; call calculate_size
; ;mov al,[size]
; mov byte ah,0x03
; mov byte ch,[absoluteTrack]
; mov byte cl,[absoluteSector]
; mov byte dh,[absoluteHead]
; mov byte dl,[drive]
; int 0x13
; jc .error
; jmp .done
; .error:
; call print_error
; ; pusha
; ; db 0xcc
; ; call getkey
; ; popa
; .done:
; popa
; ret

; One sectors save method
;IN: bx = location of save file
filesave_c:
pusha
mov ax,[cluster]
mov byte [ReadSectors.status],0xf0
call LoadImage
mov byte [ReadSectors.status],0x0f
popa
ret

;IN: bx=location ah=function
filedirect_c:
;call calculate_size
mov al,[size]
mov ch, BYTE [absoluteTrack]
mov cl, BYTE [absoluteSector]
mov dh, BYTE [absoluteHead]
mov byte dl,[drive]
int 0x13
ret

; cmp byte [command_tempchar],'d'
; jne .not_dir
; pusha
; mov di,bx
; mov cx,0x0200
; mov al,0
; rep stosb
; popa
; .not_dir:

get_newfilename:
mov ax,found
mov bx,new_file_str
call os_input_dialog
ret

;
;Commands
;f=new file
;d=new directory
;r=rename file
;t=rename filename given
;x=delete file
;
filenew:
mov ax,[filesize]
mov [var_x],ax
;mov word [size],0x09 ;size of fat

cmp byte [command_tempchar],'f'
je .allocate
cmp byte [command_tempchar],'d'
je .allocate
jmp .dont_allocate
.allocate:
call calculate_fat
;inc ax
;xchg ax,cx
mov dx,[dir_seg]
mov es,dx
mov word bx,[loc3]
call ReadSectors
call find_next_free_cluster
mov bx,[cluster]
mov [.cluster],bx
call calculate_fat
;call printwordh
inc ax
xchg ax,cx
;call colon
;call printwordh
mov dx,[dir_seg]
mov es,dx
mov word bx,[loc3]
call SAVE_FAT

.dont_allocate:
call LOAD_ROOT
mov cx, WORD [bpbRootEntries]
mov word di,[loc2]
call newline
jmp .loop
.filenew_exit:
call print_error
mov ax,[var_x]
mov [filesize],ax
jmp .exitl
.loop:
mov ax,[dir_seg]
mov es,ax
cmp byte [command_tempchar],'r'
je .show_name
cmp byte [command_tempchar],'x'
je .show_name
jmp .jump_name
.show_name:
push di
mov si,ImageName
mov cx,0x000B
repe cmpsb
pop di
je .filenew_found
; call show_name
; call getkey
; cmp ah,0x01
; je .filenew_exit
; cmp ah,0x1c
; je .filenew_found
.jump_name:
mov ax,[es:di]
cmp ax,0x0000
je .filenew_not_found
add di,0x0020
jmp .loop

.rename_filename_already_recieved:
push es
mov ax,0
mov es,ax
mov ax,[os_rename_file.temp]
call get_name
pop es
jmp .rename_filename_t

;Rename a file
.rename_file:
push di
;;TODO two name call
cmp byte [command_tempchar],'t'
je .rename_filename_already_recieved
;Get input for new file name
call get_newfilename
; .rename_filename_already_recieved:
mov ax,found
call get_name
.rename_filename_t:
pop di
; mov si,ImageName
; mov cx,0x000b
; rep movsb
mov dx,[dir_seg]
mov es,dx
mov dx,[kernel_seg]
mov ds,dx
;mov di,[FileSystem_DONE.selected_file]
;mov si,di
mov si,ImageName
mov cx,0x000B
;call memcpy_far
rep movsb
call SAVE_ROOT
jmp .exitl

;Delete a file
;shift all directory list
.delete_file:
push di
add di,0x001A

;lodsw
mov ax,[es:di]
mov [.cluster],ax

pop di
;mov al,0xE5
;mov [es:di],al
;jmp .delfile_done
push ds
push es
pop ds
mov si,di
add si,0x0020
.delfile_loop:
mov cx,0x0020
rep movsb
cmp dword [si],0
jne .delfile_loop
mov dword [di],0
pop ds
.delfile_done:
call SAVE_ROOT

call calculate_fat
mov dx,[dir_seg]
mov es,dx
mov word bx,[loc3]
call ReadSectors
call delete_cluster
call calculate_fat
inc ax
xchg ax,cx
call SAVE_FAT
jmp .exitl

.filenew_not_found:
cmp byte [command_tempchar],'r'
je .exitl
cmp byte [command_tempchar],'t'
je .exitl
cmp byte [command_tempchar],'x'
je .exitl
.filenew_found:
cmp byte [command_tempchar],'r'
je .rename_file
cmp byte [command_tempchar],'t'
je .rename_file
cmp byte [command_tempchar],'x'
je .delete_file
;sub di,0x0006
;mov word ax,[.cluster]
;inc word ax
;mov word [comm],ax
;mov word [cluster],ax
;add di,0x0006
;push di
mov si,ImageName
mov cx,0x000b
rep movsb
;pop di
cmp byte [command_tempchar],'d'
je .dir
mov al,0x20
stosb
jmp .done
.dir:
mov al,0x10
stosb
.done:
mov si,.file_attributes
mov cx,14
rep movsb

;add di,0x000e
;mov bx,comm
;mov al,[bx]
;stosb
;inc bx
;mov al,[bx]
;stosb
mov si,.cluster
lodsw
stosw

;; Storing Size
cmp byte [command_tempchar],'d'
je .dir_made
;inc di
;mov al,0x02
;stosb
mov ax,[var_x]
;mov ax,[filesize]
cmp ax,0
ja .size_ok
mov ax,512
.size_ok:
;imul ax,0x200
stosw
call SAVE_ROOT

.exitl:
mov ax,[var_x]
mov [filesize],ax
mov dx,[kernel_seg]
mov es,dx
ret
.dir_made:
call SAVE_ROOT

; mov ax,[.cluster]
; ;add ax,[datasector]
; add ax,0x1F
; call printwordh

;Loading new directory
mov bx,[loc]
mov dx,[.cluster]
add dx,0x1F
mov ah,0x72
int 0x61

; mov bx,[loc]
; mov cx,0x200
; call reload_words

mov di,[loc]

;Current directory link
mov al,'.'
stosb
mov al,' '
mov cx,0x000B-1
rep stosb
mov al,0x10
stosb
mov si,.file_attributes
mov cx,14
rep movsb
mov si,.cluster
lodsw
stosw
mov ax,0
stosw
stosw

;Previous directory link
mov al,'.'
stosb
stosb
mov al,' '
mov cx,0x000B-2
rep stosb
mov al,0x10
stosb
mov si,.file_attributes
mov cx,14
rep movsb
cmp word [currentdir],0x0013
je .parent_dir_is_root
mov ax,[currentdir]
sub ax,0x001F
stosw
.parent_dir_is_root:

;Padding with zeroes
mov cx,[loc]
add cx,[bpbBytesPerSector]
sub cx,di
mov al,0
rep stosb

;Saving directory
mov dx,[.cluster]
add dx,0x1F
mov word [filesize],0x200
mov [cluster],dx
mov bx,[loc]
mov ah,0x73
int 0x61

jmp .exitl
.file_attributes:
db 0x18,0x1a,0x9a,0x42,0x7c,0x43,0x7c,0x43,0x00,0x00,0xca,0x93,0x76,0x43
.cluster: dw 0

;IN: nothing
;OUT: si=description string
filetype:

xor ah,ah
mov al,[var_x]
and al,0x0F
cmp al,0x0F
je .label

mov al,[var_x]
and al,0x08
cmp al,0x08
je .drive

mov al,[var_x]
and al,0x10
cmp al,0x10
je .dir

mov si,filestr
ret

.drive:
mov si,drivestr
jmp .attrib_return
.label:
mov si,labelstr
jmp .attrib_return
.dir:
mov si,dirstr
;jmp .attrib_return

.attrib_return:
ret

; file_ext_check:
; call colon
; mov si,tempstr
; call prnstr

; call attrib
; call space
; ; mov si,tempstr
; ; mov di,bmps
; ; call cmpstr
; ; jc .bmp
; mov si,tempstr
; mov di,txts
; call cmpstr
; jc .txt
; mov si,tempstr
; mov di,coms
; call cmpstr
; jc .com
; ;mov si,tempstr
; ;mov di,vids
; ;call cmpstr
; ;jc .vid
; ;mov si,tempstr
; ;mov di,pics
; ;call cmpstr
; ;jc .pic
; ; mov si,tempstr
; ; mov di,pnts
; ; call cmpstr
; ; jc .pnt
; ret
; ; .bmp:
; ; mov si,imagestr
; ; call prnstr
; ; ; call colon
; ; ; mov si,c_paint
; ; ; call prnstr
; ; ret
; .txt:
; mov si,c_text
; call prnstr
; call colon
; mov si,c_doc
; call prnstr
; call comma
; mov si,c_type
; call prnstr
; call comma
; mov si,c_text
; call prnstr
; ret
; .com:
; mov si,coms
; call prnstr
; call colon
; mov si,c_code
; call prnstr
; call comma
; mov si,c_run
; call prnstr
; ret
;.vid:
;mov si,c_video
;call prnstr
;call colon
;mov si,c_vedit
;call prnstr
;call comma
;mov si,c_video
;call prnstr
;ret
;.pic:
;mov si,imagestr
;call prnstr
;call colon
;mov si,c_vedit
;call prnstr
;call comma
;mov si,c_video
;call prnstr
;ret
; .pnt:
; mov si,imagestr
; call prnstr
; call colon
; mov si,c_code
; call prnstr
; call comma
; mov si,c_point
; call prnstr
; ret

attrib:

call newline
mov si,attribstr
call prnstr
call colon
mov byte [var_m],0x0f

mov al,[var_x]
cmp al,0
je .normal

mov al,[var_x]
and al,0x01
cmp al,0x01
je .read
.readret:

mov al,[var_x]
and al,0x02
cmp al,0x02
je .hidden
.hiddenret:

mov al,[var_x]
and al,0x04
cmp al,0x04
je .system
.systemret:

mov al,[var_x]
and al,0x20
cmp al,0x20
je .archive
.archiveret:

jmp .done
.normal:
cmp byte [var_m],0xf0
jne .commaskipn
call comma
.commaskipn:
mov si,normalstr
call prnstr
mov byte [var_m],0xf0
jmp .done

.read:
cmp byte [var_m],0xf0
jne .commaskipr
call comma
.commaskipr:
mov si,readonlystr
call prnstr
mov byte [var_m],0xf0
jmp .readret

.hidden:
cmp byte [var_m],0xf0
jne .commaskiph
call comma
.commaskiph:
mov si,hiddenstr
call prnstr
mov byte [var_m],0xf0
jmp .hiddenret

.system:
cmp byte [var_m],0xf0
jne .commaskips
call comma
.commaskips:
mov si,systemstr
call prnstr
mov byte [var_m],0xf0
jmp .systemret

.archive:
cmp byte [var_m],0xf0
jne .commaskipa
call comma
.commaskipa:
mov si,archivestr
call prnstr
mov byte [var_m],0xf0
jmp .archiveret

.done:
ret

show_name:
call newline
mov cx,0x000B
cmp byte [advanced_flag],0xf0
jne .advanced_off
mov cx,0x0020
.advanced_off:
mov bx,di
call reload_words
mov si,di
add si,0x0008
mov cx,0x0003
push es
push di
mov di,tempstr
rep movsb
xor al,al
stosb
pop di
pop es
push di
push si
mov si,di
add si,0x000B
mov cx,0x0015
;add si,0x0011

pop si
pop di

cmp byte [advanced_flag],0xf0
je .hexloop
call space
jmp .done

.hexloop:
;lodsb
mov al,[es:si]
inc si
call printh
dec cx
cmp cx,0
jg .hexloop
.done:
call filetype
push es
mov bx,[kernel_seg]
mov es,bx
mov bx,si
mov cx,5
call reload_words
pop es
ret

;vedit:
;jmp kernel
; mov dl,[color]
; mov [extra],dl
; mov dx,0x0A0A
; push dx
; ;mov si,[loc]
; mov word [var_b],0x0654
; mov word [player_x],0x0001
; .loop:
; mov ax,0x0FA0
; mov dx,[player_x]
; dec dx
; mul dx
; add ax,[loc]
; mov si,ax
; xor dx,dx
; call setpos
; ;mov cx,0x07D0
; call memcpyprint
; pop dx
; push dx
; call setpos
; .vedit_control:
; call getkey
; cmp ah,0x01
; je .quit
; cmp ah,0x48
; je .up
; cmp ah,0x4b
; je .left
; cmp ah,0x4d
; je .right
; cmp ah,0x50
; je .down
; cmp ah,0x53
; je .color_down
; cmp ah,0x4F
; je .color_up
; cmp ah,0x52
; je .char_down
; cmp ah,0x47
; je .char_up
; cmp ah,0x51
; je .page_down
; cmp ah,0x49
; je .page_up
; cmp ah,0x3b
; je .help
; cmp ah,0x3c
; je .chaincopy
; cmp ah,0x3D
; je .copy
; cmp ah,0x3E
; je .paste
; cmp ah,0x3f
; je .spec
; cmp ah,0x40
; je .fill
; cmp ah,0x41
; je .clear
; cmp ah,0x42
; je .clean
; cmp ah,0x43
; je .setwall
; push ax
; call .calculate_pos
; pop ax
; mov [bx],al
; inc bx
; mov ah,[bx]
; mov [color],ah
; call printf
; add word [var_b],2
; jmp .vedit_control
; .quit:
; pop dx
; mov dl,[extra]
; mov [color],dl
; jmp kernel
; .up:
; sub word [var_b],0x00A0
; call getpos
; dec dh
; call setpos
; jmp .vedit_control
; .left:
; sub word [var_b],2
; call getpos
; dec dl
; call setpos
; jmp .vedit_control
; .right:
; add word [var_b],2
; call getpos
; inc dl
; call setpos
; jmp .vedit_control
; .down:
; add word [var_b],0x00A0
; call getpos
; inc dh
; call setpos
; jmp .vedit_control
; .color_up:
; call .calculate_pos
; mov al,[bx]
; inc bx
; inc byte [bx]
; mov ah,[bx]
; mov [color],ah
; call printf
; call getpos
; dec dl
; call setpos
; jmp .vedit_control
; .color_down:
; call .calculate_pos
; mov al,[bx]
; inc bx
; dec byte [bx]
; mov ah,[bx]
; mov [color],ah
; call printf
; call getpos
; dec dl
; call setpos
; jmp .vedit_control
; .char_up:
; call .calculate_pos
; inc byte [bx]
; mov al,[bx]
; inc bx
; mov ah,[bx]
; mov [color],ah
; call printf
; call getpos
; dec dl
; call setpos
; jmp .vedit_control
; .char_down:
; call .calculate_pos
; dec byte [bx]
; mov al,[bx]
; inc bx
; mov ah,[bx]
; mov [color],ah
; call printf
; call getpos
; dec dl
; call setpos
; jmp .vedit_control
; .chaincopy:
; mov byte [.chain],0xf0
; call .calculate_pos
; mov di,bx
; jmp .vedit_control
; .chain: db 0x0f
; .copy:
; mov byte [.chain],0x0f
; call .calculate_pos
; mov al,[bx]
; inc bx
; mov ah,[bx]
; mov di,ax
; jmp .vedit_control
; .paste:
; call .calculate_pos

; cmp byte [.chain],0xf0
; je .chain_on
; mov [bx],di
; mov si,bx
; jmp .done_paste
; .chain_on:
; mov ax,[di]
; mov [bx],ax
; mov si,bx
; add di,2
; .done_paste:
; inc si
; lodsb
; mov [color],al
; sub si,2
; lodsb
; call printf
; inc si

; add word [var_b],2
; jmp .vedit_control
; .spec:
; mov word ax,[var_b]
; xor dx,dx
; mov cx,2
; div cx
; xor dx,dx
; mov cx,80
; div cx
; push ax
; mov bx,x_str
; mov ah,0x45
; mov cx,0x0005
; int 0x61
; pop ax
; mov bx,y_str
; mov dx,ax
; mov ah,0x45
; mov cx,0x0005
; int 0x61
; jmp .vedit_control
; .setwall:
; mov ah,0x50
; int 0x61
; jmp .vedit_control
; .fill:
; call .calculate_pos
; mov byte [bx],0xdb
; call .re_print
; jmp .vedit_control
; .clear:
; call .calculate_pos
; mov byte [bx],0x20
; call .re_print
; jmp .vedit_control
; .clean:
; call .calculate_pos
; mov word [bx],0x0f20
; call .re_print
; jmp .vedit_control
; .help:
; mov dx,vedit_helpstr
; xor ah,ah
; int 61h
; mov dx,vedit_helpstr2
; xor ah,ah
; int 61h
; mov dx,vedit_helpstr3
; xor ah,ah
; int 61h
; jmp .vedit_control
; .page_down:
; pop dx
; call getpos
; push dx
; dec word [player_x]
; cmp word [player_x],1
; jl .frameless
; jmp .loop
; .frameless:
; mov dl,[frame]
; mov [player_x],dl
; jmp .loop
; .page_up:
; pop dx
; call getpos
; push dx
; mov dl,[frame]
; inc word [player_x]
; cmp [player_x],dl
; jg .framemore
; jmp .loop
; .framemore:
; mov word [player_x],1
; jmp .loop

; .calculate_pos:
; mov ax,0x0FA0
; mov dx,[player_x]
; dec dx
; mul dx
; add ax,[loc]
; mov bx,ax
; add bx,[var_b]
; ret

; .re_print:
; mov si,bx
; inc si
; lodsb
; mov [color],al
; sub si,2
; lodsb
; call printf
; inc si
; add word [var_b],2
; ret
; .width: db 80
; .height: db 25

; video:
; mov dl,[color]
; ;push dx
; mov [extra],dl
; mov si,[loc]
; mov word [player_x],0x0001
; ;mov di,0xB800
; ;sub di,0x0500
; ;call memcpy
; .loop:
; ;mov bl,0x36
; ;mov ax,0x1201
; ;int 0x10
; ;call newline
; mov dx,0
; call setpos
; call memcpyprint
; ;mov bl,0x36
; ;mov ax,0x1200
; ;int 0x10
; mov dx,[frame]
; cmp dx,1
; jle .videoexit
; cmp byte [slowmode],0xf0
; je .slowmode
; call delay
; jmp .timewarpdone
; .slowmode:
; call slow
; .timewarpdone:
; call chkkey
; jnz .videoexit
; mov dx,[player_x]
; cmp dx,[frame]
; jge .limit
; inc word [player_x]
; jmp .loop
; .videoexit:
; call getkey
; cmp ah,0x43
; je .setwall
; mov dl,[extra]
; ;pop dx
; mov [color],dl
; jmp kernel
; .limit:
; mov word [player_x],0x0001
; mov si,[loc]
; jmp .loop
; .setwall:
; mov ah,0x50
; int 0x61
; jmp video

memcpyprint:
;mov word ax,[player_x]
;xor dx,dx
;mov cx,0x0200
;mul cx
mov bx,0xB800
mov es,bx
xor bx,bx
;mov si,[loc]
;add si,ax
mov cx,0x07D0
.loop:
lodsw
;cmp [es:bx],ax
;je .skip
mov [es:bx],ax
;.skip:
add bx,2
loop .loop
xor bx,bx
mov es,bx
ret

;IN: si-Source String,di-Destination String
;OUT: ax-Length
;
;Find end of string
;and copy string with comma , at end
memcpyza:
mov cx,0xffff
memcpyz:
push di
push si
mov di,si

mov al,0
repne scasb
mov cx,di
sub cx,si
pop si
pop di
rep movsb
mov byte [di-1],','
ret

memcpy:
lodsb
stosb
cmp al,0
jne memcpy
ret

memcpyr:
lodsb
stosb
sub si,2
sub di,2
loop memcpyr
ret

memcpy_far_dir:
push es
push ds
push dx
mov dx,[kernel_seg]
mov es,dx
mov dx,[dir_seg]
mov ds,dx
pop dx
rep movsb
pop ds
pop es
ret

step_f:
pushf
mov bp,sp
or word [bp+0],0x0100
popf
mov byte [step_flag],0xf0
mov byte [var_f],0x0f
mov dx,[loc]
mov word [.ip],dx
jmp run
.ip:
dw 0
;jmp kernel

reload_words:
cmp cx,0x0000
jle .reload_words_end
dec cx
mov byte al,[es:bx]
call printf
inc bx
jmp reload_words
.reload_words_end:
ret

doc_up:
call getpos
dec dh
sub word [var_a],0x50
call setpos
jmp doc_shown_control

doc_right:
call getpos
inc dl
inc word [var_a]
call setpos
jmp doc_shown_control

doc:
; mov ax,0x0200
; ;xor dx,dx
; mov cx,[size]
; imul ax,cx
;cmp dx,0
;jg .small_file
;mov ax,0xFFFF
;.small_file:
mov ax,[size]
mov [var_b],ax
mov word [var_a],0x0000
mov si,[loc]
doc_loop:
lodsb
inc word [var_a]
call printf
mov word cx,[var_a]
cmp word cx,[var_b]
jge doc_shown_control2
cmp word [var_a],0x07Cf
jge doc_shown
jmp doc_loop
doc_shown:
;mov word [var_a],0x004f
mov word [var_a],0x0050
mov dx,0x0100
call setpos
doc_shown_control2:
dec word [var_a]
doc_shown_control:
call getpos
cmp dh,0x00
jle doc_top_move
cmp dh,0x18
jge doc_bottom_move
jmp doc_control_fine

doc_top_move:
mov byte [var_x],dl
mov byte [var_y],dh
mov dx,0x0000
call setpos
;sub word [var_a],0x0050
mov ax,0x0701
call clear_bios_function
mov word bx,[loc]
add word bx,[var_a]
sub byte bl,[var_x]
sub bx,0x0050
inc bx
mov cx,0x0050
call reload_words
mov byte dl,[var_x]
mov byte dh,[var_y]
inc dh
call setpos
jmp doc_control_fine

doc_bottom_move:
mov byte [var_x],dl
mov byte [var_y],dh
mov dx,0x1800
call setpos
;add word [var_a],0x0050
mov ax,0x0601
call clear_bios_function
mov word bx,[loc]
;add word bx,0x07D0
add word bx,[var_a]
sub byte bl,[var_x]
add bx,0x0050
inc bx
mov cx,0x004f
call reload_words
mov al,[bx]
call printf_c
mov byte dl,[var_x]
mov byte dh,[var_y]
dec dh
call setpos
jmp doc_control_fine

doc_control_fine:

call getkey
cmp ah,0x48
je doc_up
cmp ah,0x4b
je doc_left
cmp ah,0x4d
je doc_right
cmp ah,0x50
je doc_down
cmp ah,0x01
je doc_exit
cmp ah,0x29
je doc_exit
cmp ah,0x3b
je doc_help
cmp ah,0x3d
je doc_copy
cmp ah,0x3e
je doc_paste
cmp ah,0x3f
je doc_spec
cmp ah,0x40
je doc_clear
cmp ah,0x52
je doc_paste

call printf
inc word [var_a]
mov word bx,[loc]
add word bx,[var_a]
mov byte [bx],al
jmp doc_shown_control
doc_exit:
call newprompt
jmp kernel
doc_help:
mov dx,doc_helpstr
xor ah,ah
int 61h
jmp doc_shown_control
doc_copy:
mov word bx,[loc]
add word bx,[var_a]
inc bx
mov si,bx
jmp doc_shown_control
doc_paste:
inc word [var_a]
mov word bx,[loc]
add word bx,[var_a]
lodsb
mov byte [bx],al
call printf
jmp doc_shown_control
doc_spec:
pusha
mov ah,0x49
mov bx,c_loc
mov dx,[loc]
add dx,[var_a]
inc dx
mov cx,0x0005
int 0x61
popa
jmp doc_shown_control
doc_clear:
inc word [var_a]
mov word bx,[loc]
add word bx,[var_a]
mov byte [bx],0
call printf
jmp doc_shown_control

doc_left:
call getpos
dec dl
dec word [var_a]
call setpos
jmp doc_shown_control

doc_down:
call getpos
inc dh
add word [var_a],0x50
call setpos
jmp doc_shown_control

; c_length_f:
; mov si,length
; call change
; jmp kernel

c_htod_f:
call gethex
push ax
call gethex
pop bx
mov ah,bl
ror eax,16
call gethex
push ax
call gethex
pop bx
mov ah,bl
push ax
call colon
pop ax
call printn
jmp kernel

c_scrolllen_f:
mov si,scrolllength
call change
jmp kernel

; c_frame_f:
; mov si,frame
; call change
; cmp byte [frame],0
; jle .frameless
; jmp kernel
; .frameless:
; mov byte [frame],1
; jmp kernel

; c_score_f:
; not byte [score]
; jmp kernel

c_autostart_f:
not byte [autostart]
jmp kernel

c_micro_f:
not byte [micro]
jmp kernel

; c_multi_f:
; not byte [multi]
; jmp kernel

clock:
mov si,.string
mov di,found
mov cx,9
rep movsb

call command
call chkkey
jnz kernel
call getpos
sub dh,2
xor dl,dl
call setpos
jmp clock
.string:
db "csltslds",0

page_change:
call directgetkey
mov al,[page]
inc al
cmp al,0x07
jle .page_fine
xor al,al
.page_fine:
mov [page],al
mov ah,0x05
int 10h
call newprompt
jmp command_line

page_change_c:
call directgetkey
.skip_key:
mov al,[page]
inc al
cmp al,0x07
jle .page_fine
xor al,al
.page_fine:
call getpos
push dx
mov byte [page],al
mov ah,0x05
int 10h
pop dx
call setpos
;call newprompt
ret

reg_int:
;call set_timer
;call ProgramPIT
mov ax,0x0000
mov di,int00h
call set_ivt
mov ax,0x0001
mov di,int01h
call set_ivt
mov ax,0x0003
mov di,int03h
call set_ivt
mov ax,0x0004
mov di,int04h
call set_ivt
mov ax,0x0005
mov di,int05h
call set_ivt
mov ax,0x0006
mov di,int06h
call set_ivt
mov ax,0x0007
mov di,int07h
call set_ivt
; mov ax,0x0008
; mov di,int08h
; call set_ivt
;mov ax,0x0009
;mov di,int09h
;call set_ivt
mov ax,0x000b
mov di,int0bh
call set_ivt
; mov ax,0x000c
; mov di,int0ch
; call set_ivt
mov ax,0x000d
mov di,int0dh
call set_ivt
; mov ax,0x000e
; mov di,int0eh
; call set_ivt
mov ax,0x000f
mov di,int0fh
call set_ivt
mov ax,0x001c
mov di,int1ch
call set_ivt
mov ax,0x001b;;TODO may cause problems
mov di,int1bh
call set_ivt
mov ax,0x0020
mov di,int20h
call set_ivt
mov ax,0x0021
mov di,int21h
call set_ivt
mov ax,0x0022	;;Alias
mov di,int21h	;;Alias
call set_ivt	;;Alias
mov ax,0x002b
mov di,int2bh
call set_ivt
; mov ax,0x002c
; mov di,int2ch
; call set_ivt
mov ax,0x0033
mov di,int33h
call set_ivt
mov ax,0x004A
mov di,int4ah
call set_ivt
mov ax,0x0060
mov di,int60h
call set_ivt
mov ax,0x0061
mov di,int61h
call set_ivt
; mov ax,0x0062
; mov di,int62h
; call set_ivt
mov ax,0x0064
mov di,int64h
call set_ivt
ret

set_ivt:
xor dx,dx
mov es,dx
mov bl,0x04
mul bl
mov bx,ax
xor ax,ax
mov es,ax
mov word [bx],di
add bx,2
mov word dx,[kernel_seg]
mov [bx],dx
ret

ackport:
cmp al,0x0f
jle irqsmall
mov al,0x20
out 0xa0,al
irqsmall:
mov al,0x20
out 0x20,al
ret

; clrport64:

; in al,0x60
; call printf

; in al,0x64
; mov ah,al
; or al,80h
; out 0x61,al
; xchg ah,al
; out 61h,al

; ;and al,1
; ;cmp al,0x01
; ;jge clrport64
; ret

int00h:
pusha
xor dx,dx
mov ds,dx
mov es,dx
mov si,dividebyzerostr
call prnstr
call getkey
mov al,0x00
call ackport
popa
iret

int01h:
cli
pusha
pushf
mov bp,sp
and word [bp+0],0xFEFF
popf
sti
xor dx,dx
mov ds,dx
mov es,dx

cmp byte [step_flag],0xf0
jne .goon_on
call newline

popa
call debug_int
pusha
call newline
mov si,c_code
call prnstr
call colon
mov cx,[var_i]
mov si,[step_f.ip]
mov [step_f.ip],cx
sub cx,si
cmp cx,0
jl .toobig
cmp cx,0x0140
jg .toobig
.loop:
lodsb
call printh
loop .loop
call colon
lodsb
call printh
call colon
.toobig:

mov al,0x01
call ackport
cmp byte [var_f],0xf0
jne .check
call chkkey
jz .goon_on
.check:
call getkey
cmp ah,0x01
je .quit
cmp ah,0x29
je .quit
cmp ah,0x3b
je .help
cmp ah,0x4f
je .goon
cmp ah,0x52
je .goon
cmp al,'q'
je .quit
.goon_on:
popa
;pop bx
;pop ax
;xor ax,ax
;push ax
;mov bx,kernel
;push bx
iret
.goon:
cmp byte [var_f],0xf0
je .goon_turn
mov byte [var_f],0xf0
jmp .goon_on
.goon_turn:
mov byte [var_f],0x0f
jmp .goon_on
.help:
mov dx,step_helpstr
xor ax,ax
int 0x61
jmp .check
.quit:
mov byte [step_flag],0x0f
popa
jmp interrupt_return_to_kernel
; pop bx
; pop ax
; xor ax,ax
; push ax
; mov bx,kernel
; push bx
; iret

int03h:
pusha
xor ax,ax
mov ds,ax
mov es,ax
call newline
popa
call debug_int
pusha
mov al,0x03
call ackport
popa
iret

int04h:
pusha
xor ax,ax
mov ds,ax
mov es,ax
call newline
popa
call debug_int
mov si,exception_str
call prnstr
pusha
mov al,0x04
call printh
push ax
call getkey
pop ax
call ackport
popa
iret

int05h:
pusha
xor dx,dx
mov ds,dx
mov es,dx
call storescreen
mov al,0x05
call ackport
popa
iret

int06h:
pusha
xor dx,dx
mov ds,dx
mov es,dx
mov si,invalidstr
call prnstr
call getkey
mov al,0x06
call ackport
popa
iret

int07h:
pusha
xor dx,dx
mov ds,dx
mov es,dx
mov si,mathprocstr
call prnstr
mov si,notfoundstr
call prnstr
call getkey
mov al,0x07
call ackport
popa
iret

; int08h:
; pusha
; xor ax,ax
; mov ds,ax
; mov es,ax

; popa
; mov al,0x08
; call ackport
; iret

; call newline
; popa
; call debug_int
; mov si,doublefaultstr
; call prnstr
; pusha
; mov al,0x08
; call printh
; call ackport
; popa
; iret

int0bh:
pusha
xor ax,ax
mov ds,ax
mov es,ax
call newline
popa
call debug_int
mov si,faultstr
call prnstr
pusha
mov al,0x0b
call printh
push ax
call getkey
pop ax
call ackport
popa
iret

int0ch:
pusha
xor ax,ax
mov ds,ax
mov es,ax
call newline
popa
call debug_int
mov si,faultstr
call prnstr
pusha
mov al,0x0c
call printh
push ax
call getkey
pop ax
call ackport
popa
iret

int0dh:
pusha
xor ax,ax
mov ds,ax
mov es,ax
call newline
popa
call debug_int
mov si,faultstr
call prnstr
pusha
mov al,0x0d
call printh
push ax
call getkey
pop ax
call ackport
popa
;iret
	pop ax				; point stacked IP beyond...
	add ax,5			; ...the offending instruction
	push ax
	iret

; int0eh:
; pusha
; xor ax,ax
; mov ds,ax
; mov es,ax
; call newline
; popa
; call debug_int
; mov si,pagefaultstr
; call prnstr
; pusha
; mov al,0x0e
; call ackport
; call getkey
; popa
; iret

int0fh:
pusha
xor ax,ax
mov ds,ax
mov es,ax
call newline
popa
call debug_int
mov si,faultstr
call prnstr
pusha
mov al,0x0f
call printh
push ax
call getkey
pop ax
call ackport
popa
iret

int1bh:
pusha
xor dx,dx
mov ds,dx
mov es,dx
popa
call newline
call debug_int
pusha
call getkey
mov al,0x1b
call ackport
popa
iret

int20h:
mov dx,0
mov ds,dx
mov es,dx
mov al,0x20
call ackport
mov ax,0x4C00
int 0x21
; jmp interrupt_return_to_kernel
; pop bx
; pop ax
; xor ax,ax
; push ax
; mov bx,kernel
; push bx
; iret

int21h:
pusha
mov al,0x21
call ackport
popa
cmp ah,0x09
je int21h_display_string
pusha
mov dx,0
mov ds,dx
mov es,dx
popa

cmp ah,0x00
je int21h_close_process
cmp ah,0x01
je int21h_read_char
cmp ah,0x02
je int21h_display_char
cmp ah,0x06
je int21h_directinputoutput
cmp ah,0x07
je int21h_read_char_direct
cmp ah,0x08
je int21h_read_char_direct_check
; cmp ah,0x09
; je int21h_display_string
cmp ah,0x0a
je int21h_get_string
cmp ah,0x25
je int21h_set_interrupt
cmp ah,0x2a
je int21h_get_date
cmp ah,0x2b
je int21h_set_date
cmp ah,0x2c
je int21h_get_time
cmp ah,0x2d
je int21h_set_time
cmp ah,0x30
je int21h_get_dos_ver
cmp ah,0x3B
je int21h_set_dir
cmp ah,0x3C
je int21h_create_file
cmp ah,0x3D
je int21h_open_file
cmp ah,0x3E
je int21h_save_file
cmp ah,0x3F
je int21h_read_file
cmp ah,0x40
je int21h_save_file
cmp ah,0x41
je int21h_delete_file
cmp ah,0x47
je int21h_get_dir
cmp ah,0x4C
je int21h_close_process
cmp ah,0x4D
je int21h_get_return_code
call newline
call debug_int
;call clrport64

iret

int21h_read_char:
call getkey
call printf
iret

int21h_display_char:
mov al,dl
cmp al,0x0A
je .newline
call printf
.done:
mov al,dl
iret
.newline:
call newline
jmp .done

int21h_directinputoutput:
cmp dl,0xFF
je .input
mov al,dl
call printf
mov al,dl
iret
.input:
xor al,al
call chkkey
jz .zero
iret
.zero:
mov dl,0x0f
iret

int21h_read_char_direct:
call directgetkey
iret

int21h_read_char_direct_check:
call getkey
iret

int21h_display_string:
pusha
mov si,dx
mov dx,ds
cmp dx,0
je .com
.loop:
lodsb
cmp al,0
je .done
cmp al,'$'
je .done
mov ah,0x0E
int 0x10
jmp .loop
.com:
push si
mov ah,0x0F
int 0x10
mov bl,bh
xor bh,bh
mov [page],bx
pop si
call prnstr_dos
.done:
popa
mov al,0x24
iret

int21h_get_string:
mov bx,dx
mov cx,[bx]
inc bx
mov di,bx
inc di
call getstr_dos
mov al,0x24
iret

int21h_set_interrupt:
xor ah,ah
mov di,dx
call set_ivt
iret

int21h_get_date:
mov al,0x04
int 0x1a
iret

int21h_set_date:
mov al,0x05
int 0x1a
xor al,al
iret

int21h_get_time:
mov al,0x02
int 0x1a
iret

int21h_set_time:
mov al,0x03
int 0x1a
xor al,al
iret

int21h_get_dos_ver:
mov ax,0x0606
iret

int21h_close_process:
mov [returncode],al
push ax
xor al,al
mov ah,0x0F
int 0x10
mov bl,bh
xor bh,bh
mov [page],bx
call newline
mov si,process_returnstr
call prnstr
call colon
pop ax
call printh
interrupt_return_to_kernel:
pop bx
pop ax
xor ax,ax
push ax
mov bx,kernel
push bx
iret

int21h_get_return_code:
xor ah,ah
mov al,[returncode]
iret

int21h_set_dir:
mov [currentdir],dx
iret

int21h_create_file:
mov ax,dx
call os_create_file
iret

int21h_open_file:
mov word [int21h_read_file.loc],0
mov ax,dx
mov cx,[locf4]
call os_load_file
call check_carry
iret

int21h_save_file:
mov bx,[locf4]
call filesave_c
clc
iret

int21h_delete_file:
mov ax,dx
call os_remove_file
iret

int21h_read_file:
mov ax,cx
mov dx,[locf4]
add dx,[.loc]
add [.loc],ax
clc
iret
.loc: dw 0

int21h_get_dir:
mov dx,[currentdir]
iret

int2bh:
pusha
mov ax,0
mov ds,ax
mov es,ax
mov al,0x2b
call ackport
popa

cmp ah,0x01
je os_print_string_i
cmp ah,0x02
je os_input_string_i
cmp ah,0x03
je os_move_cursor_i
cmp ah,0x04
je os_get_cursor_pos_i
cmp ah,0x05
je os_show_cursor_i
cmp ah,0x06
je os_hide_cursor_i
cmp ah,0x07
je os_check_for_key_i
cmp ah,0x08
je os_wait_for_key_i

cmp ah,0x10
je int21h_display_char

cmp ah,0x15
je os_serial_port_enable_i
cmp ah,0x16
je os_send_via_serial_i
cmp ah,0x17
je os_get_via_serial_i

cmp ah,0x20
je os_dialog_box_i
cmp ah,0x21
je os_dialog_box2_i
cmp ah,0x22
je os_list_dialog_i
cmp ah,0x23
je os_input_dialog_i

cmp ah,0x25
je os_draw_background_i
cmp ah,0x26
je os_draw_block_i

cmp ah,0x50
je os_load_file_i
cmp ah,0x51
je os_write_file_i
cmp ah,0x52
je os_file_exists_i
cmp ah,0x53
je os_create_file_i
cmp ah,0x54
je os_remove_file_i
cmp ah,0x55
je os_rename_file_i
cmp ah,0x56
je os_get_file_size_i
cmp ah,0x57
je os_file_selector_i

cmp ah,0x60
je os_memory_free_i
cmp ah,0x61
je os_memory_allocate_i
cmp ah,0x62
je os_memory_release_i
cmp ah,0x63
je os_memory_read_i
cmp ah,0x64
je os_memory_write_i
cmp ah,0x65
je os_memory_reset_i

iret

os_print_string_i:
call os_print_string
iret
os_input_string_i:
call os_input_string
iret
os_move_cursor_i:
call os_move_cursor
iret
os_get_cursor_pos_i:
call os_get_cursor_pos
iret
os_show_cursor_i:
call os_show_cursor
iret
os_hide_cursor_i:
call os_hide_cursor
iret
os_check_for_key_i:
call os_check_for_key
iret
os_wait_for_key_i:
call os_wait_for_key
iret
os_dialog_box_i:
mov ax,dx
mov dx,0
call os_dialog_box
iret
os_dialog_box2_i:
mov ax,dx
mov dx,1
call os_dialog_box
iret
os_input_dialog_i:
mov ax,dx
call os_input_dialog
iret
os_list_dialog_i:
mov ax,dx
call os_list_dialog
call check_carry
iret
os_draw_background_i:
mov ax,dx
call os_draw_background
iret
os_draw_block_i:
call os_draw_block
iret

;IN:DX=filename CX=location
;OUT:BX=filesize carry set if error
os_load_file_i:
mov ax,dx
call os_load_file
call check_carry
iret
os_write_file_i:
mov ax,dx
call os_write_file
call check_carry
iret
os_file_exists_i:
mov ax,dx
call os_file_exists
call check_carry
iret
os_create_file_i:
call os_create_file
iret
os_remove_file_i:
mov ax,dx
call os_remove_file
iret
os_rename_file_i:
call os_rename_file
call check_carry
iret
os_get_file_size_i:
mov ax,dx
call os_get_file_size
call check_carry
iret
os_file_selector_i:
call os_file_selector
call check_carry
iret

os_serial_port_enable_i:
call os_serial_port_enable
iret
os_send_via_serial_i:
call os_send_via_serial
iret
os_get_via_serial_i:
call os_get_via_serial
iret

os_memory_free_i:
call os_memory_free
iret
os_memory_allocate_i:
call os_memory_allocate
call check_carry
iret
os_memory_release_i:
call os_memory_release
iret
os_memory_read_i:
call os_memory_read
iret
os_memory_write_i:
call os_memory_write
iret
os_memory_reset_i:
call os_memory_reset
iret

os_print_string:
pusha
;mov al,[teletype]
;push ax
;mov byte [teletype],0xf0
;call prnstr_dos
;pop ax
;mov [teletype],al

.loop:
lodsb
cmp al,0
je .prnend
cmp al,0x0D
je .enter
cmp al,0x0A
je .enter2

call printt
jmp .loop
.enter:
inc si
jmp .done
.enter2:
cmp byte [si],0x0D
jne .done
inc si
.done:
call newline
jmp .loop

.prnend:
popa
ret

os_input_string:
pusha
mov dl,[teletype]
push dx
mov byte [teletype],0xf0
mov dx,ax
mov ah,0x04
int 0x61
pop dx
mov [teletype],dl
popa
ret

os_move_cursor:
pusha
call setpos
popa
ret

os_show_cursor:
pusha
mov cx,0x0506
mov ah,0x01
int 0x10
popa
ret

os_hide_cursor:
pusha
mov ch,0x20
mov ah,0x01
int 0x10
popa
ret

os_check_for_extkey:
os_check_for_key:
mov ah,0x01
int 0x16
jnz os_wait_for_key
mov al,0
ret

os_wait_for_key:
mov ah,0
int 0x16
ret

os_get_cursor_pos:
pusha
mov byte bh, [page]
	mov ah, 3
	int 10h
	mov [.tmp],dx
popa
mov dx,[.tmp]
ret
.tmp dw 0

os_text_mode:
; Put the operating system in text mode (mode 03h)
pusha

mov ax, 3			; Back to text mode
mov bx, 0
int 10h
mov ax, 1003h			; No blinking text!
int 10h

popa
ret

os_clear_screen:
pusha
mov ah,0x06
int 0x61

mov	ax,1003h
xor	bx,bx
int	10h
popa
ret

os_sint_to_string:
os_long_int_to_string:
os_int_to_string:
pusha
mov bx,tempstr
mov dx,ax
mov ah,0x2A
int 0x61
popa
mov ax,tempstr
ret

os_string_to_int:
pusha
mov dx,si
mov ah,0x2B
int 0x61
mov [.int_tmp],dx
popa
mov ax,[.int_tmp]
ret
.int_tmp dw 0

; ------------------------------------------------------------------
; os_load_file -- Load file into RAM
; IN: AX = location of filename, CX = location in RAM to load file
; OUT: BX = file size (in bytes), carry set if file not found

os_load_file:
call os_file_exists
jc .quit
pusha
mov bx,cx
mov dx,ax
mov ah,0x85
int 0x61
popa
call os_get_file_size
.quit:
ret

; --------------------------------------------------------------------------
; os_write_file -- Save (max 64K) file to disk
; IN: AX = filename, BX = data location, CX = bytes to write
; OUT: Carry clear if OK, set if failure

os_write_file:
mov [filesize],cx
mov word [filesize+2],0
pusha
.save_file:
call os_file_exists
jc .create_file
call filesave_c
popa
clc
ret
.create_file:
call os_create_file
jmp .save_file

; --------------------------------------------------------------------------
; os_file_exists -- Check for presence of file on the floppy
; IN: AX = filename location; OUT: carry clear if found, set if not

os_file_exists:
pusha
call get_name
mov dx,[filesize]
mov [.temp_filesize],dx
mov byte [command_tempchar],'e'
jmp fdir
.temp_filesize:
dw 512

get_name:
pusha
mov si,ax
mov di,ImageName
mov cx,0x000C
rep movsb
call checkfname
popa
ret

; --------------------------------------------------------------------------
; os_get_file_size -- Get file size information for specified file
; IN: AX = filename; OUT: BX = file size in bytes (up to 64K)
; or carry set if file not found

os_get_file_size:
call os_file_exists
;jc .quit
;sub bx,50
;dec bx
mov bx,[filesize]
.quit:
ret


; Create a new file
; IN: AX = filename location
; OUT: CF set on error
os_create_file:
	pusha
	call get_name              ; Convert filename to FAT format
	
	; Check if file exists
	mov byte [command_tempchar], 'e'
	mov [.filename_save], ax
	call filenew
	jnc .exists_error         ; Error if file exists
	
	; Find free root directory entry
	mov di, [loc2]            ; Root dir buffer
	mov cx, [bpbRootEntries]
	xor dx, dx               ; Entry counter
	
.find_entry:
	mov al, [di]
	cmp al, 0                ; Empty entry
	je .entry_found
	cmp al, 0xE5             ; Deleted entry
	je .entry_found
	add di, 32               ; Next entry
	inc dx
	loop .find_entry
	
	; No free entries
	; mov al, [fs_error_codes.dir_full] 
	; call log_fs_error
	mov si,mathprocstr ;If math CPU is present
	call os_print_string
	jmp .error

.entry_found:
	; Create directory entry
	mov si, ImageName         ; Filename
	mov cx, 11
	rep movsb
	
	mov byte [di-11+0x0B], 0x20  ; Attributes = archive
	mov dword [di-11+0x0C], 0    ; Reserved
	mov word [di-11+0x10], 0     ; Create time 
	mov word [di-11+0x12], 0     ; Create date
	mov word [di-11+0x14], 0     ; Last access
	mov word [di-11+0x16], 0     ; High bits of cluster number (FAT16)
	mov word [di-11+0x18], 0     ; Last write time
	mov word [di-11+0x1A], 0     ; First cluster
	mov dword [di-11+0x1C], 0    ; File size
	
	; Save root directory
	call SAVE_ROOT
	jc .error
	
	popa
	clc                      ; Success
	ret

.exists_error:
	popa
	stc                      ; Error - file exists
	ret
	
.error:
	popa
	stc                      ; General error
	ret

.filename_save: dw 0
.dir_full: db "Directory full",0

; --------------------------------------------------------------------------
; os_rename_file -- Change the name of a file on the disk
; IN: AX = filename to change, BX = new filename (zero-terminated strings)
; OUT: carry set on error

os_rename_file:
call os_file_exists
jc .quit
pusha
call get_name
popa
pusha
mov [.temp],bx
; pusha
; push es
; mov ax,0
; mov es,ax
; mov si,ImageName
; call prnstr
; call getkey
; pop es
; popa

;;TODO
mov byte [command_tempchar],'r'
call filenew
popa
clc
.quit:
ret
.temp: dw 0xA000

; --------------------------------------------------------------------------
; os_remove_file -- Deletes the specified file from the filesystem
; IN: AX = location of filename to remove

os_remove_file:
pusha
call get_name
mov byte [command_tempchar],'x'
call filenew
popa
ret

os_pause:
	pusha
	cmp ax, 0
	je .time_up			; If delay = 0 then bail out

	mov cx, 0
	mov [.counter_var], cx		; Zero the counter variable

	mov bx, ax
	mov ax, 0
	mov al, 2			; 2 * 55ms = 110mS
	mul bx				; Multiply by number of 110ms chunks required 
	mov [.orig_req_delay], ax	; Save it

	mov ah, 0
	int 1Ah				; Get tick count	

	mov [.prev_tick_count], dx	; Save it for later comparison

.checkloop:
	mov ah,0
	int 1Ah				; Get tick count again

	cmp [.prev_tick_count], dx	; Compare with previous tick count

	jne .up_date			; If it's changed check it    		
	jmp .checkloop			; Otherwise wait some more

.time_up:
	popa
	ret

.up_date:
	mov ax, [.counter_var]		; Inc counter_var
	inc ax
	mov [.counter_var], ax

	cmp ax, [.orig_req_delay]	; Is counter_var = required delay?
	jge .time_up			; Yes, so bail out

	mov [.prev_tick_count], dx	; No, so update .prev_tick_count 

	jmp .checkloop			; And go wait some more


	.orig_req_delay		dw	0
	.counter_var		dw	0
	.prev_tick_count	dw	0
	
	; ------------------------------------------------------------------
; os_fatal_error -- Display error message and halt execution
; IN: AX = error message string location

os_fatal_error:
mov si,ax
call prnstr
call colon
	pop ax
	call printwordh
	jmp kernel

; ==================================================================

;IN: ax-String
;OUT: ax-Length
os_string_length:
pusha
mov si,ax
call strlen
dec ax
mov [.length_tmp],ax
;mov ah,0x20
;int 0x61
popa
mov ax,[.length_tmp]
ret
.length_tmp dw 0

os_string_uppercase:
pusha
mov dx,ax
mov ah,0x18
int 0x61
popa
ret
os_string_lowercase:
pusha
mov dx,ax
mov ah,0x1B
int 0x61
popa
ret

os_string_copy:
pusha
call memcpy
popa
ret

;ax=selected file name
os_file_selector:
;mov ah,0x86
;int 0x61
mov al,0
mov di,ImageName
mov cx,11
rep stosb
mov byte [command_tempchar],'l'
call fdir
ret

; ------------------------------------------------------------------
; os_get_file_list -- Generate comma-separated string of files on floppy
; IN/OUT: AX = location to store zero-terminated filename string
os_get_file_list:
push es
push ds
pusha
mov si,[loc2]
mov di,ax
mov ax,[dir_seg]
mov ds,ax;Directory Segment
mov ax,[kernel_seg]
mov es,ax
.makelistloop:
push si

;Store name of the file
mov cx,0x000B
.store_loop:
; repnz movsb
lodsb
cmp al,0
je .store_loop
stosb
loop .store_loop
;stosb
;mov [.list_pos],di

;Store file type
mov byte [es:di],' '
inc di
lodsb
mov [es:var_x],al
push ds
mov ax,0
mov ds,ax
call filetype
mov cx,0x05
rep movsb
pop ds

;Add comma
mov byte [es:di],','
inc di
pop si
add si,0x0020 ;Update counter to next file
cmp word [ds:si],0 ;If end is reached then stop
je .exitmakelistloop
jmp .makelistloop
.exitmakelistloop:
;dec di
mov word [es:di-1],0 ;Truncate the list
popa
pop ds
pop es
ret

os_get_api_ver_string:
mov si,verstring
ret

os_get_api_version:
mov ah,0xff
int 0x61
ret

os_port_byte_out:
pusha
out dx,ax
popa
ret
os_port_byte_in:
in ax,dx
ret

; ------------------------------------------------------------------
; os_string_join -- Join two strings into a third string
; IN/OUT: AX = string one, BX = string two, CX = destination string

os_string_join:
	pusha

	mov si, ax			; Put first string into CX
	mov di, cx
	call os_string_copy

	call os_string_length		; Get length of first string

	add cx, ax			; Position at end of first string

	mov si, bx			; Add second string onto it
	mov di, cx
	call os_string_copy

	popa
	ret
	
; ==================================================================
; TachyonOS -- The TachyonOS Operating System kernel
; Copyright (C) 2013 TachyonOS Developers -- see doc/LICENCE.TXT
;
; EXTENDED MEMORY HANDLING ROUTINES
; ==================================================================
  
  
  ; Memory Data
  allocation_map:			times 128 db 0			; a memory map showing which blocks are owned by which handles
  memory_handles_used:			times 128 db 0 			; marks if a handle number is allocated, 1 for used, 0 for free

 ; os_memory_reset
 ; Reset memory allocation and clear all memory
 ; IN/OUT: none
 os_memory_reset:
	pusha
	
	;mov ax, 0x1000
	mov ax, 0x0
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
	ret
	
; os_memory_free
; Returns the amount of free memory blocks
; IN: none
; OUT: BX = number of free blocks
os_memory_free:
	pusha
	
	mov ax, 0x1000
	;mov ds, ax
	
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
	ret
	
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

	;mov ax, 0x1000
	mov ax, 0x0
	mov ds, ax
	mov es, ax
	;mov es, ax
	
	; inc byte [internal_call]
	
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
	ret
	

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
	; dec byte [internal_call]
	clc
	ret
	
	.memory_handle					db 0
	
; os_memory_release
; Release a memory handle and free it's memory blocks
; IN: BH = handle
; OUT: none
os_memory_release:
	pusha
	
	mov ax, 0
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
	ret
	
; os_memory_read
; Read memory handle to program space
; IN: BH = handle, ES:DI = output locations
os_memory_read:
	pusha
	
	mov ax, 0x0
	mov ds, ax
	mov es, ax
	
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
	ret
	
; os_memory_write
; Write memory handle from program space
; IN: BH = handle, DS:SI = source locations
os_memory_write:
	pusha
	push es
	mov dx, ds
	
	; mov ax, 0x0
	; mov ds, ax
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
	pop es
	popa
	ret
	
.source_segment						dw 0
.source_address						dw 0

; ------------------------------------------------------------------
; os_string_tokenize -- Reads tokens separated by specified char from
; a string. Returns pointer to next token, or 0 if none left
; IN: AL = separator char, SI = beginning; OUT: DI = next token or 0 if none

os_string_tokenize:
	push si

.next_char:
	cmp byte [si], al
	je .return_token
	cmp byte [si], 0
	jz .no_more
	inc si
	jmp .next_char

.return_token:
	mov byte [si], 0
	inc si
	mov di, si
	pop si
	ret

.no_more:
	mov di, 0
	pop si
	ret
	
; ------------------------------------------------------------------
; os_string_reverse -- Reverse the characters in a string
; IN: SI = string location

os_string_reverse:
	pusha

	cmp byte [si], 0		; Don't attempt to reverse empty string
	je .end

	mov ax, si
	call os_string_length

	mov di, si
	add di, ax
	dec di				; DI now points to last char in string

.loop:
	mov byte al, [si]		; Swap bytes
	mov byte bl, [di]

	mov byte [si], bl
	mov byte [di], al

	inc si				; Move towards string centre
	dec di

	cmp di, si			; Both reached the centre?
	ja .loop

.end:
	popa
	ret
	
; ------------------------------------------------------------------
; os_string_truncate -- Chop string down to specified number of characters
; IN: SI = string location, AX = number of characters
; OUT: String modified, registers preserved

os_string_truncate:
	;pusha
push si
	add si, ax
	mov byte [si], 0
pop si
	;popa
	ret

; ------------------------------------------------------------------
; os_string_strip -- Removes specified character from a string (max 255 chars)
; IN: SI = string location, AL = character to remove

os_string_strip:
	pusha

	mov di, si

	mov bl, al			; Copy the char into BL since LODSB and STOSB use AL
.nextchar:
	lodsb
	stosb
	cmp al, 0			; Check if we reached the end of the string
	je .finish			; If so, bail out
	cmp al, bl			; Check to see if the character we read is the interesting char
	jne .nextchar			; If not, skip to the next character

.skip:					; If so, the fall through to here
	dec di				; Decrement DI so we overwrite on the next pass
	jmp .nextchar

.finish:
	popa
	ret
	
; ------------------------------------------------------------------
; os_string_parse -- Take string (eg "run foo bar baz") and return
; pointers to zero-terminated strings (eg AX = "run", BX = "foo" etc.)
; IN: SI = string; OUT: AX, BX, CX, DX = individual strings

os_string_parse:
	push si

	mov ax, si			; AX = start of first string

	mov bx, 0			; By default, other strings start empty
	mov cx, 0
	mov dx, 0

	push ax				; Save to retrieve at end

.loop1:
	lodsb				; Get a byte
	cmp al, 0			; End of string?
	je .finish
	cmp al, ' '			; A space?
	jne .loop1
	dec si
	mov byte [si], 0		; If so, zero-terminate this bit of the string

	inc si				; Store start of next string in BX
	mov bx, si

.loop2:					; Repeat the above for CX and DX...
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop2
	dec si
	mov byte [si], 0

	inc si
	mov cx, si

.loop3:
	lodsb
	cmp al, 0
	je .finish
	cmp al, ' '
	jne .loop3
	dec si
	mov byte [si], 0

	inc si
	mov dx, si

.finish:
	pop ax

	pop si
	ret

; ------------------------------------------------------------------
; os_string_strincmp -- See if two strings match up to set number of chars
; IN: SI = string one, DI = string two, CL = chars to check
; OUT: carry set if same, clear if different

os_string_strincmp:
	pusha

.more:
	mov al, [si]			; Retrieve string contents
	mov bl, [di]

	cmp al, bl			; Compare characters at current location
	jne .not_same

	cmp al, 0			; End of first string? Must also be end of second
	je .terminated

	inc si
	inc di

	dec cl				; If we've lasted through our char count
	cmp cl, 0			; Then the bits of the string match!
	je .terminated

	jmp .more


.not_same:				; If unequal lengths with same beginning, the byte
	popa				; comparison fails at shortest string terminator
	clc				; Clear carry flag
	ret


.terminated:				; Both strings terminated at the same position
	popa
	stc				; Set carry flag
	ret

; Change the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved

os_set_pixel:
	pusha

	cmp ax, 320
	jge .out_of_range
	
	cmp cx, 200
	jge .out_of_range
	
	mov dx, cx
	mov cx, ax
	mov ah, 0Ch
	mov al, bl
	xor bx, bx
	int 10h
.out_of_range:
	popa
	ret
	
	
; Get the the colour of a pixel
; IN: AX=X, CX=Y, BL=colour
; OUT: None, registers preserved
os_get_pixel:
	pusha
	
	;push 1000h
	;pop ds
	
	mov dx, cx
	mov cx, ax
	mov ah, 0Dh
	xor bx, bx
	int 10h
	mov byte [.pixel], al
	popa
	mov bl, [.pixel]
	ret
	
	.pixel				db 0
	
	
; Implementation of Bresenham's line algorithm. Translated from an implementation in C (http://www.edepot.com/linebresenham.html)
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour
; OUT: None, registers preserved
os_draw_line:
	pusha				; Save parameters
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	;inc byte [internal_call]
	
	xor ax, ax			; Clear variables
	mov di, .x1
	mov cx, 11
	rep stosw
	
	popa				; Restore and save parameters
	pusha
	
	mov [.x1], cx			; Save points
	mov [.x], cx
	mov [.y1], dx
	mov [.y], dx
	mov [.x2], si
	mov [.y2], di
	
	mov [.colour], bl		; Save the colour
	
	mov bx, [.x2]
	mov ax, [.x1]
	cmp bx, ax
	jl .x1gtx2
	
	sub bx, ax
	mov [.dx], bx
	mov ax, 1
	mov [.incx], ax
	jmp .test2
	
.x1gtx2:
	sub ax, bx
	mov [.dx], ax
	mov ax, -1
	mov [.incx], ax
	
.test2:
	mov bx, [.y2]
	mov ax, [.y1]
	cmp bx, ax
	jl .y1gty2
	
	sub bx, ax
	mov [.dy], bx
	mov ax, 1
	mov [.incy], ax
	jmp .test3
	
	.done:
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	popa
	;dec byte [internal_call]
	ret
	
.y1gty2:
	sub ax, bx
	mov [.dy], ax
	mov ax, -1
	mov [.incy], ax
	
.test3:
	mov bx, [.dx]
	mov ax, [.dy]
	cmp bx, ax
	jl .dygtdx
	
	mov ax, [.dy]
	shl ax, 1
	mov [.dy], ax
	
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dx], bx
	
.xloop:
	mov ax, [.x]
	mov bx, [.x2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .xloop1
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	mov ax, [.balance]
	mov bx, [.dx]
	sub ax, bx
	mov [.balance], ax
	
.xloop1:
	mov ax, [.balance]
	mov bx, [.dy]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	jmp .xloop
	
.dygtdx:
	mov ax, [.dx]
	shl ax, 1
	mov [.dx], ax
	
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
	shl bx, 1
	mov [.dy], bx
	
.yloop:
	mov ax, [.y]
	mov bx, [.y2]
	cmp ax, bx
	je .done
	
	mov ax, [.x]
	mov cx, [.y]
	mov bl, [.colour]
	call os_set_pixel
	
	xor si, si
	mov di, [.balance]
	cmp di, si
	jl .yloop1
	
	mov ax, [.x]
	mov bx, [.incx]
	add ax, bx
	mov [.x], ax
	
	mov ax, [.balance]
	mov bx, [.dy]
	sub ax, bx
	mov [.balance], ax
	
.yloop1:
	mov ax, [.balance]
	mov bx, [.dx]
	add ax, bx
	mov [.balance], ax
	
	mov ax, [.y]
	mov bx, [.incy]
	add ax, bx
	mov [.y], ax
	
	jmp .yloop
	
	
	.x1 dw 0
	.y1 dw 0
	.x2 dw 0
	.y2 dw 0
	
	.x dw 0
	.y dw 0
	.dx dw 0
	.dy dw 0
	.incx dw 0
	.incy dw 0
	.balance dw 0
	.colour db 0
	.pad db 0
	
; Draw (straight) rectangle
; IN: CX=X1, DX=Y1, SI=X2, DI=Y2, BL=colour, CF = set if filled or clear if not
; OUT: None, registers preserved
os_draw_rectangle:
	pusha
	pushf
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	
	;inc byte [internal_call]
	
	mov word [.x1], cx
	mov word [.y1], dx
	mov word [.x2], si
	mov word [.y2], di
	
	; top line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y1]
	call os_draw_line
	
	; left line
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x1]
	mov di, [.y2]
	call os_draw_line
	
	; right line
	mov cx, [.x2]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line

	; bottom line
	mov cx, [.x1]
	mov dx, [.y2]
	mov si, [.x2]
	mov di, [.y2]
	call os_draw_line
	
	popf
	jnc .finished_fill
	
.fill_shape:
	inc word [.y1]
	
	mov ax, [.y1]
	cmp ax, [.y2]
	jge .finished_fill
	
	mov cx, [.x1]
	mov dx, [.y1]
	mov si, [.x2]
	mov di, [.y1]
	call os_draw_line
	
	jmp .fill_shape
	
.finished_fill:
	popa
	;dec byte [internal_call]
	ret
	
	.x1				dw 0
	.x2				dw 0
	.y1				dw 0
	.y2				dw 0

; Draw freeform shape
; IN: BH = number of points, BL = colour, SI = location of shape points data
; OUT: None, registers preserved
; DATA FORMAT: x1, y1, x2, y2, x3, y3, etc
os_draw_polygon:
	pusha
	
	;mov ax, 1000h
	;mov ds, ax
	;mov es, ax
	
	;inc byte [internal_call]
	
	dec bh
	mov byte [.points], bh
	
	mov word ax, [fs:si]
	add si, 2
	mov word [.xi], ax
	mov word [.xl], ax
	
	mov word ax, [fs:si]
	add si, 2
	mov word [.yi], ax
	mov word [.yl], ax
	
	.draw_points:
		mov cx, [.xl]
		mov dx, [.yl]
		
		mov word ax, [fs:si]
		add si, 2
		mov word [.xl], ax
		
		mov word ax, [fs:si]
		add si, 2
		mov word [.yl], ax
		
		push si
		
		mov si, [.xl]
		mov di, [.yl]
		
		call os_draw_line
		
		pop si
		
		dec byte [.points]
		cmp byte [.points], 0
		jne .draw_points
		
	mov cx, [.xl]
	mov dx, [.yl]
	mov si, [.xi]
	mov di, [.yi]
	call os_draw_line
	
	popa
	;dec byte [internal_call]
	ret
	
	.xi				dw 0
	.yi				dw 0
	.xl				dw 0
	.yl				dw 0
	.points				db 0
	

; Clear the screen by setting all pixels to a single colour
; BL = colour to set
os_clear_graphics:
	pusha
	
	mov ax, 0xA000
	mov es, ax

	mov al, bl
	mov di, 0
	mov cx, 64000
	rep stosb

	popa
	ret
	
	
; ----------------------------------------
; os_draw_circle -- draw a circular shape
; IN: AL = colour, BX = radius, CX = middle X, DX = middle y

os_draw_circle:
	pusha

	;push gs
	;pop ds
	
	;inc byte [internal_call]

	mov [.colour], al
	mov [.radius], bx
	mov [.x0], cx
	mov [.y0], dx

	mov [.x], bx
	mov word [.y], 0
	mov ax, 1
	shl bx, 1
	sub ax, bx
	mov [.xChange], ax
	mov word [.yChange], 0
	mov word [.radiusError], 0
jmp .next_point
	
.finish:
	popa
	;dec byte [internal_call]
	ret
	
.next_point:
	cmp cx, dx
	jl .finish

	;ax bx - function points
	;cx = x 
	;dx = y
	;si = -x
	;di = -y

	mov cx, [.x]
	mov dx, [.y]
	mov si, cx
	xor si, 0xFFFF
	inc si
	mov di, dx
	xor di, 0xFFFF
	inc di

	; (x + x0, y + y0)
	mov ax, cx
	mov bx, dx
	call .draw_point

	; (y + x0, x + y0)
	xchg ax, bx
	call .draw_point

	; (-x + x0, y + y0)
	mov ax, si
	mov bx, dx
	call .draw_point

	; (-y + x0, x + y0)
	mov ax, di
	mov bx, cx
	call .draw_point

	; (-x + x0, -y + y0)
	mov ax, si
	mov bx, di
	call .draw_point

	; (-y + x0, -x + y0)
	xchg ax, bx
	call .draw_point

	; (x + x0, -y + y0)
	mov ax, cx
	mov bx, di
	call .draw_point

	; (y + x0, -x + y0)
	mov ax, dx
	mov bx, si
	call .draw_point
	
	inc word [.y]
	mov ax, [.yChange]
	add [.radiusError], ax
	add word [.yChange], 2
	
	mov ax, [.radiusError]
	shl ax, 1
	add ax, [.xChange]
	
	mov cx, [.x]
	mov dx, [.y]
	
	cmp ax, 0
	jle .next_point
	
	dec word [.x]
	mov ax, [.xChange]
	add [.radiusError], ax
	add word [.xChange], 2

	mov cx, [.x]
	jmp .next_point

.draw_point:
	; AX = X, BX = Y
	pusha
	add ax, [.x0]
	add bx, [.y0]
	mov cx, bx
	mov bl, [.colour]
	call os_set_pixel
	popa
	ret

.colour				db 0
.x0				dw 0
.y0				dw 0
.radius				dw 0
.x				dw 0
.y				dw 0
.xChange			dw 0
.yChange			dw 0
.radiusError			dw 0

; ; ------------------------------------------------------------------
; ; os_draw_border -- draw a single character border
; ; BL = colour, CH = start row, CL = start column, DH = end row, DL = end column

; os_draw_border:
	; pusha
	
	; ;mov ax, 0x1000
	; ;mov ds, ax
	
	; ;inc byte [internal_call]

	; mov [.start_row], ch
	; mov [.start_column], cl
	; mov [.end_row], dh
	; mov [.end_column], dl

	; mov al, [.end_column]
	; sub al, [.start_column]
	; dec al
	; mov [.width], al
	
	; mov al, [.end_row]
	; sub al, [.start_row]
	; dec al
	; mov [.height], al
	
	; mov ah, 09h
	; mov bh, 0
	; mov cx, 1

	; mov dh, [.start_row]
	; mov dl, [.start_column]
	; call os_move_cursor

	; mov al, [.character_set + 0]
	; int 10h
	
	; mov dh, [.start_row]
	; mov dl, [.end_column]
	; call os_move_cursor
	
	; mov al, [.character_set + 1]
	; int 10h
	
	; mov dh, [.end_row]
	; mov dl, [.start_column]
	; call os_move_cursor
	
	; mov al, [.character_set + 2]
	; int 10h
	
	; mov dh, [.end_row]
	; mov dl, [.end_column]
	; call os_move_cursor
	
	; mov al, [.character_set + 3]
	; int 10h
	
	; mov dh, [.start_row]
	; mov dl, [.start_column]
	; inc dl
	; call os_move_cursor
	
	; mov al, [.character_set + 4]
	; mov cx, 0
	; mov cl, [.width]
	; int 10h
	
	; mov dh, [.end_row]
	; call os_move_cursor
	; int 10h
	
	; mov al, [.character_set + 5]
	; mov cx, 1
	; mov dh, [.start_row]
	; inc dh
	
; .sides_loop:
	; mov dl, [.start_column]
	; call os_move_cursor
	; int 10h
	
	; mov dl, [.end_column]
	; call os_move_cursor
	; int 10h
	
	; inc dh
	; dec byte [.height]
	; cmp byte [.height], 0
	; jne .sides_loop
	
	; popa
	; ;dec byte [internal_call]
	; ret
	
	
; .start_column				db 0
; .end_column				db 0
; .start_row				db 0
; .end_row				db 0
; .height					db 0
; .width					db 0

; .character_set				db 218, 191, 192, 217, 196, 179

os_run_basic:
mov di,found
mov si,ImageName
mov cx,0x000B
mov al,0
stosb
mov byte [getstr.end],0
pop ax
jmp command_received

; ==================================================================

os_set_time_fmt:
os_set_date_fmt:
os_get_time_string:
os_get_date_string:
mov bx,c_clock
ret

os_string_chomp:
os_bcd_to_int:

os_dump_registers:

os_dump_string:
os_print_digit:
os_long_int_negate:

;os_draw_rectangle:
os_draw_border:

os_square_root:
db 0xCC
ret

; ------------------------------------------------------------------
; os_print_horiz_line -- Draw a horizontal line on the screen
; IN: AX = line type (1 for double (-), otherwise single (=))
; OUT: Nothing (registers preserved)

os_print_horiz_line:
	pusha

	mov cx, ax			; Store line type param
	mov al, 196			; Default is single-line code

	cmp cx, 1			; Was double-line specified in AX?
	jne .ready
	mov al, 205			; If so, here's the code

.ready:
	mov cx, 0			; Counter
	mov ah, 0Eh			; BIOS output char routine

.restart:
	int 10h
	inc cx
	cmp cx, 80			; Drawn 80 chars yet?
	je .done
	jmp .restart

.done:
	popa
	ret
	
; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = width, BL = colour, DH = start row, DL = start column

os_draw_horizontal_line:
	pusha
		
	mov cx, 0
	mov cl, bh
	
	call os_move_cursor
	
	mov ah, 09h
	mov al, 196
	mov bh, 0
	int 10h

	popa
	ret
	
; ------------------------------------------------------------------
; os_draw_horizontal_line - draw a horizontal between two points
; IN: BH = length, BL = colour, DH = start row, DL = start column

os_draw_vertical_line:
	pusha
		
	mov cx, 0
	mov cl, bh
	
	mov ah, 09h
	mov al, 179
	mov bh, 0
	
.lineloop:
	push cx
	
	call os_move_cursor
	
	mov cx, 1
	int 10h
	
	inc dh
	
	pop cx
	
	loop .lineloop

	popa
	ret

; ------------------------------------------------------------------
; os_find_char_in_string -- Find location of character in a string
; IN: SI = string location, AL = character to find
; OUT: AX = location in string, or 0 if char not present

os_find_char_in_string:
	pusha

	mov cx, 1			; Counter -- start at first char (we count
					; from 1 in chars here, so that we can
					; return 0 if the source char isn't found)

.more:
	cmp byte [si], al
	je .done
	cmp byte [si], 0
	je .notfound
	inc si
	inc cx
	jmp .more

.done:
	mov [.tmp], cx
	popa
	mov ax, [.tmp]
	ret

.notfound:
	popa
	mov ax, 0
	ret


	.tmp	dw 0


; ------------------------------------------------------------------
; os_string_charchange -- Change instances of character in a string
; IN: SI = string, AL = char to find, BL = char to replace with

os_string_charchange:
	pusha

	mov cl, al

.loop:
	mov byte al, [si]
	cmp al, 0
	je .finish
	cmp al, cl
	jne .nochange

	mov byte [si], bl

.nochange:
	inc si
	jmp .loop

.finish:
	popa
	ret

; ------------------------------------------------------------------
; os_serial_port_enable -- Set up the serial port for transmitting data
; IN: AX = 0 for normal mode (9600 baud), or 1 for slow mode (1200 baud)

os_serial_port_enable:
	pusha

	mov dx, 0			; Configure serial port 1
	cmp ax, 1
	je .slow_mode

	mov ah, 0
	mov al, 11100011b		; 9600 baud, no parity, 8 data bits, 1 stop bit
	jmp .finish

.slow_mode:
	mov ah, 0
	mov al, 10000011b		; 1200 baud, no parity, 8 data bits, 1 stop bit	

.finish:
	int 14h

	popa
	ret


; ------------------------------------------------------------------
; os_send_via_serial -- Send a byte via the serial port
; IN: AL = byte to send via serial; OUT: AH = Bit 7 clear on success

os_send_via_serial:
	pusha

	mov ah, 01h
	mov dx, 0			; COM1

	int 14h

	mov [.tmp], ax

	popa

	mov ax, [.tmp]

	ret


	.tmp dw 0


; ------------------------------------------------------------------
; os_get_via_serial -- Get a byte from the serial port
; OUT: AL = byte that was received; OUT: AH = Bit 7 clear on success

os_get_via_serial:
	pusha

	mov ah, 02h
	mov dx, 0			; COM1

	int 14h

	mov [.tmp], ax

	popa

	mov ax, [.tmp]

	ret


	.tmp dw 0


; ==================================================================


; ------------------------------------------------------------------
; os_draw_background -- Clear screen with white top and bottom bars
; containing text, and a coloured middle section.
; IN: AX/BX = top/bottom string locations, CX = colour

os_draw_background:
	pusha

	push ax				; Store params to pop out later
	push bx
	push cx

	mov dl, 0
	mov dh, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 80
	mov bl, 01110000b
	mov al, ' '
	int 10h

	mov dh, 1
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw colour section
	mov cx, 1840
	pop bx				; Get colour param (originally in CX)
	mov bh, 0
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 0
	call os_move_cursor

	mov ah, 09h			; Draw white bar at bottom
	mov bh, 0
	mov cx, 80
	mov bl, 01110000b
	mov al, ' '
	int 10h

	mov dh, 24
	mov dl, 1
	call os_move_cursor
	pop bx				; Get bottom string param
	mov si, bx
	call os_print_string

	mov dh, 0
	mov dl, 1
	call os_move_cursor
	pop ax				; Get top string param
	mov si, ax
	call os_print_string

	mov dh, 1			; Ready for app text
	mov dl, 0
	call os_move_cursor

	popa
	ret

; ------------------------------------------------------------------
; os_draw_block -- Render block of specified colour
; IN: BL/DL/DH/SI/DI = colour/start X pos/start Y pos/width/finish Y pos

os_draw_block:
	pusha

.more:
	call os_move_cursor		; Move to block starting position

	mov ah, 09h			; Draw colour section
	mov bh, 0
	mov cx, si
	mov al, ' '
	int 10h

	inc dh				; Get ready for next line

	mov ax, 0
	mov al, dh			; Get current Y position into DL
	cmp ax, di			; Reached finishing point (DI)?
	jne .more			; If not, keep drawing

	popa
	ret
	
; ------------------------------------------------------------------
; os_list_dialog -- Show a dialog with a list of options
; IN: AX = comma-separated list of strings to show (zero-terminated),
;     BX = first help string, CX = second help string
; OUT: AX = number (starts from 1) of entry selected; carry set if Esc pressed

os_list_dialog:
	pusha

	push ax				; Store string list for now

	push cx				; And help strings
	push bx

	call os_hide_cursor


	mov cl, 0			; Count the number of entries in the list
	mov si, ax
.count_loop:
	lodsb
	;cmp word [si], 0
	cmp al, 0
	je .done_count
	cmp al, ','
	jne .count_loop
	inc cl
	jmp .count_loop

.done_count:
	inc cl
	mov byte [.num_of_entries], cl


	mov bl, 01001111b		; White on red
	mov dl, 20			; Start X position
	mov dh, 2			; Start Y position
	mov si, 40			; Width
	mov di, 23			; Finish Y position
	call os_draw_block		; Draw option selector window

	mov dl, 21			; Show first line of help text...
	mov dh, 3
	call os_move_cursor

	pop si				; Get back first string
	call os_print_string

	inc dh				; ...and the second
	call os_move_cursor

	pop si
	call os_print_string


	pop si				; SI = location of option list string (pushed earlier)
	mov word [.list_string], si


	; Now that we've drawn the list, highlight the currently selected
	; entry and let the user move up and down using the cursor keys

	mov byte [.skip_num], 0		; Not skipping any lines at first showing

	mov dl, 25			; Set up starting position for selector
	mov dh, 7

	call os_move_cursor

.more_select:
	pusha
	mov bl, 11110000b		; Black on white for option list box
	mov dl, 21
	mov dh, 6
	mov si, 38
	mov di, 22
	call os_draw_block
	popa

	call .draw_black_bar

	mov word si, [.list_string]
	call .draw_list

.another_key:
	call os_wait_for_key		; Move / select option
	cmp ah, 48h			; Up pressed?
	je .go_up
	cmp ah, 50h			; Down pressed?
	je .go_down
	cmp al, 13			; Enter pressed?
	je .option_selected
	cmp al, ' '			; Space pressed?
	je .option_selected_with_arg
	cmp al, 27			; Esc pressed?
	je .esc_pressed
	; cmp al,1			; Up pressed?
	; je .go_up
	; cmp al,2			; Down pressed?
	; je .go_down
	cmp al,'w'			; Up pressed?
	je .go_up
	cmp al,'s'			; Down pressed?
	je .go_down
	cmp al,'W'			; Up pressed?
	je .go_up
	cmp al,'S'			; Down pressed?
	je .go_down
	cmp ah,0x51
	je .page_down
	cmp ah,0x49
	je .page_up
	jmp .more_select		; If not, wait for another key

.page_down:
mov ax,0x5000
jmp .keystore

.page_up:
mov ax,0x4800
;jmp .keystore

.keystore:
mov cx,[length]
.keystore_loop:
call keybsto
loop .keystore_loop
jmp .more_select

.go_up:
call os_get_cursor_pos
	cmp dh, 7			; Already at top?
	jle .hit_top

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	dec dh				; Row to select (increasing down)
	jmp .more_select


.go_down:				; Already at bottom of list?
call os_get_cursor_pos
	cmp dh, 20
	je .hit_bottom

	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	call .draw_white_bar

	mov dl, 25
	call os_move_cursor

	inc dh
	jmp .more_select


.hit_top:
	mov byte cl, [.skip_num]	; Any lines to scroll up?
	cmp cl, 0
	je .another_key			; If not, wait for another key

	dec byte [.skip_num]		; If so, decrement lines to skip
	jmp .more_select


.hit_bottom:				; See if there's more to scroll
	mov cx, 0
	mov byte cl, dh

	sub cl, 7
	inc cl
	add byte cl, [.skip_num]

	mov byte al, [.num_of_entries]
	cmp cl, al
	je .another_key

	inc byte [.skip_num]		; If so, increment lines to skip
	jmp .more_select

.esc_pressed:
	call os_show_cursor
	call os_get_cursor_pos
	popa
	stc				; Set carry for Esc
	ret
.option_selected_with_arg:
mov byte [getstr.end],0x20
.option_selected:
	call os_show_cursor
	call os_get_cursor_pos

	sub dh, 7

	mov ax, 0
	mov al, dh

	inc al				; Options start from 1
	add byte al, [.skip_num]	; Add any lines skipped from scrolling

	mov word [.tmp], ax		; Store option number before restoring all other regs

	popa

	mov word ax, [.tmp]
	clc				; Clear carry as Esc wasn't pressed
	ret



.draw_list:
	pusha

	mov dl, 23			; Get into position for option list text
	mov dh, 7
	call os_move_cursor


	mov cx, 0			; Skip lines scrolled off the top of the dialog
	mov byte cl, [.skip_num]

.skip_loop:
	cmp cx, 0
	je .skip_loop_finished
.more_lodsb:
	lodsb
	cmp al, ','
	jne .more_lodsb
	dec cx
	jmp .skip_loop


.skip_loop_finished:
	mov bx, 0			; Counter for total number of options


.more:
	lodsb				; Get next character in file name, increment pointer

	;cmp word [si], 0			; End of string?
	cmp al, 0			; End of string?
	je .done_list

	cmp al, ','			; Next option? (String is comma-separated)
	je .newline

	mov ah, 0Eh
	int 10h
	jmp .more

.newline:
	mov dl, 23			; Go back to starting X position
	inc dh				; But jump down a line
	call os_move_cursor

	inc bx				; Update the number-of-options counter
	cmp bx, 14			; Limit to one screen of options
	jl .more

.done_list:
	popa
	call os_move_cursor

	ret



.draw_black_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, 00001111b		; White text on black background
	mov al, ' '
	int 10h

	popa
	ret



.draw_white_bar:
	pusha

	mov dl, 22
	call os_move_cursor

	mov ah, 09h			; Draw white bar at top
	mov bh, 0
	mov cx, 36
	mov bl, 11110000b		; Black text on white background
	mov al, ' '
	int 10h

	popa
	ret


	.tmp			dw 0
	.num_of_entries		db 0
	.skip_num		db 0
	.list_string		dw 0

; ------------------------------------------------------------------
; os_input_dialog -- Get text string from user via a dialog box
; IN: AX = string location, BX = message to show; OUT: AX = string location

os_input_dialog:
	pusha

	push ax				; Save string location
	push bx				; Save message to show


	mov dh, 10			; First, draw red background box
	mov dl, 12

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 55
	mov bl, 01001111b		; White on red
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	mov dl, 14
	mov dh, 11
	call os_move_cursor


	pop bx				; Get message back and display it
	mov si, bx
	call os_print_string

	mov dl, 14
	mov dh, 13
	call os_move_cursor


	pop ax				; Get input string back
	call os_input_string

	popa
	ret


; ------------------------------------------------------------------
; os_dialog_box -- Print dialog box in middle of screen, with button(s)
; IN: AX, BX, CX = string locations (set registers to 0 for no display)
; IN: DX = 0 for single 'OK' dialog, 1 for two-button 'OK' and 'Cancel'
; OUT: If two-button mode, AX = 0 for OK and 1 for cancel
; NOTE: Each string is limited to 40 characters

os_dialog_box:
	pusha

	mov [.tmp], dx

	call os_hide_cursor

	mov dh, 9			; First, draw red background box
	mov dl, 19

.redbox:				; Loop to draw all lines of box
	call os_move_cursor

	pusha
	mov ah, 09h
	mov bh, 0
	mov cx, 42
	mov bl, 01001111b		; White on red
	mov al, ' '
	int 10h
	popa

	inc dh
	cmp dh, 16
	je .boxdone
	jmp .redbox


.boxdone:
	cmp ax, 0			; Skip string params if zero
	je .no_first_string
	mov dl, 20
	mov dh, 10
	call os_move_cursor

	mov si, ax			; First string
	call os_print_string

.no_first_string:
	cmp bx, 0
	je .no_second_string
	mov dl, 20
	mov dh, 11
	call os_move_cursor

	mov si, bx			; Second string
	call os_print_string

.no_second_string:
	cmp cx, 0
	je .no_third_string
	mov dl, 20
	mov dh, 12
	call os_move_cursor

	mov si, cx			; Third string
	call os_print_string

.no_third_string:
	mov dx, [.tmp]
	; cmp dx, 0
	; je .one_button
	cmp dx, 1
	je .two_button
	cmp dx, 2
	je .two_button

.one_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 35
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 38			; OK button, centred at bottom of box
	mov dh, 14
	call os_move_cursor
	mov si, .ok_button_string
	call os_print_string

	jmp .one_button_wait


.two_button:
	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	call .get_button_string_one
	call os_print_string

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	call .get_button_string_two
	call os_print_string

	mov cx, 0			; Default button = 0
	jmp .two_button_wait



.one_button_wait:
	call os_wait_for_key
	cmp al, 13			; Wait for enter key (13) to be pressed
	je .one_button_wait_done
	cmp ah,0x01
	je .one_button_wait_done
	jmp .one_button_wait
.one_button_wait_done:
	call os_show_cursor

	popa
	ret


.two_button_wait:
	call os_wait_for_key

	cmp ah, 75			; Left cursor key pressed?
	jne .noleft

	mov bl, 11110000b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	call .get_button_string_one
	call os_print_string

	mov bl, 01001111b		; White on red for cancel button
	mov dh, 14
	mov dl, 42
	mov si, 9
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	call .get_button_string_two
	call os_print_string

	mov cx, 0			; And update result we'll return
	jmp .two_button_wait


.noleft:
	cmp ah, 77			; Right cursor key pressed?
	jne .noright


	mov bl, 01001111b		; Black on white
	mov dh, 14
	mov dl, 27
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 30			; OK button
	mov dh, 14
	call os_move_cursor
	call .get_button_string_one
	call os_print_string

	mov bl, 11110000b		; White on red for cancel button
	mov dh, 14
	mov dl, 43
	mov si, 8
	mov di, 15
	call os_draw_block

	mov dl, 44			; Cancel button
	mov dh, 14
	call os_move_cursor
	call .get_button_string_two
	call os_print_string

	mov cx, 1			; And update result we'll return
	jmp .two_button_wait


.noright:
	cmp al, 13			; Wait for enter key (13) to be pressed
	jne .two_button_wait

	call os_show_cursor

	mov [.tmp], cx			; Keep result after restoring all regs
	popa
	mov ax, [.tmp]

	ret

.get_button_string_one:
cmp [.tmp],2
je .string_one_switch
mov si, .ok_button_string
ret
.string_one_switch:
mov si,.on_button_string
ret

.get_button_string_two:
cmp [.tmp],2
je .string_two_switch
mov si, .cancel_button_string
ret
.string_two_switch:
mov si,.off_button_string
ret
	
	.ok_button_string	db 'OK', 0
	.cancel_button_string	db 'Cancel', 0
	; .ok_button_noselect	db '   OK   ', 0
	; .cancel_button_noselect	db '   Cancel   ', 0

.on_button_string	db 'On', 0
.off_button_string	db ' Off', 0

	.tmp dw 0
	
mouse_wait_0:
	mov cx, 65000
	mov dx, 0x64
.wait:
	in al, dx
	bt ax, 0
	jc .okay
	loop .wait
.okay:
	ret
	
; ---------------------------------

mouse_wait_1:
	mov cx, 65000
	mov dx, 0x64
.wait:
	in al, dx
	bt ax, 1
	jnc .okay
	loop .wait
.okay:
	ret
	
; -----------------------------------------------------
; mouse_write --- write a value to the mouse controller
; IN: AH = byte to send

mouse_write:
	; Wait to be able to send a command
	call mouse_wait_1
	; Tell the mouse we are sending a command
	mov al, 0xD4
	out 0x64, al
	; Wait for the final part
	call mouse_wait_1
	; Finally write
	mov al, ah
	out 0x60, al
	ret
	
; -----------------------------------------------------
; mouse_read --- read a value from the mouse controller
; OUT: AL = value

mouse_read:
	; Get the response from the mouse
	call mouse_wait_0
	in al, 0x60
	ret
	
; -----------------------------------------------------
; os_mouse_setup --- setup the mouse driver
; IN/OUT: none

os_mouse_setup:
	pusha
	
	; Enable the auxiliary mouse device
	call mouse_wait_1
	mov al, 0xA8
	out 0x64, al
	
	; Enable the interrupts
	call mouse_wait_1
	mov al, 0x20
	out 0x64, al
	call mouse_wait_0
	in al, 0x60
	or al, 0x02
	mov bl, al
	call mouse_wait_1
	mov al, 0x60
	out 0x64, al
	call mouse_wait_1
	mov al, bl
	out 0x60, al
	
	; Tell the mouse to use default settings
	mov ah, 0xF6
	call mouse_write
	call mouse_read		; Acknowledge
	
	; Enable the mouse
	mov ah, 0xF4
	call mouse_write
	call mouse_read		; Acknowledge
	
	; Setup the mouse handler
	cli
	push es
	mov ax, 0x0000
	mov es, ax
	mov word [es:0x01D0], mouse_handler
	mov word [es:0x01D2], 0x00
	pop es
	sti
	
	popa
	ret

	
; ----------------------------------------
; TachyonOS Mouse Driver
	
mouse_handler:
	cli

	pusha
	push ds
	
	;mov ax, 0x1000
	;mov ds, ax
	mov ax, 0
	mov ds, ax
	
	; Check that data is available for the mouse
	in al, 0x64
	bt ax, 5
	jnc .finish

	cmp byte [.number], 0
	je .data_byte
	
	cmp byte [.number], 1
	je .x_byte
	
	cmp byte [.number], 2
	je .y_byte

.data_byte:
	in al, 0x60
 	mov [mouse_data], al
 	
;  	bt ax, 3
;  	jc .alignment
 	
 	mov byte [.number], 1
 	jmp .finish
 	
.alignment:
	mov byte [.number], 0
	jmp .finish
 	
.x_byte:
	in al, 0x60
	mov [mouse_delta_x], al
	mov byte [.number], 2
	.finish_link:
	jmp .finish
	
	.zero_x:
	mov word [mouse_x_raw], 0
	jmp .scale_x
	
.y_byte:
	in al, 0x60
	mov [mouse_delta_y], al
	mov byte [.number], 0

; Now we have the entire packet it is time to process its data.
; We want to figure out the new X and Y co-ordinents and which buttons are pressed.
	
.process_packet:
	mov ax, 0
	mov bx, 0
	mov bl, [mouse_data]
	test bx, 0x00C0			; If x-overflow or y-overflow is set ignore packet
	jnz .finish_link

	; Mark there has been a change in mouse position
	mov byte [mouse_changed], 1
	
	; Get the movement values
	mov cx, 0
	mov cl, [mouse_delta_x]
	mov dx, 0
	mov dl, [mouse_delta_y]
	
	; Check data byte for the X sign flag
	bt bx, 4
	jc .negative_delta_x

	; Add the movement speed to the raw position
	add [mouse_x_raw], cx
	jmp .scale_x
	
.negative_delta_x:
	xor cl, 0xFF
	inc cl

	cmp cx, [mouse_x_raw]
	jg .zero_x
	
	sub [mouse_x_raw], cx
	
.scale_x:
	; Scale raw position to find the cursor position
	mov cx, [mouse_x_raw]
	
	mov ax, cx
	mov cl, [mouse_x_scale]
	shr ax, cl
	mov cx, ax
	mov [mouse_x_position], cx
	
.check_x_boundries:
	cmp cx, [mouse_x_minimum]
	jl .fix_x_minimum
	
	cmp cx, [mouse_x_limit]
	jg .fix_x_limit
	
.find_y_position:
	bt bx, 5			; Check data byte for the Y sign flag
	jc .negative_delta_y
	
	cmp dx, [mouse_y_raw]
	jg .zero_y
	
	sub [mouse_y_raw], dx
	jmp .scale_y
	
.negative_delta_y:
	xor dl, 0xFF
	inc dl
		
	add [mouse_y_raw], dx
	
.scale_y:
	mov dx, [mouse_y_raw]
	
	mov cl, [mouse_y_scale]
	shr dx, cl
	mov [mouse_y_position], dx
	
.check_y_boundries:
	cmp dx, [mouse_y_minimum]
	jl .fix_y_minimum
	
	cmp dx, [mouse_y_limit]
	jg .fix_y_limit
	
.check_buttons:
	bt bx, 0
	jc .left_mouse_pressed
	
	mov byte [mouse_button_left], 0
	
	bt bx, 2
	jc .middle_mouse_pressed
	
	mov byte [mouse_button_middle], 0
	
	bt bx, 1
	jc .right_mouse_pressed
	
	mov byte [mouse_button_right], 0
	
.finish:
	mov al, 0x20			; End Of Interrupt (EOI) command
	out 0x20, al			; Send EOI to master PIC
	out 0xa0, al			; Send EOI to slave PIC
	
	pop ds
	popa
	sti
	iret
	
	.number				db 0
	
.fix_x_minimum:
	mov cx, [mouse_x_minimum]
	mov [mouse_x_position], cx
	
	mov ax, cx
	mov cl, [mouse_x_scale]
	shl ax, cl
	mov [mouse_x_raw], ax

	jmp .find_y_position
	
.fix_x_limit:
	mov cx, [mouse_x_limit]
	mov [mouse_x_position], cx
	
	mov ax, cx
	mov cl, [mouse_x_scale]
	shl ax, cl
	mov [mouse_x_raw], ax
	
	jmp .find_y_position
	
.zero_y:
	mov word [mouse_y_raw], 0
	jmp .scale_y
	
.fix_y_minimum:
	mov dx, [mouse_y_minimum]
	mov [mouse_y_position], dx
	
	mov cl, [mouse_y_scale]
	shl dx, cl
	mov [mouse_y_raw], dx
	
	jmp .check_buttons
	
.fix_y_limit:
	mov dx, [mouse_y_limit]
	mov [mouse_y_position], dx
	
	mov cl, [mouse_y_scale]
	shl dx, cl
	mov [mouse_y_raw], dx
	
	jmp .check_buttons
	
.left_mouse_pressed:
	mov byte [mouse_button_left], 1
	
	bt bx, 2
	jc .middle_mouse_pressed
	
	mov byte [mouse_button_middle], 0
	
	bt bx, 1
	jc .right_mouse_pressed
	
	mov byte [mouse_button_right], 0
	
	jmp .finish
	
.middle_mouse_pressed:
	mov byte [mouse_button_middle], 1
	
	bt bx, 1
	jc .right_mouse_pressed
	
	mov byte [mouse_button_right], 0
	
	jmp .finish
	
.right_mouse_pressed:
	mov byte [mouse_button_right], 1
	
	jmp .finish
	
	
; --------------------------------------------------
; os_mouse_locate -- return the mouse co-ordinents
; IN: none
; OUT: CX = Mouse X, DX = Mouse Y
	
os_mouse_locate:
	mov cx, [gs:mouse_x_position]
	mov dx, [gs:mouse_y_position]
	
	ret

	
; --------------------------------------------------
; os_mouse_move -- set the mouse co-ordinents
; IN: CX = Mouse X, DX = Mouse Y
; OUT: none

os_mouse_move:
	pusha
	
	mov ax, cx
	mov [gs:mouse_x_position], ax
	mov [gs:mouse_y_position], dx
	
	mov cl, [gs:mouse_x_scale]
	shl ax, cl
	mov [gs:mouse_x_raw], ax
	
	mov cl, [gs:mouse_y_scale]
	shl dx, cl
	mov [gs:mouse_y_raw], dx
	
	popa
	ret


; --------------------------------------------------
; os_mouse_show -- shows the cursor at current position
; IN: none
; OUT: none

os_mouse_show:
	push ax
;	mov ax, 0x1000
	;mov ds, ax
	cmp byte [mouse_cursor_on], 1
	je .already_on
	
	mov ax, [mouse_x_position]
	mov [mouse_cursor_x], ax
	
	mov ax, [mouse_y_position]
	mov [mouse_cursor_y], ax
	
	call mouse_toggle
	
	mov byte [mouse_cursor_on], 1
	
	pop ax
	
.already_on:
	ret
	

; --------------------------------------------------
; os_mouse_hide -- hides the cursor
; IN: none
; OUT: none
	
os_mouse_hide:
	;push ax
	;mov ax, 0x1000
	;mov ds, ax
;	pop ax

	cmp byte [mouse_cursor_on], 0
	je .already_off
	
	call mouse_toggle
	
	mov byte [mouse_cursor_on], 0
	
.already_off:
	ret
	

mouse_toggle:
	pusha
	
	; Backup cursor position
	mov ah, 03h
	mov bh, 0
	int 10h
	push dx
	
	; Move the cursor into mouse position
	mov ah, 02h
	mov bh, 0
	mov byte dh,[mouse_cursor_y]
	mov byte dl,[mouse_cursor_x]
	int 10h
	
	; Find the colour of the character
	mov ah, 08h
	mov bh, 0
	int 10h
	
	; Invert it to get its opposite
	not ah
	
	; Display new character
	mov bl, ah
	mov ah, 09h
	mov bh, 0
	mov cx, 1
	int 10h
	
	; Restore the cursor position
	mov ah, 02h
	mov bh, 0
	pop dx
	int 10h
	
	popa
	ret

; --------------------------------------------------
; os_mouse_range -- sets the range maximum and 
;	minimum positions for mouse movement
; IN: AX = min X, BX = min Y, CX = max X, DX = max Y
; OUT: none

os_mouse_range:
	mov [gs:mouse_x_minimum], ax
	mov [gs:mouse_y_minimum], bx
	mov [gs:mouse_x_limit], cx
	mov [gs:mouse_y_limit], dx
	
	ret
	
	
; --------------------------------------------------
; os_mouse_wait -- waits for a mouse event
; IN: none
; OUT: none

os_mouse_wait:
	mov byte [gs:mouse_changed], 0
	
.wait:
	hlt
	cmp byte [gs:mouse_changed], 1
	je .done
	
	jmp .wait

.done:
	ret

	
; --------------------------------------------------
; os_mouse_anyclick -- check if any mouse button is pressed
; IN: none
; OUT: none

os_mouse_anyclick:
	cmp byte [gs:mouse_button_left], 1
	je .click
	
	cmp byte [gs:mouse_button_middle], 1
	je .click
	
	cmp byte [gs:mouse_button_right], 1
	je .click
	
	clc
	ret
	
.click:
	stc
	ret
	

; --------------------------------------------------
; os_mouse_leftclick -- checks if the left mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

os_mouse_leftclick:
	cmp byte [gs:mouse_button_left], 1
	je .pressed
	
	clc
	ret
	
.pressed:
	stc
	ret


; --------------------------------------------------
; os_mouse_middleclick -- checks if the middle mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

os_mouse_middleclick:
	cmp byte [gs:mouse_button_middle], 1
	je .pressed
	
	clc
	ret
	
.pressed:
	stc
	ret
	
	
; --------------------------------------------------
; os_mouse_rightclick -- checks if the right mouse button is pressed
; IN: none
; OUT: CF = set if pressed, otherwise clear

os_mouse_rightclick:
	cmp byte [gs:mouse_button_right], 1
	je .pressed
	
	clc
	ret
	
.pressed:
	stc
	ret
	
	
; ------------------------------------------------------------------
; os_input_wait -- waits for mouse or keyboard input
; IN: none
; OUT: CF = set if keyboard, clear if mouse

os_input_wait:
	push ax
	
	mov byte [gs:mouse_changed], 0
	
.input_wait:
	; Check with BIOS if there is a keyboard key available
	mov ah, 11h
	int 16h
	jnz .keyboard_input
	
	; Check with mouse driver if the mouse has sent anything
	cmp byte [gs:mouse_changed], 1
	je .mouse_input
	
	hlt
	
	jmp .input_wait
	
.keyboard_input:
	pop ax
	stc
	ret
	
.mouse_input:
	pop ax
	clc
	ret
	
	
; ------------------------------------------------------------------
; os_mouse_scale -- scale mouse movment speed as 1:2^X
; IN: DL = mouse X scale, DH = mouse Y scale

os_mouse_scale:
	mov [gs:mouse_x_scale], dl
	mov [gs:mouse_y_scale], dh
	ret


mouse_data				db 0
mouse_delta_x				db 0
mouse_delta_y				db 0
mouse_x_raw				dw 0
mouse_y_raw				dw 0
mouse_x_scale				db 0
mouse_y_scale				db 0
mouse_x_position			dw 0
mouse_y_position			dw 0
mouse_x_minimum				dw 0
mouse_x_limit				dw 0
mouse_y_minimum				dw 0
mouse_y_limit				dw 0
mouse_button_left			db 0
mouse_button_middle			db 0
mouse_button_right			db 0
mouse_cursor_on				db 0
mouse_cursor_x:				dw 0
mouse_cursor_y:				dw 0
mouse_changed				db 0

;os_return:
;	ret

; int2ch:
; xor ax,ax
; mov ds,ax
; mov es,ax

; mov si,bx
; mov di,dx
; push cx

; call color_switch

; call getpos
; ;push dx
; ;pop bx
; mov bx,dx
; pop dx
; push bx
; push dx
; call setpos
; call storeline
; pop dx
; push dx
; call setpos
; call prnstr
; call getkey
; call colon
; mov si,di
; call prnstr
; call getkey
; call color_switch
; pop dx
; call setpos
; call restoreline
; pop dx
; call setpos
; mov al,0x2c
; call ackport

; iret

int33h:
pusha
mov al,0x33
call ackport
xor ax,ax
mov ds,ax
mov es,ax
popa

cmp ah,0x00
je int33_mouse_setup
cmp ah,0x01
je int33_show_mouse
cmp ah,0x02
je int33_hide_mouse
cmp ah,0x03
je int33_mouse_pos
cmp ah,0x04
je int33_move_mouse

cmp ah,0x07
je int33_mouse_horzlimit
cmp ah,0x08
je int33_mouse_vertlimit
cmp ah,0x21;33
je int33_mouse_setup

call debug_int
iret

int33_show_mouse:
call os_mouse_show
iret
int33_hide_mouse:
call os_mouse_hide
iret
int33_mouse_pos:
mov bx,0
call os_mouse_anyclick
jc .click
jmp .done
.click:
call os_mouse_leftclick
jc .left
jmp .clickright
.left:
add bx,1
.clickright:
call os_mouse_rightclick
jc .right
jmp .midclick
.right:
add bx,2
.midclick:
call os_mouse_middleclick
jc .middle
jmp .done
.middle:
add bx,4
.done:
;push bx
call os_mouse_locate
;pop bx
iret
int33_move_mouse:
call os_mouse_move
iret

int33_mouse_horzlimit:
mov [gs:mouse_x_minimum], cx
mov [gs:mouse_x_limit], dx
iret
int33_mouse_vertlimit:
mov [gs:mouse_y_minimum], cx
mov [gs:mouse_y_limit], dx
iret

int33_mouse_setup:
call os_mouse_setup
mov ax,0xffff
mov bx,2
iret

int4ah:
;mov cx,0xf000
;.emptyloop:
;cli
;nop
;dec cx
;loop .emptyloop
pusha
mov al,0x4a
call ackport
xor dx,dx
mov ds,dx
mov es,dx

mov ah,0x07
int 0x1a

call newline
mov si,alarmtextstr
call prnstr
call newline

popa
call debug_int
;call clrport64
call getkey
cmp ah,0x1C
je .int4ah_continue
pop ax
;pop ax
;xor ax,ax
;push ax
mov ax,kernel
push ax
iret
.int4ah_continue:
iret

;int08h:
;pusha
;xor dx,dx
;mov ds,dx
;mov es,dx

;mov ax,0x0e43
;int 10h

;mov al,0x08
;call ackport
;call clrport64
;popa
;cmp [EnableDigitized],1                  ;If it's set to 1, process next lines of code
;jne NoDigitizedSound                     ;If not, do the standard irq0 routine
   
;cmp al,0x80                                 ;If the byte taken from the memory is less than 80h,
                                                         ;turn off the speaker to prevent "unwanted" sounds,
;jb TurnOffBeeper                          ;like: ASCII strings (e.g. "WAVEfmt" signature etc).
;mov bx,[WAVSamplingRate]              ;Turn on the speaker with the WAV's sampling rate.
;mov bx,6000
;call Sound_On
;jmp Sound_Done
;TurnOffBeeper:
;call Sound_Off
;Sound_Done:
;inc esi                                         ;Increment ESI to load the next byte
;NoDigitizedSound:   
;iret

;Sound_On:                                     ; A routine to make sounds with BX = frequency in Hz
   ;mov ax,0x34dd                        ; The sound lasts until NoSound is called
   ;mov dx,0x0012                
   ;cmp dx,bx                
   ;jnc Done1               
   ;div bx                
   ;mov bx,ax
   ;in al,0x61
   ;test al,3
   ;jnz A99                
   ;or al,3                                 ;Turn on the speaker itself
   ;out 0x61,al                
   ;mov al,0xb6
   ;out 0x43,al
; A99:    
   ; mov al,bl 
   ; out 0x42,al              
   ; mov al,bh
   ; out 0x42,al
; Done1:
   ; ret

; Sound_Off:
   ; in al,0x61                 
   ; and al,11111100b                               ;Turn off the speaker
   ; out 0x61,al
   ; ret

; PlayWAV:
   ; ;mov [WAVSamplingRate],10000;;;;;;;;;;;Your sampling rate;;;;;;;;;;;;
   ; ;mov [WAVFileSize],;;;;;;;;;;;; Size of your WAV file ;;;;;;;;;;;;;
   ; ;mov esi,FileLoaded ;;;;;;;;;;;;;; ESI = offset where the file is ;;;;;;;;;;;;;
   ; mov esi,0x3000
   ; ;mov cx,[WAVSamplingRate]                    ;IRQ0 fires e.g. 6000 times a second
   ; mov cx,6000
   ; call ProgramPIT                                  ;when a 6000Hz WAV file is played. This is how
                                                              ; ;the speaker can play the digitized sound:
                                                              ; ;it turns on and off very fast with the specified
                                                              ; ;wave sample rate.
   ; ;mov ecx,[WAVFileSize]                         ;Sets the loop point
   ; xor dx,dx
   ; mov ax,[size]
   ; mov cx,0x0200
   ; mul cx
   ; xor ecx,ecx
   ; mov cx,ax
   ; ;mov ecx,0x00000800
   ; mov [EnableDigitized],1                       ;Tells the irq0 handler to process the routines
; Play_Repeat:
   ; lodsb                                              ;Loads a byte from ESI to AL
   ; hlt                                                 ;Wait for IRQ to fire
   ; loop Play_Repeat                              ;and the whole procedure is looped ECX times
   ; mov [EnableDigitized],0                     ;Tells the irq0 handler to disable the digitized functions
   ; mov cx,0x12                                 
   ; call ProgramPIT                                       ;Return to 18.2 kHz IRQ0
   ; call Sound_Off                                        ;Turn the speaker off just in case
   ; ret

; set_timer:
; mov al,0xb6
; out 0x43,al
; mov ax,1193
; out 0x43,al
; shr ax,8
; out 0x43,al
; ret

; ProgramPIT:
; ;mov al,0x36
; mov al,0xb6
; out 0x43,al
; ;mov ax,1193
; mov eax,1193180
; mov ebx,[loc]
; div ebx ;frequency
; out 0x43,al
; shr ax,8
; out 0x43,al
; ret

;int09h:
;xor dx,dx
;mov ds,dx
;mov es,dx

;in al,0x60
;call printf

;mov al,0x09
;call ackport
;call clrport64
;iret

int1ch:
pusha
mov al,0x1c
call ackport
popa

pusha

mov bp,ds
push bp
mov bp,es
push bp
xor bp,bp
mov ds,bp
mov es,bp

;cmp byte [multi],0xf0

;jmp .multitasking_off

; jne .multitasking_off
; call pcbsave

; call newline
; mov si,pcb+3
; mov cx,23
; .loop:
; lodsb
; call printh
; loop .loop

; inc byte [currentprocess]
; push ax
; mov al,[totalprocess]
; dec al
; cmp [currentprocess],al
; jg .pmore
; jmp .jump
; .pmore:
; mov byte [currentprocess],1
; .jump:
; ;call pcbload
; ;db 0xcc
; mov byte [multi],0x0f
; jmp .multitasking_off

; pop bp
; pop bp
; pop ax
; pop ax
; pop ax

; mov al,0x1c
; call ackport
; ;mov ax,[bp]
; ;call printwordh
; jmp word [bp]

.multitasking_off:
pop dx
mov es,dx
pop dx
mov ds,dx
popa
iret

;xor bp,bp
;mov es,bp
;mov bp,0x0046
;inc dword [es:bp]
;mov al,'*'
;call printf
; call chkkey
; cmp ah,0x0F
; je .pagekey
; cmp ah,0x44
; je .quitkey
; je .pagekey
; jmp .done
; .pagekey:
; call directgetkey
; call page_change_c
; jmp .done
; .quitkey:
; call directgetkey
; cli
; pop ax
; pop ax
; xor ax,ax
; push ax
; mov ax,kernel
; push ax
; sti
; .done:
; call getpos

int60h:
pusha
xor ax,ax
mov ds,ax
mov es,ax
popa
call debug_int

mov al,0x60
call ackport
iret

int61h:
pusha
xor ax,ax
mov ds,ax
mov es,ax
mov al,0x61
call ackport
popa
mov [.function],ah
; cmp ah,0
; je .ok
; mov [.function],al
; .ok:
cmp ah,0x00
je int61_box_str_top	; String Message Box
cmp ah,0x01
je int61h_set_color
cmp ah,0x02
je int61h_set_color2
cmp ah,0x03
je int61h_prnstr
cmp ah,0x04
je int61h_getstr
cmp ah,0x05
je int61h_cmpstr
cmp ah,0x06
je int61h_cls
cmp ah,0x07
je int61h_set_size
cmp ah,0x08
je int61h_change_typemode
cmp ah,0x09
je int61h_delay
cmp ah,0x0A
je int61h_slow
cmp ah,0x0B
je int61h_newline
cmp ah,0x0C
je int61h_set_prompt
cmp ah,0x0D
je int61h_pipestore
cmp ah,0x0E
je int61h_mint
cmp ah,0x0F
je int61h_kernelreturn
cmp ah,0x10
je int61h_storescreen
cmp ah,0x11
je int61h_restorescreen
cmp ah,0x12
je int61h_setmessage
cmp ah,0x13
je int61h_getmessage
cmp ah,0x14
je int61h_reload_words
cmp ah,0x15
je int61h_cmpstr_s
cmp ah,0x16
je int61h_scroll_down
cmp ah,0x17
je int61h_random_word
cmp ah,0x18
je int61h_to_upper
cmp ah,0x19
je int61h_start_pc_tone
cmp ah,0x1A
je int61h_stop_pc_tone
cmp ah,0x1B
je int61h_to_lower
cmp ah,0x20
je int61_printn
cmp ah,0x21
je int61_getno
cmp ah,0x22
je int61_printh
cmp ah,0x23
je int61_gethex
cmp ah,0x24
je int61_printwordh
cmp ah,0x25
je int61_printdwordh
cmp ah,0x26
je int61_printnb
cmp ah,0x27
je int61_printn_big
cmp ah,0x28
je int61_getno

cmp ah,0x2A
je int61_itoa
cmp ah,0x2B
je int61_atoi

cmp ah,0x30
je int61_getpos
cmp ah,0x31
je int61_setpos
cmp ah,0x32
je int61_get_typemode
cmp ah,0x33
je int61_strlen

cmp ah,0x35
je int61_add_kernel_buffer
cmp ah,0x36
je int61_execute_kernel_buffer
cmp ah,0x37
je int61_kernel_buffer_address

cmp ah,0x40
je int61_box_str_top	;	String InputBox
cmp ah,0x41
je int61_msgbox_no	;Input Decimal
; cmp ah,0x41
; je int61_inputbox_no_big
; cmp ah,0x43
; je int61_inputbox_hex
;cmp ah,0x44
;je int61_inputbox_str

cmp ah,0x45
je int61_msgbox_no	;Byte Decimal
cmp ah,0x46
je int61_msgbox_no	;Word Decimal
cmp ah,0x47
je int61_msgbox_no	;DWord Decimal
cmp ah,0x48
je int61_msgbox_no	;Word Hexadecimal
cmp ah,0x49
je int61_msgbox_no	;Word Hexadecimal

cmp ah,0x50
je int61_wall

cmp ah,0x60
je int61_start_debug

cmp ah,0x70
je int61_getcluster
cmp ah,0x71
je int61_setcluster
cmp ah,0x72
je int61_loadcluster
cmp ah,0x73
je int61_savecluster
cmp ah,0x74
je int61_LBACHS

cmp ah,0x80
je int61_roamselect
cmp ah,0x81
je int61_save_file
cmp ah,0x82
je int61_addpath
cmp ah,0x85
je int61_load_filebyname
cmp ah,0x86
je int61_file_selector

cmp ah,0xFF
je int61h_ver

call debug_int

iret
.function:
dw 0

; int61h_message:
; mov si,dx

; call color_switch

; call getpos
; push dx
; xor dx,dx
; call setpos
; call storeline
; xor dx,dx
; call setpos
; call prnstr
; call getkey
; call color_switch
; xor dx,dx
; call setpos
; call restoreline
; pop dx
; call setpos
; iret

int61h_set_color:
mov [color],dl
iret

int61h_set_color2:
mov [color2],dl
iret

int61h_prnstr:
mov si,dx
call prnstr
iret

int61h_getstr:
mov di,dx
call getstr
iret

int61h_cmpstr:
xor al,al
mov si,bx
mov di,dx
call cmpstr
jc .sequal
mov al,0x0F
jmp .done
.sequal:
mov al,0xF0
.done:
iret

int61h_cls:
call clear_screen
xor dx,dx
dec dh
call setpos
iret

int61h_set_size:
mov [size],dx
iret

int61h_change_typemode:
not byte [teletype]
iret

int61h_delay:
call delay
iret

int61h_slow:
call delay
iret

int61h_newline:
call newline
iret

int61h_set_prompt:
mov si,dx
mov di,prompt
mov cx,0x000F
rep movsb
clc
iret

int61h_pipestore:
mov di,dx
mov si,dx
; call pipespace2enter
; mov si,di
; call pipestore
call store_pipe_command
iret

int61h_mint:
mov al,dl
mov di,found
stosb
xor al,al
stosb
call command
iret

int61h_kernelreturn:
mov byte [kernelreturnflag],0xf0
mov word [kernelreturnaddr],.int61h_kernelreturn_ret
jmp command_start
.int61h_kernelreturn_ret:
iret

int61h_storescreen:
call getpos
push dx
call storescreen
pop dx
call setpos
iret

int61h_restorescreen:
call getpos
push dx
call restorescreen
pop dx
call setpos
iret

int61h_setmessage:
mov [message],dx
iret

int61h_getmessage:
mov dx,[message]
iret

int61h_reload_words:
mov bx,dx
call reload_words
iret

int61h_cmpstr_s:
xor al,al
mov si,bx
mov di,dx
call cmpstr_s
jc .sequal
mov al,0x0F
jmp .done
.sequal:
mov al,0xF0
.done:
iret

int61h_scroll_down:
call scroll_down
iret

int61h_random_word:
; pusha
; call slow
; call os_seed_random
; popa
mov ax,dx
call os_get_random
mov dx,cx
iret
;call delay
; xor ah,ah
; int 0x1a
; mov bx,dx
; ;mov bx,[bx]
; mov ax,[bx]
; xchg bx,cx
; xor dx,dx
; mul bx
; .loop2:
; sub cx,dx
; sub ax,cx
; add dx,ax
; cmp ax,dx
; jl .loop2
; .loop3:
; add cx,dx
; add ax,cx
; sub dx,ax
; cmp dx,ax
; jg .loop3
; add dx,cx
; cmp dx,0
; je int61h_random_word
; iret

int61h_to_upper:
mov si,dx
.loop:
lodsb
cmp al,0x61
jl .okay
cmp al,0x7A
jg .okay
sub al,0x20
dec si
mov [si],al
.okay:
cmp al,0
jne .loop
iret

int61h_to_lower:
mov si,dx
.loop:
lodsb
cmp al,0x41
jl .okay
cmp al,0x5A
jg .okay
add al,0x20
dec si
mov [si],al
.okay:
cmp al,0
jne .loop
iret

int61h_start_pc_tone:
mov ax,dx
call os_speaker_tone
iret

int61h_stop_pc_tone:
call os_speaker_off
iret

int61_printn:
mov ax,dx
call printn
iret

int61_getno:
call getno
mov edx,eax
iret

int61_printh:
mov al,dl
call printh
iret

int61_gethex:
call gethex
mov dl,al
iret

int61_printwordh:
mov ax,dx
call printwordh
iret

int61_printdwordh:
xchg ax,dx
mov dx,bx
call printdwordh
iret

int61_printnb:
mov al,dl
call printnb
iret

int61_printn_big:
mov eax,edx
call printn
iret

int61_itoa:
mov di,bx
mov ax,dx
call itoa
iret

int61_atoi:
mov si,dx
call atoi
mov dx,ax
iret

int61_getpos:
call getpos
iret

int61_setpos:
call setpos
iret

int61_get_typemode:
mov dl,[teletype]
iret

int61_strlen:
mov si,dx
call strlen
mov dx,ax
iret

int61_add_kernel_buffer:
mov si,dx
mov di,found
call memcpy
iret

int61_execute_kernel_buffer:
mov byte [kernelreturnflag],0xf0
mov word [kernelreturnaddr],.return_address
jmp command_received
.return_address:
iret

int61_kernel_buffer_address:
mov dx,found
iret

int61_box_str_top:
mov si,dx
mov di,bx
call color_switch

call getpos
push dx
push di
xor dx,dx
call setpos
call storeline
xor dx,dx
call setpos
call prnstr
pop di
cmp byte [int61h.function],0x40
je .getstr
;call prnstr
call getkey
jmp .done
.getstr:
call colon
call getstr
;jmp .done
.done:
call color_switch
xor dx,dx
call setpos
call restoreline
pop dx
call setpos
iret

int61_msgbox_no:
mov si,bx
mov edi,edx
push cx

call color_switch

call getpos
mov bx,dx
pop dx
push bx
push dx
call setpos
call storeline
pop dx
push dx
call setpos
call prnstr
mov eax,edi
cmp byte [int61h.function],0x41
je .in_no
cmp byte [int61h.function],0x45
je .small
cmp byte [int61h.function],0x46
je .no
cmp byte [int61h.function],0x48
je .wordh
cmp byte [int61h.function],0x49
je .wordh
; cmp [int61h.function],0x47
; je .big
call printn
jmp .done
.in_no:
call getno
jmp .done
.small:
call printnb
jmp .done
.no:
call printn
jmp .done
.wordh:
call printwordh
;jmp .done
.done:
call getkey
call color_switch
pop dx
call setpos
call restoreline
pop dx
call setpos
iret

int61_wall:
not byte [wall_flag]
cmp byte [wall_flag],0xf0
jne .off
call storescreen
.off:
iret

int61_start_debug:
pushf
mov bp,sp
or word [bp+0],0x0100
popf
mov byte [step_flag],0xf0
mov byte [var_f],0x0f
pop dx
mov word [step_f.ip],dx
push dx
iret

int61_getcluster:
mov dx,[cluster]
iret
int61_setcluster:
mov [cluster],dx
iret
int61_loadcluster:
push bx
mov ax,dx
call LBACHS
;mov bx,[locf4]
pop bx
mov ah,0x02 ;Read function
call filedirect_c
;mov ax,[locf4]
iret
int61_savecluster:
push bx
mov ax,[cluster]
call LBACHS
pop bx
;mov bx,[locf4]
;call filesave_c
mov ah,0x03 ;Write function
call filedirect_c
iret
int61_LBACHS:
mov ax,[cluster]
call LBACHS
mov ax,[size]
mov ch, BYTE [absoluteTrack]
mov cl, BYTE [absoluteSector]
mov dh, BYTE [absoluteHead]
mov byte dl,[drive]
iret

int61_roamselect:
mov di,dx
mov bx,[currentdir]
mov [var_c],bx
mov word [comm],0x0f0f
mov byte [command_tempchar],'t'
mov bx,roam_ret
mov [extra],bx
jmp fdir
roam_ret:
mov bx,[var_c]
mov [currentdir],bx
iret

int61_save_file:
mov bx,dx
mov dx,[kernel_seg]
mov es,dx
call filesave_c
clc
iret

int61_addpath:
mov [currentdirtemp],dx
call c_addpath_f_call
iret

;IN: dx=file_name bx=memory_location
int61_load_filebyname:
; mov ax,dx
; mov cx,bx
; call os_load_file
; iret
;push bx
mov ax,[loc]
mov [.temploc],ax
mov [loc],bx
mov ax,dx
call get_name
mov word [comm],0x0f0f
mov byte [command_tempchar],'c'
mov bx,.return_address
mov [extra],bx
jmp fdir
.return_address:
mov ax,[.temploc]
mov [loc],ax
;pop di
; mov byte [command_tempchar],'i'
; jmp fdir
iret
.temploc:
dw 0

;IN: nothing OUT:ax,dx=filename
int61_file_selector:
; mov byte [command_tempchar],'l'
; call fdir
call os_file_selector
mov dx,ax
iret

int61h_ver:
mov ax,[ver]
iret

int64h:
pusha
xor ax,ax
mov ds,ax
mov es,ax
mov al,0x62
call ackport
popa

cmp ah,0x01
je int64_getsize
cmp ah,0x02
je int64_getcolor
cmp ah,0x03
je int64_getcolor2
cmp ah,0x04
je int64_getscrolllen
cmp ah,0x05
je int64_getpage
cmp ah,0x06
je int64_getbytesize

cmp ah,0x30
je int64_setidlecmd

cmp ah,0xff
je int64_getverstring
iret

int64_getsize:
;push ax
mov dx,[size]
;mov ax,[var_j]
;cmp  ax,dx
;jl .ok
;mov dx,ax
;.ok:
;pop ax
iret

int64_getcolor:
mov dl,[color]
iret

int64_getcolor2:
mov dl,[color2]
iret

int64_getscrolllen:
mov dl,[scrolllength]
iret

int64_getpage:
mov dx,[page]
xchg dh,dl
iret

int64_getbytesize:
mov dx,[filesize]
iret

int64_setidlecmd:
mov si,dx
mov di,idle_kenel_commandstr
mov cx,idle_kenel_commandstr_end-idle_kenel_commandstr
rep movsb
iret

int64_getverstring:
mov dx,verstring
iret

newprompt:
call getpos
xor dl,dl
call setpos
mov si,prompt
call prnstr
ret

alarm:
mov al,'H'
call printf
call colon
call gethex
mov ch,al
push cx
call colon
mov al,'M'
call printf
call colon
call gethex
pop cx
mov cl,al
push cx
call colon
mov al,'S'
call printf
call colon
call gethex
pop cx
mov dh,al
pusha
cmp byte [autostart],0xf0
jne .autostart_off
mov ah,0x08
int 0x1a
.autostart_off:
popa
mov ah,0x06
int 0x1a
jmp kernel

alarmtext:
mov di,alarmtextstr
call getstr
jmp kernel

;---------------------------------
; Aplaun OS additional os_routines
;---------------------------------

; -----------------------------------------------------------------
; Program to display PCX images (320x200, 8-bit only)
; more resolutions with basic support
; -----------------------------------------------------------------
;IN: si-start of the image location
os_print_splash:

	mov ax, 0A000h			; ES = video memory
	mov es, ax

	mov al,[si+3] ; Bits per pixel
	mov [.bits_per_pixel],al
	mov ax,[si+8] ; X Maximum
	inc ax
	mov [.width],ax
	mov ax,[si+10] ; Y Maximum
	inc ax
	mov [.height],ax
	
	;mov si, 1080h			; Move source to start of image data
	add si,80h				; (First 80h bytes is header)

	xor di, di			; Start our loop at top of video RAM

.decode:
	mov cx, 1
	lodsb
	cmp al, 192			; Single pixel or string?
	jb .single
	and al, 63			; String, so 'mod 64' it
	mov cl, al			; Result in CL for following 'rep'
	lodsb				; Get byte to put on screen
.single:
	rep stosb			; And show it (or all of them)
	;cmp di, 64001
	mov ax,[.height]
	imul ax,[.width]
	inc ax
	cmp di,ax
	jb .decode


	mov dx, 3c8h			; Palette index register
	xor al, al			; Start at color 0
	out dx, al			; Tell VGA controller that...
	inc dx				; ...3c9h = palette data register

; 256 colours, 3 bytes each
push ax
xor cx,cx
mov cl,[.bits_per_pixel]
mov ax,1
.no_of_colours_loop:
imul ax,2 ; 2^bits
loop .no_of_colours_loop
mov cx,ax
pop ax
imul cx,3 ; For 3 bytes

	;mov cx, 768
.setpal:
	lodsb				; Grab the next byte.
	shr al, 2			; Palettes divided by 4, so undo
	out dx, al			; Send to VGA controller
	loop .setpal

	mov ax, [kernel_seg]			; Reset ES back to original value
	mov es, ax
ret
.bits_per_pixel:
db 0
.width:
dw 0
.height:
dw 0

;IN: ax=help string bx=location to store result
;Provides option to select yes or no
;and stores the result in position pointed by bx
os_get_switch_dialog:
pusha
push bx
;mov bx,filestr
;mov bx,.switch_string
mov bx,0
mov cx,.switch_select
mov dx,2
call os_dialog_box
pop bx
cmp ax,0
je .on
popa
mov byte [bx],0x0f
ret
.on:
popa
mov byte [bx],0xf0
ret
; .switch_string:
; db "Switch >>",0
.switch_select:
db "Select your option :",0

;IN: ax=help string bx=location to store result
;Provides option to enter a number in dialog box
;and stores the result in position pointed by bx
os_get_int_dialog:
pusha
push bx
mov bx,ax
mov ax,tempstr
call os_input_dialog
mov si,tempstr
call atoi
pop bx
mov [bx],al
popa
ret

c_setting_f:
;Clear Screen
mov ah,0x06
int 0x61

;Create List of options
mov di,found
mov si,.quicksettings
call memcpyza
mov si,c_completeload
call memcpyza
mov si,c_advanced
call memcpyza
; mov si,c_size
; call memcpyza
; mov si,c_fname
; call memcpyza
mov si,c_prompt
call memcpyza
mov si,kernel_idle_time_str
call memcpyza
mov si,kernel_idle_command_str
call memcpyza
; mov si,c_alarmtext
; call memcpyza
mov si,c_exit
call memcpyza
dec di
mov byte [di],0
mov ax,found
mov bx,verstring
mov cx,c_setting
call os_list_dialog

jc .exit_l
cmp ax,1;quick
je .quick
cmp ax,2;autosize
je .autosize
cmp ax,3;advanced
je .advanced
cmp ax,4;prompt
je .prompt
cmp ax,5;idle-time
je .idle_time
cmp ax,6;idle-command
je .idle_command
cmp ax,7;exit
je .exit_l
; cmp ax,3
; je .prompt

.exit_l:
call clear_screen
jmp kernel
.autosize:
mov ax,c_autosize
mov bx,autosize_flag
call os_get_switch_dialog
jmp c_setting_f
.advanced:
mov ax,c_advanced
mov bx,advanced_flag
call os_get_switch_dialog
jmp c_setting_f
.prompt:
mov ax,prompt
mov bx,c_prompt
call os_input_dialog
jmp c_setting_f
.idle_time:
mov ax,kernel_idle_time_str
mov bx,idle_kernel_waittime
call os_get_int_dialog
jmp c_setting_f
.idle_command:
mov ax,idle_kenel_commandstr
mov bx,kernel_idle_command_str
call os_input_dialog
jmp c_setting_f
.quick:
;Show current settings quickly

mov ah,0x06 ;Clear Screen
int 0x61

mov si,c_size
call prnstr
call colon
mov ax,[size]
;mov ax,[filesize]
call printn
call space
mov si,c_head
call prnstr
call colon
mov al,[head]
call printnb
call space
mov si,c_track
call prnstr
call colon
mov al,[track]
call printnb

; call newline
; mov al,'H'
; call printf
; call colon
; mov al,[absoluteHead]
; call printh
; call space
; mov al,'T'
; call printf
; call colon
; mov al,[absoluteTrack]
; call printh
; call space
; mov al,'S'
; call printf
; call colon
; mov al,[absoluteSector]
; call printh
call print_HTS_details.direct

call newline
mov si,c_color
call prnstr
call colon
mov al,[color]
call printnb

call space
mov si,c_color2
call prnstr
call colon
mov al,[color2]
call printnb

call newline
mov si,c_drive
call prnstr
call colon
mov al,[drive]
call printnb
call space
mov si,c_drive2
call prnstr
call colon
mov al,[drive2]
call printnb

call newline
mov si,c_videomode
call prnstr
call colon
mov al,[mode]
call printnb

; call newline
; mov si,c_difficulty
; call prnstr
; call colon
; mov al,[difficulty]
; call printnb

; call space
; mov si,c_length
; call prnstr
; call colon
; mov al,[length]
; call printnb

call space
mov si,c_scrolllen
call prnstr
call colon
mov al,[scrolllength]
call printnb

; call newline
; mov si,c_frame
; call prnstr
; call colon
; mov al,[frame]
; call printnb

call newline
mov si,process_returnstr
call prnstr
call colon
mov al,[returncode]
call printh

call newline
mov si,c_loc
call prnstr
call colon
mov cx,0
mov si,loc

.quicksettings_loc_loop:
call space
mov al,cl
add al,'0'
call printf
call colon
lodsw
call printwordh
inc cx
cmp cx,8
jb .quicksettings_loc_loop

call newline
mov si,c_loc2
call prnstr
call colon
mov ax,[loc2]
call printwordh

call space
mov si,c_loc3
call prnstr
call colon
mov ax,[loc3]
call printwordh

call newline
mov si,c_setdir
call prnstr
call colon
mov ax,[currentdir]
call printwordh

call space
mov si,c_addpath
call prnstr
call colon
mov si,path_list
mov cx,0
.loop:
lodsw
inc cx
cmp ax,0
je .loopexit
call printwordh
call colon
cmp cx,10
jge .loopexit
jmp .loop
.loopexit:

call newline
mov si,c_page
call prnstr
call colon
mov ax,[page]
call printwordh

call space
mov si,messagestr
call prnstr
;call colon
mov ax,[message]
call printwordh

call newline
mov si,c_idle_command
call prnstr
call colon
mov si,idle_kenel_commandstr
call prnstr

call space
mov si,c_idle_time
call prnstr
call colon
mov al,[idle_kernel_waittime]
call printnb

call newline
mov si,c_fname
call prnstr
call colon
mov si,ImageName
call prnstr

call space
mov si,c_fsize
call prnstr
call colon
mov ax,[filesize]
call printn

call newline
mov si,c_prompt
call prnstr
call colon
mov si,prompt
call prnstr

call newline
mov si,c_alarmtext
call prnstr
call colon
mov si,alarmtextstr
call prnstr

call newline
mov si,c_typemode
call prnstr
call colon
mov si,teletype
call switchshow

call space
mov si,c_scrollmode
call prnstr
call colon
mov si,scrollmode
call switchshow

call newline
mov si,c_slowmode
call prnstr
call colon
mov si,slowmode
call switchshow

; call space
; mov si,c_score
; call prnstr
; call colon
; mov si,score
; call switchshow

call newline
mov si,c_rollcolor
call prnstr
call colon
mov si,rollcolor
call switchshow

call space
mov si,c_wall
call prnstr
call colon
mov si,wall_flag
call switchshow

call newline
mov si,c_autostart
call prnstr
call colon
mov si,autostart
call switchshow

call space
mov si,c_cursor
call prnstr
call colon
mov si,cursor
call switchshow

call space
mov si,c_echo
call prnstr
call colon
mov si,echo_flag
call switchshow

call newline
mov si,c_autosize
call prnstr
call colon
mov si,autosize_flag
call switchshow

call space
mov si,c_advanced
call prnstr
call colon
mov si,advanced_flag
call switchshow

call space
mov si,c_completeload
call prnstr
call colon
mov si,completeload_flag
call switchshow

call newline
mov si,c_micro
call prnstr
call colon
mov si,micro
call switchshow

; call space
; mov si,c_multi
; call prnstr
; call colon
; mov si,multi
; call switchshow

jmp kernel
.quicksettings:
db "Show Settings",0

switchshow:
cmp byte [si],0xf0
je .switchon
cmp byte [si],0x0f
je .switchoff
mov byte [si],0x0f
.switchoff:
mov si,coff
call prnstr
ret
.switchon:
mov si,con
call prnstr
ret

pipe:
mov di,found
call getstr
mov si,found
call store_pipe_command
jmp kernel

;IN:si-command to store
store_pipe_command:
call pipespace2enter
call pipestore
ret

pipespace2enter:
pusha
.loop:
lodsb
cmp al,0x20
je .space
cmp al,0x00
je .end
jmp .loop
.space:
mov al,0x0D
dec si
mov [si],al
jmp .loop
.end:
popa
ret

pipestore:
pusha
.loop:
lodsb
cmp al,0x0D
je .enter
cmp al,0x00
je .end
mov ah,0x00
call keybsto
jmp .loop
.enter:
mov ah,0x1C
call keybsto
jmp .loop
.end:
popa
ret

keybsto:
pusha
; mov ch,ah
; mov cl,al
mov cx,ax
mov ah,0x05
int 16h
popa
ret

; pcbsave:
; pusha
; mov al,[currentprocess]
; xor ah,ah
; mov bx,23
; mul bx
; mov bx,ax
; add bx,3
; mov si,pcb
; add si,bx

; pop ax
; mov [si],ax
; add si,2
; pop ax
; mov [si],ax
; add si,2
; pop ax
; mov [si],ax
; add si,2
; pop ax
; mov [si],ax
; add si,2
; pop ax
; mov [si],ax
; add si,2
; pop ax
; mov [si],ax
; add si,2
; pop ax
; mov [si],ax
; add si,2
; pop ax
; mov [si],ax
; add si,2

; pushf
; pop ax
; mov [si],ax
; add si,2

; pop bx
; pop ax
; ;push ax
; push bx
; mov [si],ax

; ret

; pcbload:
; mov al,[currentprocess]
; xor ah,ah
; mov bx,23
; mul bx
; mov bx,ax
; add bx,3
; mov bp,pcb
; add bp,bx

; mov ax,[bp]
; add bp,2
; mov di,ax

; mov ax,[bp]
; add bp,2
; mov si,ax

; ;mov ax,[bp]
; add bp,2

; mov ax,[bp]
; add bp,2
; mov sp,ax

; mov ax,[bp]
; add bp,2
; mov bx,ax

; mov ax,[bp]
; add bp,2
; mov dx,ax

; mov ax,[bp]
; add bp,2
; mov cx,ax

; mov ax,[bp]
; add bp,2

; add bp,2
; ret

edit:
;mov dx,[loc]
;mov ah,0x80
;int 0x61

;mov ax,0x0003
;int 0x10
;mov ax,0x0500
;int 10h
mov word [firstrow],1
mov word [rowpos],0
mov byte [row],0
mov byte [col],0

;call argument
mov si,[argument_position]
cmp si,0
je mainloop
cmp byte [si],0
je mainloop
mov ax,si
mov cx,[loc]
call os_load_file

mainloop:
cmp word [rowpos],79
jg .morerows
mov word [rowpos],0
.morerows:
call checkpos
call checkline_eol
xor dx,dx
call setpos_c
mov ah,0x06
int 0x61

;Set cursor according to mode
cmp byte [insert_mode],0x0f
je .overwrite_mode_cursor
mov cx,0x0506
mov ah,0x01
int 10h
jmp .cursor_set
.overwrite_mode_cursor:
mov cx,0x090f
mov ah,0x01
int 10h
;jmp .cursor_set
.cursor_set:

mov cx,[firstrow]
jmp showscreen.firstline

;Main loop to show a screenful of text
showscreen:
;call newline
push cx
call newline
pop cx
.firstline:
push cx
mov dx,cx
call loadlinepos
;mov ax,[si]
;cmp ax,0
;je .popexit
;call getkey

;Checking when to stop loop
call check_for_eof
jc .exitloop

;If bottom of screen is reached
call getpos
cmp dh,[border_max_y]
jge .exitloop

;Show the line
call showline

;Else show next line
pop cx
inc cx
;cmp cx,25
;jle showscreen
jmp showscreen

.exitloop:
pop cx
mov dh,[row]
mov dl,[col]
;jmp .ok
mov cx,[rowpos]
.rowloop:
cmp cx,80
jge .more
jmp .ok
.more:
inc dh
sub cx,80
jmp .rowloop
.ok:
push dx
; mov bl,[color2]
mov dh,[border_max_y]
; dec dh
mov dl,[border_min_x]
; mov si,[border_max_x]
; ;inc si
; mov di,[border_max_y]
; call os_draw_block
call setpos_c
mov si,edit_help_str
call color_switch
call prnstr
call color_switch
pop dx
call setpos_c
jmp control
.popexit:
pop cx
jmp .exitloop

check_for_eof:
pusha
cmp byte [free_roam],0x0f
jne .skipsizecheck
mov dx,[filesize]	;Get file size
;mov ah,0x06
;int 0x64
;mov dh,0
mov bx,si
sub bx,[loc]
cmp bx,dx	;If end of file is reached
jg .exitloop;then stop the loop
.skipsizecheck:
popa
clc
ret
.exitloop:
popa
stc
ret

control:
call getkey

cmp ah,0x01
je .quit
cmp al,0x08
je .back
cmp ah,0x3B
je .help
cmp ah,0x3C
je .save
cmp ah,0x3D
je .copy
cmp ah,0x3E
je .paste
cmp ah,0x3F
je .newfile
cmp ah,0x40
je .loadfile
cmp ah,0x41
je .deleteline
cmp ah,0x42
je .details
cmp ah,0x43 ; F9
je .option
cmp ah,0x47
je .home
cmp ah,0x4f
je .end
cmp ah,0x49
je .page_up
cmp ah,0x48
je .up
cmp ah,0x4B
je .left
cmp ah,0x4D
je .right
cmp ah,0x50
je .down
cmp ah,0x51
je .page_down
cmp ah,0x52
je .mode_toggle
cmp ah,0x53
je .del

; If not a special key then add to file
push ax
call getcurrentpos
cmp byte [insert_mode],0x0F
je .overwrite_mode
call strshiftr ; Insert a space
inc word [filesize]
.overwrite_mode:
pop ax
mov [si],al
cmp al,13
je .enter
inc byte [col]
jmp mainloop
.home:
mov byte [col],0
jmp mainloop
.end:
call loadlineend
mov di,si
call loadlinepos
sub di,si
mov dx,di
dec dl
mov [col],dl
jmp mainloop
.page_down:
add word [firstrow],6
jmp mainloop
.page_up:
sub word [firstrow],6
jmp mainloop
.mode_toggle:
not byte [insert_mode]
jmp mainloop

.enter:
inc si
call strshiftr
inc word [filesize]
mov byte [si],10
inc byte [row]
mov byte [col],0
jmp mainloop

.quit:
jmp kernel
.help:
; xor ah,ah
; mov dx,edit_help_str
; int 0x61
mov ax,verstring
mov bx,c_edit
mov cx,signature
mov dx,0
call os_dialog_box
jmp mainloop

.save:
mov ax,ImageName ; Delete the file if it already exists
call os_remove_file

mov ax,ImageName
mov cx,[filesize]
mov bx,[loc]
call os_write_file
;jmp control
jmp edit

.copy:
call getcurrentpos
mov [var_i],si
jmp control

.paste:
mov si,[var_i]
lodsb
push ax
call getcurrentpos
call strshiftr
inc word [filesize]
pop ax
mov [si],al

push ax
call getcurrentpos
cmp si,[var_i]
jnl .paste_ahead
inc word [var_i]
.paste_ahead:
inc word [var_i]
pop ax

cmp al,13
je .penter
inc byte [col]
jmp mainloop
.penter:
inc word [var_i]
inc word [filesize]
jmp .enter

.newfile:

;Clear text buffer
mov di,[loc]
mov cx,1024
mov al,0
rep stosb

;Get new file name
mov bx,new_file_str
mov ax,tempstr2
call os_input_dialog

; Delete the file if it already exists
mov ax,tempstr2
call os_remove_file

;Saving new empty file
mov ax,tempstr2
mov bx,[loc]
mov byte [bx],10 ; One newline character
mov cx,1
;call os_create_file
call os_write_file

jmp edit

.loadfile:
; mov bx,file_name_str
; mov ax,found
; call os_input_dialog
call os_file_selector
;mov ax,found
mov cx,[loc]
call os_load_file
jmp edit

.deleteline:
;Delete whole one line
call loadlineend
mov di,si
call loadlinepos
sub di,si
mov cx,di
.deleteline_loop:
pusha
call strshift
dec word [filesize]
popa
loop .deleteline_loop

.check_eol:
cmp byte [si],0x0D
je .del_eol
cmp byte [si],0x0A
je .del_eol
jmp mainloop
.del_eol:
call strshift
dec word [filesize]
jmp .check_eol

.details:
mov dl,[col]
mov dh,0
mov bx,x_str
mov ah,0x45
mov cx,0x0005
int 0x61
mov dx,[firstrow]
add dl,[row]
mov bx,y_str
mov ah,0x45
mov cx,0x0005
int 0x61
jmp mainloop

.option:
mov di,found
mov si,.free_roam_str
call memcpyza
mov si,c_exit
call memcpyza
dec di
mov byte [di],0
mov ax,found
mov bx,verstring
mov cx,c_setting
call os_list_dialog

jc .exit_l
cmp ax,1;free roam
je .free_roam

.exit_l:
jmp mainloop
.free_roam:
mov ax,.free_roam_str
mov bx,free_roam
call os_get_switch_dialog
jmp .option
.free_roam_str:
db "Free Roam in Memory",0

.up:
dec byte [row]
jmp mainloop
.left:
dec byte [col]
jmp mainloop
.right:
inc byte [col]
jmp mainloop
.down:
inc byte [row]
jmp mainloop
.back:
dec byte [col]
call getcurrentpos
mov di,si
cmp byte [di],0x0A
je .enterdel
inc di
call strshift
dec word [filesize]
jmp mainloop
.enterdel:
dec di
cmp byte [di],0x0D
jne .enterdel2
dec si
call strshift
dec word [filesize]
;.adel:
;call getcurrentpos
;call strshift
;jmp mainloop
.enterdel2:
call getcurrentpos
call strshift
dec word [filesize]
jmp mainloop
.del:
call getcurrentpos
call strshift
call getcurrentpos
mov di,si
cmp byte [di],0x0D
je .enterdel2
cmp byte [di],0x0A
je .enterdel2
jmp mainloop

checkpos:
;Check if borders are reached
;;TODO better handling for bigger files
cmp word [firstrow],1
jl .firstrow_l
cmp byte [row],0
jl .row_l
cmp byte [row],24
jg .row_h
cmp byte [col],0
jl .col_l
cmp byte [col],79
jg .col_h

call getcurrentpos
call check_for_eof
jc .exitloop
ret
.exitloop:
dec byte [col]
jmp checkpos
.firstrow_l:
mov byte [row],0
mov word [firstrow],1
jmp checkpos
.row_l:
inc byte [row]
dec word [firstrow]
jmp checkpos
.row_h:
dec byte [row]
call checkline_eol
inc word [firstrow]
jmp checkpos

.col_l:
cmp word [rowpos],79
jg .notstart
dec byte [row]
;add byte [col],80
mov word [rowpos],0
mov byte [col],0
jmp checkpos
.notstart:
sub word [rowpos],79
mov byte [col],79
jmp checkpos
.col_h:

call loadlineend
mov di,si
call getcurrentpos
cmp si,di
jge .eol
.ok:
mov dl,[col]
xor dh,dh
add [rowpos],dx
mov byte [col],0
inc byte [row]
jmp checkpos
.eol:
inc byte [row]
mov byte [col],0
jmp checkpos

;See if end of line is encountered
checkline_eol:
call loadlineend
mov di,si
call getcurrentpos
cmp si,di
jge .eol
.ok:
ret
.eol:
inc byte [row]
mov byte [col],0
ret

;---------------------------
;IN: nothing
;OUT: si = location in memory at current pos
;---------------------------
getcurrentpos:
mov dx,[firstrow]
add dl,[row]
call loadlinepos
;add byte si,[col]
mov cx,si
add cx,[rowpos]
add cl,[col]
mov si,cx
ret

;---------------------------
; IN: nothing
; OUT: SI = location in memory for end of the current line
;---------------------------
loadlineend:
mov dx,[firstrow]
add dl,[row]
call loadlinepos
.loop:
lodsb
cmp al,13
je .eol
cmp al,10
je .eol
cmp al,0
je .eol
jmp .loop
.eol:
ret

; printf2:
; cmp al,0x09
; je .tab
; mov ah,0x02
; mov dl,al
; int 0x21
; ret
; .tab:
; mov cx,8
; .loop:
; mov ah,0x02
; mov dl,0x20
; int 0x21
; loop .loop
; ret

;---------------------------
;IN: nothing
;OUT: si = location in memory 
;	for start for current line
;---------------------------
loadlinepos:
mov si,[loc]
mov word [.linecount],1
.check_end:
cmp word [.linecount],dx
jl .loop
ret
.loop:
lodsb
cmp al,0x0D
je .linefound
cmp al,0x0A
je .linefound2
jmp .loop

.linefound:
inc si
.linefound2:
inc word [.linecount]
jmp .check_end
.linecount:
dw 0

;Print line from si
showline:
lodsb
;End if newline character is found
cmp al,0x0D
je .done
cmp al,0x0A
je .done
cmp al,0
je .done
call getpos
cmp dx,0x184F
jge .done
call printt
;call printf2
;mov ah,0x02
;mov dl,al
;int 0x21
jmp showline
.done:
ret

; newline:
; mov ah,0x0B
; int 0x61
; ret

firstrow: dw 0
rowpos: dw 0
;row: db 0
;col: db 0
;loc:
;dw 0x7000

;Simple Text Viewer
;with percent status
;and bookmark jump
; read:
;
; mov al,[teletype]
; mov [col],al
; mov byte [teletype],0xf0
; call newline
; call newline
; call getpos
; dec dh
; call setpos
; xor dx,dx
; mov [var_a],dx
; ; xor ax,ax
; ; mov al,[size]
; ; mov bx,0x200
; ; imul ax,bx
; mov ax,[filesize]
; mov [var_b],ax
; .read_loop:
; mov si,[loc]
; add si,[var_a]
; .loop:
; lodsb
; cmp al,0x09
; je .tab
; call printf
; inc word [var_a]
; mov dx,[var_a]
; cmp dx,[var_b]
; jge .filedone
; call getpos
; cmp dh,24
; jge .bottom
; jmp .loop
; .bottom:
; call getpos
; push dx
; xor dl,dl
; call setpos
; call space
; mov si,c_loc
; call prnstr
; call colon
; mov ax,[var_a]
; call printwordh
; mov al,'/'
; call printf
; mov ax,[var_b]
; call printwordh
; call space
; call space
; mov ax,[var_a]
; xor dx,dx
; mov bx,100
; mul bx
; mov bx,[var_b]
; div bx
; call printn
; mov al,'%'
; call printf
; call space
; call space
; pop dx
; .control:
; call getkey
; cmp ah,0x01
; je .filedone
; cmp ah,0x29
; je .filedone
; cmp ah,0x1C
; je .pagedown
; cmp ah,0x51
; je .pagedown
; cmp ah,0x47
; je .pageup
; cmp ah,0x49
; je .pageup
; cmp ah,0x3C
; je .jump
; cmp ah,0x3D
; je .jump
; cmp ah,0x3B
; je .help
; push dx
; call getpos
; xor dl,dl
; call setpos
; call clearline
; call scroll_down
; pop dx
; mov dh,0x17
; sub dh,[scrolllength]
; call setpos
; jmp .read_loop
; .filedone:
; mov al,[col]
; cmp al,0xf0
; je .filedoneskip
; mov byte [teletype],0x0f
; .filedoneskip:
; jmp kernel
; .help:
; mov dx,read_helpstr
; xor ah,ah
; int 61h
; jmp .control
; .jump:
; mov si,c_jmp
; call prnstr
; call space
; call colon
; call gethex
; mov bx,var_a
; inc bx
; mov [bx],al
; call gethex
; dec bx
; mov [bx],al
; jmp .pagedown
; .pageup:
; mov dx,[var_a]
; sub dx,0x07D0
; mov [var_a],dx
; .pagedown:
; call clear_screen
; xor dx,dx
; call setpos
; jmp .read_loop
; .tab:
; mov cl,[length]
; xor ch,ch
; mov al,0x20
; .tabloop:
; call printf
; dec cx
; cmp cx,0
; jg .tabloop
; jmp .loop

c_cursor_f:
not byte [cursor]
cmp byte [cursor],0xf0
je .on
call os_hide_cursor
jmp kernel
.on:
call os_show_cursor
jmp kernel

signature:
db 'DivJ',0
;jmp kernel

;EnableDigitized     db 0

bpbBytesPerSector:  	DW 512
bpbSectorsPerCluster: 	DB 1
bpbReservedSectors: 	DW 1
bpbNumberOfFATs: 	DB 2
bpbRootEntries: 	DW 224
bpbTotalSectors: 	DW 2880
;bpbMedia: 		DB 0xf0  ;; 0xF1
bpbSectorsPerFAT: 	DW 9
bpbSectorsPerTrack: 	DW 18
bpbHeadsPerCylinder: 	DW 2
;bpbHiddenSectors: 	DD 0
;bpbTotalSectorsBig:     DD 0

datasector  dw 0x0000
cluster     dw 0x0000
absoluteSector db 0x05
absoluteHead   db 0x00
absoluteTrack  db 0x00

; difficulty:
; db 0x00
scrolllength:
db 0x01
length:
db 0x06
; ball_x:
; dw 0x000C
; ball_y:
; dw 0x000C
; down_flag:
; db 0xF0
; right_flag:
; db 0xF0
; AI_flag:
; db 0xF0
; play_chance_flag:
; dw 0x00F0
; player_x:
; dw 0x000A
; player_y:
; dw 0x000C
; player2_x:
; dw 0x0000
; player2_y:
; dw 0x0000

message:
dw 0

vars:

var_a:
dw 0x0000
var_b:
dw 0x0000 ; Temp one time uses
var_c:
dw 0x0000 ;Temp stores currentdir in roam
var_d: ;Microkernel path loop
dw 0x0000
var_e: ;Batch pos variable
dw 0x0000
var_f db 0x0f,0x0f

var_i:
dw 0x0000 ;Temp swap uses

;---------------------------
;Used for temporarily storing HTS
var_j:
dw 0x0000
var_k:
dw 0x0000
var_l:
dw 0x0000
;---------------------------

var_m: ;Temp uses
dw 0x0000
;var_n: ;Temp fdir sp storage
;dw 0x0000

filesize:
dw 0x0000,0x0200

var_x:
dw 0x00
var_y:
dw 0x01

row	db 0x00
col	db 0x00

head:
db 0x00
track:
db 0x00

DRIVE_TYPE:
db 0x00
SECTORS_PER_TRACK:
dw 0x0000
NUMBER_OF_DRIVES:
dw 0x0000
NUMBER_OF_HEADS:
dw 0x0000
os_random_seed	dw 0

teletype:
db 0x0f
rollcolor:
db 0x0f
scrollmode:
db 0xf0
slowmode:
db 0x0f
autostart:
db 0x0f
micro:
db 0xf0
; multi:
; db 0x0f
cursor:
db 0xf0
echo_flag:
db 0xf0
autosize_flag:
db 0xf0
advanced_flag:
db 0x0f
step_flag: db 0x0f
wall_flag: db 0x0f
completeload_flag:
db 0xf0
currentdir:
dw 0x0013
currentdirtemp:
dw 0x0013
returncode:
db 0x00
size:
dw 0x01
drive:
db 0x80
drive2:
db 0x80
mode:
db 0x03
color:
;db 27
db 0x31
color2:
;db 49
db 0x74
;frame:
;db 0x0A
; xmouse:
; dw 0x0000
; ymouse:
; dw 0x0000
page:
dw 0
;--------
;File Locations
loc:
dw 0x6000
locf1:
dw 0x6500
locf2:
dw 0x7000
locf3:
dw 0x7500
locf4:
dw 0x8000
locf5:
dw 0x8500
locf6:
dw 0x9000
locf7:
dw 0x9500
;--------
loc2: ; Folder
dw 0x0000
; dw 0x9400
loc3: ; Root
dw 0x7000
loc4: ; Program List
dw 0xA000
temploc:
dw 0xF000
kernel_seg:
dw 0x0000
data_seg:
dw 0x0000
dir_seg:
dw 0x2000
extra:
dw 0x0000
comm:
dw 0x0000
comm2:
dw 0x0000
free_roam:
db 0x0f
insert_mode:
db 0xF0

kernelreturnflag:
db 0x0F
kernelreturnaddr:
dw 0

argument_position:
dw 0

c_start:

c_load:
db 'load',0
c_save:
db 'save',0
c_run:
db 'run',0
c_runa:
db 'runa',0
c_execute:
db 'execute',0
c_batch:
db 'batch',0
c_text:
db 'text',0
c_code:
db 'code',0
c_doc:
db 'doc',0
; c_read:
; db 'read',0
c_edit:
db 'edit',0
c_type:
db 'type',0
c_print:
db 'print',0
c_clock:
db 'clock',0
;c_frame:
;db 'frame',0
c_wall:
db 'wall',0
drivestr:
c_drive:
db 'drive',0
c_drive2:
db 'drive2',0
c_driveinfo:
db 'driveinfo',0
c_debug:
db 'debug',0
c_pipe:
db 'pipe',0
c_loc:
db 'loc',0
c_loc2:
db 'loc2',0
c_loc3:
db 'loc3',0
c_dataseg:
db 'dataseg',0
c_htod:
db 'htod',0
c_dtoh:
db 'dtoh',0
c_reset:
db 'reset',0
c_cls:
db 'cls',0
c_prompt:
db 'prompt',0
c_alias:
db 'alias',0
c_border:
db 'border',0
c_color:
db 'color',0
c_color2:
db 'color2',0
c_typemode:
db 'typemode',0
c_videomode:
db 'videomode',0
c_scrolllen:
db 'scrolllen',0
; c_difficulty:
; db 'difficulty',0
; c_length:
; db 'length',0
c_rollcolor:
db 'rollcolor',0
c_scrollmode:
db 'scrollmode',0
c_slowmode:
db 'slowmode',0
;c_memsize:
;db 'memsize',0
c_micro:
db 'micro',0
; c_multi:
; db 'multi',0
c_settime:
db 'settime',0
c_setdate:
db 'setdate',0
c_alarm:
db 'alarm',0
c_alarmtext:
db 'alarmtext',0
c_autostart:
db 'autostart',0
c_setting:
db 'setting',0
c_install:
db 'install',0
; c_score:
; db 'score',0
; c_icon:
; db 'icon',0
; c_point:
; db 'point',0
c_page:
db 'page',0
c_track:
db 'track',0
c_head:
db 'head',0
c_size:
db 'size',0
c_fsize:
db 'fsize',0
c_fname:
db 'fname',0
c_autosize:
db 'autosize',0
c_advanced:
db 'advanced',0
c_completeload:
db 'completeload',0
c_idle_time:
db 'idletime',0
c_idle_command:
db 'idlecmd',0

c_q:
db 'q',0
c_a:
db 'a',0
c_z:
db 'z',0
c_roam:
db 'roam',0
c_dir:
db 'dir',0
c_newdir:
db 'newdir',0
c_setdir:
db 'setdir',0
c_addpath:
db 'addpath',0
c_addpathc:
db 'addpathc',0

c_nm:
db 'nm',0
c_fnew:
db 'fnew',0
c_fsave:
db 'fsave',0
c_rename:
db 'rename',0
c_copy:
db 'copy',0
c_del:
db 'del',0
c_cd:
db 'cd',0
c_cddot:
db 'cd..',0

c_sound:
db 'sound',0
c_reboot:
db 'reboot',0
c_restart:
db 'restart',0
c_step:
db 'step',0
; c_play:
; db 'play',0
c_calc:
db 'calc',0
; c_bcalc:
; db 'bcalc',0
c_paint:
db 'paint',0
;c_video:
;db 'video',0
;c_vedit:
;db 'vedit',0
; c_star:
; db 'star',0
c_help:
db 'help',0
c_exit:
db 'exit',0
c_cursor:
db 'cursor',0
c_echo:
db 'echo',0
c_fhlt:
db 'fhlt',0
; c_jmp:
; db 'jmp',0

c_end:

axs:
db 'AX',0
cxs:
db 'CX',0
dxs:
db 'DX',0
bxs:
db 'BX',0
sps:
db 'SP',0
bps:
db 'BP',0
sis:
db 'SI',0
dis:
db 'DI',0
ips:
db 'IP',0
flags:
db '   Flags  ',0
dss:
db 'DS',0
ess:
db 'ES',0
sss:
db 'SS',0
css:
db 'CS',0
; bmps:
; db 'BMP',0
; txts:
; db 'TXT',0
coms:
db 'COM',0
;pics:
;db 'PIC',0
;vids:
;db 'VID',0
; pnts:
; db 'PNT',0
x_str:
db 'X :',0
y_str:
db 'Y :',0

gdtinfo: dw gdt_end - gdt -1
dd gdt
gdt: dd 0,0
flatdesc: db 0xff,0xff,0,0,0,10010010b,11001111b,0
gdt_end:
db 0

ver:
dw 1029
verstring:
db ' Aplaun OS (version 1.02.9) ',0
main_list:
db 'Main : load,save,run,execute,batch',0
editor_list:
db 'View/Editors: text,code,doc,edit,type,sound,paint',0
; setting_list:
; db 'Settings: loc,prompt,color,drive,autosize',0
; setting2_list:
; db 'echo,page,help,exit,calc,clock',0
; showsetting_list:
; db 'driveinfo,debug,alias,border,setting',0
; misc_list:
; db 'micro,wall,restart,reset,cls',0
; advanced_cmd:
; db 'Adv/pro: fhlt,step,addpathc,dataseg,runa',0
; common_control:
; db 'Common Keys : Arrow,wasd,F1 series,Tab-Change,(Esc or ~)-Close',0
loc_command:
db 'Locations: loc(apps/files),loc2(Folder),loc3(FAT)',0
; experimental:
; db 'Experimental: ',0
file_command:
db 'File: q,a,z,{fname,nm},fnew,del,fsave',0
dir_command:
db 'Dir: dir,newdir,cd,cd..,rename,copy,roam',0
mint_list:
db 'Mint:d-date,t-time,c-clock,{i,I}print,h-help,v-ver,s-space,p-pause,l-line,e-exit',0

doc_helpstr:
db 0x1B,0x18,0x19,0x1A,' (Esc,~)-Close, F1-Help,F3-Copy,{F4,Insert-Paste},F5-Details,F6-Fill0',0
; read_helpstr:
; db '(Enter,PgDwn)-Next Page, (Home,PgUp)-GoBack, (F2,F3)-jmp to loc',0
step_helpstr:
db '(Esc,q)-quit (Ins,End)-Continue ',0
;vedit_helpstr:
;db 0x1B,0x18,0x19,0x1A,'-Move,Esc-Close,F1-Help,F2-chaincopy,F3-Copy,F4-Paste,F5-Details',0
;vedit_helpstr2:
;db ' (Del-ColorDown,End-ColorUp), (Insert-CharDown,Home-CharUp)',0
;vedit_helpstr3:
;db ' (PgUp-FrameUp,PgDown-FrameDown), F6-Fill,F7-Clear,F8-Clean,F9-SetWall',0
edit_help_str:
db "F1About [F2]Save F3Copy F4Paste [F5]New [F6]Load [F7]LineDel F8Details F9Option",0

shutdownstr:
db 'System Halted. Safe to turn off.',0
process_returnstr:
db 'RetValue',0
;drive_f:
;db 'Drive :',0
; imsgf:
; db 'Floppy:',0
; imsgh:
; db 'Hard disk:',0
mousestr:
db 'Mouse',0
gameportstr:
db 'GmPort',0
messagestr:
db 'msg:',0
freespacestr:
db 'free space : ',0
kernel_idle_time_str:
db 'idle kernel waiting time',0
kernel_idle_command_str:
db 'idle-kernel command',0
imsge:
db 'Failed',0
successstr:
db 'Success',0
notfoundstr:
db 'Not '
foundstr:
db 'Found',0
toobigstr:
db 'Too big',0
argstr:
db 'Arguments: ',0
; drive_type_str:
; db 'DrvType:',0
numberof_str:
db 'No. of ',0
drive_spt_str:
db 'Sector/Track:',0
new_file_str:
db 'New '
file_name_str:
db 'File Name :',0
file_selector_str:
db 'Select a file >>',0

con:
db 'ON',0
coff:
db 'OFF',0
oldstr:
db 'old',0
newstr:
db 'new',0
all_command_str:
db 'All'
commandstr:
db ' Command: ',0
; imagestr:
; db 'image',0
; drivestr:
; db 'drive',0
labelstr:
db 'label',0
dirstr:
db 'dir  ',0
filestr:
db 'file ',0
attribstr:
db 'attrib',0
normalstr:
db 'normal',0
readonlystr:
db 'readonly',0
hiddenstr:
db 'hidden',0
systemstr:
db 'system',0
archivestr:
db 'archive,new',0
dividebyzerostr:
db 'div/0',0
invalidstr:
db 'Invalid',0
mathprocstr:
db 'MathCPU',0
; doublefaultstr:
; db 'DoubleFault',0
; pagefaultstr:
; db 'PageFault',0
faultstr:
db 'Fault',0
exception_str:
db 'Exception ',0

alarmtextstr:
db 'Alarm',0 ; anykey=kernel enter=continue
;db ' Alarm :Press anykey=kernel or enter=continue.',0

path_list:
times 10 dw 0
autorunstr:
;db 'pwd confg lvlh ',0
;db 'confg pwd lvlh ',0
db 'autorun ',0
idle_kernel_waittime:
db 10
idle_kenel_commandstr:
;db 'clock screen p ',0
db 'roam wwwwwwwwwww',0
idle_kenel_commandstr_end:

ImageName:
db 'COMMON  TXT'
dw 0
ImageNameTemp:
db 'COMMON  TXT'
dw 0
prompt:
db 'Bigger Picture:',0
command_tempchar:
db 0
tempstr:
times 20 db 0
tempstr2:
times 40 db 0

;times 5 db 0
;times 15 db 0
;currentprocess:
; db 0
;totalprocess:
; db 1
;pcb:
; db 0x00
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

; db 0x01
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

; db 0x02
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

; db 0x03
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

; db 0x04
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

; db 0x05
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

; db 0x06
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

; db 0x07
; db 0x00
; db 0x01
; times 9 dw 0
; dw 0

;TODO implementation
; previous_command_buffersize equ 80
; previous_command_index:
; dw 0
; previous_command:
; times previous_command_buffersize db 0

found:
times 25 db 0

;times (512*44)-($-$$) db 0 ; Diet Size
; times (512*45+0x100)-($-$$) db 0 ; Optimal Size
times (512*51)-($-$$) db 0 ; Healthy Size