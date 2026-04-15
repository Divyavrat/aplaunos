REM Serial Communications for MikeOS (SERIAL.BAS)
REM Created by Joshua Beck
REM Released under the GNU General Public Licence revision 3
REM Send any bugs, comments or changes to: mikeosdeveloper@gmail.com
REM Uses the MikeBASIC++ Library version 3

INCLUDE "MBPP.BAS"

SERIAL ON 9600
CLS
INK 15

REM MB++ Parameters
C = 4
H = 6
T = 3

MAINMENU:
  $T = "Serial Communication"
  $5 = "Send File"
  $6 = "Send Picture"
  $7 = "Chat"
  $8 = "Recieve"
  $9 = "Exit"
  GOSUB MENUBOX
  IF V < 4 THEN GOSUB CONNECT
  IF V = 1 AND E = 1 THEN GOSUB SENDFILE
  IF V = 2 AND E = 1 THEN GOSUB SENDPIC
  IF V = 3 AND E = 1 THEN GOSUB CHAT
  IF V = 4 THEN GOSUB RECIEVE
  IF V = 5 THEN GOTO ENDPROG
GOTO MAINMENU

CONNECT:
  PRINT "Attempting Connection..."

  REM send a connection request, try 100 times then time out
  Y = 0
  DO
    SERIAL SEND 4
    SERIAL REC X
    IF X = 96 THEN X = 0
    Y = Y + 1
    IF Y > 100 THEN X = 22
  LOOP UNTIL X > 0
  
  REM now lets check our response

  REM if the reply was ACK connection was accepted
  E = 1
  IF X = 6 THEN PRINT "Connected"
  IF X = 6 THEN RETURN

  REM otherwise find a reason it was not

  E = 0
  $E = "Bad Protocol"
  IF X = 22 THEN $E = "Connection Timed Out"
  IF X = 21 THEN $E = "Connection Denied"
  IF X = 4 THEN $E = "Both Machines Transmitting!"
  PRINT $E
  GOTO ERRBOX

SENDFILE:
  REM get a filename
  $T = "Send File"
  $5 = ""
  $6 = "Input filename to send"
  V = 1
  GOSUB INPBOX

  REM verify the filename is valid
  SIZE $I
  IF S > 6000 THEN $E = "File too big!"
  IF S > 6000 THEN GOTO ERRBOX
  IF R > 0 THEN $E = "File does not exist!"
  IF R > 0 THEN GOTO ERRBOX

  REM now load it
  LOAD $I 58000

  REM send filename
  SERIAL SEND 17
  LEN $I X
  FOR Y = 1 TO X
    STRING GET $I Y W
    SERIAL SEND W
  NEXT Y
  SERIAL SEND 25
   
  X = S / 256
  SERIAL SEND X
  X = S % 256
  SERIAL SEND X

  SERIAL SEND 2
  S = S + 58000
  FOR X = 58000 TO S
    PEEK Y X
    SERIAL SEND Y
  NEXT X
  SERIAL SEND 3
  PRINT "File '" ;
  PRINT $I ;
  PRINT "' send."
  PRINT "Disconnected"
  SERIAL SEND 27
  E = 0
RETURN

SENDPIC:
  $T = "Send Picture"
  $5 = "Input the name of an"
  $6 = "ASCII Artist picture to send."
  V = 1
  GOSUB INPBOX
  SIZE $I
  $E = ""
  IF $I = "" THEN $E = "Cannot have blank name!"
  IF S > 2001 THEN $E = "Invalid Picture"
  IF S < 2001 THEN $E = "Invalid Picture"
  IF R > 0 THEN $E = "File does not exist!"
  IF $E = "" THEN GOTO NOERROR
  GOTO ERRBOX
  NOERROR:
  LOAD $I 58000
  SERIAL SEND 18
  LEN $I X
  FOR Y = 1 TO X
    STRING GET $I Y W
    SERIAL SEND W
  NEXT Y
  SERIAL SEND 25
  SERIAL SEND 2
  FOR X = 58000 TO 60001
    PEEK Y X
    SERIAL SEND Y
  NEXT X
  PRINT "Picture '" ;
  PRINT $I ;
  PRINT "' sent."
  SERIAL SEND 27
  E = 0
  PRINT "Disconnected"
RETURN

CHAT:
  PRINT "Starting Chat"
  SERIAL SEND 19
  
MESSAGE:
  GOSUB CUSTINP
  IF X = 27 THEN RETURN
  IF $1 = "" THEN GOTO MESSAGE

  STRING GET $1 1 W
  W = W % 256
  IF W = 35 THEN GOTO SPCMD

  LEN $1 W
  SERIAL SEND 2
  FOR X = 1 TO W
    STRING GET $1 X Y
    SERIAL SEND Y
  NEXT X
  SERIAL SEND 3
GOTO MESSAGE
    
SPCMD:
  S = 0
  X = 2
  DO
    STRING GET $1 X W
    W = W % 256
    IF W > 96 AND W < 123 THEN W = W - 32
    X = X - 1
    STRING SET $2 X W
    X = X + 2
  LOOP UNTIL W = 0
  X = 0
  STRING SET $2 9 X
  IF $2 = "SENDBEEP" THEN SERIAL SEND 7
  IF $2 = "SENDBEEP" THEN S = 1
  IF $2 = "SENDBEEP" THEN GOTO MESSAGE
  IF $2 = "SENDCODE" THEN GOSUB SENDCODE
  IF $2 = "SENDCODE" THEN GOTO MESSAGE
  STRING SET $2 5 X
  IF $2 = "HELP" THEN GOTO HELP
  IF $2 = "EXIT" THEN SERIAL SEND 27
  IF $2 = "EXIT" THEN E = 0
  IF $2 = "EXIT" THEN PRINT "Disconnected"
  IF $2 = "EXIT" THEN S = 1
  IF $2 = "EXIT" THEN RETURN
GOTO MESSAGE

HELP:
  PRINT "Avaliable commands:"
  PRINT "SENDBEEP: Sends a beep to the connected device"
  PRINT "SENDCODE [number]: Send a number instead of text"
  PRINT "HELP: Displays this help"
  PRINT "EXIT: Close the connect"
GOTO MESSAGE

SENDCODE:
  X = 10
  DO
    STRING GET $2 X W
    STRING SET $3 X W
  LOOP UNTIL W = 0
  NUMBER $3 W
  SERIAL SEND W
  S = 1
RETURN

CUSTINP:
  CURSPOS A B
  E = 1
  MOVE 2 23
  PRINT "SerialText> " ;
INPLOOP:
  X = 0
  CURSOR ON
  DO
    GETKEY K
    IF K = 0 THEN GOTO NOKEY
    IF K = 8 THEN GOTO BACKSPACE
    IF K = 13 THEN LOOP UNTIL K = 13
    IF K = 13 THEN GOTO ENDINP
    IF K = 27 THEN END
    STRING SET $1 E K
    PRINT CHR K ;
    E = E + 1
    NOKEY:
    X = X + 1
  LOOP UNTIL X = 1000
  SERIAL REC X
  IF X = 96 THEN X = 0
  IF X = 27 THEN E = 0
  IF X = 27 THEN MOVE A B
  IF X = 27 THEN RETURN
  IF X = 7 THEN SOUND 100 2
  IF X = 7 THEN GOTO INPLOOP
  IF X = 2 THEN GOSUB RECTEXT
  IF X = 2 THEN GOTO INPLOOP
GOTO INPLOOP  

BACKSPACE:
  X = E + 12
  MOVE X 23
  PRINT " " ;
  W = 0
  STRING SET $1 E W
  E = E - 1
  IF E = 0 THEN E = 1
  X = E + 13
  MOVE X 23
GOTO NOKEY
  
ENDINP: 
  CURSOR OFF
  X = 0
  STRING SET $1 E X
  MOVE 0 23
  FOR X = 0 TO 159
    PRINT " " ;
  NEXT X
  MOVE A B 
RETURN

RECTEXT:
  X = 1
  DO
    SERIAL REC W
    IF W = 0 THEN W = 32
    IF W = 3 THEN W = 0
    STRING SET $4 X W
    X = X + 1
  LOOP UNTIL W = 0
  MOVE A B
  PRINT "Serial Message: " ;
  PRINT $4
  CURSPOS A B
  X = E + 13
  MOVE X 23
  X = 2
RETURN  

RECIEVE:
  REM recieving protocol
  
  PRINT "Awaiting Connecting, press escape to cancel..."

  REM wait for a connection and check for escape key
  WAITCON:
  DO
    SERIAL REC X
    GETKEY K
    IF K = 27 THEN LOOP UNTIL K = 27
    IF K = 27 THEN RETURN
    REM 4 is to connect
  LOOP UNTIL X = 4

  REM accept connection with 6 (ACK)
  SERIAL SEND 6
  PRINT "Connected"

  WAITTYPE:
  DO
    SERIAL REC X
    GETKEY K
    IF K = 27 THEN LOOP UNTIL K = 27
    IF K = 27 THEN RETURN
  LOOP UNTIL X > 0

  REM find out which protocol to use
  IF X = 17 THEN GOSUB RECFILE
  IF X = 18 THEN GOSUB RECPIC
  IF X = 19 THEN GOSUB MESSAGE

  REM or if it is disconnect
  IF X = 27 THEN E = 0
  IF X = 27 THEN PRINT "Disconnected"
  IF X = 27 THEN PRINT "Awaiting Connecting, press escape to cancel..."
  IF X = 27 THEN GOTO WAITCON
GOTO WAITTYPE

RECFILE:
  PRINT "Recieving file..."
  REM recieve filename terminated by 25 (EM)
  X = 1
  DO
    SERIAL REC W
    IF W = 0 THEN W = 32
    IF W = 25 THEN W = 0
    STRING SET $1 X W
    X = X + 1
  LOOP UNTIL W = 0

  REM recieve filesize upper+lower
  SERIAL REC X
  SERIAL REC Y
  S = X * 256
  S = S + Y

  REM wait for file start
  DO
    SERIAL REC X
  LOOP UNTIL X = 2

  REM recieve file
  S = S + 58000
  FOR X = 58000 TO S
    SERIAL REC W
    POKE W X
  NEXT X
  S = S - 58000

  REM get file end
  DO
    SERIAL REC X
  LOOP UNTIL X = 3

  PRINT "Recieved file: " ;
  PRINT $1
  SAVE $1 58000 S
  IF R > 0 THEN GOSUB SAVEERR

  REM okay, now wait for another instruction
  X = 0
RETURN

SAVEERR:
  IF R = 2 THEN GOTO EXISTS
  $E = "Read-only Disk!"
  GOTO ERRBOX

EXISTS:
  $T = "Save Error"
  $5 = "File exists, enter a new"
  $6 = "name to save the file as."
  V = 1
  GOSUB INPBOX
  SAVE $I 58000 S
  IF R > 0 THEN GOTO SAVEERR
  PRINT "File saved as: " ;
  PRINT $I
RETURN

RECPIC:
  PRINT "Recieving picture..."
  X = 1
  DO
    SERIAL REC W
    IF W = 0 THEN W = 32
    IF W = 25 THEN W = 0
    STRING SET $1 X W
    X = X + 1
  LOOP UNTIL W = 0

  DO
    SERIAL REC X
  LOOP UNTIL X = 2

  FOR X = 58000 TO 60001
    SERIAL REC W
    POKE W X
  NEXT X
 
  V = 58000
  GOSUB PICTOTXT

  CLS
  C = 7
  MOVE 0 0
  V = 58000
  X = 80
  Y = 24
  GOSUB ANCITEXT
  C = 4

  WAITPIC:
  WAITKEY K

  $T = $1
  $5 = "Save Picture"
  $6 = "Discard Picture"
  $7 = "Cancel"
  $8 = ""
  $9 = ""
  GOSUB MENUBOX

  IF V = 1 THEN GOTO SAVEPIC
  IF V = 2 THEN GOTO DISCPIC
  IF V = 3 THEN GOTO WAITPIC

SAVEPIC:
  SAVE $1 58000 2001
  IF R > 0 THEN GOTO SAVEERR

DISCPIC:
  CLS
  RETURN
