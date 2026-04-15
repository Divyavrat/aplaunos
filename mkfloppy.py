import os

def create_floppy():
    with open("fat16.img", "wb") as f:
        # Boot sector - load the actual compiled bootloader!
        if os.path.exists("BOOT.IMG"):
            with open("BOOT.IMG", "rb") as bf:
                boot = bytearray(bf.read(512))
        else:
            print("Warning: BOOT.IMG not found!")
            boot = bytearray(512)
            boot[510:512] = b'\x55\xAA'
            
        # Ensure it has the boot signature just in case
        boot[510:512] = b'\x55\xAA'
        f.write(boot)
        
        # FAT1
        fat1 = bytearray(512 * 9)
        fat1[0] = 0xF0
        fat1[1] = 0xFF
        fat1[2] = 0xFF
        f.write(fat1)
        
        # FAT2
        fat2 = bytearray(512 * 9)
        fat2[0] = 0xF0
        fat2[1] = 0xFF
        fat2[2] = 0xFF
        f.write(fat2)
        
        # Root dir (14 sectors)
        f.write(bytearray(512 * 14))
        
        # Data (2880 - 1 - 9 - 9 - 14) = 2847 sectors
        f.write(bytearray(512 * 2847))
        
        print("created fat16.img (1.44 MB)")

if __name__ == "__main__":
    create_floppy()
