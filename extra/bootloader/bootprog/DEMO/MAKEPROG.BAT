@echo off
tasm startupc.asm
tlink /t startupc.obj

tasm startupe.asm
tlink startupe.obj

del *.obj
del *.map
