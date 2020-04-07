@echo off
echo Build script for Windows
echo.

path %path%;%CD%\build_programs

echo Assembling bootloader...
cd source\bootload
nasm -O0 -f bin -o bootload.bin bootload.asm
cd ..

echo Assembling MikeOS kernel...
nasm -O0 -f bin -o kernel.bin kernel.asm
nasm -O0 -f bin -o zkernel.sys zkernel.asm

echo Assembling programs...
cd ..\programs
 for %%i in (*.asm) do nasm -O0 -fbin %%i
 for %%i in (*.bin) do del %%i
 for %%i in (*.) do ren %%i %%i.bin
cd ..

echo Adding bootsector to disk image...
partcopy "%CD%\source\bootload\bootload.bin" "%CD%\disk_images\tachyonos.flp" 0h 511d

echo Mounting disk image...
imdisk -a -f disk_images\tachyonos.flp -s 1440K -m B:

echo Copying kernel and applications to disk image...
copy source\kernel.bin b:\
copy source\zkernel.sys b:\
copy programs\*.bin b:\
copy programs\*.bas b:\
copy diskfiles\*.* b:\

echo Dismounting disk image...
imdisk -D -m B:

del disk_images\tachyonos.ima
copy disk_images\tachyonos.flp disk_images\tachyonos.ima

echo Done!
pause