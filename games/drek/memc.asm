memclear:			;Clear RAM
	mov ax,0		;IN - dx, stop point, si, start point
	add dx,1
.loop:
	cmp si,dx
	je .done
	mov ax,'0'
	mov [si],ax
	add si,1
	jmp .loop
jmp .loop
.done:
ret

markfull:	
	push ax
	push bx 		;Mark RAM location as full
	mov ax,0		;IN - dx, stop point, si, start point
.loop:
	cmp si,dx
	je .done
	mov ax,'*'
	mov [si],ax
	add si,1
	jmp .loop
jmp .loop
.done:	
	pop ax
	pop bx
ret

swapstack:
	cmp ax,0
	je .stack0
	
	cmp ax,1
	je .stack1
	
	jmp .done

.stack0:
	pusha
	mov [sp1],sp
	mov ax,0
	mov sp,[sp0]
	popa
jmp .done

.stack1:
	pusha
	mov [sp0],sp
	mov ax,0
	mov sp,[sp1]
	popa
jmp .done

.done:
ret

printstack:
	mov bx,0
	mov si,sp
.loop:
	mov ah,0Eh
	lodsb	
	cmp bx,64
	je .done
	int 10h	
	add bx,1
	jmp .loop
.done:
	mov si,return
	call print
	mov ax,sp
	call tostring
	mov si,ax
	call print
	.end:
ret

maloc:			;Allocate RAM
	mov dx,ax	;IN - ax, size
	push dx		;OUT - ax, bottom, bx, top
	mov si,void + 20
.find:
	cmp byte[si],'0'
	je .test
	add si,1
	add dx,1
	cmp dx,void + 1000h
	je .full
	jmp .find
.test:
	add si,1
	cmp byte[si],'0'
	je .aloc
	jmp .find
.aloc:
	sub si,1
	pop dx
	mov ax,si
	mov bx,ax
	add bx,dx
	mov dx,bx
	mov si,ax
	call markfull
	jmp .done
.full:
	mov si,.err
	call print
	jmp .done
.done:
ret
	.err db 'Memory full',13,10,0

load2mem:	
	mov ax,si		;Load into memory		
	mov di,bx		;IN - ax, top, bx, bottom, si, source		
.loop:
	mov al,[si]
	mov [di],al
	add di,1
	add si,1
	cmp byte al,0
	jne .loop
.done:		
ret

memaloc:
	mov si,.prmpt
	call print
	mov di,buffer
	call input
	
	mov si,buffer
	call toint
	
	call maloc
	
	push bx
	call tostring
	mov si,ax
	call print
	mov si,.space 
	call print
	
	pop bx
	mov ax,bx
	call tostring
	mov si,ax
	call print
	mov si,return
	call print
ret
	.prmpt db 'Size>',0
	.space db ' - ',0

freemem:
	mov si,.bot
	call print
	mov di,buffer
	call input
	
	mov si,buffer
	call toint
	cmp ax,void + 19
	jle .err
	mov si,ax
	push si
	
	mov si,.top
	call print
	mov di,buffer
	call input
	mov si,buffer
	call toint
	mov dx,ax
	pop si
	call memclear
	jmp .done
.err:
	mov si,.errmsg
	call print
	jmp .done
.done:
ret
	.top db 'Top>',0
	.bot db 'Bottom>',0
	.errmsg db 'Illegal!',13,10,0

shiftmem:				;SI, source, DI, destination, AX, length
	pusha
	mov dx,0
	mov bx,ax
.loop:
	cmp di,void + 20
	jle .done
	mov al, [si]			
	mov [di], al
	add si,1
	add di,1
	add dx,1
	cmp dx,bx			
	jne .loop
.done:
	popa
ret