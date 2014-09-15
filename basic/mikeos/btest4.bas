cls
print ""
print "Include test"
p = PROGSTART
print "PROGSTART :" ;
print hex p
p = RAMSTART
print "RAMSTART :" ;
print hex p
print "Press a key..."
waitkey a
print "Including a hello file."
include "mbpp.bas"
print ""
print "Include complete"
print "Putting 305 at 10"
x = 10
v = 305
gosub arrayput
rand v 0 100
print "Getting 305 at 10"
x = 10
gosub arrayget
print v
print "SubFunction used"
end