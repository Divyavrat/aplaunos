nasm BOOT.ASM -O1 -o BOOT.IMG
rem nasm kernel.ASM -O1 -o kernel.COM
rem fasm BOOT.ASM BOOT.IMG
fasm kernel.asm kernel.com
pause
exit