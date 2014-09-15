; FTL - LIFE Game 1.6 - Freeware by David Mitchell
; email: Dave@zenonic.demon.co.uk
;
; FTL is a small (5K) implementation of John Horton Conway's LIFE
; algorithm for a 200 by 200 universe on a CGA.
;
; largley written in July/August 1988
;
; Equates
dos     equ     21h     ; DOS interrupt
dosvfn  equ     30h     ; DOS Version function
creafn  equ     3ch     ; open file
openfn  equ     3dh     ; open file
closfn  equ     3eh     ; close file
readfn  equ     3fh     ; read file
writfn  equ     40h     ; write file
alloc   equ     48h     ; allocate memory
setblk  equ     4ah     ; set block
keyfn   equ     6       ; get keyboard char (no echo)
errhand equ     2       ; error output
buflen  equ     4096
colval  equ     0efh    ; set color active
vduseg  equ     40h     ; BIOS VDU information
vduoff  equ     10h     ;
colbuff equ     0b800h  ; color adapter buffer

bwide   equ     200     ; width of the universe
bdeep   equ     200     ; depth of the universe
bsize   equ     bwide * bdeep           ; 40K bytes

genrow  equ     0       ; row containing "Tick ..."
gencol  equ     bwide/8 + 2
limrow  equ     1       ; row containing "Limit ..."
limcol  equ     bwide/8 + 2
posrow  equ     2       ; row containing "X= ..."
poscol  equ     gencol
bufrow  equ     3       ; row containing "Box( ... "
bufcol  equ     gencol
conrow  equ     5       ; starting row of detail view
concol  equ     bwide/8 + 2
dmrow   equ     19      ; message row
dmcol   equ     27

sep1    equ     8*1024 - bwide/4        ; offset to odd CGA lines
sep2    equ     8*1024 + bwide/4 - 80   ; offset to even CGA lines

kbd     equ     16h     ; keyboard interrupt
kcr     equ     13      ; return
kesc    equ     27      ; escape
ktab    equ     9       ; tab
kbtab   equ     15      ; backtab (extended key)
kbsp    equ     8       ; backspace
kdel    equ     83      ; delete
kf1     equ     59      ; F1
khome   equ     71      ; home
kup     equ     72      ; up
kpgup   equ     73      ; pgup
kleft   equ     75      ; left
kright  equ     77      ; right
kcleft  equ     115     ; c-left
kcright equ     116     ; c-right
kend    equ     79      ; end
kdown   equ     80      ; down
kpgdn   equ     81      ; pgdn

        ; BIOS VDU stuff
video   equ     10h     ; video interrupt
wxor    equ     83h     ; xor logic
wand    equ     03h     ; and logic
setmode equ     0       ; select set mode
setcur  equ     2       ; set cursor pos
wchat   equ     9       ; write char/attr
wchar   equ     10      ; write char
wdot    equ     12      ; write dot
rdot    equ     13      ; read dot
getmode equ     15      ; select set mode
setcol  equ     0bh     ; select color change
mrmode  equ     4       ; medium-resolution color graphics
bgid    equ     0       ; set background color
plid    equ     1       ; set palette

life    segment para
        assume  cs:life,ds:life,es:life

; map PSP area
        org     80h     ; length of supplied pars
plen    label   byte
        org     81h
parea   label   byte    ; supplied parms
        ;org     100h
		org 6000h
;start:
start    proc    far
main proc far
jmp     begin

; data areas
fgcol1  db      64      ; masks for use in setting pixels
fgcol2  db      16
fgcol3  db      4
fgcol4  db      1

fgcolor db      1       ; foreground (pixel) colour
bgcolor db      16      ; black background
lscolor db      3       ; current position spot colour
bdcolor db      0aah    ; border color
palette db      0       ; green/red/brown
oldmode db      0       ; saved video mode
olddot  db      0       ; saved pixel at current position
newdot  db      03h     ; current position dot
boxdot  db      82h     ; used for box drawing

bcount  db      ?       ; bit count when cutting
buffp   dw      ?       ; pointer to current byte in buffer (load/save)
work    db      ?       ; work byte used for cutting

        ; messages
doserr  db      "FTL doesn't run under DOS 1 - sorry",13,10,0
memerr  db      "Not enough memory - sorry",13,10,0
nocol   db      "No Colour Adapter - sorry",13,10,0

hello   db      '  FTL V1.6   ' ,0
        db      '  Freeware   ',0
        db      '    by       ',0
        db      'Dave Mitchell',0
        db      '             ',0
        db      ' F1 for Help ',0
        db      0

bxmsg   db      'CUTTING:     ',0
        db      '/     toggles',0
        db      ' active edges',0
        db      'Del   clears ',0
        db      'Enter accepts',0
        db      'Esc   cancels',0
        db      0

rrmsg   db      'MANIPULATING:',0
        db      'Use -- to',0
        db      'reflect box, ',0
        db      'PgUp and PgDn',0
        db      'to rotate it. ',0
        db      'Esc to return',0
        db      0

        ;        1234567890123456789012345
helpmsg db      'The Board is an array of',0
        db      '200 * 200 cells. Use the',0
        db      'cursor keys to move the',0
        db      'current position.',0
        db      ' ',0
        db      'Space sets cells on/off',0
        db      'A  adjusts board centre',0
        db      'B  cycles background',0
        db      'C  cuts and stores a box',0
        db      'D  toggles detail on/off',0
        db      'G  go (Esc stops)',0
        db      'L  loads box from file',0
        db      'K  sets a breakpoint',0
        db      'M  manipulates box',0
        db      'P  pastes a stored box',0
        db      'Q  quits to DOS',0
        db      'S  saves box to file',0
        db      'T  advances one tick',0
        db      'Z  zeros the board',0
        db      '1  selects box buffer 1',0
        db      '2  selects box buffer 2',0
        db      '+  toggles palette',0
        db      ' ',0
prmsg   db      'Press any key to return.',0
        db      0

        ;        1234567890123456789012345
lsmsg   db      'Enter limit (or Esc)',0
filmsg  db      'Enter filename (or Esc)',0
rdemsg  db      'Error reading file     ',0
wremsg  db      'Error writing file     ',0
oklmsg  db      'Buffer has been loaded ',0
oksmsg  db      'Buffer has been saved  ',0

genmsg  db      ' Tick:  '
genval  db      '     ',0
gvlen   equ     $ - genmsg - 2

limmsg  db      ' Limit: '
limval  db      '     ',0
nolim   db      'None '

posmsg  db      ' X='
xpos    db      '     Y='
ypos    db      '   ',0
bufmsg  db      'Box( )' ; icon goes within parentheses
xbuf    db      '   *'
ybuf    db      '   ',0

vbuffp  dw      vbuff1  ; pointer to current buffer (vbuff1 or vbuff2)
curbox  db      1       ; current buffer in use (1 or 2)

bortp   dw      bort1a  ; box icon set to be used
bortv   dw      0       ; box icon within set to be used (0-3)
borta   dw      bort1a  ; normal box icon set
bortb   dw      bort1b  ; reflected box icon set
bortp1  dw      bort1a  ; current box 1 icon set
bortp2  dw      bort2a  ; current box 2 icon set
bortv1  dw      0       ; current box 1 icon within set
bortv2  dw      0       ; current box 2 icon within set

borient equ     bufrow*4*80 + concol * 2 + 8    ; screen address of icon

        ; "1" shape
bort1a  db   00h, 00h ;       ........  ; shape 0
        db   02h, 00h ;       ...*....
        db   0ah, 00h ;       ..**....
        db   2ah, 00h ;       .***....
        db   02h, 00h ;       ...*....
        db   02h, 00h ;       ...*....
        db   2ah,0a0h ;       .*****..
        db   00h, 00h ;       ...*....
        db   00h, 00h ;       ........  ; shape 1
        db   20h, 80h ;       .*..*...
        db   20h,0a0h ;       .*..**..
        db   2ah,0a8h ;       .******.
        db   20h, 00h ;       .*......
        db   20h, 00h ;       .*......
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 2
        db   0ah,0a8h ;       ..*****.
        db   00h, 80h ;       ....*...
        db   00h, 80h ;       ....*...
        db   00h,0a8h ;       ....***.
        db   00h,0a0h ;       ....**..
        db   00h, 80h ;       ....*...
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 3
        db   00h, 00h ;       ........
        db   00h, 08h ;       ......*.
        db   00h, 08h ;       ......*.
        db   2ah,0a8h ;       .******.
        db   0ah, 08h ;       ..**..*.
        db   02h, 08h ;       ...*..*.
        db   00h, 00h ;       ........

bort1b  db   00h, 00h ;       ........  ; shape 0
        db   00h, 80h ;       ....*...
        db   00h,0a0h ;       ....**..
        db   00h,0a8h ;       ....***.
        db   00h, 80h ;       ....*...
        db   00h, 80h ;       ....*...
        db   0ah,0a8h ;       ..*****.
        db   00h, 00h ;       .... ...
        db   00h, 00h ;       ........  ; shape 1
        db   02h, 08h ;       ...*..*.
        db   0ah, 08h ;       ..**..*.
        db   2ah,0a8h ;       .******.
        db   00h, 08h ;       ......*.
        db   00h, 08h ;       ......*.
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 2
        db   0ah,0a8h ;       .*****..
        db   02h, 00h ;       ...*....
        db   02h, 00h ;       ...*....
        db   2ah, 00h ;       .***....
        db   0ah, 00h ;       ..**....
        db   02h, 00h ;       ...*....
        db   00h, 00h ;       ........
        db   00h, 00h ;       .........  ; shape 3
        db   00h, 00h ;       .........
        db   20h, 00h ;       .*.......
        db   20h, 00h ;       .*.......
        db   2ah,0a8h ;       .*******.
        db   20h,0a0h ;       .*...**..
        db   20h, 80h ;       .*...*...
        db   00h, 00h ;       .........

bort2a  db   00h, 00h ;       ........  ; shape 0
        db   0ah, 80h ;       ..***...
        db   20h, 20h ;       .*...*..
        db   00h, 80h ;       ....*...
        db   02h, 00h ;       ...*....
        db   0ah, 00h ;       ..*.....
        db   2ah,0a0h ;       .*****..
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 1
        db   20h, 20h ;       .*...*..
        db   28h, 08h ;       .**...*.
        db   22h, 08h ;       .*.*..*.
        db   20h, 88h ;       .*..*.*.
        db   20h, 20h ;       .*...*..
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 2
        db   0ah,0a8h ;       ..*****.
        db   00h, 20h ;       .....*..
        db   00h, 80h ;       ....*...
        db   02h, 00h ;       ...*....
        db   08h, 08h ;       ..*...*.
        db   02h,0a0h ;       ...***..
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 3
        db   00h, 00h ;       ........
        db   08h, 08h ;       ..*...*.
        db   22h, 08h ;       .*.*..*.
        db   20h, 88h ;       .*..*.*.
        db   20h, 28h ;       .*...**.
        db   08h, 08h ;       ..*...*.
        db   00h, 00h ;       ........

bort2b  db   00h, 00h ;       ........  ; shape 0
        db   02h,0a0h ;       ...***..
        db   08h, 08h ;       ..*...*.
        db   02h, 00h ;       ...*....
        db   00h, 80h ;       ....*...
        db   00h, 20h ;       .....*..
        db   0ah,0a8h ;       ..*****.
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 1
        db   08h, 08h ;       ..*...*.
        db   20h, 28h ;       .*...**.
        db   20h, 88h ;       .*..*.*.
        db   22h, 08h ;       .*.*..*.
        db   08h, 08h ;       ..*...*.
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 2
        db   2ah,0a0h ;       .*****..
        db   08h, 00h ;       ..*.....
        db   02h, 00h ;       ...*....
        db   00h, 80h ;       ....*...
        db   20h, 20h ;       .*...*..
        db   0ah, 80h ;       ..***...
        db   00h, 00h ;       ........
        db   00h, 00h ;       ........  ; shape 3
        db   00h, 00h ;       ........
        db   20h, 20h ;       .*...*..
        db   20h, 88h ;       .*..*.*.
        db   22h, 08h ;       .*.*..*.
        db   28h, 08h ;       .**...*.
        db   20h, 20h ;       .*...*..
        db   00h, 00h ;       ........

bxr1    dw      ?       ; top row of box
bxc1    dw      ?       ; left column of box
bxr2    dw      ?       ; bottom row of box
bxc2    dw      ?       ; right column of box

bxw     dw      0       ; box width
bxd     dw      0       ; box depth (must follow width)

bxw1    dw      0       ; width of box 1
bxd1    dw      0       ; depth

bxw2    dw      0       ; width of box 2
bxd2    dw      0       ; depth

locrow  dw      bdeep/2 ; current position
loccol  dw      bwide/2
loco    dw      0       ; address of top left detail cell within board buffer

oldrow  dw      bdeep/2 ; old position of current position
oldcol  dw      bwide/2 ; (before cursor key moved it)

count   dw      0       ; count used during display of detail area
sholoc  db      0ffh    ; detail switch (0 = no detail)
step    db      0       ; if 1 then running continously
updat   db      0       ; if NZ, then we must redisplay board
gener   dw      0       ; current tick count
limit   dw      0       ; breakpoint tick count

detail  equ     conrow*4*80 + concol * 2        ; screen address of detail area

        ; detail area shapes
blobon  db  0ffh,0ffh ;       ........  Normal blob (LIVE)
        db  0eah,0abh ;       ........
        db  0eah,0abh ;       ........
        db  0eah,0abh ;       ........
        db  0eah,0abh ;       ........
        db  0eah,0abh ;       ........
        db  0eah,0abh ;       ........
        db  0ffh,0ffh ;       ........

bloboff db  0ffh,0ffh ;       ........  (DEAD)
        db  0c0h, 03h ;       .      .
        db  0c0h, 03h ;       .      .
        db  0c0h, 03h ;       .      .
        db  0c0h, 03h ;       .      .
        db  0c0h, 03h ;       .      .
        db  0c0h, 03h ;       .      .
        db  0ffh,0ffh ;       ........

blobonx db  0aah,0aah ;       ........  Central blob (LIVE)
        db  0aah,0aah ;       ........
        db  0aah,0aah ;       ........
        db  0aah,0aah ;       ........
        db  0aah,0aah ;       ........
        db  0aah,0aah ;       ........
        db  0aah,0aah ;       ........
        db  0aah,0aah ;       ........

blobofx db  0aah,0aah ;       ........  (DEAD)
        db  080h, 02h ;       .      .
        db  080h, 02h ;       .      .
        db  080h, 02h ;       .      .
        db  080h, 02h ;       .      .
        db  080h, 02h ;       .      .
        db  080h, 02h ;       .      .
        db  0aah,0aah ;       ........

dectab  dw      38528,152       ; 10M
        dw      16960,15        ; 1M
        dw      34464,1         ; 100K
        dd      10000,1000,100,10,1

ten     dw      10

b2dhi   dw      ?       ; used for bin2dec calculations
b2dlo   dw      ?
prec    dw      8       ; number of digits desired

fhand   dw      ?       ; file handle used for load/save

begin:  cld
        mov     sp,offset stk
        mov     ah,dosvfn       ; check DOS level
        int     dos
        cmp     al,0
        jnz     okdos
; not 2 or later so ..
        mov     dx,offset doserr
sorry:  call    saymsg
        int     20h     ; back to DOS
okdos:

        ; set up medium res mode etc
        ; but first have we got a color card?
        mov     ax,colbuff
        mov     es,ax
        mov     al,byte ptr es:[0]
        mov     ah,al   ; save it
        xor     al,0ffh
        xor     byte ptr es:[0],0ffh
        cmp     al,byte ptr es:[0]
        mov     byte ptr es:[0],ah      ; it appears there's no colour buffer
        mov     dx,offset nocol
        jnz     sorry
        mov     cx,vduseg               ; set up 320 by 200 4-colour mode
        mov     es,cx
        and     byte ptr es:[vduoff],colval
        mov     ah,setmode
        mov     al,mrmode
        int     video
        call    setbgc                  ; set background
        call    setpal                  ; and palette

        push    ds
        pop     es      ; es points to data seg again

        ;call    getmem                  ; shrink to code + buffers
		;mov    word ptr elife,9400h
        call    stripe                  ; draw vertical line at right of universe
        mov     si,offset hello
        call    dmsgs                   ; display banner
        mov     si,vbuffp
        mov     buffp,si                ; set up pointer to current box
        inc     buffp
        call    clear                   ; clear the board
		mov ah,1
		int 21h
        ;call    parms
        call    calco                   ; calculate detail area position
        call    dokey                   ; run the game
        mov     ah,setmode              ; return to 80 column mode
        mov     al,3
        int     video
        int     20h                     ; back to DOS
main    endp

parms   proc    ; look for a parm (filename)
        mov     al,byte ptr plen
        or      al,al           ; any parms?
        jnz     pmove
        ret
pmove:  ; move filename
        mov     si,offset parea
        mov     di,offset filnm
        xor     cx,cx
pmlp:   lodsb
        cmp     al,' '
        jz      pmlp
        or      al,al
        jz      pmexit
        cmp     al,kcr
        jz      pmend
        stosb
        inc     cx
        jmp     pmlp
pmend:  or      cx,cx
        jz      pmexit
        mov     byte ptr [di],0
        ;call    loadp
pmexit: ret
parms   endp

cycle   proc    ; advance to next generation
        mov     si,offset board
        mov     di,offset rowtab
        mov     byte ptr [di],0 ; ensure we skip the first row
        mov     byte ptr [di + bdeep - 1],0     ; and the last
        mov     bx,bwide        ; values to add/subtract
        xor     bp,bp
        sub     bp,bx
        mov     ah,10h
        ; first we examine each cell and influence its neighbours
        mov     dl,bdeep
cyolp:
        cmp     byte ptr [di],1
        jz      cyes
        add     si,bx
        mov     byte ptr [di],bh        ; bh is zero
        inc     di
        dec     dl
        jnz     cyolp
        jmp     cycel
cyes:   xor     dh,dh
        mov     cx,bx           ; outer loop - for each row
        dec     cx              ; less border
        dec     cx
        inc     si              ; step over border
cylp:   lodsb                   ; inner loop for each column
        test    al,ah
        jnz     cyyx
        loop    cylp
        jmp     cyel
cyyx:   ; here we deal with the 8 neighbours of the current cell:
        ;
        ;       123
        ;       4X5
        ;       678
        ;
        inc     dh
        push    si
        inc     byte ptr es:[si+bp]     ; 3
        inc     byte ptr [si]           ; 5
        inc     byte ptr [si+bx]        ; 8
        dec     si
        inc     byte ptr es:[si+bp]     ; 2
        inc     byte ptr [si+bx]        ; 7
        dec     si
        inc     byte ptr es:[si+bp]     ; 1
        inc     byte ptr [si]           ; 4
        inc     byte ptr [si+bx]        ; 6
        pop     si
        loop    cylp
cyel:   inc     si              ; step over border
        or      dh,dh
        jz      cynr
        mov     byte ptr [di-1],1       ; indicate previous row change
        mov     byte ptr [di],1         ; and current row change
        mov     byte ptr [di+1],1       ; and next row change
cynr:   inc     di
        dec     dl
        jnz     cyolp

        ; now set the proper value for each cell
cycel:  mov     si,offset board
        mov     dx,bdeep
        mov     di,offset rowtab
        mov     cx,bwide
cyoslp: cmp     byte ptr [di],1         ; outer, row, loop
        jz      cysi
        add     si,cx
        inc     di
        dec     dx
        jnz     cyoslp
        jmp     cyex
cysi:   xor     bx,bx
cyslp:  lodsb                   ; inner, column, loop
        or      al,al
        jz      cyns
        mov     ah,10h
        cmp     al,3            ; new cell born
        jz      cyst
        cmp     al,12h          ; old cell lives
        jz      cyst
        cmp     al,13h          ; old cell lives
        jz      cyst
cynz:   mov     ah,0
        jmp     cnst
cyst:   inc     bx              ; indicate active found
cnst:   mov     [si-1],ah
cyns:   loop    cyslp
        or      bx,bx           ; any active found?
        jnz     cynns
        mov     byte ptr [di],2
cynns:  inc     di
        mov     cx,bwide        ; reinstate cx
        dec     dx
        jnz     cyoslp
cyex:   mov     updat,1
        inc     gener
        ret
cycle   endp

stripe  proc    ; draw vertical stripe at right
        push    es
        mov     ax,colbuff
        mov     es,ax   ; es:di points to video buffer
        mov     al,bdcolor
        mov     di,bwide/4 + 1
        mov     cx,bdeep/2
bdlp:   mov     es:[di],al
        mov     es:[di + 8 * 1014],al
        add     di,80   ; bytes in a line
        loop    bdlp
        pop     es
        ret
stripe  endp

dline   proc    ; display current line
        push    es
        mov     si,offset board
        xor     di,di
        mov     ax,colbuff
        mov     es,ax   ; es:di points to video buffer
        mov     cx,locrow
        mov     dx,40
        mov     bx,bwide
        test    cx,1            ; odd line?
        jz      dlnl0
        add     di,8*1024 - 40
dlnl0:  jcxz    dlnl1
dlnl:   add     di,dx
        add     si,bx
        loop    dlnl
dlnl1:  mov     cx,bwide/4
dlnlp:
        lodsb           ; get point in al
        xor     ah,ah
        or      al,al
        jz      dln1
        or      ah,fgcol1
dln1:
        lodsb
        or      al,al
        jz      dln2
        or      ah,fgcol2
dln2:
        lodsb
        or      al,al
        jz      dln3
        or      ah,fgcol3
dln3:
        lodsb
        or      al,al
        jz      dln4
        or      ah,fgcol4
dln4:   mov     al,ah
        stosb
        loop    dlnlp
        pop     es
        ret
dline   endp

display proc    ; display board
        push    es
        mov     si,offset board
        xor     di,di
        mov     ax,colbuff
        mov     es,ax   ; es:di points to video buffer
        mov     bx,bdeep/2
        mov     bp,offset rowtab
        mov     dx,bwide        ; 200 points
        mov     cx,bwide/4      ; 50 bytes
dloop:  ; first we do an even line
        cmp     byte ptr [bp],0
        jnz     dleine
        add     di,cx
        add     si,dx
        jmp     dlo
dleine: lodsb           ; get point in al
        xor     ah,ah
        or      al,al
        jz      dle1
        or      ah,fgcol1
dle1:
        lodsb
        or      al,al
        jz      dle2
        or      ah,fgcol2
dle2:
        lodsb
        or      al,al
        jz      dle3
        or      ah,fgcol3
dle3:
        lodsb
        or      al,al
        jz      dle4
        or      ah,fgcol4
dle4:   mov     al,ah
        stosb
        loop    dleine
        mov     cx,bwide/4      ; 50 bytes
dlo:
        ; then an odd line
        inc     bp
        add     di,sep1
        cmp     byte ptr [bp],0
        jnz     dloine
        add     di,cx
        add     si,dx
        jmp     dli
dloine:
        xor     ah,ah
        lodsb
        or      al,al
        jz      dlo1
        or      ah,fgcol1
dlo1:
        lodsb
        or      al,al
        jz      dlo2
        or      ah,fgcol2
dlo2:
        lodsb
        or      al,al
        jz      dlo3
        or      ah,fgcol3
dlo3:
        lodsb           ; get points in al
        or      al,al
        jz      dlo4
        or      ah,fgcol4
dlo4:   mov     al,ah
        stosb
        loop    dloine
        mov     cx,bwide/4      ; 50 bytes
dli:    sub     di,sep2 ; back to even line
        inc     bp
        dec     bx
        jz      dexit
        jmp     dloop
dexit:
        pop     es
        ret
display endp

getmem  proc    ; shrink to include memory for board, buffers etc
        mov     ah,setblk
        mov     bx,offset elife
        add     bx,15   ; round up
        shr     bx,1
        shr     bx,1
        shr     bx,1
        shr     bx,1
        int     dos
		jc      gmerr
        ret
gmerr:  mov     dx,offset memerr
        call    saymsg
        int     20h     ; back to DOS
getmem  endp

clear   proc    ; clear the board
        xor     ax,ax
        mov     di,offset empty1
        mov     cx,bwide*7
    rep stosb                   ; clear pre-board
        mov     di,offset board
        mov     cx,bsize/2
    rep stosw                   ; clear board
        mov     di,offset empty2
        mov     cx,bwide*7
    rep stosb                   ; clear postboard
        mov     locrow,bdeep/2
        mov     loccol,bwide/2
        call    calco
        ;       ensure we display everything
        mov     al,1
        mov     di,offset rowtab - 1
        mov     cx,bdeep + 1
    rep stosb
        mov     updat,1
        mov     gener,0
        mov     limit,-1
        call    saylim
        call    saybox
        call    saygen
        ret
clear   endp

calco   proc    ; calculate offset of local area
        push    bx
        push    cx
        mov     si,offset board - bwide * 6
        mov     ax,bwide
        mov     cx,locrow
        jcxz    clcx
clclp:  add     si,ax
        loop    clclp
clcx:   mov     ax,loccol
        add     si,ax
        sub     si,6    ; go back 6
        mov     loco,si
        call    saypos
        pop     cx
        pop     bx
        ret
calco   endp

dcells  proc    ; show detail area
        push    es
        mov     ax,colbuff
        mov     es,ax
        mov     di,detail
        mov     si,loco
        mov     word ptr count,13
dclp1:
        mov     cx,13
dclp2:  lodsb
        call    blob
        inc     di
        inc     di
        loop    dclp2
        add     si,bwide - 13   ; next row
        add     di,4*80 - 26   ; next row
        dec     word ptr count
        jnz     dclp1
        pop     es
        ret
dcells  endp

blob    proc    ; draw blob at di  (8 by 8)
                ; if Al Z then bloboff
        push    cx
        push    si
        push    di
        mov     cx,4
        cmp     di,detail + 6*4*80 + 6*2        ; is it central one?
        jnz     blnorm
        mov     si,offset blobofx
        or      al,al
        jz      blblp
        mov     si,offset blobonx
        jmp     blblp
blnorm: mov     si,offset bloboff
        or      al,al
        jz      blblp
        mov     si,offset blobon
blblp:  lodsw
        stosw
        add     di,8*1024 - 2
        lodsw
        stosw
        sub     di,8*1024 + 2 - 80
        loop    blblp
        pop     di
        pop     si
        pop     cx
        ret
blob    endp

orient  proc    ; show orientation icon
        push    es
        mov     ax,colbuff
        mov     es,ax
        mov     di,borient
        mov     si,bortp
        mov     ax,bortv
        shl     ax,1    ; each
        shl     ax,1    ; entry
        shl     ax,1    ; is
        shl     ax,1    ; 16 bytes
        add     si,ax
        mov     cx,4
orlp:   lodsw
        stosw
        add     di,8*1024 - 2
        lodsw
        stosw
        sub     di,8*1024 + 2 - 80
        loop    orlp
        pop     es
        ret
orient  endp

setbgc  proc    ; set background color
        mov     ah,setcol
        mov     bh,bgid
        mov     bl,bgcolor
        int     video
        mov     updat,1
        ret
setbgc  endp

setpal  proc    ; set  palette
        mov     ah,setcol
        mov     bh,plid
        mov     bl,palette
        int     video
        mov     updat,1
        ret
setpal  endp

getkey  proc    ; get a keystroke
        mov     ah,0
        int     kbd
        ret
getkey  endp

dokey   proc    ; run the game
nxtkey:
        cmp     updat,0
        jz      nknd
        call    display
nknd:   cmp     sholoc,0
        jz      nosl
        call    dcells
nosl:
        cmp     step,0
        jz      tkget
        mov     ah,1
        int     kbd
        jnz     tkget
        jmp     tkgo
tkget:  call    wldot
        call    getkey
        call    rwldot
        mov     updat,0
        or      al,al   ; extended code?
        jnz     isspc
        jmp     dkext
isspc:  cmp     al,' '  ; space?
        jnz     palkey
        mov     si,loco
        add     si,bwide * 6 + 6
        xor     byte ptr [si],10h
        mov     di,offset rowtab
        add     di,locrow
        mov     byte ptr [di],1
        call    dline
        jmp     tkey
palkey: cmp     al,'+'  ; palette
        jnz     tbkey
        inc     palette
        call    setpal
        jmp     tgkey
tbkey:  cmp     al,ktab ; tab
        jnz     snkeys
        mov     bx,locrow
        mov     cx,loccol
        jmp     adcrr   ; is treated like control-right
snkeys: ; here we test for shift+cursor keys (appear in al as 1-9)
        cmp     ah,khome
        jl      b1key
        cmp     ah,kpgdn
        jg      b1key
        cmp     al,'8'  ; only up
        jz      scok
        cmp     al,'2'  ; down
        jz      scok
        cmp     al,'4'  ; left
        jz      scok
        cmp     al,'6'  ; and right
        jz      scok
        jmp     b1key
scok:   ; treat as a space ...
        push    ax
        mov     si,loco
        add     si,bwide * 6 + 6
        xor     byte ptr [si],10h
        mov     di,offset rowtab
        add     di,locrow
        mov     byte ptr [di],1
        call    dline
        pop     ax
        ; then a cursor key ...
        jmp     dkext
b1key:  cmp     al,'1'  ; box 1
        jnz     b2key
        cmp     curbox,2
        jz      b1do
        jmp     tkey
b1do:   mov     borta,offset bort1a
        mov     bortb,offset bort1b
        mov     vbuffp,offset vbuff1
        mov     ax,bxw  ; save old
        mov     bxw2,ax
        mov     ax,bxd
        mov     bxd2,ax
        mov     ax,bortp
        mov     bortp2,ax
        mov     ax,bortv
        mov     bortv2,ax
        mov     ax,bxw1 ; set new
        mov     bxw,ax
        mov     ax,bxd1
        mov     bxd,ax
        mov     ax,bortp1
        mov     bortp,ax
        mov     ax,bortv1
        mov     bortv,ax
        call    saybox
        mov     curbox,1
        jmp     tkey
b2key:  cmp     al,'2'  ; box 2
        jnz     qukey
        cmp     curbox,1
        jz      b2do
        jmp     tkey
b2do:   mov     borta,offset bort2a
        mov     bortb,offset bort2b
        mov     vbuffp,offset vbuff2
        mov     ax,bxw  ; save old
        mov     bxw1,ax
        mov     ax,bxd
        mov     bxd1,ax
        mov     ax,bortp
        mov     bortp1,ax
        mov     ax,bortv
        mov     bortv1,ax
        mov     ax,bxw2 ; set new
        mov     bxw,ax
        mov     ax,bxd2
        mov     bxd,ax
        mov     ax,bortv2
        mov     bortv,ax
        mov     ax,bortp2
        mov     bortp,ax
        call    saybox
        mov     curbox,2
        jmp     tkey
qukey:  and     al,0dfh
        cmp     al,'Q'
        jnz     adjey
        ; all done
        ret
adjey:  cmp     al,'A'  ; adjust
        jnz     bakey
        call    recent
        jmp     tgkey
bakey:  cmp     al,'B'  ; background
        jnz     fokey
        inc     bgcolor
        call    setbgc
        jmp     tgkey
fokey:  cmp     al,'F'  ; foreground
        jnz     zekey
        inc     fgcolor
        and     byte ptr fgcolor,3
        mov     al,fgcolor
        mov     fgcol4,al
        shl     al,1
        shl     al,1
        mov     fgcol3,al
        shl     al,1
        shl     al,1
        mov     fgcol2,al
        shl     al,1
        shl     al,1
        mov     fgcol1,al
        mov     updat,1
        jmp     tgkey
zekey:  cmp     al,'Z'  ; zero (clear/restart)
        jnz     makey
        call    clear
        jmp     tkey
makey:  cmp     al,'M'  ; manipulate
        jnz     sakey
        call    manip
        jmp     tkey
sakey:  cmp     al,'S'  ; save
        jnz     lokey
        call    save
        jmp     tkey
lokey:  cmp     al,'L'  ; load
        jnz     dekey
        call    load
        jmp     tkey
dekey:  cmp     al,'D'  ; toggle local switch
        jnz     gokey
        xor     byte ptr sholoc,0ffh
        jmp     tgkey
gokey:  cmp     al,'G'  ; run
        jnz     brkey
        mov     step,1
        mov     ax,gener
        cmp     ax,limit
        jnz     tgkey
        mov     limit,-1
        call    saylim
        jmp     tkgo
brkey:  cmp     al,'K'  ; set breakpoint
        jnz     tikey
        call    getlim
        jmp     tgkey
tikey:  cmp     al,'T'  ; tick
        jnz     cukey
        jmp     tlcy
cukey:  cmp     al,'C'  ; cut
        jnz     pakey
        call    cut
        jmp     tkey
pakey:  cmp     al,'P'  ; paste
        jnz     tkey
        call    paste
        jmp     tkey
tkgo:   mov     ax,gener
        cmp     ax,limit
        jz      tlbp
        call    cycle   ; cycle a generation
        call    qikgen
        jmp     nxtkey
tlbp:   call    beep
        mov     step,0
        jmp     nxtkey
tlcy:   call    cycle   ; cycle a generation
        call    qikgen
tkey:   mov     step,0
tgkey:  jmp     nxtkey

dkext:  cmp     ah,kf1
        jnz     dcurs
        call    help
        jmp     nxtkey
dcurs:  mov     bx,locrow
        mov     cx,loccol
        cmp     ah,kup
        jnz     adkd
adku1:
        dec     bx
        jmp     adlp
adkd:   cmp     ah,kdown
        jnz     adkl
adkd1:
        inc     bx
        jmp     adlp
adkl:   cmp     ah,kleft
        jnz     adkr
adkl1:
        dec     cx
        jmp     adlp
adkr:   cmp     ah,kright
        jnz     adpd
adkr1:
        inc     cx
        jmp     adlp
adpd:   cmp     ah,kpgdn
        jnz     adpu
        add     bx,10
        jmp     adlp
adpu:   cmp     ah,kpgup
        jnz     adhm
        sub     bx,10
        jmp     adlp
adhm:   cmp     ah,khome
        jnz     adbt
        xor     cx,cx
        jmp     adlp
adbt:   cmp     ah,kbtab
        jz      adcll
adcl:   cmp     ah,kcleft
        jnz     adcr
adcll:  sub     cx,10
        jmp     adlp
adcr:   cmp     ah,kcright
        jnz     aden
adcrr:  add     cx,10
        jmp     adlp
aden:   cmp     ah,kend
        jnz     adlp
        mov     cx,bwide - 1
        jmp     adlp
adlp:   cmp     bx,0
        jge     adb1
        xor     bx,bx
adb1:   cmp     cx,0
        jge     adc1
        xor     cx,cx
adc1:   cmp     bx,bdeep
        jl      adb2
        mov     bx,bdeep-1
adb2:   cmp     cx,bwide
        jl      adc2
        mov     cx,bwide-1
adc2:   mov     locrow,bx
        mov     loccol,cx
        call    calco
        jmp     tgkey
dokey   endp

recent  proc    ; recenter the board
        mov     di,offset worka
        mov     al,0
        mov     cx,bwide
    rep stosb                   ; clear work area
        mov     ax,locrow
        cmp     ax,bdeep/2
        jl      rectop
        jg      recbot
        mov     ax,loccol
        sub     ax,bwide/2
        jz      recex
        mov     cx,bdeep
        mov     bp,offset rowtab
        mov     si,offset board
        mov     di,offset board
rce1:   call    movit
        mov     byte ptr [bp],1
        inc     bp
        add     si,bwide        ; advance to next line
        add     di,bwide
        loop    rce1
        mov     updat,1
recex:  ret
rectop: sub     ax,bdeep/2
        neg     ax
        mov     si,offset board + bwide*bdeep - bwide
        mov     di,si
        mov     cx,ax
        mov     bx,bwide
rct1:   sub     si,bx
        loop    rct1    ; si points at new bottom line
        mov     cx,bdeep
        sub     cx,ax
        mov     bp,offset rowtab + bdeep - 1
        push    ax
        mov     ax,loccol
        sub     ax,bwide/2
rct2:   call    movit
        mov     byte ptr [bp],1
        dec     bp
        sub     si,bwide        ; reverse to previous line
        sub     di,bwide
        loop    rct2
        pop     ax
        mov     cx,ax
rct3:   call    zeroit
        mov     byte ptr [bp],1
        dec     bp
        sub     di,bwide
        loop    rct3
        mov     updat,1
        ret

recbot: sub     ax,bdeep/2
        mov     si,offset board
        mov     cx,ax
        mov     bx,bwide
rcb1:   add     si,bx
        loop    rcb1    ; si points at new top line
        mov     cx,bdeep
        sub     cx,ax
        mov     bp,offset rowtab
        mov     di,offset board
        push    ax
        mov     ax,loccol
        sub     ax,bwide/2
rcb2:   call    movit
        mov     byte ptr [bp],1
        inc     bp
        add     si,bwide        ; advance to next line
        add     di,bwide
        loop    rcb2
        pop     ax
        mov     cx,ax
rcb3:   call    zeroit
        mov     byte ptr [bp],1
        inc     bp
        add     di,bwide
        loop    rcb3
        mov     updat,1
        ret
recent  endp

zeroit  proc    ; clear line at di
        push    cx
        push    ax
        push    di
        mov     cx,bwide
        mov     al,0
    rep stosb
        pop     di
        pop     ax
        pop     cx
        ret
zeroit  endp

movit   proc    ; move line at si to workarea, adjust, and move back to di
        push    cx
        push    ax
        push    si
        push    di
        mov     bx,di
        mov     di,offset worka
        cmp     ax,0
        jl      mvback
        add     si,ax
mvmv:   mov     cx,bwide
        sub     cx,ax
    rep movsb                   ; move part in
        mov     si,offset worka
        mov     di,bx
        mov     cx,bwide
    rep movsb                   ; move work back
        pop     di
        pop     si
        pop     ax
        pop     cx
        ret
mvback: neg     ax
        add     di,ax
        jmp     mvmv
movit   endp

getfn   proc    ; get filename
        mov     si,offset filmsg
        call    gmsg
        mov     di,offset filnm
        call    getstr
        ret
getfn   endp

getlim  proc    ; get limit
glredo: mov     si,offset lsmsg
        call    gmsg
        mov     di,offset limstr
        call    getstr
        jnc     glcalc
        xor     bx,bx
glsay:  cmp     bx,0
        jnz     glset
        dec     bx
glset:  mov     limit,bx
        call    saylim
        ret
glcalc:
        xor     ax,ax
        mov     bx,ax
        mov     cx,ax
        mov     dx,ax
        mov     si,offset limstr
glclp:  lodsb
        or      al,al
        jz      glsay
        mov     cl,al
        cmp     cl,'0'
        jb      glredo
        cmp     cl,'9'
        jg      glredo
        and     cl,0fh
        mov     ax,bx
        mul     ten
        add     ax,cx
        mov     bx,ax
        jmp     glclp
getlim  endp

getstr  proc    ; get a string
        mov     dh,4
        mov     dl,0
        mov     ah,setcur
        int     video
gslp:   call    getkey
        or      al,al
        jnz     gsne
        cmp     ah,kdel         ; delete?
        jz      gsbs
        jmp     gslp
gsne:   cmp     al,kesc         ; cancel?
        jz      gsex
        cmp     al,kcr          ; end of name?
        jz      gsend
        cmp     al,kbsp         ; backspace?
        jnz     gsok
gsbs:   or      dl,dl
        jz      gslp
        dec     di
        dec     dl
        xor     bx,bx
        mov     ah,setcur
        int     video
        mov     al,' '
        mov     ah,wchat
        mov     bx,wand
        mov     cx,1
        int     video
        jmp     gslp
gsok:   cmp     dl,bwide/8
        jl      gsst
        dec     di
        dec     dl
gsst:   stosb                   ; save character
        mov     ah,wchat        ; show character
        mov     bx,wand
        mov     cx,1
        int     video
        mov     dh,4
        inc     dl
        xor     bx,bx
        mov     ah,setcur
        int     video
        jmp     gslp
gsend:  mov     al,0
        stosb
        call    restore
        clc
        ret
gsex:   call    restore
        stc
        ret
getstr  endp

save    proc    ; save box in file
        call    getfn
        jc      saex
        call    create
        jc      sabad
        call    write
        call    close
        mov     si,offset oksmsg
        jmp     saeb
sabad:  call    beep
        mov     si,offset wremsg
saeb:   call    pmsg
        call    restore
saex:   ret
save    endp

load    proc    ; load box from file
        call    getfn
        jc      loex
loadp  proc
		call    open
        jc      lobad
        call    read
        call    close
        mov     ax,borta
        mov     bortp,ax
        mov     word ptr bortv,0
        mov     si,vbuffp
        mov     buffp,si
        inc     buffp
        call    saybox
        mov     si,offset oklmsg
        jmp     loeb
lobad:  call    beep
        mov     si,offset rdemsg
loeb:   call    pmsg
        call    restore
loex proc
   ret
   loex endp
loadp endp
load    endp

gmsg    proc    ; say get type msg
        mov     dh,3
        mov     dl,0
        call    dmsg
        ret
gmsg    endp

pmsg    proc    ; display msg and "press any key"
        call    gmsg
        inc     dh
        mov     si,offset prmsg
        call    dmsg
        call    getkey
        ret
pmsg    endp

open    proc    ; open file
        mov     dx,offset filnm
        mov     ah,openfn
        mov     al,0    ; read only
        int     dos
        jc      openx
        mov     fhand,ax
openx:  ret
open    endp

create  proc    ; create file
        mov     dx,offset filnm
        mov     ah,creafn
        xor     cx,cx           ; standard attributes
        int     dos
        jc      creax
        mov     fhand,ax
        clc
creax:  ret
create  endp

close   proc    ; close fhand
        mov     bx,fhand
        cmp     bx,5            ; is it a standard one?
        jc      clsex           ; yes, then avoid it
        mov     ah,closfn
        int     dos
clsex:  ret
close   endp

read    proc    ; read in the buffer
        mov     dx,offset bxw
        mov     cx,4
        mov     bx,fhand
        mov     ah,readfn
        int     dos
        dec     bxw
        dec     bxd
        mov     ax,bxw
        mov     bx,bxd
        cmp     ax,0
        jl      rdbad
        cmp     bx,0
        jl      rdbad
        cmp     ax,bwide
        jge     rdbad
        cmp     bx,bwide
        jge     rdbad
        inc     ax
        inc     bx
        mul     bx
        mov     dx,vbuffp
        mov     cx,ax
        mov     bx,fhand
        mov     ah,readfn
        int     dos
        ret
rdbad:  call    clrbox
        ret
read    endp

clrbox  proc    ; reset box to empty state
        mov     bxd,0
        mov     bxw,0
        mov     ax,borta
        mov     bortp,ax
        mov     word ptr bortv,0
        mov     si,vbuffp
        mov     buffp,si
        inc     buffp
        call    saybox
        ret
clrbox  endp

write   proc    ; write out the buffer
        ; first the size
        inc     bxw
        inc     bxd
        mov     dx,offset bxw
        mov     cx,4
        mov     bx,fhand
        mov     ah,writfn
        int     dos
        dec     bxw
        dec     bxd
        ; then the data
        mov     dx,vbuffp
        mov     cx,buffp
        sub     cx,dx
        inc     cx
        mov     bx,fhand
        mov     ah,writfn
        int     dos
        cmp     ax,cx   ; all bytes written? (carry set if not)
        ret
write   endp

dobox   proc    ; get user to fix a box
        mov     si,offset bxmsg
        call    dmsgs
        mov     bx,locrow
        mov     bxr1,bx
        mov     bxr2,bx
        mov     cx,loccol
        mov     bxc1,cx
        mov     bxc2,cx
dbgk:   cmp     bx,bdeep
        jl      dbb
        mov     bx,bdeep-1
dbb:    cmp     bx,0
        jge     dbc
        xor     bx,bx
dbc:    cmp     cx,bwide
        jl      dbc1
        mov     cx,bwide-1
dbc1:   cmp     cx,0
        jge     dbc2
        xor     cx,cx
dbc2:   mov     bxr2,bx
        mov     bxc2,cx
        call    box     ; display box
        call    saybox
        call    getkey
        call    box     ; remove box
        cmp     al,kesc ; Esc
        jnz     dbne
        jmp     dbesc
dbne:   cmp     al,kcr
        jnz     dbsl
        mov     si,offset hello
        call    dmsgs
        clc
        ret
dbsl:   cmp     al,'/'
        jnz     dbtb
        xchg    bxr1,bx
        xchg    bxc1,cx
        jmp     dbgk
dbtb:   cmp     al,ktab
        jnz     dbek
        jmp     dbcrr
dbek:   or      al,al
        jnz     dbgk
        cmp     ah,kdel
        jnz     dbndl
        call    delbox
        jmp     dbesc
dbndl:  cmp     ah,kup
        jnz     dbnu
        dec     bx
        jmp     dbgk
dbnu:   cmp     ah,kdown
        jnz     dbnd
        inc     bx
        jmp     dbgk
dbnd:   cmp     ah,kleft
        jnz     dbnl
        dec     cx
        jmp     dbgk
dbnl:   cmp     ah,kright
        jnz     dbbt
        inc     cx
        jmp     dbgk
dbbt:   cmp     ah,kbtab
        jz      dbcll
dbcl:   cmp     ah,kcleft
        jnz     dbcr
dbcll:  sub     cx,10
        jmp     dbgk
dbcr:   cmp     ah,kcright
        jnz     dbpu
dbcrr:  add     cx,10
        jmp     dbgk
dbpu:   cmp     ah,kpgup
        jnz     dbpd
        sub     bx,10
        jmp     dbgk
dbpd:   cmp     ah,kpgdn
        jnz     dbhome
        add     bx,10
        jmp     dbgk
dbhome: cmp     ah,khome
        jnz     dbend
        xor     cx,cx
        jmp     dbgk
dbend:  cmp     ah,kend
        jnz     dbbad
        mov     cx,bwide
        jmp     dbgk
dbbad:  jmp     dbgk
dbesc:  mov     si,offset hello
        call    dmsgs
        call    clrbox
        stc
        ret
dobox   endp

delbox  proc    ; clear current box area
        ; first set things up
        call    ratbox
        mov     bcount,8
        mov     work,0
        mov     di,offset board
        mov     cx,bwide
        mov     al,0
        mov     si,offset rowtab
        add     si,bxr1
dllp:   add     di,word ptr bxr1
        loop    dllp
        add     di,word ptr bxc1
        mov     dx,bxd
        inc     dx
dllp2:  mov     cx,bxw
        inc     cx      ; has width
        push    di
dllp1:  stosb
        loop    dllp1
        pop     di
        mov     byte ptr [si],1         ; indicate line has changed
        inc     si
        add     di,bwide
        dec     dx
        jnz     dllp2
        mov     updat,1
        ret
delbox  endp

saymsg  proc    ; display message using standard error output
        push    es
        push    ds
        pop     es
        mov     al,0    ; find length by
        mov     di,dx   ; searching string for 0
        mov     cx,-1   ; max length
  repne scasb
        sub     di,dx   ; di points to char afer 0
        dec     di
        mov     cx,di   ; length of message
        mov     bx,errhand
        mov     ah,writfn
        int     dos
        pop     es
        ret
saymsg  endp

saygen  proc    ; display generation number
        mov     si,offset genval
        mov     ax,gener
        call    ax2dec5
        mov     si,offset genmsg
        mov     dh,genrow
        mov     dl,gencol
        call    dmsg
        ret
saygen  endp

qikgen  proc    ; quick increment and display of generation number
        mov     si,offset genmsg + gvlen ; least sig dig
        mov     dx,gencol + gvlen
qglp:   cmp     byte ptr [si],'9'
        jnz     qgdg
        mov     byte ptr [si],'0'
        dec     si
        dec     dx
        jmp     qglp
qgdg:   cmp     byte ptr [si],' '
        jnz     qgid
        mov     byte ptr [si],'0'
qgid:   inc     byte ptr [si]
        mov     dh,genrow
        call    dmsg
        ret
qikgen  endp

saylim  proc    ; display stop limit
        mov     ax,limit
        cmp     ax,-1
        jnz     slok
        mov     si,offset nolim
        mov     di,offset limval
        mov     cx,5
    rep movsb
        jmp     slsay
slok:   mov     si,offset limval
        call    ax2dec5
slsay:  mov     si,offset limmsg
        mov     dh,limrow
        mov     dl,limcol
        call    dmsg
        ret
saylim  endp

saypos  proc    ; display current position
        mov     si,offset xpos
        mov     ax,loccol
        call    ax2dec
        mov     si,offset ypos
        mov     ax,locrow
        call    ax2dec
        mov     si,offset posmsg
        mov     dh,posrow
        mov     dl,poscol
        call    dmsg
        ret
saypos  endp

saybox  proc    ; display box size
        push    bx
        push    cx
        mov     si,offset xbuf
        mov     ax,bxw
        inc     ax
        call    ax2dec
        mov     si,offset ybuf
        mov     ax,bxd
        inc     ax
        call    ax2dec
        mov     si,offset bufmsg
        mov     dh,bufrow
        mov     dl,bufcol
        call    dmsg
        call    orient
        pop     cx
        pop     bx
        ret
saybox  endp

dmsgs   proc
        mov     dh,dmrow
        mov     dl,dmcol
dmslp:  call    dmsg
        inc     dh
        cmp     byte ptr [si],0
        jnz     dmslp
        ret
dmsgs   endp

dmsg    proc    ; display msg [si] at dh,dl
        push    dx
        push    cx
dmlp:   xor     bx,bx
        mov     ah,setcur
        int     video
        lodsb
        or      al,al
        jz      dmex
        push    ax
        mov     ah,wchat
        mov     bx,wand
        mov     cx,1
        int     video
        inc     dl
        pop     ax
        jmp     dmlp
dmex:   pop     cx
        pop     dx
        ret
dmsg    endp

wldot   proc    ; read/write dot at locrow/loccol
        push    ax
        mov     ah,rdot
        mov     dx,locrow
        mov     cx,loccol
        int     video
        mov     olddot,al
        mov     ah,wdot
        mov     dx,locrow
        mov     cx,loccol
        mov     oldrow,dx
        mov     oldcol,cx
        mov     al,newdot
        int     video
        pop     ax
        ret
wldot   endp

rwldot  proc    ; rewrite dot at locrow/loccol
        push    ax
        mov     ah,wdot
        mov     dx,oldrow
        mov     cx,oldcol
        mov     al,olddot
        int     video
        pop     ax
        ret
rwldot  endp

help    proc    ; display help lines
        mov     si,offset helpmsg
        mov     dh,1
        mov     dl,1
hllp:   call    dmsg
        inc     dh
        cmp     byte ptr [si],0
        jnz     hllp
        call    getkey
        call    restore
        ret
help    endp

restore proc    ; restore universe to screen (after display of messages)
        mov     updat,1
        mov     al,1
        mov     di,offset rowtab - 1
        mov     cx,bdeep + 1
    rep stosb
        ret
restore endp

cut     proc    ; cut a rectangular area
        call    dobox
        jnc     cuok
        ret
cuok:   ; first set things up
        call    ratbox
        mov     si,vbuffp
        mov     buffp,si
        mov     bcount,8
        mov     work,0

        mov     bx,offset board
        mov     cx,bwide
culp:   add     bx,word ptr bxr1
        loop    culp
        add     bx,word ptr bxc1

        mov     dx,bxd
        inc     dx
cutlp2: mov     cx,bxw
        inc     cx      ; has width
        push    bx
cutlp1: mov     ah,[bx]
        inc     bx
        call    putbyte
        loop    cutlp1
        pop     bx
        add     bx,bwide
        dec     dx
        jnz     cutlp2
        call    flush
        ret
cut     endp

paste   proc    ; paste a rectangular area
        ; first set things up
        mov     bcount,8
        mov     si,vbuffp
        lodsb
        mov     buffp,si
        mov     work,al
        mov     di,offset rowtab
        add     di,locrow
        mov     bx,loco
        add     bx,bwide * 6 + 6
        mov     dx,bxd
        inc     dx
        mov     bp,bwide
        sub     bp,loccol       ; space left in this row
paslp2: mov     cx,bxw
        inc     cx      ; has width
        push    bx
        push    bp
paslp:
        call    getbyte
        or      bp,bp
        jz      pasno1
        mov     [bx],ah
        dec     bp
        inc     bx
pasno1: loop    paslp
        pop     bp
        pop     bx
        mov     byte ptr [di],1         ; indicate line has changed
        cmp     di,offset erowtab
        jz      pasno2                  ; don't go outside board
        inc     di
        add     bx,bwide
pasno2: dec     dx
        jnz     paslp2
        mov     updat,1
        ret
paste   endp

clrbuf  proc    ; clear temporary buffer
        mov     al,0
        mov     cx,bdeep*bwide/8
        mov     di,offset vbuffx
    rep stosb           ; clear temp buffer
        ret
clrbuf  endp

manip   proc    ; rotate/reflect buffer in various ways
        mov     si,offset rrmsg
        call    dmsgs
mngk:   call    saybox
        call    clrbuf
        call    getkey
        or      al,al
        jz      mnek
        cmp     al,kesc
        jz      mnex
        jmp     mnbad
mnex:
        mov     si,offset hello
        call    dmsgs
        ret
mnek:   cmp     ah,kpgdn
        jnz     mnpu
        call    rotate
        jmp     mngk
mnpu:   cmp     ah,kpgup
        jnz     mncr
        call    rotate  ; rotate anticlockwise
        call    clrbuf
        call    rotate  ; by 3 clockwise ones
        call    clrbuf
        call    rotate
        jmp     mngk
mncr:   cmp     ah,kright
        jz      mnrv
        cmp     ah,kleft
        jnz     mncu
mnrv:   call    reflver ; vertical reflect
        jmp     mngk
mncu:   cmp     ah,kup
        jz      mnrh
        cmp     ah,kdown
        jnz     mnbad
mnrh:   call    reflhor ; horizontal reflect
        jmp     mngk
mnbad:  call    beep
        jmp     mngk
manip   endp

reflhor proc    ; horizontal reflection U/D
        xor     cx,cx   ; cx is row counter
        mov     ax,cx   ; set up getbit counter
rholp:  cmp     cx,bxd
        jg      rhex    ; all done
        xor     dx,dx   ; dx is col counter
        push    cx
        mov     bx,bxd
        sub     bx,cx
        mov     cx,bx
        xor     bx,bx
        jcxz    rhxe
rhxlp:  add     bx,bxw
        inc     bx
        loop    rhxlp
rhxe:   pop     cx      ; bx has base putbit value for inner loop
rhilp:  cmp     dx,bxw
        jg      rheilp
        call    getbit  ; Z set to indicate
        call    putbit
        inc     ax      ; increment getbit counter
        inc     bx      ; increment putbit counter
        inc     dx      ; increment col counter
        jmp     rhilp
rheilp: inc     cx      ; increment row counter
        jmp     rholp
rhex:   call    boxsize
        mov     cx,ax
        mov     si,offset vbuffx
        mov     di,vbuffp
    rep movsb           ; move stuff back into main buffer
        ; update orientation icon
        mov     ax,borta
        mov     bx,bortb
        cmp     bortp,ax
        jz      rho
        xchg    ax,bx
rho:    mov     bortp,bx
        mov     ax,bortv
        add     ax,2
        and     ax,3
        mov     bortv,ax
        ret
reflhor endp

reflver proc    ; vertical reflection   L/R
        xor     cx,cx   ; cx is row counter
        mov     ax,cx   ; set up getbit counter
        mov     bx,bxw  ; set up putbit counter
rvolp:  cmp     cx,bxd
        jg      rvex    ; all done
        xor     dx,dx   ; dx is col counter
rvilp:  cmp     dx,bxw
        jg      rveilp
        call    getbit  ; Z set to indicate
        call    putbit
        inc     ax      ; increment getbit counter
        dec     bx      ; decrement putbit counter
        inc     dx      ; increment col counter
        jmp     rvilp
rveilp: inc     cx      ; increment row counter
        add     bx,bxw
        add     bx,bxw
        inc     bx
        inc     bx
        jmp     rvolp

rvex:   call    boxsize
        mov     cx,ax
        mov     si,offset vbuffx
        mov     di,vbuffp
    rep movsb           ; move stuff back into main buffer
        ; update orientation icon
        mov     ax,borta
        mov     bx,bortb
        cmp     bortp,ax
        jz      rvo
        xchg    ax,bx
rvo:    mov     bortp,bx
        ret
reflver endp

rotate  proc    ; rotate buffer 90 degrees clockwise
        xor     cx,cx   ; cx is row counter
        mov     ax,cx   ; set up getbit counter
rtolp:  cmp     cx,bxd
        jg      rtex    ; all done
        mov     bx,bxd
        sub     bx,cx   ; bx has base putbit value for inner loop
        xor     dx,dx   ; dx is col counter
rtilp:  cmp     dx,bxw
        jg      rteilp
        call    getbit  ; Z set to indicate
        call    putbit
        inc     ax      ; increment getbit counter
        add     bx,bxd
        inc     bx      ; increment putbit counter
        inc     dx      ; increment col counter
        jmp     rtilp
rteilp: inc     cx      ; increment row counter
        jmp     rtolp
rtex:
        mov     ax,bxd  ; swap bxd and bxw
        mov     bx,bxw
        mov     bxw,ax
        mov     bxd,bx
        call    boxsize
        mov     cx,ax
        mov     si,offset vbuffx
        mov     di,vbuffp
    rep movsb           ; move stuff back into main buffer
        ; update orientation icon
        mov     ax,bortv
        mov     bx,1
        mov     dx,borta
        cmp     bortp,dx
        jz      rtt1
        mov     bx,-1
rtt1:   add     ax,bx
        and     ax,3
        mov     bortv,ax
        ret
rotate  endp

boxsize proc    ; return box size (in bytes = 8 pels)
        mov     ax,bxd
        mov     bx,bxw
        inc     ax
        inc     bx
        mul     bx
        add     ax,7
        shr     ax,1    ; divide by 2
        shr     ax,1    ; by 4
        shr     ax,1    ; by 8
        ret
boxsize endp

getbit  proc    ; get bit ax from vbuffn
        push    ax
        push    cx
        mov     cx,ax
        mov     ch,80h  ; create mask
        and     cl,7    ; cl has bit we want
        jz      gbns
        shr     ch,cl
gbns:   shr     ax,1
        shr     ax,1
        shr     ax,1    ; ax has byte we want
        mov     si,vbuffp
        add     si,ax
        mov     al,[si]
        and     al,ch
        pop     cx
        pop     ax
        ret
getbit  endp

putbit  proc    ; put bit bx into vbuffn
        push    ax
        push    bx
        push    cx
        mov     ch,0    ; create a bit mask
        jz      pbz
        mov     ch,80h
pbz:
        mov     cl,bl
        and     cl,7    ; cl has bit we want
        jz      pbns
        shr     ch,cl
pbns:   shr     bx,1
        shr     bx,1
        shr     bx,1    ; bx has byte we want

        mov     di,offset vbuffx
        add     di,bx
        mov     al,[di]
        or      al,ch
        mov     [di],al
        pop     cx
        pop     bx
        pop     ax
        ret
putbit  endp

getbyte proc    ; get next byte from buffer into AH
        mov     ah,0
        mov     al,work
        shl     al,1
        jnc     gbcn
        mov     ah,10h
gbcn:   dec     bcount
        jnz     gbex
        mov     si,buffp
        lodsb
        mov     buffp,si
        mov     bcount,8
gbex:   mov     work,al
        ret
getbyte endp

putbyte proc    ; put byte AH into buffer
        shr     ah,1
        shr     ah,1
        shr     ah,1
        shr     ah,1
        mov     al,work
        or      al,ah
        dec     bcount
        jz      pbcy
        shl     al,1
        mov     work,al
        ret
pbcy:   mov     bcount,8
        mov     di,buffp
        stosb
        mov     buffp,di
        ret
putbyte endp

flush   proc    ; flush remaining bits in work into buffer
        mov     cl,bcount
        dec     cl
        mov     al,work
        shl     al,cl
        mov     di,buffp
        stosb
        ret
flush   endp

ratbox  proc    ; rationalise box so r1 <= r2 and c1 <= c2
        mov     ax,bxr1
        mov     bx,bxr2
        cmp     ax,bx
        jle     rb1
        xchg    ax,bx
        mov     bxr1,ax
        mov     bxr2,bx
rb1:    sub     bx,ax
        mov     bxd,bx
        mov     ax,bxc1
        mov     bx,bxc2
        cmp     ax,bx
        jle     rb2
        xchg    ax,bx
        mov     bxc1,ax
        mov     bxc2,bx
rb2:    sub     bx,ax
        mov     bxw,bx
        ret
ratbox  endp

box     proc    ; draw box r1,c1,r2,c2
        push    ax
        push    bx
        push    cx
        push    dx
        mov     ax,bxc1
        mov     cx,bxc2
        cmp     ax,cx
        jge     bx1
        xchg    ax,cx
bx1:    ; cx has smaller column
        sub     ax,cx           ; ax has positive width
        mov     bxw,ax
        mov     ax,bxr1
        mov     dx,bxr2
        cmp     ax,dx
        jge     bx2
        xchg    ax,dx
bx2:    ; dx has smaller row
        sub     ax,dx           ; ax has positive depth
        mov     bxd,ax
        mov     bx,bxw          ; width
        inc     bx
        dec     cx
blp1:   inc     cx
        mov     ah,wdot         ; draw horizontal bits
        mov     al,boxdot
        int     video
        cmp     bxd,0           ; ignore 2nd line if over first
        je      bnh2
        add     dx,bxd          ; depth
        mov     ah,wdot
        int     video
        sub     dx,bxd
bnh2:   dec     bx
        jnz     blp1

        mov     bx,bxd
        cmp     bx,2
        jl      bxex            ; ignore if not at least one gap
        dec     bx
blp2:
        inc     dx
        mov     ah,wdot         ; draw vertical bits
        int     video
        cmp     bxw,0           ; ignore 2nd line if over first
        je      bnv2
        sub     cx,bxw
        mov     ah,wdot
        int     video
        add     cx,bxw
bnv2:   dec     bx
        jnz     blp2
bxex:   pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
box     endp

beep    proc    ; sound a beep
        mov     ah,14
        mov     al,7
        int     video
        ret
beep    endp

; numeric subroutines

ax2dec  proc    ; convert ax to decimal (3 digits) at si
        push    di
        push    si
        mov     b2dhi,0
        mov     b2dlo,ax
        mov     prec,3
        mov     di,si
        mov     si,offset b2dlo
        call    b2d
        call    rl0x
        pop     si
        pop     di
        ret
ax2dec  endp

ax2dec5 proc    ; convert ax to decimal (5 digits) at si
        push    di
        push    si
        mov     b2dhi,0
        mov     b2dlo,ax
        mov     prec,5
        mov     di,si
        mov     si,offset b2dlo
        call    b2d
        call    rl0x
        pop     si
        pop     di
        ret
ax2dec5 endp

b2d     proc    ; convert binary at si to decimal at di
        push    dx
        push    cx
        push    ax
        push    si
        push    di
        cmp     si,offset b2dlo
        jz      b2dok
        mov     dx,[si]
        mov     b2dlo,dx
        mov     dx,[si + 2]
        mov     b2dhi,dx
b2dok:  ; adjust table start for desired precision
        mov     si,offset dectab + 32   ; 4 bytes per entry
        mov     cx,prec
        add     cx,cx
        add     cx,cx
        sub     si,cx
        xor     cx,cx
b2dlp:  mov     dx,b2dhi        ; current digit in CL -  index in ch
        mov     ax,b2dlo
        or      ax,ax   ; clear flags
        sub     ax,[si]
        sbb     dx,2[si]
        jl      b2dd
        inc     cl
        mov     b2dhi,dx
        mov     b2dlo,ax
        jmp     b2dlp
b2dd:   or      cl,30h  ; turn to ascii
        mov     byte ptr [di],cl
        inc     di
        xor     cl,cl
        inc     ch
        add     si,4
        cmp     ch,byte ptr prec
        jne     b2dlp
        pop     di
        pop     si
        pop     ax
        pop     cx
        pop     dx
        ret
b2d     endp

rl0     proc    ; remove up to 7 leading zeros from decimal no at di
        mov     prec,8
        call    rl0x
        ret
rl0     endp

rl0x    proc    ; remove leading zeros from decimal no at di
        push    di
        push    ax
        mov     al,byte ptr prec ; no of digits
        dec     al
xl0lp:  cmp     byte ptr [di],'0'
        jnz     xrl0
        mov     byte ptr [di],' '
        inc     di
        dec     al
        jnz     xl0lp
xrl0:   pop     ax
        pop     di
        ret
rl0x    endp
start endp

worka   equ     $       ; work area for re-centering
vbuffx  equ     worka + bwide ; temporary buffer used for rotates/reflects etc
vbuff1  equ     vbuffx + bdeep*bwide/8 + 1      ; primary buffer
vbuff2  equ     vbuff1 + bdeep*bwide/8 + 1      ; secondary buffer
rowtab  equ     vbuff2 + bdeep*bwide/8 + 1      ; interesting row table
erowtab equ     rowtab + bdeep + 1
empty1  equ     erowtab + 1                     ; dead stuff
board   equ     empty1 + 7*bwide                ; the universe
eboard  equ     board + bwide*bdeep - 1         ; more dead stuff
empty2  equ     eboard + 1
ebrd    equ     empty2 + 7*bwide
filnm   equ     ebrd + 1                        ; buffer for file name
limstr  equ     filnm + 50
stk     equ     limstr + 300    ; 50 for limit string - 250 for stack
elife   equ     stk + 3
life    ends
        ;end     start
		;start endp
		end