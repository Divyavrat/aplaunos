WELCOME
=======

Anyone can make any program in Aplaun OS.
Source code of previous apps are provided.
They can be modified to create new apps.

How can I help ?
----------------

You can contribute and make -

1. Apps
2. Games
3. Utilities
4. Screen Savers
5. Compilers and Interpreters
6. Animations
7. Database Handlers
8. Common themes and custom packages for OS

We'd prefer if your contributions were well commented
for better understanding of its working and for ease in future use.

Tools and Softwares
-------------------

Following are the tools that can be used to create -

1. `asm` - asm4mo assembler to create any type of app.
2. `basic` - MikeBASIC interpreter to create any general software.
3. `batch` - scripts can be made for various automations.
4. `bfc` - Brainf** compiler to create mini apps for Aplaun.
5. `forth` - Interpreter to use a stack based language.
6. `basic.bas` - MikeBASIC interactive interpreter.
7. `bfi.bas` - Brainf** interpreter to run files and code
8. And ofcourse machine language coding can be done by `code` or `code2` commands.

Assembly `ASM` Syntax
=====================

All code must be org to 6000h by `org 6000h`
or org 24576 to create programs.

For creating a `asm` program -

1. Name your new file by - `fname'
2. Create a new file - `fnew`
3. Load it on memory - `q`
4. Edit and Write your Code - `edit`
5. Save your file - `fsave`
6. Assemble it - `asm acode.asm acode.bin`
7. Run it - `acode.bin`

Other than this any code can be used.
Common Operations for a program can be accessed
using API provided to apps in many interrupts
or System Calls at different locations.

For API list check the folder API in text folder.
It gives all interrupts and all their functions to select
with `ah` register.
Different API is provided in `int` 61h,64h,2Bh,21h,etc.
All default BIOS calls can also be used like `int 10h` .

For system calls check kernel.inc or mikedev.inc or tachyonos.inc.
It gives a list of locations that can be called to use the given function.

Common APIs provided -

1. Input / Output functions
2. User Interface
3. String and Variable operations.
4. Mouse Interrupts and Calls
5. File Handling Operations
6. Memory Manager
7. Sound and Misc calls

Program Template -
```nasm
org 6000h
;Your code goes here
ret
```

In OS, the `loc` setting defines where the
files are loaded and run from. Thus it defines
the memory location that the programs must org to.
Its default value is 6000h. Thus its used most commonly.

You can use API and System Calls to create
a more compact code with better efficiency.

Sample Program -

```nasm
;--------------------------
; Sample Hello World Program
; for Aplaun OS
;--------------------------

org 6000h ; org to default location

mov ah,03h ; Print String function
mov dx,hello_str ; Giving String Location
int 61h ; General API of Aplaun OS
ret ; Return back to OS

;Data - Variables and Strings
hello_str:
db "Hello World",0
```

BASIC Syntax
============

BASIC is a general programming language.
Its easy and short.

BASIC programs are portable, short
and easily readable by humans.
They're also machine-independent
as they are mostly interpreted.
Thus any code you write in BASIC can be
used in other OS directly.

For any BASIC program -

1. Name your new file by - `fname'
2. Create a new file - `fnew`
3. Load it on memory - `q`
4. Edit and Write your Code - `edit`
5. Save your file - `fsave`
6. Run it with BASIC interpreter - `basic acode.bas`

You can use any commands given in the BASIC command list
given in text folder.

Sample Program -

```basic
REM *** Hello World for BASIC ***

REM Print the output string
PRINT "Hello World"

REM Return back to interpreter
END
```

Use mikeos basic handbook for more details
on each BASIC command.

FORTH Interpreter
==================

Forth is a easy stack based language.
Its interpreter in Aplaun is fast and responsive.

Sample Program -

```forth
." Hello World"
```

It can be used to create any definitions
and keywords for quick use.

```forth
: FLOOR5 ( n -- n' ) 1- 5 MAX ;
```

see brainf help file in doc folder for more details.

Brainf***
==========

Its an **esoteric* language mainly made for fun.
Its turing-complete and thus any function
can also be made in this language.

```brainf***
Add a few blocks +++++ And output them .+.+.-.-.
```

Batch language
==============

A set of commands separated by newlines.
They are executed one-by-one by the kernel.

Sample **bat** file -

```batch
echo
IHelloWorld
sstlsstlsscl
calc 5+3-2
driveinfo
IDone
echo
```

Machine Language
================

Any current instruction set can be used
to create program binaries directly.

Sample **hex** code to print `A` on screen.

```binary
B4 0E B0 41 CD 10 C3
```
