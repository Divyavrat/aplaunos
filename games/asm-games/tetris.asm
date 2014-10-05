
org 0x100

SECTION .text

main:
	call space_init

	call get_random_numer
	mov [next_tetris], edx

	call space_new_element

	call vga_init
	call vga_clean

	call space_draw
	call space_draw_next_tetris

	main_loop:
	;call vga_clean
	;call space_draw

	call get_ticks
	mov esi, eax

	call space_down

	.tick_loop:

	call is_press_any_key
	cmp al, 0xff
	jnz .no_key
		call read_key

		cmp al, 27
		jnz .no_esc
			jmp .end
		.no_esc:

		cmp al, 'p'
		jnz .no_key_pause
			mov bl, [pause_mod]
			not bl
			mov [pause_mod], bl

			pushad
			call vga_clean
		
			call space_draw
			call space_draw_next_tetris
			popad

			mov bl, 0xff
			cmp [pause_mod], bl
			jnz .no_pause
				call vga_draw_pause
				jmp .tick_loop
			.no_pause:
		.no_key_pause:

		mov bl, 0x00
		cmp [pause_mod], bl
		jnz .tick_loop

		cmp al, 0x0
		jnz .no_special_key
			call read_key
	
			cmp al, 'M'
			jnz .no_move_right
				call space_right
			.no_move_right:
	
			cmp al, 'K'
			jnz .no_move_left
				call space_left
			.no_move_left:
	
			cmp al, 'P'
			jnz .no_move_down
				jmp main_loop
			.no_move_down:

			mov al, 0x0
		.no_special_key:

		cmp al, 'r'
		jnz .no_reset
			call space_init

			call get_random_numer
			mov [next_tetris], edx

			call space_new_element

			call vga_clean
		
			call space_draw
			call space_draw_next_tetris
		.no_reset:

		cmp al, ' '
		jnz .no_tetris_turn
			call space_tetris_turn
		.no_tetris_turn:
	.no_key:

	mov bl, 0x00
	cmp [pause_mod], bl
	jnz .tick_loop
	
	call get_ticks
	sub eax, esi
	cmp eax, 100
	jb .tick_loop

	jmp main_loop

.end:
	call vga_quit
	call end

; ============================================================
; vypise znak
; dl -- ASCII znak
print_char:
	mov ah, 0x02
	;mov dl, 'A'
	int 0x21
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
; caka na stlacenie lubovolneho klavesu
wait_press_any_key:
.loop:
	mov ah, 0x0B
	int 0x21
	cmp al, 0x00
	jz .loop
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
; vrat nahodne cislo od 0 do 6
; edx -- vratene nahodne cislo z  intervalu 0...eax-1
get_random_numer:
	pushad
		call get_date
		xor eax, eax

		cmp byte [radom_type], 0x0
		jnz .no_zero
			mov byte [radom_type], 0x1
			mov al, dl
			jmp .break
		.no_zero:

		cmp byte [radom_type], 0x0
		jz .xzero
			mov byte [radom_type], 0x0
			mov al, dh
			jmp .break
		.xzero:

		.break:

		xor edx, edx

		mov ebx, 7
		div ebx
		mov [radom_tmp], edx
	popad
	
	mov edx, [radom_tmp]
	;mov edx, 1
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
; bude cakat urcity pocet stotin sekundy
; edx -- pocet stotin sekundy
wait_time:
	push eax
	push edi

	call get_ticks
	mov edi, eax

	.loop:
		call get_ticks
		sub eax, edi
	
		cmp eax, edx
	jb .loop
	
	pop edi
	pop eax
ret

; ============================================================
; vypise reazec ukonceny znakom '$'
; dx -- pointer na retazex
print:
	mov ah, 0x09
	;mov dx, str
	int 0x21
ret

; ============================================================
HexDigit:
	cmp dl, 10
	jb .mensi
	add dl, 'A'-10
	ret
.mensi:
	or dl, '0'
	ret

; ============================================================
; eax - 32-bitove cislo
; ebx - zaklad sustavy
; edi - pointer na buffer kam sa zapise
NUMtoASCII:

	pushad
	xor esi, esi

.smycka_p:
	xor edx, edx
	div ebx
	call HexDigit
	push edx
	inc esi
	test eax, eax
	jnz .smycka_p
	cld

.smycka_z:
	pop eax
	stosb
	dec esi
	test esi, esi
	jnz .smycka_z
	mov byte [edi], '$'
	popad
ret


; ============================================================
space_init:
	xor eax, eax
	.loop_1:
		mov byte [space+eax], 0x0
		inc eax
	cmp eax, 25*12
	jnz .loop_1

	;mov byte [space+12*23+1], 0x1

	xor eax, eax
	.loop_2:
		mov byte [space+eax], 0x1
		add eax, 12
	cmp eax, 12*25
	jnz .loop_2

	mov eax, 11
	.loop_3:
		mov byte [space+eax], 0x1
		add eax, 12
	cmp eax, 11+12*24
	jnz .loop_3

	mov eax, 12*24
	.loop_4:
		mov byte [space+eax], 0x1
		inc eax
	cmp eax, 12*25
	jnz .loop_4
ret

space_print:
	pushad

	mov eax, space
	mov ebx, 0
	.loop:

		pushad
			mov edi, eax
			xor eax, eax
			mov al, [edi]
			mov ebx, 10
			mov edi, str
			call NUMtoASCII

			mov dx, str
			call print

			mov dl, ' '
			call print_char
		popad
	
		inc eax
		inc ebx

		cmp ebx, 12
		jnz .nic
			mov ebx, 0
			pushad
			mov dl, 0xA
			call print_char
			popad
		.nic:

	cmp eax, space+25*12
	jnz .loop

	popad
ret

; ============================================================
space_down_line:
	pushad
		cmp esi, space+1
		jz .return

		mov eax, esi
		sub eax, 12	; riadok nadomnou
		mov ebx, esi	; sucasny riadok
		mov ecx, 10	; citac

		.loop:
			mov dl, [eax]
			mov [ebx], dl

			inc eax
			inc ebx
			dec ecx
		cmp ecx, 0
		jnz .loop

	sub esi, 12
	call space_down_line

.return:
	popad
ret

; ============================================================
; hlada plny riadok
; esi -- adresa od ktorej sa hlada plny riadok
space_find_line:
	pushad

	cmp esi, space+1
	jz .return

	xor eax, eax
	xor edx, edx

	;mov esi, space+12*23+1
	
	.loop1:
		add dl, [esi]
		inc eax
		inc esi
	cmp eax, 10
	jnz .loop1

	sub esi, 10

	cmp dl, 10
	jnz .no_fill_line
		;call end
		call space_down_line
		call space_find_line
	.no_fill_line:

	sub esi, 12
	call space_find_line

	.return:
	popad
ret

; ============================================================
space_draw_next_tetris:
	pushad

	mov eax, 4*4*4
	mov ebx, [next_tetris]
	mul ebx

	mov ecx, eax
	add ecx, tetris

	mov esi, 150
	mov edi, 50

	mov edx, esi

	xor ebx, ebx
	.loop_y:
		xor eax, eax
		mov esi, edx
		.loop_x:

		cmp byte [ecx], 0
		jz .nothing
			call vga_draw_cube
		.nothing:

		add esi, 8
		inc eax
		inc ecx	
		cmp eax, 4
		jnz .loop_x

		
	add edi, 8
	inc ebx
	cmp ebx, 4
	jnz .loop_y

	popad
ret

; ============================================================
space_draw:
	pushad

	mov esi, 50
	xor edi, edi

	mov edx, esi
	xor ecx, ecx

	xor ebx, ebx
	.loop_y:
		xor eax, eax
		mov esi, edx
		.loop_x:

		cmp byte [space+ecx], 0
		jz .nothing
			call vga_draw_cube
		.nothing:

		add esi, 8
		inc eax
		inc ecx	
		cmp eax, 12
		jnz .loop_x

		
	add edi, 8
	inc ebx
	cmp ebx, 25
	jnz .loop_y

	popad
ret

; ============================================================
space_xchg:
	pushad

	xor eax, eax
	.loop_1:
		cmp byte [space+eax], 0x2
		jnz .next
			mov byte [space+eax], 0x1
		.next:
		inc eax
	cmp eax, 12*25
	jnz .loop_1

	popad
ret

; ============================================================
space_down:
	pushad

	mov esi, 50+11*8
	mov edi, 25*8

	xor eax, eax
	.loop_1:
		cmp byte [space+eax], 0x2
		jnz .next

		cmp byte [space+eax+12], 0x1
		jnz .next
			call space_xchg

			mov esi, space+12*23+1
			call space_find_line

			call space_new_element

			call vga_clean
		
			call space_draw
			call space_draw_next_tetris

			jmp .return

		.next:
		inc eax
	cmp eax, 12*25
	jnz .loop_1

	mov eax, 12*25-1
	.loop_2:
		cmp byte [space+eax], 0x2
		jnz .next_2

			call vga_draw_cube
			sub edi, 8
			call vga_clean_cube
			add edi, 8

			mov byte [space+eax], 0x0
			mov byte [space+eax+12], 0x2
		.next_2:

		sub esi, 8
		cmp esi, 50-8
		jnz .loop_3
			mov esi, 50+11*8
			sub edi, 8
		.loop_3:

		dec eax
	cmp eax, 0
	jnz .loop_2

	.return:
	popad
ret

space_right:
	pushad

	mov esi, 50+11*8
	mov edi, 24*8

	xor eax, eax
	.loop_1:
		cmp byte [space+eax], 0x2
		jnz .next

		cmp byte [space+eax+1], 0x1
		jnz .next
			jmp .return

		.next:
		inc eax
	cmp eax, 12*25
	jnz .loop_1

	mov eax, 12*25-1
	.loop_2:
		cmp byte [space+eax], 0x2
		jnz .next_2

			call vga_clean_cube
			add esi, 8
			call vga_draw_cube
			sub esi, 8

			mov byte [space+eax], 0x0
			mov byte [space+eax+1], 0x2
		.next_2:

		sub esi, 8
		cmp esi, 50-8
		jnz .loop_3
			mov esi, 50+11*8
			sub edi, 8
		.loop_3:

		dec eax
	cmp eax, 0
	jnz .loop_2

	.return:
	popad
ret

space_left:
	pushad

	mov esi, 50
	mov edi, 0

	xor eax, eax
	.loop_1:
		cmp byte [space+eax], 0x2
		jnz .next

		cmp byte [space+eax-1], 0x1
		jnz .next
			jmp .return

		.next:
		inc eax
	cmp eax, 12*25
	jnz .loop_1

	mov eax, 0
	.loop_2:
		cmp byte [space+eax], 0x2
		jnz .next_2

			call vga_clean_cube
			sub esi, 8
			call vga_draw_cube
			add esi, 8

			mov byte [space+eax], 0x0
			mov byte [space+eax-1], 0x2
		.next_2:

		add esi, 8
		cmp esi, 50+12*8
		jnz .loop_3
			mov esi, 50
			add edi, 8
		.loop_3:

		inc eax
	cmp eax, 12*25
	jnz .loop_2

	.return:
	popad
ret

; ============================================================
space_new_element:
	pushad

	mov edx, [next_tetris]
	mov [this_tetris], edx

	mov eax, 0x0
	mov [tetris_turn], eax

	mov eax, 4*4*4
	mul edx
	add eax, tetris
	mov edx, eax	; adresa na kocku

	mov esi, space+2

	xor eax, eax

	.loop_y:
		xor ebx, ebx

		.loop_x:
			mov cl, [edx]
			;mov [edi], cl

			pushad
				add ebx, 3
				mov edx, 12
				mul edx
				add eax, ebx
				add eax, space
				mov [eax], cl
			popad

			inc ebx
			inc edx
		cmp ebx, 4
		jnz .loop_x

		inc eax
	cmp eax, 4
	jnz .loop_y

	call get_random_numer
	mov [next_tetris], edx
popad
ret

; ============================================================
space_tetris_turn:
	pushad
	inc dword [tetris_turn]

	mov eax, 0x4
	cmp [tetris_turn], eax
	jnz .no_four
		mov eax, 0x0
		mov [tetris_turn], eax
	.no_four:

	mov eax, [this_tetris]
	mov ebx, 4*4*4
	mul ebx
	mov esi, eax ; offset zakladnej kocky od adresy tetris

	mov eax, [tetris_turn]
	mov ebx, 4*4
	mul ebx
	add esi, eax ;; +offset kocky na ktoru sa ma otocit

	add esi, tetris
	;mov esi, tetris

	; vymaz povodny tetris
	xor edi, edi	; adresa na ktorej sa zacinal povodny tetris

	; najde adresu na ktorej sa nachadza tetris
	xor eax, eax
	.loop_1:
		cmp byte [space+eax], 0x2
		jnz .next
			cmp edi, 0x0
			jnz .no_set
				mov edi, space
				add edi, eax
			.no_set:
		.next:
		inc eax
	cmp eax, 12*25
	jnz .loop_1

	;jmp pokus

	;zisti ci sa kocka moze otovit
	pushad

	xor eax, eax
	xor ebx, ebx

	.loop_2:
		mov cl, [esi]
		mov ch, [edi]

		cmp cl, 0x2
		jnz .next_1
			
		cmp ch, 0x1
		jnz .next_1
			popad
			jmp .my_return
		.next_1:

		inc eax
		inc esi
		inc edi

		cmp eax, 4
		jnz .no_next
			add edi, 12-4
			xor eax, eax
		.no_next:
	
		inc ebx
	cmp ebx, 4*4
	jnz .loop_2

	popad

	; vymaze povodnu kocku
	pushad

	xor eax, eax
	.loop_3:
		cmp byte [space+eax], 0x2
		jnz .next_2
			mov byte [space+eax], 0x0
		.next_2:
		inc eax
	cmp eax, 12*25
	jnz .loop_3

	popad

	; dopisanie otocenej kocky
	xor eax, eax
	xor ebx, ebx

	.loop_4:
		mov cl, [esi]

		cmp cl, 0x2
		jnz .no_set_tetris
			mov [edi], cl
		.no_set_tetris:

		inc eax
		inc esi
		inc edi

		cmp eax, 4
		jnz .no_next_2
			add edi, 12-4
			xor eax, eax
		.no_next_2:
	
		inc ebx
	cmp ebx, 4*4
	jnz .loop_4
	
	call vga_clean
		
	call space_draw
	call space_draw_next_tetris

	.my_return:

	popad
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
vga_draw_pause:
	pushad

	mov esi, 83
	mov edi, 100

	mov edx, esi
	xor ecx, ecx

	xor ebx, ebx
	.loop_y:
		xor eax, eax
		mov esi, edx
		.loop_x:

		cmp byte [pause+ecx], 1
		jnz .nothing
			call vga_put_pixel
		.nothing:

		inc esi
		inc eax
		inc ecx	
		cmp eax, 29
		jnz .loop_x

		
	inc edi
	inc ebx
	cmp ebx, 8
	jnz .loop_y

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
vga_draw_cube:
	pushad

	mov edx, esi
	xor ecx, ecx

	xor ebx, ebx
	.loop_y:
		xor eax, eax
		mov esi, edx
		.loop_x:

		cmp byte [cube+ecx], 1
		jnz .nothing
			call vga_put_pixel
		.nothing:

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

cube:	; 8x8
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1
	db 1,0,1,0,1,0,1,0
	db 0,1,0,1,0,1,0,1


pause:	; 29x8
	db 1,1,1,0,0,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,1,1,0,0,0,1,1,1,1,
	db 1,0,0,1,0,1,0,0,1,0,0,1,0,0,0,0,1,0,0,1,0,0,1,0,1,0,0,0,0,
	db 1,0,0,1,0,1,0,0,1,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,0,0,0,0,
	db 1,0,0,1,0,1,0,0,1,0,0,1,0,0,0,0,1,0,1,0,0,0,0,0,1,1,1,0,0,
	db 1,1,1,0,0,1,1,1,1,0,0,1,0,0,0,0,1,0,0,1,1,0,0,0,1,0,0,0,0,
	db 1,0,0,0,1,0,0,0,0,1,0,1,0,0,0,0,1,0,0,0,0,1,0,0,1,0,0,0,0,
	db 1,0,0,0,1,0,0,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,1,0,0,0,0,
	db 1,0,0,0,1,0,0,0,0,1,0,0,0,1,1,0,0,0,0,1,1,0,0,0,0,1,1,1,0

tetris:
	db 2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0 ; I
	db 2,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0
	db 2,2,2,2,0,0,0,0,0,0,0,0,0,0,0,0
	db 2,0,0,0,2,0,0,0,2,0,0,0,2,0,0,0

	db 2,2,0,0,2,2,0,0,0,0,0,0,0,0,0,0 ; O
	db 2,2,0,0,2,2,0,0,0,0,0,0,0,0,0,0
	db 2,2,0,0,2,2,0,0,0,0,0,0,0,0,0,0
	db 2,2,0,0,2,2,0,0,0,0,0,0,0,0,0,0

	db 2,2,2,0,2,0,0,0,0,0,0,0,0,0,0,0 ; L
	db 2,2,0,0,0,2,0,0,0,2,0,0,0,0,0,0
	db 0,0,2,0,2,2,2,0,0,0,0,0,0,0,0,0
	db 2,0,0,0,2,0,0,0,2,2,0,0,0,0,0,0

	db 2,2,2,0,0,2,0,0,0,0,0,0,0,0,0,0 ; T
	db 0,2,0,0,2,2,0,0,0,2,0,0,0,0,0,0
	db 0,2,0,0,2,2,2,0,0,0,0,0,0,0,0,0
	db 0,2,0,0,0,2,2,0,0,2,0,0,0,0,0,0

	db 2,2,2,0,0,0,2,0,0,0,0,0,0,0,0,0 ; J
	db 0,2,0,0,0,2,0,0,2,2,0,0,0,0,0,0
	db 2,0,0,0,2,2,2,0,0,0,0,0,0,0,0,0
	db 2,2,0,0,2,0,0,0,2,0,0,0,0,0,0,0

	db 2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0 ; Z
	db 0,2,0,0,2,2,0,0,2,0,0,0,0,0,0,0
	db 2,2,0,0,0,2,2,0,0,0,0,0,0,0,0,0
	db 0,2,0,0,2,2,0,0,2,0,0,0,0,0,0,0

	db 0,2,2,0,2,2,0,0,0,0,0,0,0,0,0,0 ; S
	db 2,0,0,0,2,2,0,0,0,2,0,0,0,0,0,0
	db 0,2,2,0,2,2,0,0,0,0,0,0,0,0,0,0
	db 2,0,0,0,2,2,0,0,0,2,0,0,0,0,0,0

pause_mod:	db 0

SECTION .bss
	str : resb 32
	timer_tmp: resd 1
	radom_type : resd 1
	radom_tmp: resd 1
	this_tetris : resd 1
	tetris_turn : resd 1
	next_tetris : resd 1
	space : resb 12*25
