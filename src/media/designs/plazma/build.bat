rem nasm plazma.asm -o plazma.com
rem fasm plazma.asm plazma.com
jwasm -bin plazma.asm
del plazma.com
ren plazma.bin plazma.com
fasm plazma2.asm plazma2.com
pause