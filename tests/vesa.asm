;org 0x7c00
org 0x6000

[BITS 16]           ;Tell Assembler to generate 16-bit code

jmp short start         ;Goto start, skip BIOS-Parameter-Block
nop             

;------------BIOS Parameter Block---------------;
;         Needed to recognize the disk      ;
;-----------------------------------------------;
OEMName:        db 'TEST OS '   ;Name of Orignal Equipment Manufacturer
bytesPerSector:     dw 512      ;Number of bytes in each sector
sectPerCluster:     db 1        ;Sectors in one cluster, 1 for FAT12
reservedCluster:    dw 1        ;1 sector is reserved for boot
totalFATs:      db 2        ;There are 2 fats in FAT12 these are copies of each other
rootDirEntries:     dw 224      ;Total entries (files or folders) in root directory
totalSectors:       dw 2880     ;Total Sectors in whole disk
mediaType:      db 0xf0     ;Media type 240 for floppies
sectorsPerFAT:      dw 9        ;Sectors used in on FAT
sectorsPerTrack:    dw 18       ;Sectors in one Track
totalHeads:     dw 2        ;Total sides of disk
hiddenSectors:      dd 0        
hugeSectors:        dd 0
driveNumber:        db 0        ;Drive Number 0 for A:\ floppy
            db 0
signature:      db 41       ;41 for floppies
volumeID:       dd 0        ;Any number
volumeLabel:        db 'TEST OS    ';Any 11-char name
fileSystem:     db 'FAT12   '   ;Type of file system on disk
;------------------------------------------------


;_______________________________________________

gdt:    dd 0x00000000,0x00000000 ;null descriptor
    dd 0x0000ffff,0x00cf9a00 ;code
    dd 0x0000ffff,0x00cf9200

gdtreg: dw 0x17          ;gdt size + 1
    dd 0             ;gdt base (latter filled)

start:
mov ax,0x4f01 ;get vesa mode info
mov cx,0115h ;video mode number
mov di,modeblock
int 0x10
mov esi, [modeblock+0x28] ;save linear frame buffer base = es:di+0x28

mov ax,0x4f02 ;set vesa mode
mov bx,0115h ;video mode number
int 0x10

mov ax,0x2401
int 0x15    ;enable a20 gate

xor eax,eax
mov ax,cs   
shl eax,4
mov [gdt+0x08+2],ax
shr eax,16
mov [gdt+0x20+4],al


xor eax,eax
mov ax,cs
shl eax,4
add eax,gdt
mov [gdtreg+2],eax
lgdt[gdtreg]

mov eax,cr0
or eax,1

cli
mov cr0,eax
jmp 0x08:pstart

[bits 32]
pstart:
mov eax,0x10
mov es,ax
mov ds,ax
mov fs,ax
mov ss,ax
mov gs,ax


cls:
mov eax,0xffffffff
mov edi, esi
mov ecx,1024*768*1/2
cld
rep stosd

main:
;test code
mov edi,esi 

mov ecx,1024*768*1/2*1/2
displayloop:
mov byte [edi],0xff
inc di
mov word [edi],0
add di,2
loop displayloop

mov ecx,1024*768*1/2*1/2
displayloop2:
mov word [edi],0
add di,2
mov byte [edi],0xff
inc di
loop displayloop2

mov byte[edi],0x00
inc edi
mov byte[edi],0x00
inc edi
mov byte[edi],0xff
inc edi
mov byte[edi],0x00
inc edi

mov byte[edi],0x00
inc edi
mov byte[edi],0xff
inc edi
mov byte[edi],0x00
inc edi
mov byte[edi],0x00
inc edi

mov byte[edi],0xff
inc edi
mov byte[edi],0x00
inc edi
mov byte[edi],0x00
inc edi
mov byte[edi],0x00
inc edi  

mov byte[edi],0x00
inc edi
mov byte[edi],0x00
inc edi
mov byte[edi],0xff
inc edi
mov byte[edi],0x00
inc edi

mov byte[edi],0x00
inc edi
mov byte[edi],0xff
inc edi
mov byte[edi],0x00
inc edi
mov byte[edi],0x00
inc edi

jmp $

times 510-($-$$) db 0
dw 0xaa55

modeblock: