
org 0x100

SECTION .text

main:
out 0x44, ax

call vga_init

mov edx, [level]
call load_level

call vga_print_level

.main_loop:
	call control
	;call vga_print_level
	call need_next_level
jmp .main_loop

call vga_quit
call end

; edx -- cislo levela
load_level:
	pushad
		mov eax, [level_array+edx*4]
		
		cmp eax, 0
		jnz .no_end
			dec edx
			mov [level], edx
			mov eax, [level_array+edx*4]
		.no_end:

		.my_loop:
			mov cl, [eax+ebx]
			mov [place+ebx], cl

			inc ebx
		cmp ebx, 16*16
		jnz .my_loop

	popad
ret

; eax - offset
vga_refresh_element:
	pushad
		xor ebx, ebx
		mov bl, [place+eax]
		mov ebp, [object+ebx*4]

		xor edx, edx
		mov ebx, 16

		div ebx

		mov ebx, edx

		; eax - y
		; ebx - x

		mov ecx, 10
		mul ecx
		mov edi, eax

		mov eax, ebx
		mov ecx, 10
		mul ecx
		mov esi, eax

		call vga_put_image
	popad
ret

vga_print_level:
	pushad
		xor esi, esi
		xor edi, edi
		xor eax, eax

.loop_y:
		xor ebx, ebx
		mov bl, [place+eax]
		mov ebp, [object+ebx*4]

		call vga_put_image

		add esi, 10
		inc eax
		
		cmp esi, 10*16
		jnz .loop_x
			mov esi, 0
			add edi, 10
		.loop_x:

		cmp edi, 10*16
		jnz .loop_y

	popad
ret

; edx -- player move
player_action:
	pushad

	mov eax, place

	.loop_1:

		cmp byte [eax], 0x5
		jnz .no_found_player
			jmp .found_player
		.no_found_player:

	inc eax
	cmp eax, 16*16
	jnz .loop_1

	.found_player:

	mov ecx, eax
	add ecx, edx
	add ecx, edx

	add edx, eax

	cmp byte [edx], 3
	jnz .no_box
		cmp byte [ecx], 0
		jnz .no_move_box
			mov byte [ecx], 3
			mov byte [edx], 0
		.no_move_box:

		cmp byte [ecx], 2
		jnz .no_move_box_to_point
			mov byte [ecx], 4
			mov byte [edx], 0
		.no_move_box_to_point:
	.no_box:
	
	cmp byte [edx], 4
	jnz .no_box2
		cmp byte [ecx], 0
		jnz .no_move_box2
			mov byte [ecx], 4
			mov byte [edx], 0
		.no_move_box2:

		cmp byte [ecx], 2
		jnz .no_move_box_to_point2
			mov byte [ecx], 4
			mov byte [edx], 2
		.no_move_box_to_point2:
	.no_box2:

	cmp byte [edx], 0
	je .move_player

	cmp byte [edx], 2
	je .move_player

	jmp short .ret

	.move_player:
		mov bl, [ground]
		mov byte [eax], bl;
	
		mov bl, [edx]
		mov [ground], bl
		mov byte [edx], 5

	.ret:

	sub eax, place
	call vga_refresh_element

	sub edx, place
	mov eax, edx
	call vga_refresh_element

	sub ecx, place
	mov eax, ecx
	call vga_refresh_element

	popad
ret

control:
	pushad

	call read_key

	cmp al, 0
	jnz .no_special_key
		call read_key

		cmp al, 'H'
		jnz .no_up
			mov edx, -16
			call player_action
		.no_up:

		cmp al, 'M'
		jnz .no_right
			mov edx, 1
			call player_action
		.no_right:

		cmp al, 'K'
		jnz .no_left
			mov edx, -1
			call player_action
		.no_left:

		cmp al, 'P'
		jnz .no_down
			mov edx, 16
			call player_action
		.no_down:

	.no_special_key:

	cmp al, 'r'
	jnz .no_restart
		mov edx, [level]
		call load_level
		
		call vga_clean
		call vga_print_level
	.no_restart:

	cmp al, 'n'
	jnz .no_next_level
		inc dword [level]
		mov edx, [level]
		call load_level
		
		call vga_clean
		call vga_print_level
	.no_next_level:

	cmp al, 27
	jnz .no_esc
		call vga_quit
		call end
	.no_esc:

	popad
ret

need_next_level:
	pushad

	mov eax, place

	.loop_1:

	cmp byte [eax], 3
	jz .my_ret

	inc eax
	cmp eax, place+16*16
	jnz .loop_1

	inc dword [level]
	mov edx, [level]
	call load_level
	
	call vga_clean
	call vga_print_level

	.my_ret:

	popad
ret

; ============================================================
; cita klaves z klavesnice
; ak je to specialny znak 0x0
; cita nasledujuci znak
; al -- nacitany znak z klavesnice
read_key:
.loop:
	mov ah, 0x07
	int 0x21
	;cmp al, 0x0
	;jz .loop
ret

; ============================================================
vga_init:
; inicialuzuje VGA
	xor	eax, eax
	mov	al, 0x13
	int	0x10
ret

; ============================================================
vga_clean:
	pushad
	
	push	word 0xa000
	pop	es
	
	mov eax, 320*200
	
	.loop:
		mov byte [es:eax], 0
		dec eax
	cmp eax, 0
	jnz .loop
	
	popad
ret

; ============================================================
; zasvieti pixel
; esi -- suradnica X
; edi -- suradnica Y
; cl - color
vga_put_pixel:
	pushad
	
	push	word 0xa000
	pop	es
	
	mov eax, 320	; eax = 320
	mul edi		; eax *= edi
	add eax, esi    ; eax += esi

	mov byte [es:eax], cl
	
	popad
ret

; ============================================================
; esi -- suradnica X
; edi -- suradnica Y
; ebp -- surandnica obrazka
vga_put_image:
	pushad
	
	mov ebx, esi

	mov ecx, esi
	xor eax, eax
	mov al, [ebp]
	add ecx, eax
	inc ebp
	
	mov edx, edi
	xor eax, eax
	mov al, [ebp]
	add edx, eax
	inc ebp

	.loop_y:
		push cx
		mov cl, [ebp]
		call vga_put_pixel
		pop cx

		inc esi
		inc ebp
	
		cmp esi, ecx
		jnz .loop_x
			mov esi, ebx
			inc edi
		.loop_x:
		
	cmp edi, edx
	jnz .loop_y

	popad

ret

; ============================================================
; ukonci VGA
vga_quit:
	xor ax, ax
	mov es, ax

	mov ax, 0x02
	int 0x10
ret

; ============================================================
; ukonci program
end: 
	mov ah, 0x4c
	mov al, 0x0
	int 0x21
ret

; ============================================================

SECTION .data

g_nothing: db 0xA, 0xA
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

g_wall:
	db 0xA, 0xA
	db 0x07,0x07,0x0F,0x07,0x07,0x07,0x07,0x07,0x07,0x07
	db 0x07,0x07,0x0F,0x07,0x07,0x07,0x07,0x07,0x07,0x07
	db 0x07,0x07,0x0F,0x07,0x07,0x07,0x07,0x07,0x07,0x07
	db 0x07,0x07,0x0F,0x07,0x07,0x07,0x07,0x07,0x07,0x07
	db 0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F,0x0F
	db 0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x0F,0x07,0x07
	db 0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x0F,0x07,0x07
	db 0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x0F,0x07,0x07
	db 0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x0F,0x07,0x07
	db 0x07,0x07,0x07,0x07,0x07,0x07,0x07,0x0F,0x07,0x07

g_point:
	db 0xA, 0xA
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x0E,0x0E,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x0E,0x0E,0x0E,0x0E,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x0E,0x0E,0x0E,0x0E,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x0E,0x0E,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

g_box:
	db 0xA, 0xA
	db 0x00,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x00
	db 0x06,0x00,0x06,0x06,0x06,0x06,0x06,0x06,0x00,0x06
	db 0x06,0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x06,0x06
	db 0x06,0x06,0x00,0x06,0x06,0x06,0x06,0x00,0x06,0x06
	db 0x06,0x06,0x00,0x06,0x06,0x06,0x06,0x00,0x06,0x06
	db 0x06,0x06,0x00,0x06,0x06,0x06,0x06,0x00,0x06,0x06
	db 0x06,0x06,0x00,0x06,0x06,0x06,0x06,0x00,0x06,0x06
	db 0x06,0x06,0x00,0x00,0x00,0x00,0x00,0x00,0x06,0x06
	db 0x06,0x00,0x06,0x06,0x06,0x06,0x06,0x06,0x00,0x06
	db 0x00,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x06,0x00 

g_box2:
	db 0xA, 0xA
	db 0x00,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x00
	db 0x04,0x00,0x04,0x04,0x04,0x04,0x04,0x04,0x00,0x04
	db 0x04,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x04
	db 0x04,0x04,0x00,0x04,0x04,0x04,0x04,0x00,0x04,0x04
	db 0x04,0x04,0x00,0x04,0x04,0x04,0x04,0x00,0x04,0x04
	db 0x04,0x04,0x00,0x04,0x04,0x04,0x04,0x00,0x04,0x04
	db 0x04,0x04,0x00,0x04,0x04,0x04,0x04,0x00,0x04,0x04
	db 0x04,0x04,0x00,0x00,0x00,0x00,0x00,0x00,0x04,0x04
	db 0x04,0x00,0x04,0x04,0x04,0x04,0x04,0x04,0x00,0x04
	db 0x00,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x04,0x00 

g_you:
	db 0xA, 0xA
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x0E,0x0E,0x0E,0x0E,0x00,0x00,0x00
	db 0x00,0x00,0x0E,0x0E,0x0E,0x0E,0x0E,0x0E,0x00,0x00
	db 0x00,0x0E,0x0E,0x00,0x0E,0x0E,0x00,0x0E,0x0E,0x00
	db 0x00,0x0E,0x0E,0x0E,0x0E,0x0E,0x0E,0x0E,0x0E,0x00
	db 0x00,0x0E,0x0E,0x00,0x0E,0x0E,0x00,0x0E,0x0E,0x00
	db 0x00,0x0E,0x0E,0x0E,0x00,0x00,0x0E,0x0E,0x0E,0x00
	db 0x00,0x00,0x0E,0x0E,0x0E,0x0E,0x0E,0x0E,0x00,0x00
	db 0x00,0x00,0x00,0x0E,0x0E,0x0E,0x0E,0x00,0x00,0x00
	db 0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00

object: dd g_nothing, g_wall, g_point, g_box, g_box2, g_you

ground:
	db 0

level:
	dd 0

level_array: dd level1, level2, level3, level4, level5, level6, 0

level1:
	db 0,0,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,1,2,1,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,1,0,1,1,1,1,0,0,0,0,0,0,0,0
	db 1,1,1,3,0,3,2,1,0,0,0,0,0,0,0,0
	db 1,2,0,3,5,1,1,1,0,0,0,0,0,0,0,0
	db 1,1,1,1,3,1,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,1,2,1,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,1,1,1,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

level2:
	db 1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	db 1,5,0,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 1,0,3,3,1,0,1,1,1,0,0,0,0,0,0,0
	db 1,0,3,0,1,0,1,2,1,0,0,0,0,0,0,0
	db 1,1,1,0,1,1,1,2,1,0,0,0,0,0,0,0
	db 0,1,1,0,0,0,0,2,1,0,0,0,0,0,0,0
	db 0,1,0,0,0,1,0,0,1,0,0,0,0,0,0,0
	db 0,1,0,0,0,1,1,1,1,0,0,0,0,0,0,0
	db 0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

level3:
	db 0,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0
	db 0,1,0,0,0,0,0,1,1,1,0,0,0,0,0,0
	db 1,1,3,1,1,1,0,0,0,1,0,0,0,0,0,0
	db 1,0,5,0,3,0,0,3,0,1,0,0,0,0,0,0
	db 1,0,2,2,1,0,3,0,1,1,0,0,0,0,0,0
	db 1,1,2,2,1,0,0,0,1,0,0,0,0,0,0,0
	db 0,1,1,1,1,1,1,1,1,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

level4:
	db 0,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0
	db 1,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 1,5,3,0,1,0,0,0,0,0,0,0,0,0,0,0
	db 1,1,3,0,1,1,0,0,0,0,0,0,0,0,0,0
	db 1,1,0,3,0,1,0,0,0,0,0,0,0,0,0,0
	db 1,2,3,0,0,1,0,0,0,0,0,0,0,0,0,0
	db 1,2,2,4,2,1,0,0,0,0,0,0,0,0,0,0
	db 1,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

level5:
	db 0,1,1,1,1,1,0,0,0,0,0,0,0,0,0,0
	db 0,1,5,0,1,1,1,0,0,0,0,0,0,0,0,0
	db 0,1,0,3,0,0,1,0,0,0,0,0,0,0,0,0
	db 1,1,1,0,1,0,1,1,0,0,0,0,0,0,0,0
	db 1,2,1,0,1,0,0,1,0,0,0,0,0,0,0,0
	db 1,2,3,0,0,1,0,1,0,0,0,0,0,0,0,0
	db 1,2,0,0,0,3,0,1,0,0,0,0,0,0,0,0
	db 1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

level6:
	db 0,0,0,1,1,1,1,1,1,1,0,0,0,0,0,0
	db 1,1,1,1,0,0,0,0,0,1,0,0,0,0,0,0
	db 1,0,0,0,2,1,1,1,0,1,0,0,0,0,0,0
	db 1,0,1,0,1,0,0,0,0,1,1,0,0,0,0,0
	db 1,0,1,0,3,0,3,1,2,0,1,0,0,0,0,0
	db 1,0,1,0,0,4,0,0,1,0,1,0,0,0,0,0
	db 1,0,2,1,3,0,3,0,1,0,1,0,0,0,0,0
	db 1,1,0,0,0,0,1,0,1,0,1,1,1,0,0,0
	db 0,1,0,1,1,1,2,0,0,0,5,0,1,0,0,0
	db 0,1,0,0,0,0,0,1,1,0,0,0,1,0,0,0
	db 0,1,1,1,1,1,1,1,1,1,1,1,1,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
	db 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

SECTION .bss

place : resb 16*16