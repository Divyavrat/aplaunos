; tabsize = 8
; Plazma by .nebula (June, 2001)
; This is my first 256b intro, so it is rather simple.

		.model	tiny
		.code
		.386
		;org	100h
		org 6000h

start:
		mov	al,13h
		int	10h
;================================================================================================
;	Set the palette (black->red->yellow->white->black)
;================================================================================================
		mov     dx,3C8h		
		xor     ax,ax
		out     dx,al		; initialize
		inc     dx
		mov	cx,300h		
		mov	al,62		; EAX=<Green=0,Blue=0,Red=0,temp=62>

set_pal:
		cmp	al,62
		jb	okidoki
		inc	ah
		mov	al,62

okidoki:				;		  \/---------------/\
		ror	eax,8		; first run	Green->Blue->Red->temp
		test	cl,1		
		bt	cx,1
		ja	skip		; jump if CF!=0 && ZF!=0
		out	dx,al
		jmp	short continue_loop

skip:
		test	al,al
		jnz	continue_loop
		test	ah,ah
		jz	continue_loop
		sub	eax,01010100h

continue_loop:
		loop	set_pal
		test	ah,ah
		jz	leave_set_pal
		mov	eax,3d3d3d00h
		mov	cx,100h
		;mov	cx,6000h
		jmp	short set_pal

leave_set_pal:
;================================================================================================
;	Make a cosines lookup table using cos(x[k])=2*cos(span/steps)*cos(x[k-1])-cos(x[k-2])
;	where span is the span of cosines to calculate
;	      steps is the number of steps this span is broken into
;================================================================================================
		mov	di,offset cos_table[4]
		mov	ebx,16777137
		mov	eax,ebx
		stosd
		mov	cx,2046

build_table_loop:
		imul	ebx
		shrd	eax,edx,23
		sub	eax,dword ptr [di-8]
		stosd
		loop	build_table_loop
;================================================================================================
		push	0A000h
		pop	es
main_loop:
;================================================================================================
;	Drawing plazma 
;================================================================================================
;	x and y coordinates are stored on stack
;	
;	The pixel color is determined by this formula:
;	color(x,y)=32*{cos(c_a*x+c_b*p_time+c_c)+
;			cos(c_d*x+c_e*p_time+c_f)+
;			cos(c_g*y+c_h*p_time+c_i)+
;			cos(c_j*y+c_k*p_time+c_l)+4}

		xor	di,di
		xor	ax,ax

draw_plasma_loop:
		push	ax		; x coordinate
		push	cx		; y coordinate
		xor	ecx,ecx		
		xor	eax,eax		
		mov	si,offset c_a	
		mov	bp,sp

calculate:					; bp+2=x, bp+4=y
		xor	bx,bx
		lodsw				; AX=c_a
		imul	word ptr [bp+2]		; AX=x*c_a
		add	bx,ax			; BX=BX+AX
		lodsw				; AX=c_b
		imul	word ptr p_time		; AX=t*c_b
		add	bx,ax			; BX=BX+AX
		lodsw				; AX=c_c
		add	bx,ax			; BX=BX+AX
		and	bx,2047			; BX=BX mod 1111111111b
		shl	bx,2			; BX=BX > 2
		add	ecx,dword ptr cos_table[bx] ; ECX=cos(BX)

		cmp	si,offset c_d		; if (si==c_d) //first interation
		jz	calculate		; calculate cos(c_d*x+c_e*p_time+c_f)
		cmp	si,offset c_j		; if (si==c_j) //second interation
		jz	calculate		; calculate cos(c_j*y+c_k*p_time+c_l)
		cmp	bp,sp			; if (haven't switched to
						; cos(c_g*y+c_h*p_time+c_i)+
						; cos(c_j*y+c_k*p_time+c_l)
						; caclulation)
		jb	leave_calculate
		dec	bp			; then DO
		dec	bp			; switch to y
		jmp	short calculate

leave_calculate:
		shr	ecx,18
		mov	al,cl

		stosb				; put pixel

		pop	cx
		pop	ax
		inc	ax
		cmp	ax,320
		jl	continue_draw_plasma_loop
		xor	ax,ax
		inc	cx
		cmp	cx,200
		jg	exit

continue_draw_plasma_loop:
		jmp	short draw_plasma_loop

exit:
;================================================================================================

		inc	word ptr p_time

		mov	dx,5000		; delay
		xor	cx,cx
		mov	ah,86h
		int	15h

		mov	ah,11h
		int	16h
		jz	main_loop

		mov	ax,0003h
		int	10h
		ret
; Constants
; for X
c_a	dw	2	; scale
c_b	dw	-17	; spped
c_c	dw	0	; phase
c_d	dw	7	; scale
c_e	dw	13	; speed
c_f	dw	0	; phase
; for Y
c_g	dw	3	; scale
c_h	dw	-3	; speed
c_i	dw	0	; phase
c_j	dw	5	; scale
c_k	dw	23	; speed
c_l	dw	0	; phase

p_time	dw	0	; time

; Data: Cosines lookup table
cos_table	dd	01000000h

		end	start