ORG 0x6000
jmp start  ; Skip our data area

welcome   db 'welcome to onem16!', 0x0D, 0x0A, 'please close the door when you leave.', 0x0D, 0x0A, 0
prompt    db '>>', 0

;-----[ start, entry point ]-----;
start:                           ;
   xor ax, ax                    ; make it zero (faster than mov)
   mov ds, ax                    ; Data segment 0
   mov si, welcome               ; Source index is now a pointer to the welcome message
   call print_string             ; Print the string
   cli                           ; disable interrupts
   mov word[ds:(9*4)], kb_handler; tell interrupt handler where the party's at
   mov word[ds:(9*4)+2], 0       ; ^ same stuff i guess, dunno
   sti                           ; enable interrupts
   jmp .loop	                     ; jump to the main loop
;--------------------------------;

;-----[ main loop, CLI etc ]-----;
.loop:                            ;
   jmp .loop                      ; end of loop enter hang mode
;--------------------------------;

;-----[ parse command ]-----;
exec_command:               ;
;---------------------------;

;-----[ get the keyboard input ]-----;
kb_handler:                          ; not a dummy function :3
   pusha                             ; puts something on the stack, no idea what or what the a stands for
   in al, 0x60                       ; read the scancode
   call print_string                 ; print dat char
   mov al, 0x20                      ; tell the interrupt thing shits good
   out 0x20, al                      ; ^
   popa                              ; reads something from the stack
   iret                              ; return from the function
;------------------------------------;

;-----[ print_string, message location = si ]-----;
print_string:                                     ;
   lodsb                                          ; Grab a byte from our data source (message)
   or al, al                                      ; zero=end of string
   jz .done                                       ; get out
   mov ah, 0x0E                                   ; tell BIOS we want to use the Teletype function
   int 0x10                                       ; tell BIOS to run the function
   jmp print_string                               ; Jump to the start
 .done:	                                          ; When we are finished,
   ret		                                      ; Return to main code
;-------------------------------------------------;

;-----[ hang, endless loop ]-----;
hang:                            ;
   jmp hang                      ; We could jmp $ but this is cleaner
;--------------------------------;

;-----[ Boot Signature ]-----;
times 510-($-$$) db 0        ; Make sure we are at the end of the sector: 510 - (current location - code length)  
db 0x55	                     ; First byte of sig
db 0xAA                      ; Second byte of sig
;----------------------------;