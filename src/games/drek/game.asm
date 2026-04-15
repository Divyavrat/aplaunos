;   This program is free software: you can redistribute it and/or modify
;   it under the terms of the GNU General Public License as published by
;   the Free Software Foundation, either version 3 of the License, or
;   (at your option) any later version.
;
;    This program is distributed in the hope that it will be useful,
;    but WITHOUT ANY WARRANTY; without even the implied warranty of
;    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;    GNU General Public License for more details.
;
;    You should have received a copy of the GNU General Public License
;    along with this program.  If not, see <http://www.gnu.org/licenses/>.
;	
;	Copywrite Sean Haas, Tristan Spincer 2011-12

pit db 'You fall into a spiked pit, you die!',13,10,'Respawn!',13,10,13,10,0
seeknife db 'You see a knife',13,10,0
youhasknife db 'You are holding a knife',13,10,0
nsew db 'north, south, east, west',0
swe db 'south, east, west',0
nwe db 'north, east, west',0
nsw db 'north, south, west',0
we db 'east, west',0
sw db 'south, west',0
ns db 'north, south',0
ne db 'north, east',0
se db 'south, east',0
nw db 'north, west',0
nse db 'north, south, east',0
n db 'north',0
s db 'south',0
e db 'east',0
w db 'west',0
read db 'read',0
grab db 'grab',0
stab db 'stab',0
moves db 0
hasknife db 0
isknife db 0
qphys db 0

getinput:
	mov si,.prmpt
	call print
	mov di,buffer
	call input
ret
	.prmpt db '>',0

cmdshell:
	mov si,reboot
	call compare
	jc .rebootcmd
	
	mov si,n
	call compare
	jc .north
	
	mov si,s
	call compare
	jc .south

	mov si,e
	call compare
	jc .east

	mov si,w
	call compare
	jc .west

	mov si,read
	call compare
	jc .read

	mov si,grab
	call compare
	jc .grab

	mov si,stab
	call compare
	jc .stab

	mov ax,'er'
	jmp .done
.rebootcmd:
	call reboot1
	jmp .done
.north:
	mov al,'n'
	jmp .done
.south:
	mov al,'s'
	jmp .done
.east:
	mov al,'e'
	jmp .done
.west:
	mov al,'w'
	jmp .done
.read:
	mov al,'r'
	jmp .done
.grab:
	mov al,'g'
	cmp byte[isknife],1
	jne .done
	mov byte[hasknife],1
	mov si,youhasknife
	call print
	jmp .done
.stab:
	mov al,'k'
	jmp .done
.done:
ret

startroom:
	push di
	call print
	call printret
	mov si,.cango
	call print
	pop si
	call print
	call printret
	call printret

	call getrnd
	cmp al,80
	jge .isknife
	jmp .getinput
.isknife:
	cmp byte[qphys],0
	je .getinput
	cmp byte[hasknife],1
	je .getinput
	mov byte[isknife],1
	mov si,seeknife
	call print
.getinput:
	mov di,buffer
	call getinput
	mov di,buffer
	call cmdshell
	cmp ax,'er'
	je .getinput

	add byte[moves],1
ret
	.cango db 'You can go:',13,10,0

room1:
	mov si,.info
	mov di,nwe
	call startroom
	
	cmp al,'n'
	je .room2

	cmp al,'e'
	je .room4

	cmp al,'w'
	je .room5
	jmp .done
.room2:
	jmp room2
.room4:
	jmp room4
.room5:
	jmp room5
.done:
	jmp room1
ret
	.info db 'You are in a dark room',0

room2:
	mov si,.info
	mov di,se
	call startroom
	
	cmp al,'s'
	je .room1

	cmp al,'e'
	je .room6
	jmp .done	
.room1:
	jmp room1
.room6:
	jmp room6
.done:
	jmp room2
ret
	.info db 'You enter a room with a sharp twist in one direction',13,10,'The walls are a dark brick. You see an oak door to your right.',0

room3:
	mov si,.info
	mov di,se
	call startroom
	
	cmp al,'e'
	je .room24

	cmp al,'s'
	je .boss
	jmp .done	
.room24:
	jmp room24
.boss:
	jmp boss
.done:
	jmp room3
ret
	.info db 'This is a beautiful traditional Japanese room',13,10,'the floors are made of straw mats, and a very comfy under your feet',13,10,'You guiltily acknowledge you shouldn’t be wearing your shoes',13,10,'You can Throw upon the Paper Screen doors to your SOUTH or EAST',13,10,'The door to your South seems to distort slightly',13,10,'you can even see disturbing shadows behind it',13,10,'Most likely illusions caused by the setting sun.',0	

room4:
	mov si,.info
	mov di,we
	call startroom

	cmp al,'r'
	je .read

	cmp al,'w'
	je .room1

	cmp al,'e'
	je .room21
	jmp .done
.read:
	mov si,.book
	call print
	call printret
	jmp room4
.room1:
	jmp room1
.room21:
	jmp room21
.done:
	jmp room4
ret
	.info db 'You are in a library',13,10,'The walls are lined with books',13,10,'their leather spines enlayed with flourishes of gold',13,10,'You see an open book sitting in a table in the middle of the room',0
	.book db 'Welcome to the Castle Dreckig',13,10,'`Tis a maze of dungeons',13,10,'You must find a weapon, escape the maze, and kill Cthulhu',13,10,'...or DIE',13,10,0

room5:
	mov si,.info
	mov di,ne
	call startroom

	cmp al,'e'
	je .room1

	cmp al,'n'
	je .room7
	jmp .done
.room1:
	jmp room1
.room7:
	jmp room7
.done:
	jmp room5
ret
	.info db 'This Room is distinctly curved. It’s decorated with paintings',13,10,'It appears to be the beginnings of a large art gallery',13,10,'The painting on the wall are highly disturbing.',0

room6:
	mov si,.info
	mov di,nw
	call startroom
	
	cmp al,'w'
	je .room2

	cmp al,'n'
	je .room10
	jmp .done
.room2:
	jmp room2
.room10:
	jmp room10
.done:
	jmp room6
ret
	.info db 'This room Is luxuriously decorated, as well as padded.',13,10,'A lush red and gold hue stains the entire room. Like a cell for a king.',0

room7:
	mov si,.info
	mov di,ns
	call startroom

	cmp al,'s'
	je .room5

	cmp al,'n'
	je .room8
	jmp .done
.room5:
	jmp room5
.room8:
	jmp room8
.done:
	jmp room7
ret
	.info db 'This rooms a continuation of the art Gallery',13,10,'Its walls are covered in ghastly runes though',13,10,'And the paintings are slightly crooked',13,10,' You are besieged by pictures of beings so strange that they have no basis in reality',13,10,'If only they didn’t look so real.',0

room8:
	mov si,.info
	mov di,nse
	call startroom

	cmp al,'s'
	je .room7
	
	cmp al,'e'
	je .room9

	cmp al,'n'
	je .room12
	jmp .done
.room7:
	jmp room7
.room9:
	jmp room9
.room12:
	jmp room12
.done:
	jmp room8
ret
	.info db 'This room has a jagged ceiling. Actually wait, the ceiling is covered in spikes',13,10,'The floor is grated and stained a Rusty red',13,10,'Two Blood soaked iron bolted doors are forward and right.',0

room9:
	mov si,.info
	mov di,we
	call startroom

	cmp al,'w'
	je .room8

	cmp al,'e'
	je .room10
	jmp .done
.room8:
	jmp room8
.room10:
	jmp room10
.done:
	jmp room9
ret
	.info db 'The Door opens to reveal a room full of disconnected telephones.',13,10,'All from different years, many of them are ancient, and quite a few are new',13,10,'You pick one up and hold it to your ear.',13,10,'The lines busy. Another door lies ahead of you.',0

room10:
	mov si,.info
	mov di,swe
	call startroom

	cmp al,'s'
	je .room6
	
	cmp al,'w'
	je .room9

	cmp al,'e'
	je .room11
	jmp .done
.room6:
	jmp room6
.room9:
	jmp room9
.room11:
	jmp room11
.done:
	jmp room10
ret
	.info db 'This room is entirely and totally bare. The walls are black, smooth, unyielding',13,10,'Its pitch black too.',13,10,'After groping around in the darkness for a while you find a few doors.',0

room11:
	mov si,.info
	mov di,w
	call startroom

	pusha
	call getrnd
	cmp al,50
	jge .die
	popa

	cmp al,'w'
	je .room10

	cmp al,'r'
	je .read
	jmp .done
.room10:
	jmp room10
.die:
	popa
	mov byte[qphys],0
	mov byte[hasknife],0
	mov si,pit
	call print
	jmp room1
.read:
	mov si,.sign
	call print
	call printret
.done:
	jmp room11
ret
	.info db 'You enter a room full of bottles and flasks',13,10,'It is lit in a strangely white, sterile, ligth',13,10,'Obviously some kind of laboratory',13,10,'You see a chalkboard with a message on it',0
	.sign db 'In this land quantum physics work on the macro scale',13,10,'Object phase in and out of reality',13,10,0

room12:
	mov si,.info
	mov di,nsew
	call startroom

	cmp al,'s'
	je .room8

	cmp al,'w'
	je .room13

	cmp al,'e'
	je .room15

	cmp al,'n'	
	je .room14
	jmp .done
.room8:
	jmp room8
.room13:
	jmp room13
.room14:
	jmp room14
.room15:
	jmp room15
.done:
	jmp room12
ret
	.info db 'The bloody doors swing into a soothing darkness',13,10,'A planetarium lights the ceiling above you',13,10,'You have the feeling an entire universe is suspended just beyond your reach.',0

room13:
	mov si,.info
	mov di,e
	call startroom

	pusha
	call getrnd
	cmp al,50
	jge .die
	popa

	cmp al,'e'
	je .room12
	jmp .done
.room12:
	jmp room12
.die:
	popa
	mov byte[qphys],0
	mov byte[hasknife],0
	mov si,pit
	call print
	jmp room1
.done:
	jmp room13
ret
	.info db 'A bloody corpse faces the wall splayed out along a dark mahogany desk',13,10,'largely eaten away by mysterious wounds',13,10,'You can hear whispers in this room',13,10,'You investigate further, touching the body',13,10,'the body is a painting on the floor, and with the right light,',13,10,'extremely realistic',13,10,'The whispers abruptly stop.',0

room14:
	mov si,.info
	mov di,ns
	call startroom

	cmp al,'s'
	je .room12

	cmp al,'n'
	je .room18
	jmp .done
.room12:
	jmp room12
.room18:
	jmp room18
.done:
	jmp room14
ret
	.info db 'This room is an extremely long staircase',13,10,'its going downwards into a place that seems to be getting hotter and hotter',13,10,'The smell of sulfur rises from the bottom, surely you think, you are descending into hell.',0

room15:
	mov si,.info
	mov di,nw
	call startroom

	cmp al,'w'
	je .room12
	
	cmp al,'n'
	je .room16
	jmp .done
.room12:
	jmp room12
.room16:
	jmp room16
.done:
	jmp room15
ret
	.info db 'This room was obviously for science. Lots of floating things in jars',13,10,'There dead eyes seem to be staring at you',13,10,'following you intently around the room. So many indescribable animals...',0

room16:
	mov si,.info
	mov di,ns
	call startroom

	cmp al,'s'
	je .room15

	cmp al,'n'
	je .room17
	jmp .done
.room15:
	jmp room15
.room17:
	jmp room17
.done:
	jmp room16
ret
	.info db 'This room is covered in Xs scrawled in black ichor',13,10,'across an otherwise white wall',13,10,'The door is especially well marked',13,10,'The floor below you is grated, only darkness is below',13,10,'it feels like walking over a chasm.',0

room17:
	mov si,.info
	mov di,s
	call startroom

	cmp al,'s'
	je .room16

	cmp al,'g'
	je .grab
	jmp .done
.room16:
	jmp room16
.grab:
	mov byte[qphys],1
	mov si,.fail
	call print
	call printret
.done:
	jmp room17
ret
	.fail db 'The knife disapears from your hand',13,10,0
	.info db 'You shudder slightly as you enter this room',13,10,'A frightening ragdoll scarecrow is propped up in a chair',13,10,'hands folded over each other, it`s smiling at you, a soulless smile',13,10,'It seems to want you to do something. But what, you do not know',13,10,'You see a knife',0

room18:
	mov si,.info
	mov di,sw
	call startroom

	cmp al,'s'
	je .room14
	
	cmp al,'w'
	je .room19
	jmp .done
.room14:
	jmp room14
.room19:
	jmp room19
.done:
	jmp room18
ret
	.info db 'The room flattens out into a naturally angled cave',13,10,'a deep dank cavern that crawls with centipedes',13,10,'larger than your arms and thicker than your wrists',13,10,'They seem to clear a path for you',13,10,'you hope they do not merge back together again',13,10,'swallowing you up in a sea of chitin.',0

room19:
	mov si,.info
	mov di,se
	call startroom

	cmp al,'e'
	je .room18
	
	cmp al,'s'
	je .room20
	jmp .done
.room18:
	jmp room18
.room20:
	jmp room20
.done:
	jmp room19
ret
	.info db 'You Emerge into a room full of nothing but doors, doors and more doors',13,10,'You try them all, none of them work. You spot a staircase that emanates heat',13,10,'and the stench of rotting eggs directly ahead of you.',0

room20:
	mov si,.info
	mov di,n
	call startroom

	pusha
	call getrnd
	cmp al,50
	jge .die
	popa

	cmp al,'n'
	je .room19

	cmp al,'g'
	je .grab
	jmp .done
.room19:
	jmp room19
.grab:
	mov si,.fail
	call print
	jmp .dienow
.die:
	popa
	mov si,pit
	call print
	.dienow:
	mov byte[qphys],0
	mov byte[hasknife],0
	jmp room1
.done:
	jmp room20
ret
	.info db 'The staircase leads to what isnt hell.',13,10,'But in fact a vast frozen lake, you walk over its glacial surface',13,10,'admiring the beauty of the nothingness underneath',13,10,'Yet in the center, the ice is clear',13,10,'You peer in closely to see a beautiful lady holding a sword',13,10,'that seems to pour out raw power.',13,10,'You don`t want to wake her',13,10,'Something tells you that unless she liked you, that would be very bad indeed.',0
	.fail db 'As you reach out you slip on the ice and fall, waking the frozen female.',13,10,'She beheads you! The blood is great.',13,10,0

room21:
	mov si,.info
	mov di,nsw
	call startroom

	cmp al,'n'
	je .room22

	cmp al,'s'
	je .room23
	
	cmp al,'w'
	je room4
	jmp .done
.room22:
	jmp room22
.room23:
	jmp room23
.room4:
	jmp room4
.done:
	jmp room21
ret
	.info db 'This room has a window. It shows the beauty and serenity of a natural scene',13,10,'You could stay here forever, but the sun is setting',13,10,'the promise of darkness seems to swallow up all the beauty of nature.',0

room22:
	mov si,.info
	mov di,se
	call startroom

	cmp al,'s'
	je .room21

	cmp al,'e'
	je .room25
	jmp .done
.room21:
	jmp room21
.room25:
	jmp room25
.done:
	jmp room22
ret
	.info db 'This Room is full of Taxidermy. The centerpiece being a large dead moose',13,10,'Its expression is rather jolly, so you move forward to pet it',13,10,'The skin falls off to reveal a much less friendly skeleton',13,10,'As does the skin of every other piece, it’s a cruel practical joke by some connoisseur of taxidermy, clearly',0

room23:
	mov si,.info
	mov di,nw
	call startroom

	cmp al,'n'
	je .room22

	cmp al,'w'
	je .room24
	jmp .done
.room22:
	jmp room22
.room24:
	jmp room24
.done:
	jmp room23
ret
	.info db 'This room is rather empty, yet the floor is dominated by a Blue shag carpet',13,10,'lined along the carpet are dozens of rat holes',13,10,'You can definitely hear the chattering of rats',0	

room24:
	mov si,.info
	mov di,we
	call startroom

	cmp al,'w'
	je .room3
	
	cmp al,'e'
	je .room23
	jmp .done
.room3:
	jmp room3
.room23:
	jmp room23
.done:
	jmp room24
ret
	.info db 'This room is entirely Rococo',13,10,'you recognize the delicate architecture and nearly flawless quality of design',13,10,'You wonder, Where did you learn of Rococo even? History class perhaps?',13,10,'Ahead of you, you see a Japanese paper door that is very',13,10,'out of place with the Baroque architecture.',0

room25:
	mov si,.info
	mov di,we
	call startroom

	cmp al,'w'
	je .room22

	cmp al,'e'
	je .fail
	jmp .done
.fail:
	add byte[.trys],1
	cmp byte[.trys],5
	jl .done
	mov si,.die
	call print
	call printret
	mov byte[qphys],0
	mov byte[hasknife],0
	mov byte[.trys],0
	jmp room1	
.room22:
	jmp room22
.done:
	jmp room25
ret
	.info db 'Youa are in an infinite hallway',0
	.trys db 0
	.die db 'What part of infinite do you not get?',13,10,'Your head explodes while contemplating this! The blood is great.',13,10,'Respawn!',13,10,0
	
boss:
	mov si,.info
	mov di,n
	call startroom
	
	cmp al,'k'
	je .stab
	jmp .done
.stab:
	cmp byte[hasknife],0
	je .done
	mov byte[hasknife],0
	mov si,.win	
	call print
	mov ax,moves
	call tostring
	mov si,ax
	call print
	call printret
	mov byte[moves],0
	mov byte[qphys],0
	jmp room1
.done	:
	mov si,.dead
	call print
	call printret
	mov byte[hasknife],0
	mov byte[qphys],0
	mov byte[moves],0
	jmp room1
ret
	.dead db 'Cthulhu kills and eats you',13,10,'Respawn',13,10,0
	.win db 'You kill Cthuhlu!',13,10,'Free replay!',13,10,0
	.info db 'You have reached a long stone hallway',13,10,'You see the exit in the distance guarded by Cthulhu',13,10,'who notices your presence and starts to lurch toward you',0

getrnd:				;Psudo-Random number generator
	mov ax,0	
	in al,40h
	mov ah,[void]
	xor al,ah
	mov ah,0
ret