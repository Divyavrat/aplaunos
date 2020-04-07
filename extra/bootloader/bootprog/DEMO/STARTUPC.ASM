model tiny
.286

code	segment	use16
	assume	cs:code,ds:code,es:code
	org	100h

start:

        mov     ax, cs
        call    wax
        mov     ax, ds
        call    wax
        mov     ax, es
        call    wax
        mov     ax, ss
        call    wax
        mov     ax, sp
        call    wax

        lea     si, Msg
        cld
        mov     ah, 0eh
        mov     bx, 7
ErrorCycle:
        lodsb
        or      al, al
        jz      ErrorDone
        int     10h
        jmp     short ErrorCycle
ErrorDone:
        jmp     short $

wax:
        pusha
        mov     si, ax
        mov     cx, 4
        rol     si, cl
zzz:
        mov     ax, si
        and     al, 0fh
        lea     bx, HexTab
        xlat
        mov     ah, 0eh
        mov     bx, 7
        int     10h
        rol     si, 4
        loop    zzz
        mov     al, 32
        int     10h
        popa
        ret

HexTab  db      "0123456789ABCDEF"
sux     db      4096 dup (0) ; to ensure that long files are loaded normally
Msg	db	"Hello World! I'm a simple COM program.",13,10,0

code	ends

end	start
