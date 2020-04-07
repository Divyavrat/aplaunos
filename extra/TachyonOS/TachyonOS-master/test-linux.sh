#!/bin/sh

# This script starts the QEMU PC emulator, booting from the
# MikeOS floppy disk image

export QEMU_AUDIO_DRV=alsa
qemu-system-i386 -m 10 -soundhw pcspk -fda disk_images/tachyonos.flp

