nasm BOOT.ASM -O1 -o BOOT.IMG
rem nasm kernel.ASM -O1 -o kernel.COM
rem fasm BOOT.ASM BOOT.IMG
fasm kernel.asm kernel.com
pause
copy kernel.com J:\
OsDev.lnk
exit
qemu-system-x86_64 -fda extra/setupall.img
qemu-system-x86_64.exe -L . -m 512 -readconfig configs\ich9-ehci-uhci.cfg -drive file=\\.\PhysicalDrive3,if=none,id=usbdrive1 -device usb-storage,bus=ehci.0,drive=usbdrive1
qemu -hda ubuntu.img -boot d -cdrom ./ubuntu-9.10-desktop-i386.iso -m 512
exit