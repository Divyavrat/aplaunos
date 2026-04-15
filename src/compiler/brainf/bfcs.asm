; ---------------------------------------
;	Brainf*** Compiler (for Ecstatic OS)
;	compile with NASM ( NASM bfc.asm -o bfc.com )
;
;	run: bfc inputfile outputfile
;
;	Author: Divyavrat Jugtawat
;	Date: 20/June/2014
;	Language: x86 Assembly
;	License: GPL v3 License
;
; ---------------------------------------

; Data section all variables can be changed from here
; Strings are defined at the end of program

program_location equ 0x6000
org 0x6000		; Should be equal to the variable program_location
				; Organised according to Ecstatic OS
				; change this to others like 100h for DOS
				
use16			; 16 bits or two byte codes

infile_location equ 0xCF00
outfile_location equ 0xE500
start_block equ 0xC500	; Starting cell to be pointed
color equ 7

; System Calls definition

os_main			equ	0500h	; Where the OS code starts
os_load_file		equ	os_main+0021h	; IN: AX = filename string location,
					; CX = location to load file
					; OUT: BX = file size in bytes,
					; carry clear if OK, set if missing
os_write_file		equ	os_main+0096h	; AX = filename, BX = data location,
					; CX = number of bytes to save
os_file_exists		equ	os_main+0099h	; AX = filename, carry clear if exists
					
; Code section main program starts here
start:
push si			; save arguments

mov ax,0x0003	; reset text mode
int 0x10
mov ax,0x0500	; set page to zero
int 0x10

mov si,intro	; start introduction string
call os_print_string

pop si			; get arguments
cmp si,0		; Checking for Arguments in OS (change for others)
je noarg

mov di,infile
.infile_name_loop:	; Getting Input File name
lodsb
cmp al,0		; End of input
je .end
cmp al,0x20		; End of first name
je .next
stosb
jmp .infile_name_loop

.next:
mov al,0
stosb

mov di,outfile
.outfile_name_loop:	; Getting Output File name
lodsb
cmp al,0		; End of input
je .end
cmp al,0x20		; End of second name
je .end
stosb
jmp .outfile_name_loop

.end:
mov al,0
stosb

mov ax,infile
call os_file_exists
jc .load_error
mov ax,infile
mov cx,infile_location
call os_load_file

mov ax,outfile
call os_file_exists
jc .load_error
mov ax,outfile
mov cx,outfile_location
call os_load_file

jmp main_loop

.load_error:	; Error message and quit
mov si,load_error
call os_print_string
ret

noarg:			; No arguments, so print help string
mov si,help
call os_print_string
ret

start_functions:	; definitions at start of code
mov ax,0x0003	; reset text mode
int 0x10
mov ax,0x0500	; set page to zero
int 0x10

mov di,start_block

;jmp start
db 0xE9,0x1A,0x00

input:
push di
mov ah,0x00
int 0x16
pop di
mov [di],al

output:
push di
mov al,[di]
;mov bh,color	; color
;mov bl,0		; page
mov bx,0x0700
mov ah,0x0E		; Print character function
int 0x10
pop di
;ret
pop bx
add bx,9
jmp bx
start_functions_end:; End of default functions

main_loop:		; Main compilation loop
mov di,outfile_location
mov si,start_functions
mov cx,start_functions_end-start_functions
;sub cx,2
push cx
rep movsb
pop cx

mov si,infile_location
.loop:
lodsb
cmp al,0
je .end
cmp al,0xFF
je .end
cmp al,'+'
je .plus
cmp al,'-'
je .minus
cmp al,'>'
je .next
cmp al,'<'
je .previous
cmp al,'.'
je .output
cmp al,','
je .input

; To be implemented
cmp al,'['
je .loop
cmp al,']'
je .loop

dec cx
jmp .loop

.plus:
; mov al,0xFE
; stosb
; mov al,0x05
; stosb
mov ax,0x05FE
stosw
add cx,2
jmp .loop
.minus:
; mov al,0xFE
; stosb
; mov al,0x0D
; stosb
mov ax,0x0DFE
stosw
add cx,2
jmp .loop
.next:
mov al,0x47
stosb
inc cx
jmp .loop
.previous:
mov al,0x4F
stosb
inc cx
jmp .loop
.output:
mov al,0xB9
stosb
mov ax,cx
add ax,program_location
stosw
; mov al,0x51
; stosb

; mov al,0xBB
; stosb
mov ax,0xBB51
stosw
mov ax,program_location+0x18
stosw

; mov al,0xFF
; stosb
; mov al,0xE3
; stosb
mov ax,0xE3FF
stosw
add cx,9
jmp .loop
.input:
mov al,0xB9
stosb
mov ax,cx
add ax,program_location
stosw
; mov al,0x51
; stosb

; mov al,0xBB
; stosb
mov ax,0xBB51
stosw
mov ax,program_location+0x10
stosw

; mov al,0xFF
; stosb
; mov al,0xE3
; stosb
mov ax,0xE3FF
stosw
add cx,9
jmp .loop

.end:
mov byte [di],0xC3

mov bx,outfile_location		; Save the output file back
call os_write_file
ret

; os_print_string : SI - Input String All Registers reserved
os_print_string:
pusha			; Save all registers
.loop:
lodsb			; Load a byte from string
or al,al		; If zero then end
jz .end
mov bh,color	; color
mov bl,0		; page
mov ah,0x0E		; Print character function
int 0x10			; BIOS interrupt
jmp .loop
.end:
popa			; Restore all registers
ret

; Data section all Strings can be changed from here

intro:	db 0x0D,0x0A," Brainf*** Compiler (ver 1.3)"
		db 0x0D,0x0A," Author: Divyavrat Jugtawat",0x0D,0x0A,0
help:	db 0x0D,0x0A," Usage: bfcs inputfile outputfile",0x0D,0x0A,0
		; db 0x0D,0x0A," Output would be COM file with no header"
		; db 0x0D,0x0A," Commands: +-<>[].,"
		; db 0x0D,0x0A," All other characters are ignored.",0x0D,0x0A,0
load_error:	db 0x0D,0x0A," File not found. ",0x0D,0x0A,0

infile:	times 20 db 0
outfile:times 20 db 0
		
times 512-($-$$) db 0x90		; Padding will NOPs