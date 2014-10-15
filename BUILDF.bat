nasm BOOT.ASM -O5 -o BOOT.IMG
rem nasm kernel.ASM -O3 -o kernel.COM
rem fasm BOOT.ASM BOOT.IMG
fasm kernel.asm kernel.com
pause
exit