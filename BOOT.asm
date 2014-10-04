;bits	16						; we are in 16 bit real mode
use16
org		0					; we will set regisers later

start:	jmp main					; jump to start of bootloader
;nop				; Pad out before disk description

; ------------------------------------------------------------------
; Disk description table, to make it a valid floppy
; Note: some of these values are hard-coded in the source!
; Values are those used by IBM for 1.44 MB, 3.5" diskette

bpbOEM			db "MY USBOS" ; Disk label
bpbBytesPerSector:  	DW 512 ; Bytes per sector
bpbSectorsPerCluster: 	DB 1 ; Sectors per cluster
bpbReservedSectors: 	DW 1 ; Reserved sectors for boot record
bpbNumberOfFATs: 	DB 2 ; Number of copies of the FAT
bpbRootEntries: 	DW 224 ; Number of entries in root dir
; (224 * 32 = 7168 = 14 sectors to read)
bpbTotalSectors: 	DW 2880 ; Number of logical sectors
bpbMedia: 		DB 0xf0  ;; 0xF1 ; Medium descriptor byte
bpbSectorsPerFAT: 	DW 9 ; Sectors per FAT
bpbSectorsPerTrack: 	DW 18 ; Sectors per track (36/cylinder)
bpbHeadsPerCylinder: 	DW 2 ; Number of sides/heads
bpbHiddenSectors: 	DD 0 ; Number of hidden sectors
bpbTotalSectorsBig:     DD 0 ; Number of LBA sectors
bsDriveNumber: 	        DB 0 ; Drive No: 0
bsUnused: 		DB 0
bsExtBootSignature: 	DB 0x41;0x29 ; Drive signature: 41 for floppy
bsSerialNumber:	        DD 0xa0a1a2a3 ; Volume ID: any number
bsVolumeLabel: 	        DB " OS FLOPPY " ; Volume Label: any 11 chars
bsFileSystem: 	        DB "FAT12   " ; File system type: don't change!

absoluteSector db 0x00
absoluteHead   db 0x00
absoluteTrack  db 0x00

;************************************************;
; Convert CHS to LBA
; LBA = (cluster - 2) * sectors per cluster
;************************************************;

ClusterLBA:
          sub     ax, 0x0002                          ; zero base cluster number
          xor     cx, cx
          mov     cl, BYTE [bpbSectorsPerCluster]     ; convert byte to word
          mul     cx
          add     ax, WORD [datasector]               ; base data sector
          ret

;************************************************;
; Convert LBA to CHS
; AX=>LBA Address to convert
;
; absolute sector = (logical sector / sectors per track) + 1
; absolute head   = (logical sector / sectors per track) MOD number of heads
; absolute track  = logical sector / (sectors per track * number of heads)
;
;************************************************;

LBACHS:
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [bpbSectorsPerTrack]           ; calculate
          inc     dl                                  ; adjust for sector 0
          mov     BYTE [absoluteSector], dl
          xor     dx, dx                              ; prepare dx:ax for operation
          div     WORD [bpbHeadsPerCylinder]          ; calculate
          mov     BYTE [absoluteHead], dl
          mov     BYTE [absoluteTrack], al
          ret


;************************************************;
; Reads a series of sectors
; CX=>Number of sectors to read
; AX=>Starting sector
; ES:BX=>Buffer to read to
;************************************************;

ReadSectors:
     .MAIN:
          mov     di, 0x0005                          ; five retries for error
     .SECTORLOOP:
          push    ax
          push    bx
          push    cx
          call    LBACHS                              ; convert starting sector to CHS
          mov     ah, 0x02                            ; BIOS read sector
          mov     al, 0x01                            ; read one sector
          mov     ch, BYTE [absoluteTrack]            ; track
          mov     cl, BYTE [absoluteSector]           ; sector
          mov     dh, BYTE [absoluteHead]             ; head
          mov     dl, BYTE [bsDriveNumber]            ; drive
          int     0x13                                ; invoke BIOS
          jnc     .SUCCESS                            ; test for read error
          xor     ax, ax                              ; BIOS reset disk
          int     0x13                                ; invoke BIOS
          dec     di                                  ; decrement error counter
          pop     cx
          pop     bx
          pop     ax
          jnz     .SECTORLOOP                         ; attempt to read again
          int     0x18
     .SUCCESS:
          mov     si, msgProgress
          call    prnstr
          pop     cx
          pop     bx
          pop     ax
          add     bx, WORD [bpbBytesPerSector]        ; queue next buffer
          inc     ax                                  ; queue next sector
          loop    .MAIN                               ; read next sector
          ret


;*********************************************
;	Bootloader Entry Point
;*********************************************

main:

     ;----------------------------------------------------
     ; code located at 0000:7C00, adjust segment registers
     ;----------------------------------------------------
     
          cli						; disable interrupts
          mov     ax, 0x07C0				; setup registers to point to our segment
          mov     ds, ax
          mov     es, ax
          mov     fs, ax
          mov     gs, ax

     ;----------------------------------------------------
     ; create stack
     ;----------------------------------------------------
     
          mov     ax, 0x0000				; set the stack
          mov     ss, ax
          mov     sp, 0xFFFF
          sti						; restore interrupts

          ;mov  [bootdevice], dl
; mov al,'K'
; call printf
; call gethex
; mov [bootdevice],al
; mov [bsDriveNumber],al

	; NOTE: A few early BIOSes are reported to improperly set DL

; ******************************************************************

cmp dl, 0
	je no_change
	mov [bootdevice], dl		; Save boot device number
	mov [bsDriveNumber], dl		; Save boot device number
	push es
	mov ah, 8			; Get drive parameters
	int 13h
	pop es
	and cx, 3Fh			; Maximum sector number
	mov [bpbSectorsPerTrack], cx		; Sector numbers start at 1
	movzx dx, dh			; Maximum head number
	add dx, 1			; Head numbers start at 0 - add 1 for total
	mov [bpbHeadsPerCylinder], dx

no_change:
; ******************************************************************

	mov eax, 0			; Needed for some older BIOSes

     ;----------------------------------------------------
     ; Load root directory table
     ;----------------------------------------------------

     LOAD_ROOT:
     
     ; compute size of root directory and store in "cx"
     
          xor     cx, cx
          xor     dx, dx
          mov     ax, 0x0020                           ; 32 byte directory entry
          mul     WORD [bpbRootEntries]                ; total size of directory
          div     WORD [bpbBytesPerSector]             ; sectors used by directory
          xchg    ax, cx
          
     ; compute location of root directory and store in "ax"
     
          mov     al, BYTE [bpbNumberOfFATs]            ; number of FATs
          mul     WORD [bpbSectorsPerFAT]               ; sectors used by FATs
          add     ax, WORD [bpbReservedSectors]         ; adjust for bootsector
          mov     WORD [datasector], ax                 ; base of root directory
          add     WORD [datasector], cx
          
     ; read root directory into memory (7C00:0200)
     
          mov     bx, 0x0200                            ; copy root dir above bootcode
          call    ReadSectors

     ;----------------------------------------------------
     ; Find stage 2
     ;----------------------------------------------------

     ; browse root directory for binary image
          mov     cx, WORD [bpbRootEntries]             ; load loop counter
          mov     di, 0x0200                            ; locate first root entry
     .LOOP:
          push    cx
          mov     cx, 0x000B                            ; eleven character name
          mov     si, ImageName                         ; image name to find
		  ; xchg si,di
		; call prnstr
		; pusha
		; xor ah,ah
		; int 0x16
		; popa
		  ; xchg si,di
		  push    di
     rep  cmpsb                                         ; test for entry match
          pop     di
          je      LOAD_FAT
          pop     cx
          add     di, 0x0020                            ; queue next directory entry
          loop    .LOOP
          jmp     FAILURE

     ;----------------------------------------------------
     ; Load FAT
     ;----------------------------------------------------

     LOAD_FAT:
     
     ; save starting cluster of boot image
     
          mov     dx, WORD [di + 0x001A]
          mov     WORD [cluster], dx                  ; file's first cluster
          
     ; compute size of FAT and store in "cx"
     
          xor     ax, ax
          mov     al, BYTE [bpbNumberOfFATs]          ; number of FATs
          mul     WORD [bpbSectorsPerFAT]             ; sectors used by FATs
          mov     cx, ax

     ; compute location of FAT and store in "ax"

          mov     ax, WORD [bpbReservedSectors]       ; adjust for bootsector
          
     ; read FAT into memory (7C00:0200)

          mov     bx, 0x0200                          ; copy FAT above bootcode
          call    ReadSectors

     ; read image file into memory (0050:0000)
     
          mov     ax, 0x0000
          mov     es, ax                              ; destination for image
          mov     bx, 0x0500                          ; destination for image
          push    bx

     ;----------------------------------------------------
     ; Load Stage 2
     ;----------------------------------------------------

     LOAD_IMAGE:
     
          mov     ax, WORD [cluster]                  ; cluster to read
          pop     bx                                  ; buffer to read into
          call    ClusterLBA                          ; convert cluster to LBA
          xor     cx, cx
          mov     cl, BYTE [bpbSectorsPerCluster]     ; sectors to read
          call    ReadSectors
          push    bx
          
     ; compute next cluster
     
          mov     ax, WORD [cluster]                  ; identify current cluster
          mov     cx, ax                              ; copy current cluster
          mov     dx, ax                              ; copy current cluster
          shr     dx, 0x0001                          ; divide by two
          add     cx, dx                              ; sum for (3/2)
          mov     bx, 0x0200                          ; location of FAT in memory
          add     bx, cx                              ; index into FAT
          mov     dx, WORD [bx]                       ; read two bytes from FAT
          test    ax, 0x0001
          jnz     .ODD_CLUSTER
          
     .EVEN_CLUSTER:
     
          and     dx, 0000111111111111b               ; take low twelve bits
         jmp     .DONE
         
     .ODD_CLUSTER:
     
          shr     dx, 0x0004                          ; take high twelve bits
          
     .DONE:
     
          mov     WORD [cluster], dx                  ; store new cluster
          cmp     dx, 0x0FF0                          ; test for end of file
          jb      LOAD_IMAGE
          
     DONE:
     
          ;mov     si, msgCRLF
          ;call    prnstr
		  mov ax,[bpbSectorsPerTrack]
		  mov bx,[bsDriveNumber]
		  mov cx,[bpbHeadsPerCylinder]
		  mov dh,[bpbMedia]
		  mov dl,[bootdevice]
          push    WORD 0x0000
          push    WORD 0x0500
          retf
          
     FAILURE:
          mov     ah, 0x00
          int     0x16                                ; await keypress
          int     0x19                                ; warm boot computer

; gethex:
; call getkey
; call printf
; call atohex
; shl al,4
; mov [bsUnused],al

; call getkey
; call printf
; call atohex
; mov ah,[bsUnused]
; add al,ah
; ret

; atohex:
; cmp al,0x3a
; jle hex_num_found
; cmp al,0x5a
; jg hex_small_found
; add al,0x20
; hex_small_found:
; sbb al,0x28
; hex_num_found:
; sbb al,0x2f
; ret

printf:
mov ah,0x0e
int 0x10
ret

prnstr:
pusha
.loop:
lodsb
or al,al
jz .prnend
call printf
jmp .loop
.prnend:
popa
ret

getkey:
xor ah,ah
int 0x16
ret

     bootdevice  db 0
     datasector  dw 0x0000
     cluster     dw 0x0000
     ImageName   db "KERNEL  COM"
     msgProgress db ".", 0x00
     
          TIMES 510-($-$$) DB 0
          DW 0xAA55
