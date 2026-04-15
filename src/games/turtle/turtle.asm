; ===
; === VIRTUAL TURTLE
; === Blake Burgess
; === March - April 2014
; ===
; === Control an on-screen turtle by giving it commands: left, right, up, down, and paint.
; ===
; === The program features simple command processing and collision detection, and uses a 40x25 text mode.
; === Because it is designed to work in both MS-DOS and MikeOS, it includes string parsing functions
; === already, so the program does not have to rely solely on the MikeOS API system calls.
; ===
; === For this custom library, I devised a scheme that allows me to selectively pick which procedures to
; === import from each included source file. This means that I can minimize unnecessary program space that
; === is wasted to unused procedures. It uses the Flat Assembler's macro functions to accomplish this;
; === therefore, this program will not compile under the Net Assembler without modifications.
; ===

	;org		0x100				; MS-DOS program
	org 0x6000
	
	jmp		start

; ==============================
; === INCLUDES AND SYMBOLS =====
; ==============================

	; Only need to import the procedures necessary. Macros within the includes can be used without
	; importing them first.
	
	macro import function {function}
	
	include	"screen.asm"
	include "string.asm"
		import	string.teletype
		import	string.match
	
	include "keyboard.asm"
		import	keyboard.inputString
		import	keyboard.waitForKey
	
	cursor.xPos	equ dl
	cursor.yPos	equ dh
	start.xPos	equ 20
	start.yPos	equ 12
	promptColor	equ 0x1F		; white on blue text
	fieldColor	equ 0x2F		; white on green text
	paintColor	equ 0x4F		; white on red text
	turtleFace	equ 0x02		; filled smiley face

; ==============================
; === ENTRY POINT ==============
; ==============================

start:
	.getScreenInfo:
		screen.getMode
		mov		di, data_state.screenMode
		mov		[di], al			; preserve screen mode
	
	.setScreenMode:
		mov		al, screen.mode.text.4025
		screen.setMode				; set screen to 40x25 text, 16 colors
	
createScreen:
	.fillGreen:
		mov		cx, 23				; number of rows to fill
		mov		bh, 0				; first page
		xor		dx, dx				; position at 0, 0
		mov		al, 0				; null character
		
	.fillGreen.nextLine:
		screen.text.setCursorPosition
		push 	cx
		mov		cx, 40				; characters to write
		mov		bl, fieldColor
		screen.text.setCharacter
		inc		dh					; next row
		pop		cx
		loop	.fillGreen.nextLine
		
	.fillPrompt:
		mov		cx, 2				; number of rows to fill
		mov		cursor.xPos, 0		; position at 0, 23
		mov		cursor.yPos, 23
		
	.fillPrompt.nextLine:
		screen.text.setCursorPosition
		push	cx
		mov		cx, 40				; characters to write
		mov		bl, promptColor
		screen.text.setCharacter
		inc		dh					; next row
		pop		cx
		loop	.fillPrompt.nextLine
		
	.createTurtle:					; create turtle at start position
		mov		cursor.xPos, start.xPos
		mov		cursor.yPos, start.yPos
		screen.text.setCursorPosition
		mov		al, turtleFace
		string.putChar
	
	call	showHelp
	call	showPrompt

; ==============================
; === MAIN PROGRAM LOOP ========
; ==============================

main:
	; get command string from keyboard
	; ==============================
	mov		al, 8				; 8 max characters
	mov		ah, 1				; echo enabled
	mov		di, data_str.buffer	; pointer to string buffer
	call	keyboard.inputString
	
	; interpret string and perform the command
	; ==============================
	.checkInput:
		mov		si, data_str.buffer
		mov		di, data_command.up
		call	string.match		; == "up"
		jnc		@f					; no match? check the next command
		call	handler.goUp
		jmp		.checkInput.end
		
		@@:
		mov		di, data_command.down
		call	string.match		; == "down"
		jnc		@f					; no match? check the next command
		call	handler.goDown
		jmp		.checkInput.end
		
		@@:
		mov		di, data_command.left
		call	string.match		; == "left"
		jnc		@f					; no match? check the next command
		call	handler.goLeft
		jmp		.checkInput.end
		
		@@:
		mov		di, data_command.right
		call	string.match		; == "right"
		jnc		@f					; no match? check the next command
		call	handler.goRight
		jmp		.checkInput.end
		
		@@:
		mov		di, data_command.paint
		call	string.match		; == "paint"
		jnc		@f					; no match? check the next command
		call	handler.paint
		jmp		.checkInput.end
		
		@@:
		mov		di, data_command.exit
		call	string.match		; == "exit"
		jnc		@f					; no match? check the next command
		jmp		exit
		
		@@:
		call	showHelp
		
		.checkInput.end:
	
	call	showPrompt
	
	jmp		main

; ==============================
; === PROGRAM FUNCTION SECTION =
; ==============================
	
handler:
	.goUp:
		mov		al, byte [data_turtle.yPos]
		cmp		al, 0
		jz		@f					; collision detection
		
		mov		cursor.xPos, byte [data_turtle.xPos]
		mov		cursor.yPos, byte [data_turtle.yPos]
		screen.text.setCursorPosition
		
		mov		al, ' '				; erase old face
		string.putChar
		
		mov		al, byte [data_turtle.yPos]
		dec		al					; save new cursor position
		mov		[data_turtle.yPos], al
		
		mov		cursor.yPos, al		; update new cursor position on screen
		mov		cursor.xPos, byte [data_turtle.xPos]
		screen.text.setCursorPosition
		
		call	paintPixel			; paint pixel if enabled
		
		mov		al, turtleFace		; display new face
		string.putChar
		ret
		
		@@:
		call	clearMessageArea
		call	showBump
		ret
		
	.goDown:
		mov		al, byte [data_turtle.yPos]
		cmp		al, 22
		jz		@f					; collision detection
		
		mov		cursor.xPos, byte [data_turtle.xPos]
		mov		cursor.yPos, byte [data_turtle.yPos]
		screen.text.setCursorPosition
		
		mov		al, ' '				; erase old face
		string.putChar
		
		mov		al, byte [data_turtle.yPos]
		inc		al					; save new cursor position
		mov		[data_turtle.yPos], al
		
		mov		cursor.yPos, al		; update new cursor position on screen
		mov		cursor.xPos, byte [data_turtle.xPos]
		screen.text.setCursorPosition
		
		call	paintPixel			; paint pixel if enabled
		
		mov		al, turtleFace		; display new face
		string.putChar
		ret
		
		@@:
		call	clearMessageArea
		call	showBump
		ret
		
	.goLeft:
		mov		al, byte [data_turtle.xPos]
		cmp		al, 0
		jz		@f					; collision detection
		
		mov		cursor.xPos, byte [data_turtle.xPos]
		mov		cursor.yPos, byte [data_turtle.yPos]
		screen.text.setCursorPosition
		
		mov		al, ' '				; erase old face
		string.putChar
		
		mov		al, byte [data_turtle.xPos]
		dec		al					; save new cursor position
		mov		[data_turtle.xPos], al
		
		mov		cursor.xPos, al		; update new cursor position on screen
		mov		cursor.yPos, byte [data_turtle.yPos]
		screen.text.setCursorPosition
		
		call	paintPixel			; paint pixel if enabled
		
		mov		al, turtleFace		; display new face
		string.putChar
		ret
		
		@@:
		call	clearMessageArea
		call	showBump
		ret
		
	.goRight:
		mov		al, byte [data_turtle.xPos]
		cmp		al, 39
		jz		@f					; collision detection
		
		mov		cursor.xPos, byte [data_turtle.xPos]
		mov		cursor.yPos, byte [data_turtle.yPos]
		screen.text.setCursorPosition
		
		mov		al, ' '				; erase old face
		string.putChar
		
		mov		al, byte [data_turtle.xPos]
		inc		al					; save new cursor position
		mov		[data_turtle.xPos], al
		
		mov		cursor.xPos, al		; update new cursor position on screen
		mov		cursor.yPos, byte [data_turtle.yPos]
		screen.text.setCursorPosition
		
		call	paintPixel			; paint pixel if enabled
		
		mov		al, turtleFace		; display new face
		string.putChar
		ret
		
		@@:
		call	clearMessageArea
		call	showBump
		ret
		
	.paint:
		mov		al, byte [data_turtle.paintToggle]
		cmp		al, 0
		jnz		.paint.disable
		
		.paint.enable:				; toggle bit to 1
		mov		byte [data_turtle.paintToggle], 1
		call	clearMessageArea	; clear message line
		mov		cursor.xPos, 0		; "Paint enabled"
		mov		cursor.yPos, 23
		screen.text.setCursorPosition
		mov		si, data_str.paintOn
		call	string.teletype
		ret
		
		.paint.disable:				; toggle bit to 0
		mov		byte [data_turtle.paintToggle], 0
		call	clearMessageArea	; clear message line
		mov		cursor.xPos, 0		; "paint disabled"
		mov		cursor.yPos, 23
		screen.text.setCursorPosition
		mov		si, data_str.paintOff
		call	string.teletype
		ret

; ==========
exit:
	.restoreScreen:
		mov		di, data_state.screenMode
		mov		al, byte [di]
		screen.setMode
	
	.return:
		mov		ax, 0x4C00
		int		0x21

; ==============================
; === PROCEDURE SECTION ========
; ==============================

paintPixel:
pusha

	mov		al, byte [data_turtle.paintToggle]
	cmp		al, 0				; if paint is toggled off, break
	jz		@f
	
	mov		cx, 1				; else, set background color
	mov		bl, paintColor
	screen.text.setCharacter
	
	@@:
	
popa
ret

; ==========
clearMessageArea:
pusha

	mov		cursor.xPos, 0		; position at 0, 23
	mov		cursor.yPos, 23
	screen.text.setCursorPosition
	
	mov		al, ' '
	mov		bl, promptColor
	mov		cx, 40
	screen.text.setCharacter	; clear prompt line

popa
ret

; ==========
showBump:
pusha

	mov		cursor.xPos, 0		; position at 0, 23
	mov		cursor.yPos, 23
	screen.text.setCursorPosition
	
	mov		si, data_str.bump	; show bump message
	call	string.teletype
	
popa
ret

; ==========
showHelp:
pusha

	mov		cursor.xPos, 0		; position at 0, 23
	mov		cursor.yPos, 23
	screen.text.setCursorPosition
	
	mov		si, data_str.help	; show help message
	call	string.teletype
	
popa
ret

; ==========	
showPrompt:
pusha

	mov		bh, 0				; position at 0, 24
	mov		cursor.xPos, 0
	mov		cursor.yPos, 24
	screen.text.setCursorPosition
	
	mov		al, ' '
	mov		bl, promptColor
	mov		cx, 40
	screen.text.setCharacter	; clear prompt line
	
	mov		cursor.xPos, 0		; position at 0, 24
	mov		cursor.yPos, 24
	screen.text.setCursorPosition
	
	mov		al, '>'
	string.putChar				; display carat
	
popa
ret

; ==============================
; === DATA SECTION =============
; ==============================

data_state:
	.screenMode:
		db		?

data_turtle:
	.xPos:
		db		start.xPos
	.yPos:
		db		start.yPos
	.paintToggle:
		db		0

data_command:
	.up:
		db		"up", 0
	.down:
		db		"down", 0
	.left:
		db		"left", 0
	.right:
		db		"right", 0
	.paint:
		db		"paint", 0
	.help:
		db		"help", 0
	.exit:
		db		"exit", 0

data_str:
	.help:
		db		"up, down, left, right, paint, help, exit", 0
	.paintOn:
		db		"Paint toggled on", 0
	.paintOff:
		db		"Paint toggled off", 0
	.bump:
		db		"Bump! Hit a wall", 0
	.buffer:
		db		10 dup (0)
