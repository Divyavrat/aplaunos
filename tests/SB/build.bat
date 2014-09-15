rem nasm -f aout -o sbdetect.o sbdetect.asm

rem gcc -c -O2 -o sbdetect.o sbdetect.c

ml sbdetect.asm

ld -o sbdetect.com -Tsbdetect.scr sbdetect.o 

gcc sbdetect.obj
pause