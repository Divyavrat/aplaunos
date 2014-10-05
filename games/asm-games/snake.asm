
org 0x100

space_w		EQU	42
space_h		EQU	27
grow_plus	EQU	5
snake_len	EQU	3

SECTION .text

main:

	call game_init

	call vga_init
	
	call vga_clean
	call game_draw

	.tick_loop:

	call get_ticks
	mov esi, eax

	call game_move

	;call vga_clean
	;call game_draw

	.main_loop:

	call is_press_any_key
	cmp al, 0xff
	jnz .no_press_any_key

		call read_key

		cmp al, 0x0
		jnz .no_press_special_key
			call read_key

			cmp al, 'H'
			jnz .no_press_key_up
			cmp byte [route], +space_w
			jz .no_press_key_up
				mov edx, -space_w
				mov [route], edx
				jmp .main_loop
			.no_press_key_up:

			cmp al, 'M'
			jnz .no_press_key_right
			cmp byte [route], -1
			jz .no_press_key_right
				mov edx, +1
				mov [route], edx
				jmp .main_loop
			.no_press_key_right:

			cmp al, 'K'
			jnz .no_press_key_left
			cmp byte [route], +1
			jz .no_press_key_left
				mov edx, -1
				mov [route], edx
				jmp .main_loop
			.no_press_key_left:

			cmp al, 'P'
			jnz .no_press_key_down
			cmp byte [route], -space_w
			jz .no_press_key_down
				mov edx, +space_w
				mov [route], edx
				jmp .main_loop
			.no_press_key_down:

		.no_press_special_key:

		cmp al, 27
		jnz .no_press_esc
			jmp .end
		.no_press_esc:

		cmp al, 'r'
		jnz .no_press_reset
			call game_init
			call vga_clean
			call game_draw
		.no_press_reset:

 	.no_press_any_key:

	call get_ticks
	sub eax, esi
	cmp eax, 8
	jb .main_loop

	jmp .tick_loop

	.end:
	call vga_quit
	call end

; ============================================================
game_init:
	xor eax, eax
	.loop:
		mov byte [space+eax], 0x0
		inc eax
		cmp eax, space_w*space_h
	jnz .loop

	xor eax, eax
	.loop_2:
		inc eax

		mov byte [space+ (space_h/2)*space_w+(space_h/2-snake_len/2)+eax], al

		cmp eax, snake_len+1
	jnz .loop_2

	xor eax, eax
	.loop_a:
		mov byte [space+eax], 0xfe
		inc eax

		cmp eax, space_w-1
	jnz .loop_a

	mov eax, space_w*(space_h-1)
	.loop_b:
		mov byte [space+eax], 0xfe
		inc eax

		cmp eax, space_w*space_h
	jnz .loop_b

	xor eax, eax
	.loop_c:
		mov byte [space+eax], 0xfe
		add eax, space_w

		cmp eax, space_w*space_h
	jnz .loop_c

	mov eax, space_w-1
	.loop_d:
		mov byte [space+eax], 0xfe
		add eax, space_w

		cmp eax, space_w*space_h-1
	jnz .loop_d

	call game_add_point

	mov eax, -1
	mov [route], eax

	xor eax, eax
	mov [grow], eax
ret

; ============================================================
z_game_draw:
	xor eax, eax

	xor edi, edi

	.loop_y:
		xor esi, esi

		.loop_x:
			cmp byte [space+eax], 0x0
			jz .next
				mov ebp, snake_g

				cmp byte [space+eax], 0xfe
				jnz .no_wall
					mov ebp, wall_g
				.no_wall:

				cmp byte [space+eax], 0xfa
				jnz .no_point
					mov ebp, point_g
 				.no_point:

				call vga_draw_image
			.next:

			inc eax
			add esi, 8
			cmp esi, space_w*8
		jnz .loop_x
			
		add edi, 8
		cmp edi, space_h*8
	jnz .loop_y
ret

game_draw:
	xor eax, eax

	xor edi, edi

	.loop_y:
		xor esi, esi

		.loop_x:
			cmp byte [space+eax], 0xfe
			jz .no_draw

			cmp byte [space+eax], 0x0
			jz .next
				mov ebp, snake_g
				sub esi, 8
				sub edi, 8

				cmp byte [space+eax], 0xfe
				jnz .no_wall
					mov ebp, wall_g
				.no_wall:

				cmp byte [space+eax], 0xfa
				jnz .no_point
					mov ebp, point_g
 				.no_point:

				call vga_draw_image

				add esi, 8
				add edi, 8
			.next:

			.no_draw:

			inc eax
			add esi, 8
			cmp esi, space_w*8
		jnz .loop_x
			
		add edi, 8
		cmp edi, space_h*8
	jnz .loop_y
ret

; ============================================================
; eax -- offset v pritore space
game_refresh:
	pushad
		push eax

		xor edx, edx
		mov ecx, space_w
		div ecx
		; EAX Y
		; EDX X

		push edx
		mov ebx, 8
		mul ebx
		mov edi, eax

		pop eax
		mul ebx
		mov esi, eax

		pop eax

		sub esi, 8
		sub edi, 8

		cmp byte [space+eax], 0x0
		jnz .no_empty
			call vga_clean_cube
			jmp .return
		.no_empty:

			mov ebp, snake_g

			cmp byte [space+eax], 0xfe
			jnz .no_wall
				mov ebp, wall_g
			.no_wall:

			cmp byte [space+eax], 0xfa
			jnz .no_point
				mov ebp, point_g
			.no_point:

			call vga_draw_image

		add esi, 8
		add edi, 8

		.return:
	popad
ret

; ============================================================
game_add_point:
	pushad
		.loop:
			call get_date

			mov eax, edx
			xor edx, edx
			mov ebx, space_w*space_h
			div ebx
			
			cmp byte [space+edx], 0x0
			jnz .loop

			mov byte [space+edx], 0xfa

			mov eax, edx
			call game_refresh
	popad

ret

; ============================================================
game_move:
	pushad

	xor ebx, ebx ; pozicia hlavy
	xor ecx, ecx ; pozicia chvosta
	xor dl, dl   ; najvascia najdena hodnota

	xor eax, eax ; citac cyklu

	.loop_1:
		cmp byte [space+eax], 0x1
		jnz .continue_head
			mov ebx, eax	
		.continue_head:

		cmp [space+eax], dl
		jb .continue_tial

		cmp byte [space+eax], 0xf0
		jae .continue_tial

			mov ecx, eax
			mov dl, [space+eax]
		.continue_tial:

		inc eax
		cmp eax, space_w*space_h
	jnz .loop_1

	xor eax, eax ; citac cyklu

	.loop_2:
		cmp byte [space+eax], 0x1
		jb .continue

		cmp byte [space+eax], 0xf0
		jae .continue

			inc byte [space+eax]
		.continue:

		inc eax
		cmp eax, space_w*space_h
	jnz .loop_2

	add ebx, [route]

	cmp byte [space+ebx], 0xfe
	jnz .no_wall
		cmp dword [route], -space_w
		jnz .no_route_up
			add ebx, space_w*(space_h-2)
		.no_route_up:

		cmp dword [route], +1
		jnz .no_route_right
			sub ebx, space_w-2
		.no_route_right:

		cmp dword [route], -1
		jnz .no_route_left
			add ebx, space_w-2
		.no_route_left:

		cmp dword [route], +space_w
		jnz .no_route_down
			sub ebx, space_w*(space_h-2)
		.no_route_down:
	.no_wall:

	cmp byte [space+ebx], 0xfa
	jnz .no_point
		mov byte [space+ebx], 0x0
		mov edx, grow_plus
		add [grow], edx

		call game_add_point
	.no_point:

	cmp byte [space+ebx], 0x00
	jnz .no_step
		inc byte [space+ebx]		; posun hlavu
	
		cmp dword [grow], 0x0
		jz .no_grow
			dec dword [grow]
			jmp .prev_return
		.no_grow:

		mov byte [space+ecx], 0x0	; vymaz chvost
		jmp .prev_return
	.no_step:

	;fail
	call game_init
	call vga_clean
	call game_draw

	jmp .return

	.prev_return:
		mov eax, ebx
		call game_refresh
	
		mov eax, ecx
		call game_refresh

	.return:

	popad
ret

; ============================================================
; zistuje ci je stlaceny lubovolny klaves
; al -- 0x00 -- nie
; al -- 0xff -- ano
is_press_any_key:
	mov ah, 0x0B
	int 0x21
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
; zisti aktualny cas
; ch -- hodiny
; cl -- minuty
; dh -- sekundy
; dl -- stotiny
get_date:
	mov ah, 0x2c
	int 0x21
ret

; ============================================================
; varti pocet tiknuti
; eax -- pocet tiknuti
get_ticks:
	pushad

	mov ah, 0x2c
	int 0x21

	xor esi, esi	; esi = 0

	push edx
	xor ebx, ebx	; ebx = 0
	mov bl, ch	; pocet_hodin
	mov eax, 360000	; 360000
	mul ebx		; EAX <- pocet_hodin * 360000
	add esi, eax	; pripocitaj do vysledku
	pop edx
	
	push edx
	xor ebx, ebx	; ebx = 0
	mov bl, cl	; pocet_minut
	mov eax, 6000	; 6000
	mul ebx		; EAX <- pocet_minut * 6000
	add esi, eax	; pripocitaj do vysledku
	pop edx

	push edx
	xor ebx, ebx	; ebx = 0
	mov bl, dh	; pocet_sekund
	mov eax, 100	; 100
	mul ebx		; EAX <- pocet_sekund * 100
	add esi, eax	; pripocitaj do vysledku
	pop edx

	push edx
	xor ebx, ebx	; ebx = 0
	mov bl, dl	; pocet_stotin
	add esi, ebx	; pripocitaj do vysledku
	pop edx
	
	mov [timer_tmp], esi

	popad
	mov eax, [timer_tmp]
ret

; ============================================================
vga_init:
; inicialuzuje VGA
	xor eax, eax
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
vga_put_pixel:
	pushad
	
	push	word 0xa000
	pop	es
	
	mov eax, 320	; eax = 320
	mul edi		; eax *= edi
	add eax, esi    ; eax += esi

	mov byte [es:eax], 0x50
	
	popad
ret

; ============================================================
; zhasne pixel
; esi -- suradnica X
; edi -- suradnica Y
vga_clean_pixel:
	pushad
	
	push	word 0xa000
	pop	es
	
	mov eax, 320	; eax = 320
	mul edi		; eax *= edi
	add eax, esi    ; eax += esi

	mov byte [es:eax], 0x0
	
	popad
ret

; ============================================================
; nakresli kocku
; esi -- suradnica X
; edi -- suradnica Y
; ebp -- adresa obrazka 8x8
vga_draw_image:
	pushad

	mov edx, esi
	xor ecx, ecx

	xor ebx, ebx
	.loop_y:
		xor eax, eax
		mov esi, edx
		.loop_x:

		cmp byte [ebp+ecx], 1
		jnz .yes
			call vga_put_pixel
		.yes:

		cmp byte [ebp+ecx], 0
		jnz .no
			call vga_clean_pixel
		.no:

		inc esi
		inc eax
		inc ecx	
		cmp eax, 8
		jnz .loop_x

		
	inc edi
	inc ebx
	cmp ebx, 8
	jnz .loop_y

	popad
ret

; ============================================================
; zmaze kocku
; esi -- suradnica X
; edi -- suradnica Y
vga_clean_cube:
	pushad

	mov edx, esi
	xor ecx, ecx

	xor ebx, ebx
	.loop_y:
		xor eax, eax
		mov esi, edx
		.loop_x:

		call vga_clean_pixel

		inc esi
		inc eax
		inc ecx	
		cmp eax, 8
		jnz .loop_x

		
	inc edi
	inc ebx
	cmp ebx, 8
	jnz .loop_y

	popad
ret

; ============================================================
; ukonci VGA
vga_quit:
	xor ax,ax
	mov es,ax

	mov ax,0x02
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

snake_g:	; 8x8
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1

wall_g:		; 8x8
	db 0,1,1,1,1,1,1,1
	db 1,1,0,0,0,0,1,1
	db 1,0,1,0,0,1,0,1
	db 1,0,0,1,1,0,0,1
	db 1,0,0,1,1,0,0,1
	db 1,0,1,0,0,1,0,1
	db 1,1,0,0,0,0,1,1
	db 0,1,1,1,1,1,1,1

point_g:	; 8x8
	db 0,0,0,0,0,0,0,0
	db 0,0,0,1,1,0,0,0
	db 0,0,1,1,1,1,0,0
	db 0,1,1,1,1,1,1,0
	db 0,1,1,1,1,1,1,0
	db 0,0,1,1,1,1,0,0
	db 0,0,0,1,1,0,0,0
	db 0,0,0,0,0,0,0,0

SECTION .bss
	str : resb 32
	timer_tmp : resd 1
	radom_tmp : resd 1
	space : resb space_w*space_h
	route : resd 1
	grow : resd 1
