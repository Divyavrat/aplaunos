osgcc -Wall -O -fstrength-reduce -fomit-frame-pointer -finline-functions -nostdinc -fno-builtin -I./include -c -o main.o main.c
i586-elf-ld -T link.ld -o kernel main.o
pause