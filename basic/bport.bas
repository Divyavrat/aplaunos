main:
cls
print ""
print "Give command : " ;
input a
if a > 7 then alert " Command may cause error."
if a > 7 then goto main

print "Sending 'Set LED' command."
port out 96 237

print "Sending LED status."
port out 96 a

print "Done."
print " Do you want to continue (y/n) : "
waitkey a
if a = 'y' then goto main
end
                                                                                                                                                                                                                                 