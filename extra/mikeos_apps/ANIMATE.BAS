  GOSUB PUTSPRITE
START:
  REM clear both video pages
  PAGE 0 0
  CURSOR OFF
  CLS
  PAGE 1 1
  CLS
  CURSOR OFF
  PAGE 0 0

MAIN:
  REM continously move the sprite in the direction of a key press of WASD keys
  REM enter (13) to stop and escape (27) to quit

  REM get a key, don't wait
  GETKEY K

  REM did they press escape?
  IF K = 27 THEN GOSUB ENDPROG

  REM if it's  a lowercase, make it capital
  IF K > 96 AND K < 123 THEN K = K - 32

  REM did they press 't' to toggle case?
  J = E
  IF K = 'T' AND J = 1 THEN E = 0
  IF K = 'T' AND J = 1 THEN GOTO START
  IF K = 'T' AND J = 0 THEN E = 1

  REM did they change the direction?
  IF K = 'W' THEN D = 1
  IF K = 'S' THEN D = 2
  IF K = 'A' THEN D = 3
  IF K = 'D' THEN D = 4

  REM did they press enter to stop movement?
  IF K = 13 THEN D = 0

  REM did they press Q or E to change speed
  IF K = 'Q' THEN G = G / 2
  IF K = 'E' AND G < 17 THEN G = G * 2
  IF K = 'E' AND G = 0 THEN G = 1

  REM move the sprite in the specified direction
  REM if no key was press then it will be the same as last time
  GOSUB MOVESPRITE

  REM wait between movement
  PAUSE G

GOTO MAIN

MOVESPRITE:
  REM code to move the sprite in a direction (D)

  REM switch video pages, draw on the non-visible page
  IF E = 0 THEN IF V = 0 THEN PAGE 0 1
  IF E = 0 THEN IF V = 1 THEN PAGE 1 0

  REM remove the old sprite
  GOSUB NOSPRITE

  REM move sprite co-ordinents
  REM if D = 0 then it won't move
  IF D = 1 THEN Y = Y - 1
  IF D = 2 THEN Y = Y + 1
  IF D = 3 THEN X = X - 1
  IF D = 4 THEN X = X + 1

  REM check the sprite isn't off the screen
  IF X > 70 THEN X = 70
  IF X < 0 THEN X = 0
  IF Y > 17 THEN Y = 17
  IF Y < 0 THEN Y = 0

  REM place the sprite on the screen
  GOSUB PUTSPRITE

  REM swap display and working page
  REM display the page that was just drawn
  IF E = 0 THEN IF V = 0 THEN PAGE 0 0
  IF E = 0 THEN IF V = 1 THEN PAGE 1 1

  REM switch the page variable
  IF E = 0 THEN J = V
  IF E = 0 THEN IF J = 0 THEN V = 1
  IF E = 0 THEN IF J = 1 THEN V = 0

  REM print the page that we are on
  MOVE 0 0
  IF V = 0 THEN PRINT "Page 0"
  IF V = 1 THEN PRINT "Page 1"

  REM invert colour to black on white
  INK 112

  REM print bottom messages
  MOVE 0 23
  PRINT "Use WASD to move the character, enter to stop and escape to quit." ;
  MOVE 0 24
  PRINT "Q to speed up and E to slow down T to toggle page switching." ;

  REM back to white on black
  INK 7
RETURN

PUTSPRITE:
  P = X
  Q = Y
  R = 1
  FOR S = 0 TO 4
    FOR T = 0 TO 9
      MOVE X Y
      READ SPRITE R J 
      PRINT CHR J ;
      X = X + 1
      R = R + 1
    NEXT T
    X = P
    Y = Y + 1
  NEXT S
  X = P
  Y = Q
RETURN

NOSPRITE:
  Q = Y
  Y = Y - 1
  FOR S = 0 TO 6
    MOVE X Y
    PRINT "          " ;
    Y = Y + 1
  NEXT S
  Y = Q
RETURN

SPRITE:
032 222 219 219 219 219 219 219 221 032
032 032 186 219 219 219 219 186 032 032
032 032 186 219 221 222 219 186 032 032
032 032 186 219 219 219 219 186 032 032
032 222 219 219 219 219 219 219 221 032

ENDPROG:
  CURSOR ON
  PAGE 1 1
  CLS
  PAGE 0 0
  CLS
END
