rem *** CompTron ***
cls
print "You control a vehicle leaving a trail behind it."
print ""
print "It is always moving, and if it crosses any part"
print "of the trail or border (+ characters), the game"
print "is over. Use the W and S keys to change the direction"
print "to up and down, and A and D for left and right."
print "(Or Arrow keys)"
print "See how long you can survive! Score at the end."
print ""
print "NOTE: May perform at wrong speed in emulators!"
print ""
print "Hit a key to begin..."
waitkey x
cls
cursor off
rem *** Draw border around screen ***
gosub setupscreen
rem *** Start in the middle of the screen ***
x = 40
y = 12
rem move x y
rem *** Movement directions: 1 - 4 = up, down, left, right ***
rem *** We start the game moving right ***
d = 4
rem *** S = score variable ***
s = 0
mainloop:

move x y
print "+" ;

pause 1
getkey k

if k = 'w' then d = 1
if k = 's' then d = 2
if k = 'a' then d = 3
if k = 'd' then d = 4
if k = 1 then d = 1
if k = 2 then d = 2
if k = 3 then d = 3
if k = 4 then d = 4

if d = 1 then y = y - 1
if d = 2 then y = y + 1
if d = 3 then x = x - 1
if d = 4 then x = x + 1

if k = 'q' then goto finish
move x y
curschar c
if c = '+' then goto finish
s = s + 1

rem if x < 0 then x = 78
rem if x > 78 then x = 0
rem if y < 0 then y = 24
rem if y > 24 then y = 0

goto mainloop
finish:
cursor on
cls
print "Your score was: " ;
print s
print "Press Esc to finish"
escloop:
  waitkey x
  if x = 27 then end
  goto escloop
  
setupscreen:
move 0 0
for x = 0 to 78
print "+" ;
next x
move 0 24
 
for x = 0 to 78
print "+" ;
next x
move 0 0
  
for x = 0 to 24
move 0 x
print "+" ;
next x

move 78 0
for x = 0 to 24
move 78 x
print "+" ;
next x
return