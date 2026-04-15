import os

def create_floppy():
    with open("fat16.img", "wb") as f:
        # Boot sector
        boot = bytearray(512)
        boot[0:3] = b'\xEB\x3C\x90' # JMP short, NOP
        boot[3:11] = b'MSDOS5.0' # OEM Name
        boot[11:13] = (512).to_bytes(2, 'little') # Bytes per sector
        boot[13] = 1 # Sectors per cluster
        boot[14:16] = (1).to_bytes(2, 'little') # Reserved sectors
        boot[16] = 2 # Number of FATs
        boot[17:19] = (224).to_bytes(2, 'little') # Root dir entries
        boot[19:21] = (2880).to_bytes(2, 'little') # Total sectors
        boot[21] = 0xF0 # Media descriptor
        boot[22:24] = (9).to_bytes(2, 'little') # Sectors per FAT
        boot[24:26] = (18).to_bytes(2, 'little') # Sectors per track
        boot[26:28] = (2).to_bytes(2, 'little') # Heads
        boot[28:32] = (0).to_bytes(4, 'little') # Hidden sectors
        boot[32:36] = (0).to_bytes(4, 'little') # Large total sectors
        boot[36] = 0 # Drive number
        boot[37] = 0 # Reserved
        boot[38] = 0x29 # Extended boot signature
        boot[39:43] = (0x12345678).to_bytes(4, 'little') # Serial number
        boot[43:54] = b'NO NAME    ' # Volume label
        boot[54:62] = b'FAT12   ' # File system type
        boot[510:512] = b'\x55\xAA' # Boot signature
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
        
        print("created floppy.img (1.44 MB)")

if __name__ == "__main__":
    create_floppy()
