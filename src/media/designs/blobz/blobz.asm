; tabsize = 8
; Blobz by .nebula (July, 2001)
; This is my second 256b intro, and its got wicked FPU code!
		.model	tiny
		.code
		.386
		;org	100h
		org	6000h

start:
		mov	ax,13h
		int	10h

; Set the palette
		mov	dx,3C8h
		xor	ax,ax
		out	dx,al		; initilize

		inc	dx
		mov	ah,0FFh		; eax=<green=0,red=0,temp=ffh,blue=0>
		mov	cx,100h

set_pal:
		cmp	ah,0ffh
		jnz	skip_inc_any
		inc	al
		cmp	al,64
		jnz	skip_inc_any
		mov	al,63

skip_inc_any:				; first cycle:
		ror	eax,8		; eax=<blue=0,green=0,red=0,temp=62>
		test	cl,00000011b
		jz	skip_temp
		out	dx,al

skip_temp:
		loop	set_pal

		push	0A000h
		pop	es

		enter	20,0
;================================================================================================
x1	equ	[bp-2]
y1	equ	[bp-4]
x2	equ	[bp-6]
y2	equ	[bp-8]
x3	equ	[bp-10]
y3	equ	[bp-12]
xt	equ	[bp-14]
yt	equ	[bp-16]
time	equ	[bp-18]
color	equ	[bp-20]
;================================================================================================

next_frame:
		xor	si,si
		mov	bx,160
		mov	cx,100
		
; Change blobs' coordinates
calc_offset:
		finit
		fild	word ptr time
		fidiv	word ptr scale
		fimul	word ptr c_y3[si]
		fldpi
		fmulp	st(1),st
		fsin
		fimul	word ptr ampl_y3[si]
		fist	word ptr y3[si]
		inc	si
		inc	si
		cmp	si,12
		jnz	calc_offset
		add	word ptr x1,bx
		add	word ptr x2,bx
		add	word ptr x3,bx
		add	word ptr y1,cx
		add	word ptr y2,cx
		add	word ptr y3,cx

; Render the current frame
		shl	bx,1
		mov	cx,64000
		xor	di,di

next_pixel:
		xor	si,si
		xor	dx,dx
		mov	ax,di
		div	bx		; ax=x,dx=y
		mov	xt,dx
		mov	yt,ax

		finit

calculate:
		fld1			; 1
		fild	word ptr yt	; yt,1
		fisub	word ptr y3[si]	; yt-y1,1
		fld	st		; yt-y1,yt-y1,1
		fmulp	st(1),st	; (yt-y1)^2,1
		fild	word ptr xt	; xt,(yt-y1)^2,1
		fisub	word ptr x3[si]	; xt-x1,(yt-y1)^2,1
		fld	st		; xt-x1,xt-x1,(yt-y1)^2,1
		fmulp	st(1),st	; (xt-x1)^2,(yt-y1)^2,1
		faddp	st(1),st	; (xt-x1)^2+(yt-y1)^2,1
		fld1			; 1,(xt-x1)^2+(yt-y1)^2,1
		faddp	st(1),st	; 1+(xt-x1)^2+(yt-y1)^2,1
		fsqrt			; sqrt{1+(xt-x1)^2+(yt-y1)^2},1
		fdivp	st(1),st	; 1/sqrt{1+(xt-x1)^2+(yt-y1)^2}

		add	si,4
		cmp	si,12
		jne	calculate

		faddp	st(1),st
		faddp	st(1),st

		fimul	energy

		fist	word ptr color
		mov	ax,color
		cmp	ax,63
		jl	skip_normalize
		mov	ax,63

skip_normalize:
		stosb
		loop	next_pixel
;================================================================================================

		inc	word ptr time

		xor	ax,ax
		in	al,60h		; if ESC is pressed
		dec	ax		; exit
		jnz	next_frame	

		mov	ax,3		; restore text mode
		int	10h
		
		leave
		ret

energy		dw	1400
scale		dw	0FFh
ampl_y3		dw	50
ampl_x3		dw	120
ampl_y2		dw	60
ampl_x2		dw	80
ampl_y1		dw	75
ampl_x1		dw	100
c_y3		dw	7
c_x3		dw	4
c_y2		dw	3
c_x2		dw	5
c_y1		dw	2
c_x1		dw	1

		end	start