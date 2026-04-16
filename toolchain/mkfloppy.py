import os
import sys

def create_floppy():
    img_name = "fat16.img"
    
    # Try to remove old image to ensure it's not locked
    if os.path.exists(img_name):
        try:
            os.remove(img_name)
        except OSError as e:
            print(f"Error: Could not remove old {img_name}. It might be locked by VirtualBox.")
            print(f"Details: {e}")
            sys.exit(1)

    try:
        with open(img_name, "wb") as f:
            # Boot sector - load the actual compiled bootloader!
            if os.path.exists("build/BOOT.IMG"):
                with open("build/BOOT.IMG", "rb") as bf:
                    boot = bytearray(bf.read(512))
            else:
                print("Warning: build/BOOT.IMG not found!")
                boot = bytearray(512)
                boot[510:512] = b'\x55\xAA'
                
            # Ensure it has the boot signature just in case
            boot[510:512] = b'\x55\xAA'
            f.write(boot)
            
            # FAT1 (9 sectors for 1.44MB floppy)
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
            
            print(f"Successfully created {img_name} (1.44 MB)")
    except Exception as e:
        print(f"Critical Error creating {img_name}: {e}")
        sys.exit(1)

if __name__ == "__main__":
    create_floppy()
