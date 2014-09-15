	; Screen library
	; NAMESPACE: "screen"
	screen:
	
	; GLOBAL SYMBOLS
	
screen.mode.text.4025		equ 0x01	; 16 colors, 40x25
screen.mode.text.8025		equ 0x03	; 16 colors, 80x25
screen.mode.gfx.cga_lowres	equ 0x04	; 4 colors, 320x200
screen.mode.gfx.cga_hires	equ 0x06	; 2 colors, 640x200
screen.mode.gfx.ega_lowres	equ 0x0D	; 16 colors, 320x200
screen.mode.gfx.ega_midres	equ 0x0E	; 16 colors, 640x200
screen.mode.gfx.ega_hires	equ 0x10	; 4 colors, 640x350
screen.mode.gfx.vga_hires	equ 0x12	; 16 colors, 640x480
screen.mode.gfx.vga_lowres	equ 0x13	; 256 colors, 320x200


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "setMode"
	;
	; param:
	;	al = video mode // see symbol definitions at top of file
	; destroyed:
	;	ah
	;	al
macro screen.setMode
{
	mov		ah, 0x00
	int		0x10
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "getMode"
	;
	; return:
	;	ah = number of character columns
	;	al = display mode
	;	bh = active page
macro screen.getMode
{
	mov		ah, 0x0F
	int		0x10
}


	; SECTION: "text"
	
; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "text.setCursorPosition"
	;
	; param:
	;	bh = page number
	;		0-3 in modes 2, 3
	;		0-7 in modes 0, 1
	;		0 in graphics modes
	;	dh = row
	;	dl = column
	; destroyed:
	;	ah
macro screen.text.setCursorPosition
{
	mov		ah, 0x02
	int		0x10
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "text.getCursorPosition"
	;
	; param:
	;	bh = page number
	;		0-3 in modes 2, 3
	;		0-7 in modes 0, 1
	;		0 in graphics modes
	; return:
	;	ax = 0x0000 (Phoenix BIOS)
	;	dh = row
	;	dl = column
	; destroyed:
	;	ah
macro screen.text.getCursorPosition
{
	mov		ah, 0x03
	push	cx					; discard cursor shape data
	int		0x10
	pop		cx
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "text.setCharacter"
	;
	; param:
	;	al = character to display
	;	bh = page number
	;		0-3 in modes 2, 3
	;		0-7 in modes 0, 1
	;		0 in graphics modes
	;	bl = attribute data
	;	cx = number of times to write character
	; destroyed:
	;	ah
macro screen.text.setCharacter
{
	mov		ah, 0x09
	int		0x10
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "text.getCharacter"
	;
	; param:
	;	bh = page number
	;		0-3 in modes 2, 3
	;		0-7 in modes 0, 1
	;		0 in graphics modes
	; return:
	;	ah = character attribute
	;	al = character code
	; destroyed:
	;	ah
macro screen.text.getCharacter
{
	mov		ah, 0x08
	int		0x10
}


	; SECTION: "gfx"
	
; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "gfx.setPixel"
	;
	; param:
	;	bh = page number
	;		ignored if mode supports only one page
	;	al = pixel color
	;		if bit 7 set, value is XOR'd onto screen except in 256 color modes
	;	cx = column
	;	dx = row
	; destroyed:
	;	ah
macro screen.gfx.setPixel
{
	mov		ah, 0x0C
	int		0x10
}


; ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
; ### MACRO: "gfx.getPixel"
	;
	; param:
	;	bh = page number
	;		ignored if mode supports only one page
	;	cx = column
	;	dx = row
	; return:
	;	al = pixel color
	; destroyed:
	;	ah
macro screen.gfx.getPixel
{
	mov		ah, 0x0D
	int		0x10
}