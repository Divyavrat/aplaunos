nasm BOOT.ASM -O3 -o BOOT.IMG
nasm kernel.ASM -O3 -o kernel.COM
rem fasm BOOT.ASM BOOT.IMG
rem fasm kernel.asm kernel.com
pause
exit