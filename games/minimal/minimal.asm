; ----------------------------------------------------------------------
; MINIMAL - Minimal game for Ludum Dare 26.
; Programmed by MegaBrutal, 28 April 2013.
; Post-compo update, V1.0, 11 June 2013.
;
; Compile with NASM:
; nasm -o minimal.com minimal.asm
;
; The output is a DOS .COM file which you may run with NTVDM, DOSEmu,
; DOSBox, or... you know, under actual DOS. ;)
;
; Also, this program can be booted directly from a storage media (such
; as a floppy, most typically). To do this, you need to write the
; binary into the media's first sectors.
;
; For example, to make a bootable floppy under DOS/Windows, use the
; popular RAWRITE utility (several implementations exist, Google to
; find a suitable one).
;
; Under Linux, use the GNU DD utility, e.g.:
; dd if=minimal.com of=/dev/fd0 bs=512
; (Might require root privileges.)
; ----------------------------------------------------------------------


		ORG	0x6000			; Preserve space for Program Segment Prefix.

		CLI				; Disable hardware interrupts
		CLD				; Clear direction flag, just in case

		; Check if direct-booted from a floppy (or other media).
		; BIOS loads boot record at 0000:7C00.
		MOV	AX, CS
		CMP	AX, 0
		;JNE	DOSCODE_START		; If running under DOS, skip boot code
JMP	DOSCODE_START

; ----------------------------------------------------------------------
; BOOT CODE
;
; Executes if program is loaded upon boot sequence, otherwise it's
; jumped over. This code sets up a small DOS-like environment for the
; game to allow it to run flawlessly. Anything essential for this
; process needs to be located within the first 512 bytes of the binary
; file, since BIOS will only load the first sector from the media upon
; boot.
;
;
; MEMORY MAP:
; 07B0:0000 - Dummy PSP start (of course we don't really have a PSP now, still preserve the space)
; 07B0:0100 - Start of boot record
; 07B0:0300 - Read buffer (load rest of code here)
; ----------------------------------------------------------------------

		; Fix code location to be 100h based.
		; Physical address: 07C00h - 100h = 07B00h -> Start of 100h based code: 07B0:0100.
		JMP	07B0h:LOCATION_FIXED

LOCATION_FIXED:
		; HACK: Copy the INT 19h interrupt vector to the INT 20h vector,
		; so when the game quits with INT 20h (that would return control
		; to DOS under DOS), it'll actually call INT 19h which instructs
		; BIOS to restart the boot sequence... Wicked, huh? :D
		XOR	AX, AX
		MOV	DS, AX
		MOV	ES, AX
		MOV	SI, 19h * 4
		MOV	DI, 20h * 4
		MOVSW				; Loading CX and using the REP prefix would take more bytes,
		MOVSW				; so I just write it down twice. ;)
						; (And no, I won't use MOVSD, that's only supported since 80386!
						; I can't expect everyone to have cutting edge technology! :p)

		; Set up segment registers and stack
		MOV	AX, CS
		MOV	DS, AX
		MOV	ES, AX
		MOV	SS, AX
		MOV	SP, 0FFFEh
		STI				; Re-enable hardware interrupts

READ_TRY:
		; Since only the first 512 bytes are currently loaded (that is contained in the boot record),
		; we need to load the next 2 sectors from the media.
		MOV	AX, 0202h		; AH = 02h means read from disk; AL tells how many sectors
		MOV	CX, 2			; Read from Sector #2; Cylinder 0
		XOR	DH, DH			; Head 0
						; Assuming drive number was stored in DL by BIOS upon boot
		MOV	BX, 300h		; (ES:BX) Data buffer to load rest of code (see memory map above)
		INT	13h			; Try to read (INT 13h/AH=02h: <http://www.ctyme.com/intr/rb-0607.htm>)

		JNC	DOSCODE_START
		XOR	AX, AX
		INT	13h			; Reset drive before next read attempt
		DEC	BYTE [BIOSFAIL]
		JNZ	READ_TRY

		; EPIC FAIL - couldn't load rest of program, show a friendly message and reboot.
		MOV	DH, 24
		MOV	DL, 0
		MOV	SI, STR_FAIL
		CALL	PRINT_STRING
		CALL	READ_KEY
		INT	19h


DOSCODE_START:
		JMP	START
		DD	0DEADDEADh		; Easter Egg for Omni
		DB	0Dh, 0Ah
		DB	"Minimal game for Ludum Dare 26.", 0Dh, 0Ah
		DB	"Programmed by MegaBrutal, 28 April 2013.", 0Dh, 0Ah
		DB	"Post-compo update, V1.0, 11 June 2013.", 0Dh, 0Ah, 00h

STR_FAIL	DB	"Failed to load game!  ", 00h	; Yes, those spaces are necessary, trust me!
BIOSFAIL	DB	10			; Maximum number of INT 13h read retry attempts


; Some cute subroutines

; ----------------------------------------------------------------------
; SCREEN_CLREOLN: Clear to end of line from given cursor position.
; Inputs:
;	DH	- cursor position - row
;	DL	- cursor position - column
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
SCREEN_CLREOLN:
		PUSH	ES
		PUSH	DI
		PUSH	AX
		PUSH	BX
		PUSH	DX
		MOV	AX, 0B800h		; Video memory starts at B800:0000
		MOV	ES, AX
		XOR	AX, AX
		MOV	AL, DH
		MOV	BX, 80 * 2
		MUL	BX			; Calculate row
		POP	DX
		MOV	DI, AX
		MOV	BL, DL			; BH is cleared by above MOV BX, 80 * 2
		SHL	BX, 1
		ADD	DI, BX			; Add column position
		MOV	CX, 80
		SUB	CL, DL			; # of characters to end of line
		MOV	AX, 0720h		; 07h = Light gray; 20h = Space
		REP	STOSW
		POP	BX
		POP	AX
		POP	DI
		POP	ES
		RET


; ----------------------------------------------------------------------
; PRINT_CHAR: Prints character at location.
; Inputs:
;	AL	- character to print
;	DH	- row
;	DL	- column
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
PRINT_CHAR:
		PUSHF
		PUSH	BX
		PUSH	CX
		PUSH	AX
		MOV	AH, 02h
		XOR	BX, BX
		INT	10h			; Row & column are already set by caller (DX).
		POP	AX
		PUSH	AX			; To preserve AH.
		MOV	AH, 09h
		MOV	BL, 07h			; Light gray.
		MOV	CX, 1
		INT	10h			; Put character
		POP	AX
		POP	CX
		POP	BX
		POPF
		RET


; ----------------------------------------------------------------------
; PRINT_STRING: Prints a zero-terminated string.
; Inputs:
;	DH	- row
;	DL	- column
;	SI	- address of string
;
; Outputs:
;	DL	- new column position of the cursor
;	SI	- end of the printed string
; ----------------------------------------------------------------------
PRINT_STRING:
		PUSH	AX
PS_LOOP:
		LODSB
		CMP	AL, 0
		JE	PS_EXIT
		CALL	PRINT_CHAR		; DH, DL are already set up
		INC	DL
		JMP	PS_LOOP
PS_EXIT:
		POP	AX
		RET


; ----------------------------------------------------------------------
; READ_KEY: Reads a key from the keyboard. (Wrapper, in case I'll change
; the read method. - Currently it's INT 16h/00h.)
; Inputs:
;	None.
;
; Outputs:
;	AH	- BIOS scan code
;	AL	- ASCII character
; ----------------------------------------------------------------------
READ_KEY:
		XOR	AX, AX
		INT	16h
		RET


; ----------------------------------------------------------------------
; SCREEN_CLEAR: Clear screen.
; Inputs:
;	None.
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
SCREEN_CLEAR:
		PUSH	ES
		PUSH	DI
		PUSH	AX
		PUSH	CX
		MOV	AX, 0B800h
		MOV	ES, AX
		XOR	DI, DI
		MOV	AX, 0720h		; Light gray spaces everywhere
		MOV	CX, 80 * 25
		REP	STOSW
		POP	CX
		POP	AX
		POP	DI
		POP	ES
		RET


; ----------------------------------------------------------------------
; PRINT_NUMBER: Prints a number to the screen in decimal, right-aligned,
; fixed field size.
; Inputs:
;	AX	- number to print
;	CX	- field size
;	DH	- row
;	DL	- column (of least significant digit of the number)
;
; Outputs:
;	DL	- column right before the last printed digit
; ----------------------------------------------------------------------
PRINT_NUMBER:
		PUSH	AX
		PUSH	BX
		PUSH	CX
		PUSH	DX
PRINTN:
		MOV	BX, 10
		XOR	DX, DX
		DIV	BX

		; Save quotient in BX, move remainder to AX
		MOV	BX, AX
		MOV	AX, DX

		ADD	AL, '0'			; Convert remainder to ASCII character
		POP	DX			; Restore column/row
		CALL	PRINT_CHAR
		MOV	AX, BX			; Restore quotient to AX
		DEC	DL			; Decrement column (next digit will be printed there)
		PUSH	DX			; Save column/row for the next division
		LOOP	PRINTN			; Print next digit unless CX = 0

		POP	DX
		POP	CX
		POP	BX
		POP	AX
		RET


; ----------------------------------------------------------------------
; BOOT RECORD SIGNATURE
;
; A valid boot record must contain the word 0AA55h (little-endian) in
; the last 2 bytes of the sector (offset 01FEh), otherwise BIOS would
; refuse to boot from the media.
; ----------------------------------------------------------------------

		TIMES	01FEh-$+$$ DB 0		; Align to 01FEh by padding space with zeros
		DW	0AA55h


; ----------------------------------------------------------------------
; GAME DATA & CODE
;
; Actual game code and data are located in the 2nd and 3rd sectors.
; ----------------------------------------------------------------------

; Some cute constants
%DEFINE		MAX_HEALTH		200
%DEFINE		PLAYERCHR		'O'
%DEFINE		POTIONCHR		'*'
%DEFINE		MONSTERCHR		'@'
%DEFINE		KEY_UP			48h
%DEFINE		KEY_DOWN		50h
%DEFINE		KEY_RIGHT		4Bh
%DEFINE		KEY_LEFT		4Dh
%DEFINE		OBJECT_POTION		01h
%DEFINE		OBJECT_TREASURE		02h
%DEFINE		OBJECT_MONSTER		03h
%DEFINE		STRPOS_HEALTH		1
%DEFINE		STRPOS_TREASURES	14
%DEFINE		STRPOS_KILLS		30
%DEFINE		STRPOS_STATUS		42
%DEFINE		STRPOSN_HEALTH		STRPOS_HEALTH + 8+2
%DEFINE		STRPOSN_TREASURES	STRPOS_TREASURES + 11+2
%DEFINE		STRPOSN_KILLS		STRPOS_KILLS + 7+2


; Some cute variables
RANDSEED	DW	0
PLAYER_POS	DW	0
HEALTH		DW	MAX_HEALTH / 2
TREASURES	DW	0
KILLS		DW	0


; Some cute strings (zero terminated)

STR_HEALTH	DB	"Health:", 00h
STR_TREASURES	DB	"Treasures:", 00h
STR_KILLS	DB	"Kills:", 00h
STR_KILLED	DB	"You killed", 00h
STR_DEAD	DB	"You were killed by", 00h
STR_POTION	DB	"You drank a potion.", 00h
STR_TRFOUND	DB	"You found a treasure.", 00h

; Various enemy names
STR_DEMON	DB	"a demon", 00h
STR_DRAGON	DB	"a dragon", 00h
STR_GOBLIN	DB	"a goblin", 00h
STR_WILDBOAR	DB	"a wild boar", 00h
STR_WIZARD	DB	"a wizard", 00h
STR_OGRE	DB	"an ogre", 00h
STR_ZOMBIE	DB	"a zombie", 00h
STR_SUCCUBUS	DB	"a succubus", 00h
STR_SERAPH	DB	"a seraph", 00h
STR_PEGASUS	DB	"a dark pegasus", 00h
STR_MANTICORE	DB	"a manticore", 00h
STR_CHIMAERA	DB	"a chimaera", 00h
STR_MIMIGA	DB	"an enraged mimiga", 00h	; Hurray Cave Story!
STR_LEEBLE	DB	"a leeble", 00h			; Hello Shigi!
STR_MVYR	DB	"a m'vyr", 00h			; How's the Ghost Shards demo progressing, Strawberry? :P
STR_GOOBALL	DB	"a goo ball", 00h		; I had the Best of Times with World of Goo!
STR_HEXAGON	DB	"a super hexagon", 00h		; Terry's Hexagonest Hardestestest Super Hexagon! \o/
STR_HELLHOUND	DB	"a hellhound", 00h		; No one will get this, but I thought of Reincarnation: Dawn of War!
STR_FURDIBURB	DB	"a furdiburb", 00h		; Small's Furdiburb game for Android!

ARRAY_ENEMIES	DW	STR_DEMON, STR_DRAGON, STR_GOBLIN, STR_WILDBOAR, STR_WIZARD, STR_OGRE, STR_ZOMBIE
		DW	STR_SUCCUBUS, STR_SERAPH, STR_PEGASUS, STR_MANTICORE, STR_CHIMAERA
		DW	STR_MIMIGA, STR_LEEBLE, STR_MVYR, STR_GOOBALL, STR_HEXAGON, STR_HELLHOUND, STR_FURDIBURB
ARRAYL_ENEMIES	EQU	($-ARRAY_ENEMIES) / 2


; Some even cuter subroutines

; ----------------------------------------------------------------------
; RANDOM_CORE: Linear congruential pseudorandom number generator (LCG).
; Inputs:
;	None.
;
; Outputs:
;	AX	- next random number
; ----------------------------------------------------------------------
%DEFINE		RAND_A			5	; LCG parameter 'a'
%DEFINE		RAND_C			64539	; LCG parameter 'c'
RANDOM_CORE:
		PUSH	DX
		MOV	AX, RAND_A
		MUL	WORD [RANDSEED]		; a * r
		ADD	AX, RAND_C		; + c
		MOV	[RANDSEED], AX		; Store new seed.
		POP	DX
		RET


; ----------------------------------------------------------------------
; RANDOM_INIT: Initializes LCG with a seed obtained from the system
; clock.
; Inputs:
;	None.
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
RANDOM_INIT:
		PUSH	AX
		PUSH	CX
		PUSH	DX
		XOR	AX, AX
		INT	1Ah			; Get system time - tick count will be stored in CX:DX;
		MOV	[RANDSEED], DX		; only use lower 16 bits for seed.
		POP	DX
		POP	CX
		POP	AX
		RET


; ----------------------------------------------------------------------
; RANDOM: Gets a random number between the specified boundaries using
; the above defined RANDOM_CORE function.
; Inputs:
;	AX	- modulus
;	BX	- offset
;
; Outputs:
;	AX	- result
; ----------------------------------------------------------------------
RANDOM:
		PUSH	CX
		PUSH	DX
		XOR	DX, DX
		MOV	CX, AX			; Save modulus to CX.
		CALL	RANDOM_CORE		; Get next pseudorandom number in AX.
		DIV	CX			; Divide AX with CX.
		MOV	AX, DX			; Store remainder of division.
		ADD	AX, BX			; Add offset.
		POP	DX
		POP	CX
		RET


; ----------------------------------------------------------------------
; FIX_PLAYER_POSITION: If player went out of screen, warp him to the
; other side. (Maybe the messiest function in the entire program. :p)
; Inputs:
;	BX	- address of player position
;
; Outputs:
;	[BX]	- fixed player position
; ----------------------------------------------------------------------
FIX_PLAYER_POSITION:
		PUSH	AX
		MOV	AX, [BX]
		CMP	AL, 80
		JE	FPP_WARP_RIGHT
		CMP	AL, -1
		JE	FPP_WARP_LEFT
		JMP	FPP_CONT
FPP_WARP_RIGHT:
		XOR	AL, AL
		JMP	FPP_EXIT
FPP_WARP_LEFT:
		MOV	AL, 79
		JMP	FPP_EXIT
FPP_CONT:
		CMP	AH, 24
		JE	FPP_WARP_DOWN
		CMP	AH, -1
		JE	FPP_WARP_UP
		JMP	FPP_EXIT
FPP_WARP_DOWN:
		XOR	AH, AH
		JMP	FPP_EXIT
FPP_WARP_UP:
		MOV	AH, 23
FPP_EXIT:
		MOV	[BX], AX
		POP	AX
		RET


; ----------------------------------------------------------------------
; GAME_INIT: Initialize game data.
; Inputs:
;	None.
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
GAME_INIT:
		PUSH	AX
		PUSH	BX
		PUSH	CX
		PUSH	DI
;		XOR	AX, AX
;		MOV	DI, GAMEDATA
;		MOV	CX, 80 * 24 / 2
;		REP	STOSW			; Fill space with zeros.

		; Put some stuff on the field.
		; (Intended to be random but I don't have time - sorry. :P)
		; (Hey, but I used random.org to choose these, really!)
;		LEA	BX, [GAMEDATA]
;		MOV	[BX + 78 + (80 * 20)], BYTE OBJECT_POTION
;		MOV	[BX + 37 + (80 * 13)], BYTE OBJECT_POTION
;		MOV	[BX + 71 + (80 *  5)], BYTE OBJECT_POTION
;		MOV	[BX + 40 + (80 *  3)], BYTE OBJECT_POTION
;		MOV	[BX + 63 + (80 * 19)], BYTE OBJECT_POTION
;		MOV	[BX + 56 + (80 * 19)], BYTE OBJECT_POTION
;		MOV	[BX + 57 + (80 *  0)], BYTE OBJECT_POTION
;		MOV	[BX + 27 + (80 *  1)], BYTE OBJECT_POTION
;		MOV	[BX + 50 + (80 *  1)], BYTE OBJECT_TREASURE
;		MOV	[BX +  3 + (80 * 18)], BYTE OBJECT_TREASURE
;		MOV	[BX +  2 + (80 * 23)], BYTE OBJECT_TREASURE
;		MOV	[BX + 50 + (80 * 15)], BYTE OBJECT_TREASURE
;		MOV	[BX + 33 + (80 * 15)], BYTE OBJECT_TREASURE
;		MOV	[BX + 44 + (80 * 24)], BYTE OBJECT_TREASURE
;		MOV	[BX + 64 + (80 * 19)], BYTE OBJECT_TREASURE
;		MOV	[BX + 28 + (80 *  9)], BYTE OBJECT_TREASURE
;		MOV	[BX + 38 + (80 * 13)], BYTE OBJECT_MONSTER
;		MOV	[BX +  1 + (80 *  7)], BYTE OBJECT_MONSTER
;		MOV	[BX + 70 + (80 *  3)], BYTE OBJECT_MONSTER
;		MOV	[BX +  6 + (80 * 18)], BYTE OBJECT_MONSTER
;		MOV	[BX + 53 + (80 * 20)], BYTE OBJECT_MONSTER
;		MOV	[BX + 77 + (80 * 22)], BYTE OBJECT_MONSTER
;		MOV	[BX + 16 + (80 * 13)], BYTE OBJECT_MONSTER
;		MOV	[BX + 22 + (80 * 23)], BYTE OBJECT_MONSTER

		; Now that the above shit has been commented out,
		; time for some real random field generation. ;)
		MOV	DI, GAMEDATA
		MOV	CX, 80 * 24

GI_LOOP:
		MOV	AX, 20
		XOR	BX, BX
		CALL	RANDOM
		CMP	AX, 0			; 1/20 possibility of spawning an item/monster
		JE	GI_SPAWN_OBJECT
		XOR	AL, AL
		JMP	GI_LOOP_END

GI_SPAWN_OBJECT:
		MOV	AX, OBJECT_MONSTER
		MOV	BX, 1
		CALL	RANDOM

GI_LOOP_END:
		STOSB
		LOOP	GI_LOOP
		POP	DI
		POP	CX
		POP	BX
		POP	AX
		RET


; ----------------------------------------------------------------------
; GAME_DRAW: Draws initial game field.
; Inputs:
;	None.
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
GAME_DRAW:
		PUSH	AX
		PUSH	CX
		PUSH	DX
		PUSH	SI
		XOR	DX, DX
		LEA	SI, [GAMEDATA]
		MOV	CX, 24
GD_BIGLOOP:
		PUSH	CX
		MOV	CX, 80
GD_SMALLLOOP:
		LODSB				; Load next byte from GAMEDATA...
		CMP	AL, 0			; ...determine what it is...
		JE	GD_NOTOBJECT
		CMP	AL, OBJECT_MONSTER
		JNE	GD_NOTMONSTER
		MOV	AL, MONSTERCHR
		JMP	GD_CONT
GD_NOTMONSTER:
		MOV	AL, POTIONCHR
GD_CONT:
		CALL	PRINT_CHAR		; ...print appropriate character.
GD_NOTOBJECT:
		INC	DL
		LOOP	GD_SMALLLOOP
		XOR	DL, DL
		INC	DH
		POP	CX
		LOOP	GD_BIGLOOP

		; Write stats
		MOV	DH, 24
		MOV	DL, STRPOS_HEALTH
		LEA	SI, [STR_HEALTH]
		CALL	PRINT_STRING

		MOV	DL, STRPOS_TREASURES
		LEA	SI, [STR_TREASURES]
		CALL	PRINT_STRING

		MOV	DL, STRPOS_KILLS
		LEA	SI, [STR_KILLS]
		CALL	PRINT_STRING
		POP	SI
		POP	DX
		POP	CX
		POP	AX
		RET


; ----------------------------------------------------------------------
; GAME_PRINT_STATS: Print player stats (health, treasures, kills).
; This only prints the numbers, not the captions.
; Inputs:
;	None.
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
GAME_PRINT_STATS:
		PUSH	AX
		PUSH	CX
		PUSH	DX
		MOV	AX, WORD [HEALTH]
		MOV	CX, 3
		MOV	DH, 24
		MOV	DL, STRPOSN_HEALTH
		CALL	PRINT_NUMBER
		MOV	AX, WORD [TREASURES]
;		MOV	CX, 4
		MOV	DL, STRPOSN_TREASURES
		CALL	PRINT_NUMBER
		MOV	AX, WORD [KILLS]
;		MOV	CX, 4
		MOV	DL, STRPOSN_KILLS
		CALL	PRINT_NUMBER
		POP	DX
		POP	CX
		POP	AX
		RET


; ----------------------------------------------------------------------
; GAME_PRINT_STATUS: Prints a status message.
; Inputs:
;	SI	- address of string to print as status
;
; Outputs:
;	DH	- 24
;	DL	- actual column position of cursor
; ----------------------------------------------------------------------
GAME_PRINT_STATUS:
		PUSH	SI
		MOV	DH, 24
		MOV	DL, STRPOS_STATUS
		CALL	SCREEN_CLREOLN
		CALL	PRINT_STRING		; SI is already loaded by caller.
		POP	SI
		RET


; ----------------------------------------------------------------------
; GAME_PRINT_STATUS_ENEMY: Prints a compound message involving a
; randomly selected enemy.
; Inputs:
;	SI	- address of status string
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
GAME_PRINT_STATUS_ENEMY:
		PUSH	AX
		PUSH	BX
		PUSH	DX
		PUSH	SI
		CALL	GAME_PRINT_STATUS
;		MOV	AL, 20h			; Space.
;		CALL	PRINT_CHAR
		INC	DL			; Move one character. (PRINT_CHAR doesn't adjust DL accordingly.)
		MOV	AX, ARRAYL_ENEMIES
		XOR	BX, BX
		CALL	RANDOM
		SHL	AX, 1			; Shift left by 1 bit effectively multiplies by 2.
		MOV	BX, AX			; Move to BX, since AX can't be used in effective address calculation.
		MOV	SI, [ARRAY_ENEMIES + BX]
		CALL	PRINT_STRING
		MOV	AL, "!"
		CALL	PRINT_CHAR
		POP	SI
		POP	DX
		POP	BX
		POP	AX
		RET

; ----------------------------------------------------------------------
; GAME_HANDLE_BATTLE: Prints that the player has killed a random enemy.
; Inputs:
;	None.
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
GAME_HANDLE_BATTLE:
		PUSH	SI
		MOV	SI, STR_KILLED
		CALL	GAME_PRINT_STATUS_ENEMY
		POP	SI
		RET


; ----------------------------------------------------------------------
; GAME_HANDLE_DEAD: Prints player death message.
; Inputs:
;	None.
;
; Outputs:
;	None.
; ----------------------------------------------------------------------
GAME_HANDLE_DEAD:
		PUSH	AX
		PUSH	SI
		MOV	[HEALTH], WORD 0	; Health is supposedly negative, correct to 0.
		CALL	GAME_PRINT_STATS	; Update stats, one last time.
		MOV	SI, STR_DEAD
		CALL	GAME_PRINT_STATUS_ENEMY
		CALL	READ_KEY		; Wait for a keypress before exiting.
		POP	SI
		POP	AX
		RET


; ----------------------------------------------------------------------
; GAME_LOOP: Run game.
; Inputs:
;	None.
;
; Outputs:
;	Garbage (doesn't preserve registers).
; ----------------------------------------------------------------------
GAME_LOOP:
		CALL	GAME_PRINT_STATS
		MOV	DX, [PLAYER_POS]	; Player position will be stored in DX.
GL_ENTER:
		MOV	AL, PLAYERCHR
		CALL	PRINT_CHAR		; Print player - DX is already set.
		CALL	READ_KEY
		PUSH	AX
		MOV	AL, 20h			; Space.
		CALL	PRINT_CHAR		; Clear previous player position.
		POP	AX
		CMP	AH, KEY_UP
		JE	GL_PLAYERUP
		CMP	AH, KEY_DOWN
		JE	GL_PLAYERDOWN
		CMP	AH, KEY_RIGHT
		JE	GL_PLAYERRIGHT
		CMP	AH, KEY_LEFT
		JE	GL_PLAYERLEFT
		CMP	AX, 011Bh		; ESC?
		JE	GL_EXIT
		JMP	GL_ENTER
		
GL_EXIT:
		; Set cursor to the bottom of the screen.
		MOV	AH, 02h
		XOR	BX, BX
		MOV	DH, 25
		INT	10h
		RET

GL_PLAYERUP:
		DEC	DH
		JMP	GL_CONT
GL_PLAYERDOWN:
		INC	DH
		JMP	GL_CONT
GL_PLAYERRIGHT:
		DEC	DL
		JMP	GL_CONT
GL_PLAYERLEFT:
		INC	DL

GL_CONT:
		MOV	[PLAYER_POS], DX
		MOV	BX, PLAYER_POS
		CALL	FIX_PLAYER_POSITION

		JC	GL_NOTWARPED		; Check if warped.
		CALL	SCREEN_CLEAR
		CALL	GAME_INIT		; Generate new field.
		CALL	GAME_DRAW		; Draw new field.

GL_NOTWARPED:
		XOR	AX, AX			; Calculate GAMEDATA pos based on player pos.
		MOV	AL, DH
		MOV	BX, 80
		MUL	BL
		XOR	DH, DH
		ADD	AX, DX

		LEA	SI, [GAMEDATA]
		MOV	BX, AX
		MOV	AL, [SI + BX]

		CMP	AL, OBJECT_MONSTER
		JE	GL_BATTLE
		CMP	AL, OBJECT_POTION
		JE	GL_POTION
		CMP	AL, OBJECT_TREASURE
		JE	GL_TREASURE
		JMP	GAME_LOOP

GL_BATTLE:
		PUSH	BX			; Honestly not sure if BX needs to be preserved...
		MOV	AX, 25
		MOV	BX, 5
		CALL	RANDOM			; (Min. 5, max 30 points of damage.)
		POP	BX			; ...still did it just in case.
		SUB	[HEALTH], AX
		JBE	GL_DEAD			; Check if player is dead.
		INC	WORD [KILLS]
		CALL	GAME_HANDLE_BATTLE
		JMP	GL_CLEARITEM

GL_POTION:
		ADD	[HEALTH], WORD 5
		CMP	[HEALTH], WORD MAX_HEALTH
		JNA	GL_P_NA
		MOV	[HEALTH], WORD MAX_HEALTH	; Cap health at MAX_HEALTH
GL_P_NA:
		PUSH	DX
		PUSH	SI
		MOV	SI, STR_POTION
		CALL	GAME_PRINT_STATUS
		POP	SI
		POP	DX
		JMP	GL_CLEARITEM

GL_TREASURE:
		INC	WORD [TREASURES]
		PUSH	DX
		PUSH	SI
		MOV	SI, STR_TRFOUND
		CALL	GAME_PRINT_STATUS
		POP	SI
		POP	DX
GL_CLEARITEM:
		MOV	[SI + BX], BYTE 0	; Remove object so player won't encounter it again.
		JMP	GAME_LOOP

GL_DEAD:
		CALL	GAME_HANDLE_DEAD


START:
		MOV	AX, 0003h
		INT	10h			; Set 80x25 color text mode.
		CALL	RANDOM_INIT
		CALL	SCREEN_CLEAR
		CALL	GAME_INIT
		CALL	GAME_DRAW
		CALL	GAME_LOOP
		INT	20h			; Return to DOS.

GAMEDATA:	TIMES	0600h-$+$$ DB 0		; Pad file to exact 3 sectors length.
