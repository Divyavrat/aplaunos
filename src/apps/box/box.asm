org 0x6000
use16

mov ax,0x0013
int 10h
JMP MAINP

PS2SET:
  mov  al, 0xa8
  out  0x64, al
  call CHKPRT
ret


CHKPRT:
  xor  cx, cx		
 .again:
  in   al, 0x64
  test al, 2
  jz  .chkprtgo
  jmp .again
.chkprtgo:
ret


WMOUS:
  mov  al, 0xd4
  out  0x64, al
  call CHKPRT
ret


MBUFFUL:
  xor  cx, cx
 .mn:
  in   al, 0x64
  test al, 0x20
  jz  .mnn
  loop .mn
 .mnn:
ret



ACTMOUS:
  call WMOUS
  mov  al, 0xf4
  out  0x60, al
  call CHKPRT
  call CHKMOUS
ret

CHKMOUS:
  mov  bl, 0
  xor  cx, cx
 .vrd:
  in   al, 0x64	
  test al, 1
  jnz .yy
  loop .vrd
  mov  bl, 1
 .yy:
ret


DKEYB:
  mov  al, 0xad
  out  0x64, al
  call CHKPRT
ret


EKEYB:
  mov  al, 0xae
  out  0x64, al
  call CHKPRT
ret

GETB:
 .cagain:
  call CHKMOUS
or bl,bl
jz GETB_exit
;cmp byte [found],'s'
;je mouse_action_star
;jmp .cagain
jmp mouse_action_star
GETB_exit:
  call DKEYB
  xor  ax, ax
  in   al, 0x60
  mov  dl, al
  call EKEYB
  mov  al, dl
ret
mouse_action_star:
call mousedrawstar
jmp GETB

GETFIRST:
  call GETB
  xor  ah, ah
  mov  bl, al
  and  bl, 1
  mov  BYTE [LBUTTON], bl
  mov  bl, al
  and  bl, 2
  shr  bl, 1
  mov  BYTE [RBUTTON], bl
  mov  bl, al
  and  bl, 4
  shr  bl, 2
  mov  BYTE [MBUTTON], bl
  mov  bl, al
  and  bl, 16
  shr  bl, 4
  mov  BYTE [XCOORDN], bl
  mov  bl, al
  and  bl, 32
  shr  bl, 5
  mov  BYTE [YCOORDN], bl
  mov  bl, al
  and  bl, 64
  shr  bl, 6
  mov  BYTE [XFLOW], bl
  mov  bl, al
  and  bl, 128
  shr  bl, 7
  mov  BYTE [YFLOW], bl
ret



GETSECOND:
  call GETB
  xor  ah, ah
  mov  BYTE [XCOORD], al
ret


GETTHIRD:
  call GETB
  xor  ah, ah
  mov  BYTE [YCOORD], al
ret

MAINP:
  call PS2SET
  call ACTMOUS
  call GETB	
mouse_main:
  call GETFIRST
  call GETSECOND
  call GETTHIRD

 mov BYTE [row], 10
 mov BYTE [col], 0

;cmp byte [found],'s'
;je no_disp_select
;jmp mouse_disp
;no_disp_select:
;jmp no_mouse_disp
;mouse_disp:
 call GOTOXY
call newline
mov al,'X'
call printf
mov byte al,[xmouse]
call printnb
call space
mov al,'Y'
call printf
mov byte al,[ymouse]
call printnb
call newline
 mov  si, strcdx
 call prnstr
 mov  al, BYTE [XCOORDN]
 or   al, al
 jz  .negative
 mov  si, strneg
 call prnstr
 jmp .positive
.negative:
 call space
.positive:
 xor  ah, ah
 mov  al, BYTE [XCOORD]
 call DISPDEC
 call newline

 mov  si, strcdy	; display the text for Ycoord
 call prnstr
 mov  al, BYTE [YCOORDN]
 or   al, al
 jz  .negativex
 mov  si, strneg	; if the sign bit is 1 then display - sign
 call prnstr
 jmp .positivex
.negativex:
 call space
.positivex:
 xor  ah, ah
 mov  al, BYTE [YCOORD]
 call DISPDEC
 call newline


 mov  si, strlbt	; display the text for Lbutton
 call prnstr
 mov  al, BYTE [LBUTTON]
 xor  ah, ah
 call DISPDEC
  call newline


 mov  si, strrbt	; display the text for Rbutton
 call prnstr
 mov  al, BYTE [RBUTTON]
 xor  ah, ah
 call DISPDEC
 call newline
 

 mov  si, strmbt	; display the text for Mbutton
 call prnstr
 mov  al, BYTE [MBUTTON]
 xor  ah, ah
 call DISPDEC
 call newline
;no_mouse_disp:
call update_mouse

    xor  ax, ax
    mov  ah, 0x11
    int  0x16
    jnz quitprog

jmp mouse_main

quitprog:
ret

update_mouse:

mov  al, BYTE [XCOORDN]
 or   al, al
 jnz  .negative
mov ax,0
mov byte al,[XCOORD]
;add word [xmouse],ax
add word [xmouse],1
 jmp .y_update
 
 .negative:
 mov ax,0
mov byte al,[XCOORD]
;sub word [xmouse],ax
sub word [xmouse],1
 jmp .y_update

.y_update:
mov  al, BYTE [YCOORDN]
 or   al, al
 jnz  .negativey
mov ax,0
mov byte al,[YCOORD]
;add word [ymouse],ax
add word [ymouse],1
 jmp .done
 
 .negativey:
 mov ax,0
mov byte al,[YCOORD]
;sub word [ymouse],ax
sub word [ymouse],1

.done:

.check:
cmp word [xmouse],0
jl .x_small
cmp word [xmouse],0x0140
jg .x_big
cmp word [ymouse],0
jl .y_small
cmp word [ymouse],0x00C8
jg .y_big
jmp .ok
.x_small:
add word [xmouse],0x0140
jmp .check
.x_big:
sub word [xmouse],0x0140
jmp .check
.y_small:
add word [ymouse],0x00C8
jmp .check
.y_big:
sub word [ymouse],0x00C8
jmp .check

.ok:
; cmp al,0x7f
; jg update_x_pos
; add bx,ax
; jmp update_x_pos_done
; update_x_pos:
; sub bx,ax
; update_x_pos_done:
; mov word [xmouse],bx

; mov byte al,[YCOORD]
; mov word bx,[ymouse]

; cmp al,0x7f
; jg update_y_pos
; sub bx,ax
; jmp update_y_pos_done
; update_y_pos:
; add bx,ax
; update_y_pos_done:
; mov word [ymouse],bx
; xor bx,bx
mov word [XCOORD],bx
mov word [YCOORD],bx
mov word [XCOORDN],bx
mov word [YCOORDN],bx
ret
mousedrawstar:
mov bh,[page]
mov word cx,[xmouse]
mov word dx,[ymouse]
mov al,cl
mov ah,0x0c
int 10h
ret

DISPDEC:
    mov  BYTE [var_x], 0x00
    mov  WORD [var_b], ax
    xor  ax, ax
    xor  cx, cx
    xor  dx, dx
    mov  bx, 10000
    mov  WORD [var_a], bx
   .mainl:
    mov  bx, WORD [var_a]
    mov  ax, WORD [var_b]
    xor  dx, dx
    xor  cx, cx
    div  bx
    mov  WORD [var_b], dx
    jmp .ydisp
   
   .vdisp:
    cmp  BYTE [var_x], 0x00
    je .nodisp

   .ydisp:
    mov  ah, 0x0E			    
    add  al, 48 			     
    mov  bx, 1 
    int  0x10				    
    mov  BYTE [var_x], 0x01
   jmp .yydis

   .nodisp:

   .yydis:
    xor  dx, dx
    xor  cx, cx
    xor  bx, bx
    mov  ax, WORD [var_a]
    cmp  ax, 1
    je .bver
    cmp  ax, 0
    je .bver
    mov  bx, 10
    div  bx
    mov  WORD [var_a], ax
   jmp .mainl

   .bver:
   ret

GOTOXY:
    mov dl, BYTE [col]
    mov dh, BYTE [row]
call setpos
ret

printf:
mov dl,al
mov ah,0x02
int 0x21
ret

space:
mov al,0x20
call printf
ret

prnstr:
mov dx,si
mov ah,0x03
int 0x61
ret

printnb:
mov dl,al
mov ah,0x26
int 0x61
ret

getpos:
mov ah,0x30
int 0x61
ret

setpos:
mov ah,0x31
int 0x61
ret

newline:
mov ah,0x0B
int 0x61
ret

LBUTTON db 0x00 
RBUTTON db 0x00 
MBUTTON db 0x00 
XCOORD	db 0x00 
YCOORD	db 0x00 
XCOORDN db 0x00 
YCOORDN db 0x00 
XFLOW	db 0x00 
YFLOW	db 0x00

xmouse:
dw 0x0000
ymouse:
dw 0x0000
var_a:
dw 0x0000
var_b:
dw 0x0000
var_x	db 0x00
var_y	db 0x01

strlbt	db "Left btn:   ", 0x00
strrbt	db "Rigt btn:  ", 0x00
strmbt	db "Midl btn: ", 0x00
strcdx	db "X:", 0x00
strcdy	db "Y:", 0x00
strneg	db "-", 0x00
row	db 0x00
col	db 0x00

page:
db 0

times (512*2) - ($-$$) db 0