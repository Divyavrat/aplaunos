@echo off
echo Compiling Blue Jay Bootloader
nasm bootload/bootload.asm -o bootload/BOOTLOAD.BJK
pause