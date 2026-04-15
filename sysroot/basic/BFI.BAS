rem ################INFORMATION################################################
rem Brain*** Interpreter for MikeBASIC (BFI.BAS)
rem Version 1.0.1
rem Created by Joshua Beck
rem Licenced under the GNU General Public Licence revision 3
rem Requires MikeOS 4.3 beta 6 or better

rem ###############CONFIGURATION###############################################
rem first memory cell
f = 60000
rem last memory cell
l = 60255
rem current memory cell
c = f
rem loop location storage
u = 59900
t = u

rem ##############PROGRAM-START################################################
rem blank all the memory cells
for w = f to l
  poke 0 w
next w
  
rem did they specify a file?
if $1 = "" then goto startint
cursor off

prepfile:
  rem figure out how much space we have
  j = u - 50000

  rem check if file is too big
  size $1
  if r = 1 then goto badfile
  if s > j then goto largefile
  
  rem load the file
  load $1 50000

  rem did the file load successfully?
  if r = 1 then goto badfile

  rem instruction pointer to start of file
  i = 50000
goto runcode

startint:
  rem prompt for code
  print "Input code> " ;
  input $1

  rem instruction pointer to input string
  i = & $1

  cursor off
goto runcode

badfile:
  print "File: " ;
  print $1 ;
  print " could not be found."
goto endprog

largefile:
  print "File: " ;
  print $1 ;
  print " is too big to be loaded."
goto endprog

runcode:
  rem get instruction
  peek b i

  rem end on a null
  if b = 0 then goto endprog

  rem check keypress
  getkey z
  if z = 27 then goto endprog
  if z = 'I' then z = 'i'
  if z = 'i' then j = m
  if z = 'i' and j = 0 then m = 1
  if z = 'i' and j = 1 then m = 0

  rem execute instruction
  gosub process

  rem increase instruction pointer
  i = i + 1

  rem if display is enabled draw it
  if m = 1 then gosub showmem

goto runcode

process:
  rem find out symbol, ignore else
  if b = '+' then gosub add
  if b = '-' then gosub take
  if b = '.' then gosub out
  if b = ',' then gosub in
  if b = '>' then gosub next
  if b = '<' then gosub back
  if b = '[' then gosub startloop
  if b = ']' then gosub endloop
return

add:
  peek z c
  z = z + 1
  if z > 255 then z = 0
  poke z c
return

take:
  peek z c
  z = z - 1
  if z < 0 then z = 255
  poke z c
return

next:
  c = c + 1
  if c > l then c = f
return

back:
  c = c - 1
  if c < f then c = l
return

in:
  cursor on
  waitkey z
  print chr z
  if z = 27 then goto endprog
  poke z c
  curspos x y
  y = y - 1
  x = x + 1
  move x y
  cursor off
return

out:
  peek z c
  if z = 10 then print ""
  if z = 10 then return
  print chr z ;
return

startloop:
  peek z c
  if z > 0 then u = u + 2
  w = 0
  if z = 0 then goto jmpend
  w = i / 256
  poke w u
  u = u + 1
  v = i % 256
  poke v u
return

endloop:
  peek z c
  if z = 0 then u = u - 2
  if u < t then goto fatalcb
  if z = 0 then return
  peek z u
  u = u - 1
  peek w u
  w = w * 256
  i = w + z
  i = i - 1
  u = u - 2
  if u < t then goto fatalcb
return  
  
fatalcb:
  move 0 21
  print "Closing bracket without opening!"
goto endprog

jmpend:
  i = i + 1
  peek z i
  if z = '[' then w = w + 1
  if z = ']' and w = 0 then return
  if z = ']' then w = w - 1
goto jmpend

showmem:
  curspos x y
  move 0 20
  v = f
  print "                                                           " ;
  move 0 20
  for w = 1 to 10
    peek z v
    v = v + 1
    print z ;
    print " ";
  next w
  move 0 22
  print "                                                           ";
  move 0 22
  print i ;
  print " " ;
  w = c - f
  print w ;
  print " " ;
  print chr b ;
  move 40 22
  print " ";
  print u ;
  waitkey k
  if k = 'I' then k = 'i'
  if k = 'i' then gosub clearinfo
  if k = 27 then goto endprog
  move x y
return

clearinfo:
  move 0 20
  for z = 20 to 22
    for v = 0 to 79
      print " ";
    next v
  next z
  m = 0
return

endprog:
  print ""
  cursor on
end
