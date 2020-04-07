#!/bin/sh

# This script assembles the TachyonOS bootloader, kernel and programs
# with NASM, and then creates floppy and CD images (on Mac OS X)

# Only the root user can mount the floppy disk image as a virtual
# drive (loopback mounting), in order to copy across the files


echo ">>> TachyonOS OS X build script - requires nasm and mkisofs"


if test "`whoami`" != "root" ; then
	echo "You must be logged in as root to build (for loopback mounting)"
	echo "Enter 'su' or 'sudo bash' to switch to root"
	exit
fi


echo ">>> Assembling bootloader..."

nasm -O0 -f bin -o source/bootload/bootload.bin source/bootload/bootload.asm || exit


echo ">>> Assembling TachyonOS kernel..."

cd source
nasm -O0 -f bin -o kernel.bin kernel.asm || exit
nasm -O0 -f bin -o zkernel.sys zkernel.asm || exit
cd ..


echo ">>> Assembling programs..."

cd programs

for i in *.asm
do
	nasm -O0 -f bin $i -o `basename $i .asm`.bin || exit
done

cd ..

echo ">>> Creating floppy..."
cp disk_images/tachyonos.flp disk_images/tachyonos.dmg


echo ">>> Adding bootloader to floppy image..."

dd conv=notrunc if=source/bootload/bootload.bin of=disk_images/tachyonos.dmg || exit


echo ">>> Copying TachyonOS kernel and programs..."

rm -rf tmp-loop

dev=`hdid -nobrowse -nomount disk_images/tachyonos.dmg`
mkdir tmp-loop && mount -t msdos ${dev} tmp-loop && cp source/kernel.bin tmp-loop/ && cp source/zkernel.sys tmp-loop/

cp programs/*.bin programs/*.bas diskfiles/*.* tmp-loop

echo ">>> Unmounting loopback floppy..."

umount tmp-loop || exit
hdiutil detach ${dev}

rm -rf tmp-loop

echo ">>> TachyonOS floppy image is disk_images/tachyonos.dmg"


echo ">>> Creating CD-ROM ISO image..."

rm -f disk_images/tachyonos.iso
mkisofs -quiet -V 'TACHYON' -input-charset iso8859-1 -o disk_images/tachyonos.iso -b tachyonos.dmg disk_images/ || exit

echo '>>> Done!'

