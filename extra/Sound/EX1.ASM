     PROC USES AX BX CX
	    IN AL, 61h  ;Save state
	    PUSH AX  

	    MOV BX, 6818; 1193180/175
   MOV AL, 6Bh  ; Select Channel 2, write LSB/BSB mode 3
	    OUT 43h, AL 
   MOV AX, BX 
	    OUT 42h, AL  ; Send the LSB
   MOV AL, AH  
	    OUT 42h, AL  ; Send the MSB
   IN AL, 61h   ; Get the 8255 Port Contence
	    OR AL, 3h      
   OUT 61h, AL  ;End able speaker and use clock channel 2 for input
	    MOV CX, 03h ; High order wait value
   MOV DX 0D04h; Low order wait value
	    MOV AX, 86h;Wait service
   INT 15h        
	    POP AX;restore Speaker state
   OUT 61h, AL
	    RET
	BEEP ENDP