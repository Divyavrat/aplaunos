;Program TICTAC.ASM: Play Tic Tac Toe with the computer.
;
      ;.MODEL SMALL
      ;.DATA
       
       ;.CODE
       ;.STARTUP
org 0x6000

       mov   DX,GMSG  ;set up pointer to greeting
       MOV   AH,9     ;display string function
       INT   21H
       CALL  SHOWBRD  ;display board
NEXT:  
CALL  PMOVE    ;get player move
       CALL  SHOWBRD  ;display board
       CALL  CHECK    ;did player win or tie?
       JZ    EXIT
       CALL  CoMOVE    ;let computer move
       CALL  SHOWBRD  ;display board
       CALL  CHECK    ;did computer win or tie?
       JZ    EXIT
       JMP   NEXT     ;continue with game
	   ;ret
EXIT:ret
;  .EXIT

SHOWBRD:
; PROC  NEAR
        MOV   CX,9             ;set up loop counter
        SUB   SI,SI            ;set up index pointer
LBC:
mov bx,BPOS
add bx,si
    MOV   AL,[bx]      ;get a board position
        CBW                    ;convert to word
        MOV   DI,AX            ;set up pointer to board string
        ;MOV   AL,BOARD+SI     ;get player symbol
mov bx,BOARD
add bx,si
MOV   AL,[bx]
        ;MOV   BTXT+DI,AL      ;write into board string
mov bx,BTXT
add bx,di
MOV   [bx],AL
        INC   SI               ;advance index pointer
        LOOP  LBC              ;repeat for all nine positions
        mov   DX,BTXT          ;set up pointer to board string
        MOV   AH,9             ;display string function
        INT   21H              ;DOS call
        RET
;SHOWBRD ENDP

PMOVE:
;  PROC NEAR
       mov  DX,PMSG         ;set up pointer to player string
       MOV  AH,9            ;display string function
       INT  21H             ;DOS call
       MOV  AH,1            ;read keyboard function
       INT  21H             ;DOS call
       CMP  AL,'1'          ;insure user input is a digit
       JC   BPM
       CMP  AL,'9'+1
       JNC  BPM
       SUB  AL,31H          ;remove ASCII bias
       CBW                  ;convert to word
       MOV  SI,AX           ;set up index pointer
       ;MOV  AL,BOARD[SI]    ;get board symbol
mov bx,BOARD
add bx,si
MOV   AL,[bx]
       CMP  AL,'X'          ;is position occupied?
       JZ   PSO
       CMP  AL,'O'
       JZ   PSO
       ;MOV  BOARD[SI],'X'   ;save player move
mov bx,BOARD
add bx,si
MOV byte [bx],'X'
       mov  DX,CRLF         ;set up pointer to newline string
       MOV  AH,9            ;display string function
       INT  21H             ;DOS call
       RET
BPM:
   mov  DX,PIM1         ;set up pointer to illegal string
STP:
   MOV  AH,9            ;display string function
       INT  21H             ;DOS call
       JMP  PMOVE           ;go give user a second chance
PSO:
   mov  DX,PIM2         ;set up pointer to occupied string
       JMP  STP             ;go process error message
       RET
;PMOVE  ENDP

CoMOVE:
;  PROC NEAR
       mov  DX,P2MSG         ;set up pointer to player string
       MOV  AH,9            ;display string function
       INT  21H             ;DOS call
       MOV  AH,1            ;read keyboard function
       INT  21H             ;DOS call
       CMP  AL,'1'          ;insure user input is a digit
       JC   .BPM
       CMP  AL,'9'+1
       JNC  .BPM
       SUB  AL,31H          ;remove ASCII bias
       CBW                  ;convert to word
       MOV  SI,AX           ;set up index pointer
       ;MOV  AL,BOARD[SI]    ;get board symbol
mov bx,BOARD
add bx,si
MOV   AL,[bx]
       CMP  AL,'X'          ;is position occupied?
       JZ   .PSO
       CMP  AL,'O'
       JZ   .PSO
       ;MOV  BOARD[SI],'X'   ;save player move
mov bx,BOARD
add bx,si
MOV byte [bx],'O'
       mov  DX,CRLF         ;set up pointer to newline string
       MOV  AH,9            ;display string function
       INT  21H             ;DOS call
       RET
.BPM:
   mov  DX,PIM1         ;set up pointer to illegal string
.STP:
   MOV  AH,9            ;display string function
       INT  21H             ;DOS call
       JMP  CoMOVE           ;go give user a second chance
.PSO:
   mov  DX,PIM2         ;set up pointer to occupied string
       JMP  .STP             ;go process error message
       RET
;CoMOVE  ENDP

CHECK:
;  PROC NEAR
       SUB  SI,SI             ;clear index pointer
       MOV  CX,8              ;set up loop counter
CAT:
   ;MOV  DI,WINS[SI]       ;get first board position
mov bx,WINS
add bx,si
MOV DI,[bx]
       ;MOV  AH,BOARD[DI-1]    ;get board symbol
mov bx,BOARD
add bx,di
dec bx
MOV ah,[bx]
       ;MOV  DI,WINS[SI+2]     ;get second board pisition
mov bx,WINS
add bx,si
add bx,2
MOV di,[bx]
       ;MOV  BL,BOARD[DI-1]    ;get board symbol
mov bx,BOARD
add bx,di
dec bx
MOV dl,[bx]
       ;MOV  DI,WINS[SI+4]     ;get third board position
mov bx,WINS
add bx,si
add bx,4
MOV di,[bx]
       ;MOV  BH,BOARD[DI-1]    ;get board symbol
mov bx,BOARD
add bx,di
dec bx
MOV dh,[bx]
       ADD  SI,6              ;advance to next set of psitions
	   CMP  AH,DL             ;do all three symbols match?
       JNZ  NMA
       CMP  AH,DH
       JNZ  NMA
	   CMP  AH,'X'            ;does match contain X?
       JNZ  WIO
       mov  DX,XWIN           ;set up pointer to x-wins string
       JMP  EXC               ;go process string
WIO:
   mov  DX,OWIN           ;set up pointer to o-wins string
       JMP  EXC               ;go process string
NMA:
   LOOP CAT               ;no match, try another group
       SUB  SI,SI             ;clear index pointer
	   mov cx,9
CFB:
   ;MOV  AL,BOARD[SI]      ;get board symbol
mov bx,BOARD
add bx,si
MOV   AL,[bx]
       CMP  AL,'X'            ;is symbol X?
       JE   IAH
       CMP  AL,'O'            ;is symbol O?
       JE   IAH
       RET                    ;no tie yet
IAH:
   INC  SI                ;advance to next position
       LOOP CFB               ;go check another board symbol
       mov  DX,MTIE           ;set up pointer to tie message
EXC:
   MOV  AH,9              ;display string function
       INT  21H               ;DOS call
       SUB  AL,AL             ;set zero flag
       RET
;CHECK  ENDP

       ;END

GMSG  DB  'Two Player TIC TAC TOE.',0DH,0AH
      DB  'Player 1 is X, Player 2 is O',0DH,0AH,0DH,0AH,'$'
BOARD DB  '123456789'
BTXT  DB  0DH,0AH
      DB  '  |   |  ',0DH,0AH
      DB  '---------',0DH,0AH
      DB  '  |   |  ',0DH,0AH
      DB  '---------',0DH,0AH
      DB  '  |   |  ',0DH,0AH,0DH,0AH,'$'
BPOS  DB  2,6,10,24,28,32,46,50,54
PMSG  DB  'Player 1: Enter your move (1 to 9): $'
P2MSG DB  'Player 2: Enter your move (1 to 9): $'
PIM1  DB  0DH,0AH,'That move does not make sense, try again.',0DH,0AH,'$'
PIM2  DB  0DH,0AH,'That square is occupied, try again.',0DH,0AH,'$'
;CMSG  DB  'I choose square $'
CRLF  DB  0DH,0AH,'$'
WINS  DW  1,2,3, 4,5,6, 7,8,9                ;any row
      DW  1,4,7, 2,5,8, 3,6,9                ;any column
      DW  1,5,9, 3,5,7                       ;either diagonal
XWIN  DB  'Player 1 (X) wins the game!',0DH,0AH,'$'
OWIN  DB  'Player 2 (O) wins the game!',0DH,0AH,'$'
MTIE  DB  'The game is a tie.',0DH,0AH,'$'