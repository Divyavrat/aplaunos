WHAT IS THIS?
=============
Sample protected-mode code, in increasing order of complexity:

* Basic 32-bit protected mode.
* Access to text-mode video memory.     * Linear (flat) memory.
* Return to real mode.                  * PM interrupts/exceptions.
* Test for Virtual 8086 mode.           * PM text-output subroutine.
* CPU detection (386 or better).        * Software interrupt validation.
* "Unreal" mode (flat real, big real).
* Copying code to alternate memory location and running it there.
* Enabling A20 gate.                    * Running code in extended memory.
* Simple task state segment (TSS) use.
* Preemptive multitasking via timer interrupt.
* Ring 0 (kernel/system mode) code to/from Ring 3 (user mode) code.
* Syscalls.                             * Reprogramming 8259 interrupt chip.
* Interface/linking to C-language code. * Beginnings of a libc.
* More elaborate syscalls/exception handler.
* Scrolling video and cursor movement.

PM1.ASM is heavily commented, and tries to serve as a tutorial.

The .ASM files are written in x86 assembly language and should be
assembled with NASM (the free x86 assembler) like this:
	nasm  -o  pmXXX.com  pmXXX.asm
I am also including the PM12C.C file, which needs DJGPP, the free
32-bit C compiler for MS-DOS.

A pre-compiled version of NASM 0.97 that I downloaded from the Internet
gave me a lot of grief. The problems went away after I downloaded the
NASM sources and compiled them myself under DJGPP. Be warned.

These programs assume a 386 or better CPU (386 SX/DX, 486 SX/DX, Pentium,
Pentium II, non-Intel clone processors, etc.).

WHERE IS THIS?
==============
http://www.execpc.com/~geezer/os/pm.zip

WHAT CAN I DO WITH THIS?
========================
Anything you want, so long as you don't
- take credit for something you didn't do, or
- blame me for the results.

WHY DOESN'T IT WORK?
====================
See KNOWN BUGS, below.

	"My computer freezes up!"
pm10 and later programs do not include code to return to real mode: after
doing their thing, they freeze. Press the reset button or cycle power to
reboot.

	"It doesn't freeze up but nothing gets printed."
These apps put text on the top line of the screen by writing directly to
video memory. If the cursor is at the bottom of the screen when you type
pm1 (or whatever), the output of the program will get scrolled off the
top of the screen after it returns to DOS. Try
	cls
	pm1 (or whatever)
(thanks to Mark for the heads-up on this).

	"These programs freeze up my computer without printing anything."
pm6 will crash if extended memory is in use (e.g. by SMARTDRV). If the
crash is happening in other situations, please let me know about it.

	"The computer just reboots."
Again, this shouldn't happen (and again, let me know if it does). Bad
protected-mode code often makes the CPU triple-fault, which causes the
computer to reset itself. Hopefully, this code is simple enough that it
shouldn't have any bugs.

	"Windows 95 says 'MS-DOS mode' and terminates the program."
These programs won't run under Windows. MS-DOS mode might work, but it's
better to reboot the computer, wait for 'Starting Windows 95...' and quickly
press F8. Then chose 'Safe mode command prompt only' and run these files.

	"EMM386 privileged operation error..."
Same problem as Windows (CPU is in Virtual 8086 mode). If you are loading
EMM386.EXE in CONFIG.SYS, comment it out. Or use the F8 boot option
described above. The EMM386 that comes with Win95 lets you press 'C' to
disable EMM386 and continue, which may or may not work.

	"Nothing happens, no 'Hello' or reboot -- it just returns to DOS."
pm3.asm through pm6.asm return to DOS if Virtual 8086 mode is detected
(Windows DOS box or EMM386). pm4.asm through pm6.asm return to DOS if an
8088 or 80286 CPU is detected (though this hasn't been tested). Type
	test pm3
and look at the output. If it says
	Program 'pm3' returned errorlevel 1.
then the CPU is in Virtual 8086 mode (Windows DOS box or EMM386 in use).
If you type 'test pm4' and get
	Program 'pm4' returned errorlevel 2.
this means the CPU is not a 386 or better.

WHERE'D YOU LEARN TO DO THIS?
=============================
Freedows '98 -- Copyright (C) 1997 Joachim Breitsprecher
<j.breitsprecher@schwaben.de>

Benn Vosseteig posted some spiffy Ring 0-to-Ring 3
code on the OS development board at
    http://milkyway.isa.net.au/os-dev/cgi-bin/blueboard.exe

Linux -- Copyright (C) 1991, 1992 Linus Torvalds
I recommend the 'Historic' kernel (version 0.01), available from
    http://www.kernel.org/pub/linux/kernel/Historic/linux-0.01.tar.gz

INTEL 80386 PROGRAMMER'S REFERENCE MANUAL 1986, available from
        http://www.execpc.com/~geezer/os/386intel.zip
and many other sites.

Robert Collins' "Intel Secrets" web site:
    http://www.x86.org

Josh McDonald's OS/2000
    http://www.effect.net.au/os-dev/

KNOWN BUGS
==========
One task of pm8 seems to die if run indefinitely instead of only 18 times
(maybe this is some kind of weird resonance).

FEEDBACK
========
...is welcome.

Christopher Giese <geezer[AT]execpc.com>
