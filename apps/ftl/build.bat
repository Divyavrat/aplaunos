rem nasm ftl.asm -o ftl.com
rem fasm ftl.asm ftl.com
jwasm -bin ftl.asm
del ftl.com
ren ftl.bin ftl.com
pause