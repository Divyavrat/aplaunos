rem Level Editor for RTS game (LVLEDIT.BAS)
rem Version 1.0.2
rem A modified version of ASCII Artist
rem Uses the MikeBASIC++ library, Version 3
rem Released under the GNU General Public Licence revision 3
rem If you have any comments or changes send them to mikeosdeveloper@gmail.com

INCLUDE "MBPP.BAS"

preload:
  print "loading..."
  cls
  gosub blank
  if $1 = " " then $1 = ""
  if $1 = "" then goto nopara
  x = & $1
  gosub capitalise
  load $1 60000
  if r = 0 then $2 = $1
  if r = 0 then goto nopara
  print "File '";
  print $1 ;
  print "' not found."
  end
  nopara:
  cursor off
  z = 61990
  for x = 1 to 10
    read keyval x y
    poke y z
    z = z + 1
  next x
  goto config


  keyval:
  255 178 220 219 221 254 222 176 223 177

  config:
  l = 1
  m = 1

start:
  $Y = "ENABLE"
  c = 4
  h = 12
  t = 4
  z = 4
  gosub border
  $T = "Level Editor for RTS Game  ---- Version 1.0.0"
  gosub settitle
  gosub content
  
titlemsg:
  o = 0
  gosub colchange
  $T = "About level editor"
  $5 = "Created by Joshua Beck"
  $6 = "Version 1.0"
  $7 = "Release under GNU GPLv3"
  $8 = "Uses MB++ version 3.0.0"
  $9 = "Make sure numpad is on!"
  gosub mesbox

keyboard:
  waitkey k
  if k = 1 then gosub keyup
  if k = 2 then gosub keydown
  if k = 3 then gosub keyright
  if k = 4 then gosub keyleft
  if k = 13 then gosub setvalues
  if k = 18 then gosub refresh
  if k = 19 then gosub saveover
  if k = 27 then gosub mainmenu
  if k > 47 and k < 58 then gosub numkey
  if k > 47 and k < 58 then goto keyboard
  if k > 31 and k < 127 then gosub otherkey
goto keyboard

mainmenu:
  gosub colchange
  $T = "            Options"
  $5 = "        Return to Editor"
  $6 = "          New/Load/Save"
  $7 = "              Help"
  $8 = "       Change number value"
  $9 = "              Exit"
  gosub menubox
  if v = 1 then gosub colchange
  if v = 1 then return
  if v = 2 then gosub filemenu
  if v = 3 then gosub help
  if v = 4 then gosub change
  if v = 5 then gosub askexit
  o = 0
  gosub colchange
goto mainmenu
 
filemenu:
  $T = "        File Operations"
  $5 = "            New Level"
  $6 = "           Load Level"
  $7 = "           Save Level"
  $8 = "        Save Level As..."
  $9 = "              Back"
  gosub menubox
  w = v
  v = 0
  if w = 1 then gosub newlevel
  if w = 2 then gosub loadfile
  if w = 3 then gosub saveover
  if w = 4 then gosub savefile
  if w = 5 then return
goto filemenu

askexit:
  $T = "         Quit Program"
  $5 = ""
  $6 = "Are you sure you want to exit"
  $7 = "from the level editor?"
  $8 = ""
  $9 = ""
  gosub askbox
  if v = 1 then goto endprog
return

capitalise:
  for y = 1 to 12
    peek z x
    if z > 96 and z < 123 then z = z - 32
    poke z x
    x = x + 1
  next y
return

newlevel:
  gosub blank
  gosub content
  $T = "New Level"
  $5 = "Enter the base terrain layer"
  $6 = "character value."
  v = 0
  gosub inpbox
  for x = 60000 to 61999
    poke v x
  next x
  gosub content
  w = 0
return

blank:
  for x = 60000 to 63999
    poke 0 x
  next x
return

colchange:
  x = l + 1
  y = m + 2
  move x y
  curscol j
  if u = 2 then move 2 23
  if u = 2 then print "                            " ;
  u = 1
  if j = 0 then u = 3
  if j = 7 then u = 3
  if j = 79 then u = 3
  if o = 0 and j < 16 then j = j + 72
  if o = 1 and j > 16 then j = j - 72
  ink j
  move x y
  curschar j
  print chr j ;
  ink 7
  j = o
  if j = 1 then o = 0
  if j = 0 then o = 1
  move 70 1
  print "         " ;
  move 70 1
  print "X:" ;
  print x ;
  print " Y:" ;
  print y
  if u = 3 then return
  gosub findobj
  w = v + 9
  if u = 2 then v = 1
  if u = 2 then return
  move 2 23
  print "Data: 0x" ;
  for x = v to w
    peek j x
    print hex j ;
  next x
return

keyup:
  if m = 1 then return
  gosub colchange
  m = m - 1
  gosub colchange
  return 
keydown:
  if m = 20 then return
  gosub colchange
  m = m + 1
  gosub colchange 
  return
keyright:
  if l = 1 then return
  gosub colchange
  l = l - 1
  gosub colchange
  return
keyleft:
  if l = 77 then return
  gosub colchange
  l = l + 1
  gosub colchange
  return
numkey:
  j = k - 48
  j = j + 61990
  peek i j
  e = l + 1
  f = m + 2
  move e f
  print chr i
  j = m - 1
  j = j * 80
  j = j + l + 59999
  poke i j
  o = 0
  gosub colchange
return

otherkey:
  e = l + 1
  f = m + 2
  move e f
  print chr k
  j = m - 1
  j = j * 80
  j = j + l + 59999
  poke k j
  o = 0
  gosub colchange
return

change:
  $T = "Change characters"
  $5 = "Enter number key to change."
  $6 = "10 to cancel."
  $E = "Must be  0 - 9!"
  v = 0
  gosub inpbox
  a = v
  if a = 10 then return
  if a > 9 then goto errbox
  if a < 0 then goto errbox
  poke a 61989
  $5 = "Input a new decimal value for the key"
  $6 = "between 0 and 255."
  $E = "Must be 0 - 255!"
  v = 0
  gosub inpbox
  b = V
  peek a 61989
  if b > 255 then goto errbox
  if b < 0 then goto errbox
  j = 61990 + a
  poke b j
  return
help:
  $T = "              Help"
  $5 = "Use the arrows to move the cursor"
  $6 = "around the screen."
  $7 = "Use the numbers on the numpad to put "
  $8 = "to write characters to screen." 
  $9 = "You can save your work with Ctl+S."
  gosub mesbox
  $5 = "You can change the character"
  $6 = "value produced by a number key."
  $7 = "You can also use keyboard keys."
  $8 = "Press escape for the menu."
  $9 = "Press enter to create and edit units."
  gosub mesbox
return

savefile:
  $T = "Save"
  move 26 10 
  $5 = "Enter an 8.3 type filename to save"
  $6 = "level as (ie foo.lvl)."
  $E = "Invalid Filename!"
  v = 1
  gosub inpbox
  $1 = $I
  save $1 60000 4000
  o = 0
  gosub colchange
  if R = 2 then goto overwrite
  if R > 2 then $E = "Unknown Error!"
  if R > 0 then goto errbox
  $2 = $1
return

saveover:
  if $2 = "" then goto savefile
  $E = "File invalid! Did disk change?"
  delete $2
  save $2 60000 4000
  if r = 2 then $E = "Disk is read-only!"
  if r > 0 then goto errbox
return
  
overwrite:
  $T = "Warning!"
  $5 = ""
  $6 = "File already exists."
  $7 = "Do you wish to overwrite it?"
  $8 = ""
  $9 = ""
  gosub askbox
  if v = 0 then goto savefile
  delete $1
  $E = "Unknown Error!"
  if r = 2 then $E = "Read Only Disk!"
  if r > 0 then goto errbox
  save $1 60000 4000
  if r = 0 then $2 = $1
return

loadfile:
  $T = "Load"
  $5 = "Enter an 8.3 type filename to load"
  $6 = "from (ie foo.lvl)"
  $E = "File does not exist!"
  v = 1
  gosub inpbox
  load $I 60000
  if R > 1 then $E = "Unknown Error!"
  if R > 0 then goto errbox
  $2 = $I
  gosub refresh
  o = 0
  gosub colchange
return

content:
  ink 7
  for y = 3 to 22
    move 1 y
    print " " ;
    j = y - 3
    j = j * 80
    j = j + 60000
    for x = 2 to 78
      peek v j
      print chr v ;
      j = j + 1
    next x
  next y
  ink c
  o = 0
  gosub loadobj
  gosub colchange
return

loadobj:
  v = 62000
  for x = 0 to 199
    ink 7
    peek j v
    if j = 0 then v = v + 10
    if j = 0 then goto blankobj
    v = v + 1
    peek j v
    v = v + 4
    peek r v
    v = v + 1
    peek y v
    move r y
    v = v + 3
    peek y v
    y = y / 16
    y = y + 1
    ink y
    print chr j ;
    v = v + 1
    blankobj:
  next x
return
  
findobj:
  w = l + 1
  r = m + 2
  v = 62000
  incorrectobj:
    if v > 63999 then goto nosuchobj
    peek j v
    if j = 0 then v = v + 10
    if j = 0 then goto incorrectobj
    v = v + 5
    peek x v
    v = v + 1
    peek y v
    v = v + 4
    if w = x and r = y then v = v - 10
    if w = x and r = y then return
  goto incorrectobj
  nosuchobj:
  if u = 1 then u = 2
  if u = 2 then return
  v = 0
  $T = "Object not found"
  $5 = ""
  $6 = "There is no object at this position,"
  $7 = "Would you like to create a new one?"
  $8 = ""
  $9 = ""
  gosub askbox
  j = 0
  if v = 1 then j = 1
  if j = 1 then gosub regobj
  if j = 1 then gosub newobj
return
  
setvalues:
  gosub findobj
  if v = 0 then return
  w = v
  $T = "Change object"
  $5 = "Modify Health"
  $6 = "Move"
  $7 = "Change Character"
  $8 = "Modify Attack"
  $9 = "More..."
  gosub menubox
  if v = 1 then gosub chhealth
  if v = 2 then goto chpos
  if v = 3 then gosub chchar
  if v = 4 then gosub chattack
  if v = 5 then goto setvalues2  
  gosub content
goto setvalues

setvalues2:
  $5 = "Give Orders"
  $6 = "Change Team/Speed"
  $7 = "Kill"
  $8 = "Clone"
  $9 = "Exit"
  gosub menubox
  if v = 1 then gosub chord
  if v = 2 then gosub chteam
  if v = 3 then goto killunit
  if v = 4 then goto copyunit
  if v = 5 then goto content
goto setvalues2

chhealth:
  $T = "Modify Health"
  $5 = "Enter a new amount of health for the"
  $6 = "entity, must be between 1 and 254."
  v = 0
  gosub inpbox
  j = v
  v = 1
  if j = 255 then gosub askimmortal
  if v = 0 then return
  poke j w
  v = 0
return
  
askimmortal:
  $5 = ""
  $6 = "A value of 255 will make the unit"
  $7 = "immortal, are you sure?"
  $8 = ""
  $9 = ""
  gosub askbox
  if v = 1 then v = 255
return

chpos:
  $T = "Move"
  $5 = "Enter a new X axis for the entity"
  $6 = "Enter a new Y axis"
  v = 0
  gosub dinbox
  if a < 2 then goto chpos
  if b < 3 then goto chpos
  if a > 78 then goto chpos
  if b > 22 then goto chpos
  w = w + 5
  poke a w
  w = w + 1
  poke b w
  gosub content
  w = w - 6
  v = 0
return

chchar:
  $T = "Change Character"
  $5 = "Enter a new ASCII value for entity"
  $6 = ""
  v = 0
  gosub inpbox
  w = w + 1
  poke v w
  v = 0
  w = w - 1
return

chattack:
  $T = "Modify Attack"
  $5 = "Enter a new attack strength for the"
  $6 = "unit. 0 = no attack, max 254"
  v = 0
  gosub inpbox
  w = w + 2
  poke v w
  $5 = "Enter a new cooldown time (1-4)"
  $6 = "Enter a new attack range (up to 8)"  
  v = 0
  gosub dinbox
  w = w + 1
  peek j w
  j = j / 16
  j = j * 16
  j = j + b
  poke j w
  w = w + 1
  j = a * 16
  j = j + a
  poke j w
  w = w - 4
  v = 0
return  
  
chord:
  $T = "Give Orders"
  $5 = "Defend Area (0)"
  $6 = "Move (1)"
  $7 = "Attack Move (2)"
  $8 = "Attack (3)"
  $9 = "Other..."
  gosub menubox
  if v < 5 then v = v - 1
  if v = 5 then gosub custord
  w = w + 3
  peek j w
  j = j % 16
  v = v * 16
  j = v + j
  poke j w
  $5 = "Enter the destination column"
  $6 = "Enter the destination row"
  v = 0
  gosub dinbox
  w = w + 4
  poke a w
  w = w + 1
  poke b w
  v = 0
  w = w - 8
return
  
custord:
  $T = "Give Orders"
  $5 = "Enter the number of the order"
  $6 = "the range is 0-15."
  v = 0
  gosub inpbox
return

chteam:
  $T = "Change Team"
  $5 = "Neutral (0)"
  $6 = "Player (1)"
  $7 = "Allied (2)"
  $8 = "Enemy (3)"
  $9 = "Other Player (4)"
  gosub menubox
  v = v - 1
  j = v
  $T = "Change Type"
  $5 = "Non-mobile (0)"
  $6 = "Slow (1)"
  $7 = "Medium (2)"
  $8 = "Fast (3)"
  $9 = "More..."
  gosub menubox
  if v = 5 then gosub moretype
  v = v - 1
  j = j * 16
  j = j + v
  w = w + 9
  poke j w
  w = w - 9
  gosub content
  v = 0
return

moretype:
  $T = "More Types"
  $5 = "Flying (4)"
  $6 = "Production Building (5)"
  $7 = "Mineral (6)"
  $8 = ""
  $9 = ""
  gosub menubox
  v = v + 4
return
  
killunit:
  for j = 1 to 10
    poke 0 w
    w = w + 1
  next j
  w = w - 10
  gosub content
  v = 0
return

regobj:
  v = 62000
  do
    peek r v
    v = v + 10
  loop until r = 0
  v = v - 10
return

copyunit:
  gosub regobj
  for x = 1 to 10
    peek j w
    poke j v
    w = w + 1
    v = v + 1
  next x
  j = v
  $T = "Clone Entity"
  $5 = "Enter new clone column"
  $6 = "Enter new clone row"
  v = 0
  gosub dinbox
  j = j - 5
  poke a j
  j = j + 1
  poke b j
  w = w - 10
  gosub content
  v = 0
return

newobj:
  w = v
  $T = "New object"
  $5 = "Enter a health amount for new object"
  $6 = "Enter ASCII character for new object"
  v = 0
  gosub dinbox
  v = a
  if v = 255 then gosub askimmortal
  if v = 0 then goto newobj
  poke v w
  w = w + 1
  poke b w
  w = w + 4
  a = l + 1
  poke a w
  w = w + 1
  b = m + 2
  poke b w
  w = w - 6
  gosub loadobj
  v = w
return
