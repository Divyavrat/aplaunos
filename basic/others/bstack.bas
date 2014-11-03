cls
s = 28672
mainloop:
print " "
print " 1. Show stack"
print " 2. Push"
print " 3. Pop"
print " 4. Exit"
print " "
print " Press choice : " ;
print " "
waitkey a
if a = 49 then goto showstack
if a = 50 then goto pushstack
if a = 51 then goto popstack
if a = 52 then end
rem Exit key = 52
print "You pressed :" ;
print a ;
print ":" ;
print chr a ;
print ""
goto mainloop

showstack:
print " Stack has : " ;
a = s - 13
stackloop:
peek c a
print c ;
print ":" ;
print chr c ;
print " " ;
b = s - 2
if a > b then goto mainloop
a = a + 1
goto stackloop

pushstack:
print " Press a character to push : " ;
waitkey a
print a ;
print ":" ;
print chr a ;
poke a s
s = s + 1
goto mainloop

popstack:
print " Character Popped : " ;
s = s - 1
peek c s
rem Stack
print c ;
print ":" ;
print chr c ;
rem s
goto mainloop