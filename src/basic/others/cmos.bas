rem Prints values from CMOS
ink 4
print "CMOS:" ;
ink 7
for i = 0 to 50
gosub reg
next i
print ""
ink 4
print "Time :" ;
ink 2
i = 4
gosub reg
i = 2
gosub reg
i = 0
gosub reg
print ""
ink 4
print "Date :" ;
ink 6
gosub weekday
ink 2

i = 7
gosub reg
i = 8
gosub reg
i = 50
gosub reg
i = 9
gosub reg
end

reg:
port out 112 i
port in 113 r
print ":" ;
print hex r ;
return

weekday:
port out 112 6
port in 113 r
if r = 0 then print "Sun" ;
if r = 1 then print "Mon" ;
if r = 2 then print "Tue" ;
if r = 3 then print "Wed" ;
if r = 4 then print "Thur" ;
if r = 5 then print "Fri" ;
if r = 6 then print "Sat" ;
if r = 7 then print "Sun" ;
return
