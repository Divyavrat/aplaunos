; piano uses timer2 to produce sound
; number keys play notes to simulate
; a baby-grand piano
;-----------------------------------

portB   equ 61h         ; i/o port B
keybd2  equ 7h          ; keyboard input, no echo
doscall equ 21h         ; DOS interrupt
cont_c  equ 03h         ; control-c ASCII code

;***********************
;.model tiny
;.code
;.startup


;***********************
; main
;***********************

main:; proc

    org   0x6000          ; start address

  read_key:
    mov   ah, keybd2    ; keyboard, no echo
    int   doscall
    cmp   al,cont_c     ; is it control-c?
    jz    go_away
    
    mov   dl,al         ; print it
    push  ax
    mov   ah,2
    int   doscall
    pop   ax
    
    sub   al,31h        ; get number
    and   al,00000111b  ; mask off 5 bits

  ; get frequency for each number
    cmp   al,1d
    jnz   chk2
    mov   bx,1196h      ; c
  chk2:
    cmp   al,2d
    jnz   chk3
    mov   bx,0fach      ; d
  chk3:
    cmp   al,3d
    jnz   chk4
    mov   bx,0DF6h      ; e
  chk4:
    cmp   al,4d
    jnz   chk5
    mov   bx,0D47h      ; f
  chk5:
    cmp   al,5d
    jnz   chk6
    mov   bx,0BC1h      ; g
  chk6:
    cmp   al,6d
    jnz   chk7
    mov   bx,0A79h      ; a
  chk7:
    cmp   al,7d
    jnz   chk8
    mov   bx,953h       ; b
  chk8:
    cmp   al,8d
    jnz   chk9
    mov   bx,8CBh       ; c
  chk9:
    cmp   al,9d
    jnz   endchk
    mov   bx,7AAh       ; d
  endchk:

  ; put pitch in timer, turn on tone
    mov   al,10110110b  ; magic number
    out   43h,al        ; in timer
    mov   ax,bx         ; pitch
    out   42h,al        ; lsb into timer
    mov   al,ah         
    out   42h,al        ; msb into timer
    in    al,portB
    or    al,3          ; turn on speaker
    out   portB,al
    
  ; wait, then turn off speaker
    mov   cx,0fh     ; outer delay
  more2:
    push  cx
    mov   cx,0ffffh     ; delay
  more:
    loop  more
    pop   cx
    loop  more2
    in    al,portB
    and   al,11111100b  ; turn off speaker
    out   portB,al
    jmp   read_key      ; return to start
    
  ; leave the program
  
  go_away:
  ret
    ;.exit
    
;main endp

  ;end
