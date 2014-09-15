        ;title  lines.asm  Draws a line using Bresenham's Line Algorithm
        ;public lines
		;.model small
        ;.586
        ;.stack 100h
        ;.data
		org 0x6000
lines:

        pushad                  ;this instruction pushes ALL the registers onto the stack
		mov  ax, 0a000h
        mov  es, ax
        mov  ah, 0
        mov  al, 13h
        int  10h
        mov  cl, [color]          ;cl contains color thruout
        mov  eax, [x2]
        sub  eax,[x1]
        mov  [ddx], eax
        cmp  eax, 0
        jg   x2x1pos
        neg  eax
x2x1pos:
        mov  ebx, [y2]
        sub  ebx,[y1]
        mov  [ddy], ebx
        cmp  ebx, 0
        jg   y2y1pos
        neg  ebx
y2y1pos:
        cmp  eax, ebx
;       jl   ybigger

; The case where abs(x2-x1) >= abs(y2-y1)
        mov  [e], 0
        mov  eax,[ x1]
        mov  [x], eax
        mov  eax, [y1]
        mov  [y], eax
again:
        mov  eax, [x]
        cmp  eax, [x2]
        jg   endloop
        mov  eax, [y]
        imul eax, 320
        add  eax, [x]
        mov  byte [es:eax], cl
        add  [x], 1
        mov  eax, [ddy]
        add  [e], eax
        mov  eax, [e]
        shl  eax, 1
        cmp  eax, [ddx]
        jl   again
        mov  eax, [ddx]
        sub  [e], eax
        add  [y], 1
        jmp  again

endloop:
        mov  ah, 1
        int  21h
        mov  ah, 0
        mov  al, 3
        int  10h
        popad                  ; this instruction pops all the registers from the stack in the reverse order employed by PUSHAD            
		ret
		
x1      dd  20
y1      dd  10
x2      dd  200
y2      dd  50
x       dd  ?
y       dd  ?
ddx     dd  ?
ddy     dd  ?
e       dd  ?
color   db  4
