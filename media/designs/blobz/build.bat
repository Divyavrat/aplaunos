rem nasm blobz.asm -o blobz.com
rem fasm blobz.asm blobz.com
jwasm -bin blobz.asm
del blobz.com
ren blobz.bin blobz.com
jwasm -mz blobze.asm
rem del blobze.com
rem ren blobze.bin blobze.exe
pause