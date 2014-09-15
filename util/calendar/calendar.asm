;name "Calender"

; Irving Derin
;
; This is my calender application. It shall use a formula to figure out what the offset of the day is.
; I shall be using a bitflag variable that shall keep track of important information such as the month,leap year, offset
; The offset shall determine how many "boxes" need to be offset when starting the calendar. This will be determined
; by using the formula w = (c + y + m + d) % 7
; The c and d values are preset by using c = 6 (for 2000 - 2099) and d = 1 (find the first of the month)
; After that, 6 months shall be shown after the indicated month and year
; Navigation will allow the user to move back and forth in the months. He may exit by hitting the escape key
; Page 0 will be an introduction header
; Page 1 will be a prompt to take the month and date from the user
; Pages 2 - 7 will be used to display the months
; Many of the ideas for this code were scrapped together from example code in the emu8086 application


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This is being added after the actual assignment!!!
;; Damn, I wanted to be all sentimental here. This is my first public piece of code that I'm just throwing out there into the cold dark parts of the internet. I wish it all the best!!! But this will be a new footnote that is the book of my life. A footnote that people will want to flip too because fuck, who doesn't like a nice "This is where it all started" story? 

;; Oh right, now I remember what I wanted to say. This is an asm program that goes ahead and takes input from the user. It looks like shit, it needs a ton of work. 

org 0x6000

;Variables         


jmp start    

        
currentPage db 0   

;; MESSAGES ;;   
      
page1message1 db "Thank you for opening this application",010,013
	db "This application was written by Irving Derin",010,013
	db "On the next page, you shall be asked to enter a month and a year",010,013
	db "You will then be able to see 6 months of dates",010,013
	db "Be aware that the range of years is 2000 - 2099",010,013,010,013
	db "For the purpose of the assignment, entering 2012 as the year", 010,013
	db "And 08 for the month will be more than enough!", 010, 013
	db "Press any key to move on to the next page","$"

page2prompt1 db "Please enter year: 20"
page2prompt1Spot:
page2prompt2 db "Enter month number(01-12): "
page2prompt2Spot:	
page2prompt3 db "Press enter, then the right arrow key to move onto the next page$"	

;; PRESET VALUES ;;     

noLeap: db 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31

Leap:   db 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 

days db "01","02","03","04","05","06","07","08","09","10","11","12","13","14","15","16","17","18","19","20","21","22","23","24","25","26","27","28","29","30","31"

names db "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"

months db "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"   

;; MISC ;;

monthOff    db  5, 1, 1, 4, 6, 2, 4, 0, 3, 5, 1, 3

;; VARIABLES ;;
yearstart db "20"
yeardig1 db ?      ; First digit scanned
yeardig2 db ?      ; Second digit scanned
montdig1 db ?      ; First scanned digit
montdig2 db ?      ; Second scanned digit
leMont  dw ?       ; Final value  

;; Hacky way to make the year into a string. We just need to play around with the addresses! :P
leYear  dw ?
            
dayOff  db ?       ; The result of the day calculation!
no_of_days dw 31

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Here we are setting up the generic page for the calendar! ;


start:
    ; Boilerplate for all the fun graphics stuff! 

    mov ax, 3     ; text mode 80x25, 16 colors, 8 pages (ah=0, al=3)
    int 10h     

    ; cancel blinking and enable all 16 colors:
    mov ax, 1003h
    mov bx, 0
    int 10h

	mov [currentPage],0

    ; Print welcome message using interrupt 21!
    mov dx,page1message1
    mov ah, 9
    int 21h

    xor ax,ax  	; Clear the ax register to accept a key entry     
    int 16h
   
    inc [currentPage]
    
    
    
    ;; Next Page! 
    mov al, [currentPage]
    mov ah, 05h
    int 10h  
    
    mov al, 1 
    mov ah, 13h 
    mov bl, 00000111b
    mov bh, [currentPage]
    mov cx, page2prompt1Spot - page2prompt1
    mov dl, 10
    mov dh, 7 
    mov bp, page2prompt1
    int 10h 
    
    ;; get a character and print it!
    call getInOut
    mov [yeardig1], al
                 
    call getInOut
    mov [yeardig2], al
    
    mov  dl, al         ;; Push al register into dl -- No need for mem access
                     
    mov  al, [yeardig1]

    call MakeOneNum
    mov [leYear], cx
    add [yeardig1], 30h
    add [yeardig2], 30h

    
    ;; Second line
    mov al, 1 
    mov ah, 13h 
    mov bl, 00000111b
    mov bh, [currentPage]
    mov cx, page2prompt2Spot - page2prompt2
    mov dl, 10
    mov dh, 8 
    mov bp, page2prompt2
    int 10h    
    
    call getInOut
    mov [montdig1], al
    
    call getInOut
    mov [montdig2], al
    
    mov dl, al
    mov al, [montdig1]
    
    call MakeOneNum
    mov [leMont], cx 
    
    ;; To print this last message, we need to reset the cursor somewhere else!
    mov dh, 10
    mov dl, 9
    mov ah, 2
    int 10h
    
    ;; Quickly print the next part! 
    mov dx,page2prompt3
    mov ah,9
    int 21h
    
    wait_on_enter:
        
        xor ax,ax
        int 16h
        cmp al, 0Dh
        jnz wait_on_enter
    
    mov bx, [leYear]
    mov cx, [leMont]
    dec [leMont]
    
    call MonthStart ;; We calculate the first date!
    mov [dayOff], al
    
    
    keyControl:
   
        xor ah,ah
        int 16h  
        
        cmp ah, 4Bh      ;; Left arrow key pressed!
        je goBack
        
        cmp ah, 4Dh      ;; Right Arrow key pressed!
        je goNext      
        
		cmp ah,0x01
		je quit
        
        jmp keyControl 
        
    postControl:
	;cmp [currentPage],0
	;jle firstPage
	
        cmp [leMont],13
        je newYear
        
        
        ;; Call the offset function!
        push bx
        push cx
        push ax
        
        mov cx, [leMont]
        mov bx, [leYear]
        
        call MonthStart
        
        mov [dayOff], al
        pop ax
        pop cx
        pop bx 
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
              
        call PrintPage
    
        cmp [currentPage], 7
        
        jge lastPage         ;; If this is the last page, prepare to quit!
        
        jmp keyControl    
    
    lastPage:
        mov [currentPage],2
		mov al,[currentPage]
		mov ah, 05h
		int 0x10
		call PrintPage
		jmp keyControl
		
quit:
mov ax,0x4C07
int 0x21

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  Control Lables
    
    goBack:
        cmp [currentPage], 2 ;; If you're on the first page, don't go back!
        ;je keyControl
		jle start
        
        cmp [leMont], 0
        je lastYear
        dec [leMont]
        
        prevPage:
            push ax
            mov ah, 05h
            dec [currentPage]
            mov al, [currentPage]
            int 10h
        pop ax
        call PrintPage
        jmp keyControl
        
    goNext:
    
        cmp [leMont], 13
        je newYear
        
        inc [leMont]
        
        
        nextPage:
        push ax
        mov ah, 05h 
        inc [currentPage]
        mov al, [currentPage]
		cmp [currentPage], 7
        jge lastPage
        int 10h
        pop ax
        
        jmp postControl
        
    newYear:    ;; Only happens moving forwards!
        cmp [yeardig2],'9'
        je add2digs
        
        inc [yeardig2]
        newYearRet:
        
        mov [leMont], 1
        inc [leYear]
        
        jmp nextPage
        
    lastYear:   ;; Only happens moving backwards!
        cmp [yeardig2], "0"
        je sub2digs
        
        dec [yeardig2]
         
        lastYearRet:
        mov [leMont], 11
        dec [leYear]
        
        jmp prevPage
        
        
    add2digs:
        mov [yeardig2],'0'
        inc [yeardig1]
        jmp newYearRet
        
    sub2digs:
        mov [yeardig2],'9'
        dec [yeardig1]
        jmp lastYearRet    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Procedures                                                                  ;
getInOut:
;PROC getInOut       ;This procedure shall take a char from the screen, print it on the next cursor spot, and then leave the dec number in al 

    xor ax,ax
    
    int 16h
    mov ah, 0Ah
    mov cx, 1
    int 10h 
       
      
    mov ah, 03h
    
    int 10h
    inc dl
    mov ah,2
    int 10h
   
    sub al, 30h  
    
    ret
    
;ENDP getInOut                                                                                                       


;Place the two digits you'd like to make into 1. Top value into AL, lower value into DL, gather result inside of CX  
;PROC 
MakeOneNum:
    
    push ax
    push bx
    push dx
    
    xor ah,ah   ; Clear the top portion of the AH 
    xor dh,dh   ; Clear the top portion of the DH
     
    shl ax, 1   ; Doubling AX 
    mov cx, ax  ; Move that value to CX
    shl ax, 2   ; Now *8 the original value! 
    add cx, ax  ; x*8 + x*2 = x*10!
    add cx, dx  ; Add it to the value of dx, or the ones place digit. And we're good! :D
     
    pop dx
    pop bx
    pop ax
    
    ret
    
;ENDP MakeOneNum

;; Calculate the first of the month that was requested!
;; to do this, put the year into BX
;; put the month into CX
;; collect in AL 

;; The formula (y + y/4 + MI + d) % 7
;; Because we are using the first of each month, we make d = 1
;; MI is equal to the month index, which is calculated by using
;; a formula created by Hans Lachman. 
;; MI = ( (Month * 2.56 + 94) % 100 ) % 7
;; I've premade this array in montOff
;; We then find the year that had the last leap year. and divide by 4
;; To do this, we shift right by 2, and what ever number we have suffices!
;; The final formula becomes w = (y + y/4 + MI + 1) 

     
;PROC 
MonthStart:
    
    push bx     ;; This is the year    
    push cx     ;; This is the month! 
    
    dec cx      ;; For proper index
    
    add bx, 2000 ;; This is giving us the absolute year
   
    ;lea si, monthOff  ;; Load the month offset array! 
	mov si, monthOff
    add si, cx        ;; Get the month offset first 
    mov cl, [si]      ;; move the offset to CX
	;mov cx, [si]
    
    mov ax, bx      ;; Move the year into ax
    shr bx, 2       ;; divide the year by 4
    add ax, bx      ;; add the two now 
    add ax, cx      ;; get the month offset from cx
    inc ax          ;; Since we need the first, we add 1
    
    push dx    
    xor dx, dx      ;; clear dx
    mov cx, 7       ;; we're moduloing, so get 7 into cx    
    div cx          ;; ax / cx   
    mov al, dl      ;; we're returning the answer in ax
    pop dx          ;; return it back to how it was!
    
    pop cx          ;; put it all back!
    pop bx          ;; BACK TO HOW IT WAS NAOW!!!!
    
    ret
    
;ENDP MonthStart   
    
;; This is a function tha shall print out the calendar itself! 
;; To use this function, you will have to place the year into BX
;; Into cx, you shall contain the month
;; inside AL, you already have the first month's offset 
;; This is the day on which you will start!
;; The main method of printing the calendar will be through 
;; the use of cursors and interrupts. This is for simplicity
;; NOTE!!! This only prints it out, it does NOT display it
;; For that you need to go and press buttons as defined in the main
;; progession loop

    
;PROC 
PrintPage:
    
    pusha   ;; Just covering our bases!
    
	mov ax, 3     ; text mode 80x25, 16 colors, 8 pages (ah=0, al=3)
    int 10h     

    ; cancel blinking and enable all 16 colors:
    mov ax, 1003h
    mov bx, 0
    int 10h

	mov [currentPage],2
	mov ah,0x05
	mov al,[currentPage]
	int 0x10
	
    mov bp, months
    
    mov ax, [leMont]      ; Move our month over to ax
    dec ax              ; Make it one less for use as an index!

    mov bx, 3
    mul bx
    
    add bp, ax          ; add the offset so that we can print the month now!
    
    
    ;; Prints out the month name!
    mov bh, [currentPage]
    mov bl, 00000111b
    mov ah, 13h
    mov al, 1
    mov dl, 33
    mov dh, 0
    mov cx, 3
    int 10h
    
    ;; Print out the year!
    mov bp, yearstart
    mov ah, 13h
    mov al, 1
    mov dh, 0
    mov dl, 37        ;; This line does nothing O_o
    mov cx, 4        ;; We have a 5 character string!
    int 10h 
	
    ;; Print out the days!
    mov bp, names
    mov cx, 7
    
    mov dh, 2
    mov dl, 10
    
    
    push bp
    push dx
    
    printDaysWeek:
        pop dx
        pop bp
        push cx
        
        mov al, 1
        mov ah, 13h
        mov cx, 3
        int 10h
        ;add dl, 5
		add dl, 6
        add bp, 3
        
        pop cx
        push bp
        push dx
        
        loop printDaysWeek
        
    pop dx
    pop bp
    

    ;; Now we shall start to print out the dates
    
    
    mov ax, [leYear]
    and ax, 3            ;; Check to see if it's a leap year
    jnz notLeapYear
    
    mov bp, Leap
    jmp loadDays
    
    notLeapYear:  
    mov bp, noLeap
    
    loadDays:    
    add bp,[leMont]     ;; Add the month offset
    dec bp
	;inc bp
	push bx
	mov bx,bp
	;mov cx,[bx]
	mov ch,0
    mov cl, [bx]      ;; Move the number of days in the month into cx from the array!
	pop bx
    mov [no_of_days],cx
	;push cx
    mov bp, days      ;; Move the days array into bp
	
    printFirstRow:
        mov ax, 7       ;; seven days
        sub al, [dayOff]  ;; Yields 
        sub cl, al      ;; Number of days in the other rows!
        push cx         ;; save that number now! Days in month
        
        mov cl, al      ;; Days on that line!
        
        mov dl, 10
        mov dh, 5
        
        push cx  ;; save le counter
        
        mov cl, [dayOff]  ;; Blank spaces
        push dx
            offsetDays:
                pop dx
                
                ;add dl, 8
				add dl, 6
                
                push dx
                loop offsetDays
        pop dx  
        pop cx         ;; get days on the list! 
        
        push dx
        push bp
        
        printFirstNums:            
            pop bp
            pop dx
            push cx     ;; Push the days on the list
            mov al,1
            mov ah, 13h
            mov cx, 2
            int 10h
            add dl, 6
            add bp, 2
            
            pop cx      ;; Get them back
            push dx
            push bp
            
            loop printFirstNums
            
        pop bp
        pop dx
        ;;;;;;;;;;;;;
        
        add dh, 3     ;; We're going down a row, or 3
        mov dl, 10    ;; Back to the start!  
        
        pop cx
        sub cl, 21 ;; three rows = three weeks = 21 days
        push cx
        
        mov cx, 3  ;; We need to make three rows, lets go!

        printMidRows:
            push cx
            mov cx, 7 ;; We've got 7 days in each week
                    
            push bp
            push dx
                            
            printMidNumbers:
            cmp cl,01
			jl .done
                pop dx
                pop bp
                push cx
                
                mov al, 1
                mov ah, 13h
                mov cx, 2
                int 10h
                add dl, 6
                add bp, 2
                
                pop cx
                push bp
                push dx        
                
                loop printMidNumbers
            .done:
            pop dx
            pop bp
                
            add dh, 3
            mov dl, 10
            
            pop cx
            loop printMidRows
        
        mov dl, 10
        
        pop cx
        
        cmp cx, 7
        
        jng PreprintLastRow
            ;; if we have more than 5 rows
         
        sub cx, 7  ;; Subtract from the counter, this is our little tail :D 
        
        push cx    ;; push the tail into stack
        mov cx, 7      
        
        push bp
        push dx
        printAnotherRow:
		;cmp cl,01
			;jl .done
            pop dx
            pop bp
            push cx
            
            mov al, 1
            mov ah, 13h
            mov cx, 2
            int 10h
            add dl, 6
            add bp, 2
            
            pop cx
            push bp
            push dx
            
            loop printAnotherRow
			.done:
        pop dx
        pop bp
        
        mov dl, 10
		;mov dl, 6
        add dh, 3
            
        
        pop cx    ;; Get the tail!
        
        PreprintLastRow:
        push dx
        push bp 
        ;mov cx,7
        printLastRow:
			cmp cl,01
			jl .done
			pop bp
            pop dx
            push cx
			;jmp .all_done
			mov ax,bp
			sub ax,days
			mov cx,2
			;idiv cx
			;pusha
			;mov bx,0
			;mov dx,ax
			;mov ah,0x46
			;int 0x61
			;popa
			;cmp ax,[no_of_days]
			;jg .all_done
            
            mov al, 1
            mov ah, 13h
            mov cx, 2
            int 10h
            add dl, 6
            add bp, 2
            
            pop cx 
            push dx
            push bp
			
            loop printLastRow
			jmp .done
			dec cx
            jmp printLastRow
            .done:
        pop bp
        pop dx
        
        popa  
        
        ret
		.all_done:
		pop cx
		popa
		ret
        
;ENDP PrintPage