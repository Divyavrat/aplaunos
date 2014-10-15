rem nasm spacei.asm -o spacei.com
rem fasm spacei.asm spacei.com

jwasm -bin playwav.asm
rem ml playwav.asm
del playwav.com
ren playwav.bin playwav.com
pause