rem nasm shelta86.asm -o shelta.com
nasm shelta86.s -o sheltac.com
rem fasm forth.asm forth.com
jwasm -bin shelta86.asm
del shelta86.com
ren shelta86.bin shelta86.com
pause