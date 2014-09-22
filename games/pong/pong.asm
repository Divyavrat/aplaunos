    org 6000h
 
    start:
       call subs.cursorHide
       call subs.clearScreen
       call subs.drawPlayer
       call subs.drawCPU
       call subs.drawBall
 
    main:
       call subs.processInput
       call subs.moveCPU
       call subs.padColCheck
       call subs.moveBall
       call subs.sleep
       jmp main
 
    subs:
    .endProgram:
       call .cursorShow
       mov ax,0x4c00
       int 0x21
 
    .processInput:
       mov ah,0x01
       int 0x16
       jz .processInputEnd
    .processInputGet:
       mov ah,0x00
       int 0x16
       cmp al,0x1b
       je .endProgram
       cmp ah,0x48
       je .playerMoveUp
       cmp ah,0x50
       je .playerMoveDown
    .processInputEnd:
       ret
 
    .moveCPU:
       mov ax, [ballLoc]
       mov ah, [cpuLoc]
       inc ah
       cmp al,ah
       jl .cpuMoveUp
       jg .cpuMoveDown
       ret  
 
    .sleep:
       mov ah,0  ; function no. for read
       int 1ah   ; get the time of day count
       add dx,1  ; add one half second delay to low word
       mov bx,dx ; store end of delay value in bx
    .sleepLoop:
       int 1ah
       cmp dx,bx
       jne .sleepLoop
       ret
 
    .playerMoveUp:
       mov ch,[playerLoc]
       cmp ch,0x01
       je .playerMoveNull
       dec ch
       mov [playerLoc],ch
       call .clearPlayer
       call .drawPlayer
       ret
 
    .playerMoveDown:
       mov ch,[playerLoc]
       cmp ch,0x15
       je .playerMoveNull
       inc ch
       mov [playerLoc],ch
       call .clearPlayer
       call .drawPlayer
    .playerMoveNull:
       ret
 
    .cpuMoveUp:
       mov ch,[cpuLoc]
       cmp ch,0x01
       je .cpuMoveNull
       dec ch
       mov [cpuLoc],ch
       call .clearCPU
       call .drawCPU
       ret
 
    .cpuMoveDown:
       mov ch,[cpuLoc]
       cmp ch,0x15
       je .cpuMoveNull
       inc ch
       mov [cpuLoc],ch
       call .clearCPU
       call .drawCPU
    .cpuMoveNull:
       ret
 
 
    .cursorShow:
       mov cx,0x0d0e
       mov ah,0x01
       int 0x10
       ret
 
    .cursorHide:
       mov cx,0x2000
       mov ah,0x01
       int 0x10
       ret
 
    .clearScreen:
       mov ah,0x06
       mov al,0x00
       mov bh,0x07
       mov cx,0x0000
       mov dl,0x79
       mov dh,0x24
       int 0x10
	   
	   mov cx,25
	   .loop1:
	   push cx
	   mov cx,80
	   .loop2:
	   pop dx
	   push dx
	   push cx
       mov [curX],cl
       mov [curY],dl
       call .setCur
       mov ah,0x02
       mov dl,0x20
       int 0x21
	   pop cx
	   loop .loop2
	   pop cx
	   loop .loop1
	   
       mov bx,0x0000
       mov [curX],bx
       mov [curY],bx
       call .setCur
       ret
 
    .setCur:
       mov ah,0x02
       mov bh,0x00
       mov dl,[curX]
       mov dh,[curY]
       int 0x10
       ret
 
 
    .drawPlayer:
       mov cl,0x00
       mov ch,[playerLoc]
       mov [curX],cl
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0xb3
       int 0x21
       add ch,0x01
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0xb3
       int 0x21
       inc ch
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0xb3
       int 0x21
       ret
 
    .drawCPU:
       mov cl,0x4f
       mov ch,[cpuLoc]
       mov [curX],cl
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0xb3
       int 0x21
       add ch,0x01
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0xb3
       int 0x21
       inc ch
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0xb3
       int 0x21
       ret
 
    .drawBall:
       mov cl,[ballLoc+1]
       mov ch,[ballLoc]
       mov [curX],cl
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0x2a
       int 0x21
       ret
 
    .moveBall:
       mov cl,[ballLoc+1]
       mov ch,[ballLoc]
       mov [curX],cl
       mov [curY],ch
       call .setCur
       mov ah,0x02
       mov dl,0x20
       int 0x21
       mov al,[ballDirection]
       cmp al,0x01
       je .moveBall1
       cmp al,0x02
       je .moveBall2
       cmp al,0x03
       je .moveBall3
       cmp al,0x04
       je .moveBall4
 
    .moveBall1:
       mov ax, [ballLoc]
       cmp ah,0x01
       je .gameOver
       cmp al,0x02
       je .setBallDirection4
       dec al
       dec ah
       mov [ballLoc], ax
       call .drawBall
       ret
 
    .moveBall2:
       mov ax, [ballLoc]
       cmp ah,0x4f
       je .gameOver
       cmp al,0x01
       je .setBallDirection3
       inc ah
       dec al
       mov [ballLoc], ax
       call .drawBall
       ret
 
    .moveBall3:
       mov ax, [ballLoc]
       cmp ah,0x4f
       je .gameOver
       cmp al,0x17
       je .setBallDirection2
       inc ah
       inc al
       mov [ballLoc], ax
       call .drawBall
       ret
 
    .moveBall4:
       mov ax, [ballLoc]
       cmp ah,0x01
       je .gameOver
       cmp al,0x17
       je .setBallDirection1
       dec ah
       inc al
       mov [ballLoc], ax
       call .drawBall
       ret
 
    .setBallDirection1:
       mov al,0x01
       mov [ballDirection],al
       call .drawBall
       ret
    .setBallDirection2:
       mov al,0x02
       mov [ballDirection],al
       call .drawBall
       ret
    .setBallDirection3:
       mov al,0x03
       mov [ballDirection],al
       call .drawBall
       ret
    .setBallDirection4:
       mov al,0x04
       mov [ballDirection],al
       call .drawBall
       ret
 
    .padColCheck:
       mov ax, [ballLoc]
       cmp ah,0x1
       je .padColCheck1
       cmp ah,0x4f
       je .padColCheck2
       ret
 
    .padColCheck1:
       mov bl, [playerLoc]
       cmp al,bl
       je .bouncePlayer
       inc bl
       cmp al,bl
       je .bouncePlayer
       inc bl
       cmp al,bl
       je .bouncePlayer
       ret
 
    .padColCheck2:
       mov bl, [cpuLoc]
       cmp al,bl
       je .bounceCpu
       inc bl
       cmp al,bl
       je .bounceCpu
       inc bl
       cmp al,bl
       je .bounceCpu
       ret
 
    .bouncePlayer:
       mov al,[ballDirection]
       cmp al,0x01
       je .setBallDirection2
       cmp al,0x04
       je .setBallDirection3
       ret
 
    .bounceCpu:
       mov al,[ballDirection]
       cmp al,0x02
       je .setBallDirection1
       cmp al,0x03
       je .setBallDirection4
       ret
 
    .clearPlayer:
       mov ch,0x00
       mov cl,0x27
       call .clearPlayerLoop
       ret
    .clearPlayerLoop:
       mov ah,0x02
       mov bh,0x00
       mov dh,ch
       mov dl,0x00
       int 0x10
       mov ah,0x02
       mov dl,0x20
       int 0x21
       inc ch
       cmp ch,0x18
       jne .clearPlayerLoop
       ret
 
    .clearCPU:
       mov ch,0x00
       mov cl,0x27
       call .clearCpuLoop
       ret
    .clearCpuLoop:
       mov ah,0x02
       mov bh,0x00
       mov dh,ch
       mov dl,0x4f
       int 0x10
       mov ah,0x02
       mov dl,0x20
       int 0x21
       inc ch
       cmp ch,0x18
       jne .clearCpuLoop
       ret
 
 
    .gameOver:
       call .clearScreen
       mov ah,0x09
       mov dx,gameOver
       int 0x21
       jmp .endProgram
 
    .pause:
       mov ah,0x00
       int 0x16
       ret
 
    ;section .data
       curX: db 0x00
       curY: db 0x00
       borderSymbols db 0xb0,0xb0,'$'
       playerLoc db 0x0a
       cpuLoc db 0x0a
       ballLoc: db 0x0b,0x27
	   ballDirection db 0x01
       gameOver db 'Game over!$'