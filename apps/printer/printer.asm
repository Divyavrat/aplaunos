use16
org 0x6000

start :
        ; mov ax, data
        ; mov ds, ax
        ; mov es, ax

		mov si,msg1
        call prnstr
        mov ah, 0ah
        mov dx, buf
        int 21h
        mov si, buf + 2
        mov ch, 00h
        mov cl, [si-1]

        mov dx, 0000h
again :
        mov ah, 02h
        int 17h

        test ah, 00101001b
        jz cont
		mov si,msg2
        call prnstr
        jmp again
cont :
        mov ah, 00h
        mov dx, 0000h
next :
        mov ah, 00h
        mov al, [si]
        int 17h
        inc si
        loop next

		mov si,msg3
        call prnstr
		
        mov ax, 4c00h
        int 21h
		
		prnstr:
        mov ah, 09h
        mov dx,si
        int 21h
		ret

        msg1 db "Enter string to be printed : $"
        msg2 db 0dh, 0ah, "I/O Error or Paper out...$"
        msg3 db 0dh, 0ah, "Printing string...$"
        buf db 80
            db 0
            db 80
