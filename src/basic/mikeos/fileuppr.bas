rem *** Text file uppercaser ***

print "Enter a filename:"
input $1

x = RAMSTART

load $1 x
if r = 1 then goto error

c = s

loop:
  peek a x

  if a < 97 then goto skip
  if a > 122 then goto skip

  a = a - 32
  poke a x

skip:
  x = x + 1
  c = c - 1

  if c = 0 then goto finish
  goto loop


finish:
print "Enter filename to save to:"
input $2

x = RAMSTART

save $2 x s
if r = 1 then goto error
print "File uppercased and saved!"
end

error:
print "File error!"
end