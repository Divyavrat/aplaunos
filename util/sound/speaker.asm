You could create sound from the PC Speaker in 8086 Assembly Language by communicate with the speaker controller using IN and OUT instructions. 


This is what u need to do
      1, Set up the speaker by sending the value 182 to port 43h. .
      2. Send the frequency number to port 42h. U can check the table below for the same. 
      3, To start the beep, bits 1 and 0 of port 61h must be set to 1. Since the other bits of port 61h have other uses, they must not be modified. Therefore, you must use an IN instruction first to get the value from the port, then do an OR to set the two bits, then use an OUT instruction to send the new value to the port.
      4. Pause for the duration of the beep.
      5.Turn off the beep by resetting bits 1 and 0 of port 61h to 0. Remember that since the other bits of this port must not be modified, you must read the value, set just bits 1 and 0 to 0, then output the new value.

The following code fragment generates a beep with a frequency of 261.63 Hz (middle C on a piano keyboard) and a duration of approximately one second:

        mov     al, 182         ; Prepare the speaker for the
        out     43h, al         ;  note.
        mov     ax, 4560        ; Frequency number (in decimal)
                                ;  for middle C.
        out     42h, al         ; Output low byte.
        mov     al, ah          ; Output high byte.
        out     42h, al 
        in      al, 61h         ; Turn on note (get value from
                                ;  port 61h).
        or      al, 00000011b   ; Set bits 1 and 0.
        out     61h, al         ; Send new value.
        mov     bx, 25          ; Pause for duration of note.
.pause1:
        mov     cx, 65535
.pause2:
        dec     cx
        jne     .pause2
        dec     bx
        jne     .pause1
        in      al, 61h         ; Turn off note (get value from
                                ;  port 61h).
        and     al, 11111100b   ; Reset bits 1 and 0.
        out     61h, al         ; Send new value.

Another way to control the length of beeps is to use the timer interrupt. This gives you better control over the duration of the note and it also allows your program to perform other tasks while the note is playing.


Note 	Frequency 	Frequency #
C 	130.81 	9121
C# 	138.59 	8609
D 	146.83 	8126
D# 	155.56 	7670
E 	164.81 	7239
F 	174.61 	6833
F# 	185.00 	6449
G 	196.00 	6087
G# 	207.65 	5746
A 	220.00 	5423
A# 	233.08 	5119
B 	246.94 	4831
Middle C 	261.63 	4560
C# 	277.18 	4304
D 	293.66 	4063
D# 	311.13 	3834
E 	329.63 	3619
F 	349.23 	3416
F# 	369.99 	3224
G 	391.00 	3043
G# 	415.30 	2873
A 	440.00 	2711
A# 	466.16 	2559
B 	493.88 	2415
C 	523.25 	2280
C# 	554.37 	2152
D 	587.33 	2031
D# 	622.25 	1917
E 	659.26 	1809
F 	698.46 	1715
F# 	739.99 	1612
G 	783.99 	1521
G# 	830.61 	1436
A 	880.00 	1355
A# 	923.33 	1292
B 	987.77 	1207
C 	1046.50 	1140
