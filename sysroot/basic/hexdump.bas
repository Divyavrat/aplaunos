rem *** Hex dumper ***

print "Enter a filename:"
input $1

x = RAMSTART

load $1 x
if r = 1 then goto error

loop:
  peek a x
  print hex a ;
  print "  " ;
  x = x + 1
  s = s - 1
  if s = 0 then goto finish
  goto loop

finish:
print ""
end

error:
print "Could not load file!"
end