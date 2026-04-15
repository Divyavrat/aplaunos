rem nasm spacei.asm -o spacei.com
rem fasm spacei.asm spacei.com

jwasm -bin main.asm
del mines.com
ren mines.bin mines.com
pause