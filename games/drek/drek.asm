;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;	
;	Copywrite Sean Haas 2011-12
ORG 0x6000

JMP SHORT Init
Init:
	cli
	mov ax,0
	mov ss,ax
	mov sp,0FFFFh
	sti

	cmp byte[iscrash],1
	je bsod
	mov byte[iscrash],1

	mov ah,00h
	mov al,03h
	int 10h

	mov si,loadmem
	call print
	; mov si,0
	; mov dx,99h
	; call memclear

	mov si,void + 15
	mov dx,void + 1024
	call memclear	

        mov si,loading
        call print

	mov dx,5
        call dotdot
	call beep
        call clear

        mov si,header
        call print
	call printret

	call getrnd

	mov ah,00h
	mov al,12h
	int 10h

main:			;Main command loop
	call room1
jmp main

	sp0 dw 0
	sp1 dw 0
        loading db 13,10,'Loading',0
	loadmem db 'Setting Up Memory Allocater...',13,10,0
        dot db '.',0
	root db 'root',0
	voidat db 13,10,'Void at ',0
	ips db '1m instructions in ',0
	ipsticks db ' ticks',0
	help db 'help',0
        header db 'TBAOS powered by DreckigOS',13,10,'v0.006 Alpha',13,10,'2011-12 Sean Haas',13,10,'Flavor text by Tristan Spencer',13,10,0
        prompt db '?>',0
        error db 'Error!',13,10,0
        reboot db 'reboot',0
	rebootmsg db 'Rebooting...',0
        offmsg db 13,10,'Computer Halted...',0
	bsodmsg db 13,10,13,10,'          Dreckig has crashed, happy? :-(',13,10,'          Bang on the keyboard multiple times to walk away',0
	kbs db 'kb',13,10,0 
	return db '',13,10,0
        press db 13,10,'Press any key to continue...',13,10,0
	page dw 0
	iscrash db 0
	locked db 0
        buffer: times 64 db 0

INCLUDE "memc.asm"	
INCLUDE "game.asm"

print:			;Print string
	pusha
	mov ah,0Eh	;IN - si, string to print
	mov bl,2
.repeat:
        lodsb
        cmp al,0
        je .done
        int 10h
        jmp .repeat
.done:
	popa
        ret

dotdot:
	mov cx,0	;Print dots to the screen with a time delay
.loop:			;IN - dx, number of dots
        add cx,1
        mov si,dot
        call print
        mov ax,1
        call pause1
        cmp cx,dx
        je .done
        jmp .loop
.done:
        ret

input:			;Take keyboard input
        xor cl,cl	;IN - di, string to store input in
.loop:
        mov ah,0
        int 0x16

        cmp al,0x0D
        je .done

	cmp al,08h
	je .backspace

	cmp ah,1
	je .esc

	mov bl,2
        mov ah,0x0E
        int 10h

        stosb
        inc cl
        jmp .loop
.backspace:
	cmp cl,0
	je .loop
	
	dec di
	mov byte [di],0

	mov ah,0Eh
	mov al,08h
	int 10h

	mov al,' '
	int 10h

	mov al,08h
	int 10h
	jmp .loop
.esc:
	cmp byte[locked],1
	je .loop
	call printret
	call main
.done:
        mov al,0
        stosb

        mov ah,0x0E
        mov al,0x0D
        int 0x10
        mov al,0x0A
        int 0x10
ret

printret:
	pusha
	mov si,return
	call print
	popa
ret

waitkey:		;Wait for key press
	pusha		;OUT - ax, key pressed
	mov ax,0
	mov ah,10h
	int 16h
	mov [.tmp],ax
	popa
	mov ax,[.tmp]
ret
	.tmp dw 0

compare:		;Compare two strings
        pusha		;IN di, si, strings to compare
.loop:			;OUT - setc carry flag if strings are equal
        mov al,[si]
        mov bl,[di]
        cmp al,bl
        jne .no

        cmp al,0
        je .done

        inc si
        inc di
        jmp .loop
.no:
        popa
        clc
        ret
.done:
        popa
        stc
	ret

clear:			;Clear screen
	pusha
        mov dx,0
        pusha
        mov bh,0
        mov ah,2
        int 10h
        popa

        mov ah,6
        mov al,0
        mov bh,2
        mov cx,0
        mov dh,24
        mov dl,79
        int 10h
        popa
	jmp .done
.done:
ret

pause1:			;Time delay
        pusha		;IN - ax, time in tenths of a second
        mov bx,ax
        mov cx,1h
        mov dx,86A0h
        mov ax,0
        mov ah,86h
.loop:
        int 15h
        dec bx
        jne .loop
        popa
ret

beep:			;Beep
	mov si,.beep
	call print
ret
	.beep db 7,0

length:			;Get string length
        pusha		;IN - ax, string
        mov bx,ax	;OUT - ax, length
        mov cx,0
.loop:
        cmp byte [bx],0
        je .done
        inc bx
        inc cx
        jmp .loop
.done:
        mov word [.tmp],cx
        popa
        mov ax,[.tmp]
ret
        .tmp dw 0

bcdtoint:			;Convert BCD to int
	pusha			;IN - al, BCD 
	mov bl,al		;OUT - ax, int
	add ax,0Fh
	mov cx,ax
	shr bl,4
	mov al,10
	mul bl
	
	add ax,cx
	mov [.tmp],ax
	popa
	mov ax,[.tmp]
ret
	.tmp dw 0

toint:
        pusha
	mov ax, si			
	call length

	add si, ax		
	dec si

	mov cx, ax		

	mov bx, 0		
	mov ax, 0

	mov word [.multiplier], 1	
.loop:
	mov ax, 0
	mov byte al, [si]		
	sub al, 48			

	mul word [.multiplier]		

	add bx, ax			

	push ax				
	mov word ax, [.multiplier]
	mov dx, 10
	mul dx
	mov word [.multiplier], ax
	pop ax

	dec cx				
	cmp cx, 0
	je .finish
	dec si				
	jmp .loop
.finish:
	mov word [.tmp], bx
	popa
	mov word ax, [.tmp]

	ret

	.multiplier	dw 0
	.tmp		dw 0

tostring:
        pusha
        mov cx,0
        mov bx,10
        mov di,.t
.push:
        mov dx,0
        div bx
        inc cx
        push dx
        test ax,ax
        jnz .push
.pop:
        pop dx
        add dl,'0'
        mov [di],dl
	inc di
        dec cx
        jnz .pop

        mov byte [di],0
        popa
        mov ax,.t
ret
        .t: times 7 db 0

move:
	pusha
	mov bh,0
	mov ah,2
	int 10h
	popa
ret

back:
	pusha
	mov bh,0
	mov ah,3
	int 10h

	mov [.tmp],dx
	popa
	mov dx,[.tmp]
ret
	.tmp dw 0

copystring:
	pusha
.more:
	mov al, [si]			
	mov [di], al
	inc si
	inc di
	cmp byte al, 0			
	jne .more

.done:
	popa
	ret

findchar:
	pusha
	mov cx,1
.more:
	cmp byte [si],al
	je .done
	cmp byte [si],0
	je .no
	inc si
	inc cx
	jmp .more
.done:
	mov [.tmp],cx
	popa
	mov ax,[.tmp]
	ret
.no:
	popa
	mov ax,0
ret
	.tmp dw 0

swapit:
	mov ax,[page]
	cmp ax,0
	je .two
	
	mov ax,0
	call multi
	mov ah,05h
	mov al,0
	int 10h
	mov ax,0
	jmp .done
	
.two:
	mov ax,1
	call multi
	mov ah,05h
	mov al,1
	int 10h
	mov ax,1
	
	.done:
	mov [page],ax
ret

multi:
	cmp ax,0
	je .cpu0

	cmp ax,1
	je .cpu1
	
.cpu0:
	mov [.ax1],ax
	mov [.bx1],bx
	mov [.cx1],cx
	mov [.dx1],dx
	mov [.si1],si
	mov [.di1],di

	mov ax,[.ax0]
	mov bx,[.bx0]
	mov cx,[.cx0]	
	mov dx,[.dx0]
	mov si,[.si0]
	mov di,[.di0]
jmp .done

.cpu1:
	mov [.ax0],ax
	mov [.bx0],bx
	mov [.cx0],cx
	mov [.dx0],dx
	mov [.si0],si
	mov [.di0],di

	mov ax,[.ax1]
	mov bx,[.bx1]
	mov cx,[.cx1]	
	mov dx,[.dx1]
	mov si,[.si1]
	mov di,[.di1]
jmp .done
.done:
ret
	.ax0 dw 0
	.bx0 dw 0
	.cx0 dw 0
	.dx0 dw 0
	.si0 dw 0
	.di0 dw 0
	.ax1 dw 0
	.bx1 dw 0
	.cx1 dw 0
	.dx1 dw 0
	.si1 dw 0
	.di1 dw 0

logit:
	mov byte[locked],1
	
	mov si,.pass
	call print
	mov di,.secret
	call input

	mov ah,05
	mov al,3
	int 10h
	call clear
.loop:
	mov si,.pass
	call print
	mov di,buffer
	call input
	mov si,.secret
	mov di,buffer
	call compare
	jc .done
	jmp .loop		
	jmp .done
.done:
	call clear
.exit:
	mov byte[locked],0
ret
	.pass db 'PASS>',0
	.secret: times 8 db 0

err_call:
	pusha
	mov si,error
	call print
	popa
ret

bsod:
	mov dx,0
	mov bh,0
	mov ah,2h
	int 10h
	mov cx,2000
	mov bh,0
	mov bl,17h
	mov al,20h
	mov ah,9h
	int 10h

	mov si,bsodmsg
	call print
	call printret
	call printret
	call printstack
	xor cx,cx
	xor ax,ax
.loop:
	push cx
	int 16h
	pop cx
	add cx,1
	cmp cx,15
	jge .done
	jmp .loop
.done:
	call main
	int 19h
ret

reboot1:
	mov si,rebootmsg
	call print
	mov dx,5
        call dotdot
	call clear
        mov ax,0
        int 0x19
ret

cpuoff:
        mov si,offmsg
        call print
.loop:
	hlt
	jmp .loop
	jmp $

kernend db 13,10,'Dreckig Kernel End',13,10,0
void: db 0,0,'Void Start',0,0