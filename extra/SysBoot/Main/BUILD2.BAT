gcc -Wall -O -fstrength-reduce -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -o krnl32.exe main.c
rem i586-elf-ld -T link.ld -o kernel main.o
pause