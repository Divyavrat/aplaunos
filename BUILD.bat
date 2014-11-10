nasm BOOT.ASM -O7 -o BOOT.IMG
nasm kernel.ASM -O7 -o kernel.COM
rem fasm BOOT.ASM BOOT.IMG
rem fasm kernel.asm kernel.com
pause
exit