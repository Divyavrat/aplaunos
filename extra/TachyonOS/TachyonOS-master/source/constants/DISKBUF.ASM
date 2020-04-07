; +--------------------------+
; | Disk Buffering Addresses |
; +--------------------------+
	%DEFINE DISK_SEGMENT			0x8000		; All disk buffers use this segment

	%DEFINE BIOS_PARAMETER_BLOCK		0x0000		; First sector - 512 bytes
	%DEFINE SECTOR_TEMP			0x0200		; Temporary sector storage - 512 bytes
	%DEFINE FIRST_FAT			0x2000		; First FAT - 8 kilobytes
	%DEFINE SECOND_FAT			0x4000		; Second FAT - 8 kilobytes
	%DEFINE ACTIVE_DIRECTORY		0x8000		; Directory entry - 16 kilobytes
	%DEFINE OTHER_DIRECTORY			0xC000		; Directory entry - 16 kilobytes
	
	%DEFINE DISK_RETRIES			5		; Number of times to retry on a floppy disk error
	%DEFINE DOS_NEWLINE			0x0D, 0x0A
	
