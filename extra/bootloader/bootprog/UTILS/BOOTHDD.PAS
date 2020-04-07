{$G+}
uses dos;

Type
  TBootSector = Record
    nJump     : Array [1..3] of Byte;
    OEM       : Array [1..8] of Char;
    SectSize  : Word;
    ClustSize : Byte;
    ResSecs   : Word;
    FATCount  : Byte;
    RootSize  : Word;
    TotalSecs : Word;
    Media     : Byte;
    FATSize   : Word;
    TrackSize : Word;
    HeadCount : Word;
    HiddenSecs: Word;
    HiHidnSecs: Word;
    BTotalSecs: LongInt;
    DriveNo   : Byte;
    Res       : Byte;
    ExtBootSig: Byte;
    SerNo     : LongInt;
    VolLabel  : Array [1..11] of Char;
    FileSysID : Array [1..8] of Char;
    BootCode  : Array [1..450] of Byte
  End;

function read_boot (disk : byte; var buf) : boolean; assembler;
asm
  push  ds
  mov   al, [disk]
  mov   cx, 0ffffh              { special function for large disks }

  push  word ptr [buf+2]
  push  word ptr [buf]          { buf }
  push  1                       { 1 sector }
  push  0
  push  0                       { lba = 0 = boot sector }

  mov   bx, sp
  push  ss
  pop   ds                      { ds:bx = ^ record }

  int   25h
  pop   dx                      { redundant word }

  pop   dx
  pop   dx
  pop   dx
  pop   dx
  pop   dx                      { restore stack pointer }

  pop   ds
  cmc
  rcl   al, 1
  and   al, 1
end;

function write_boot (disk : byte; var buf) : boolean; assembler;
asm
  push  ds
  mov   al, [disk]
  mov   cx, 0ffffh              { special function for large disks }

  push  word ptr [buf+2]
  push  word ptr [buf]          { buf }
  push  1                       { 1 sector }
  push  0
  push  0                       { lba = 0 = boot sector }

  mov   bx, sp
  push  ss
  pop   ds                      { ds:bx = ^ record }

  int   26h
  pop   dx                      { redundant word }

  pop   dx
  pop   dx
  pop   dx
  pop   dx
  pop   dx                      { restore stack pointer }

  pop   ds
  cmc
  rcl   al, 1
  and   al, 1
end;

var
  b1, b2 : TBootSector;
  f : file;
  s, sr, try : word;
  ds : string;

function upstr (s : string) : string;
var i : integer;
begin
  if length(s) > 0 then
    for i := 1 to length(s) do
      s[i] := upcase(s[i]);
  upstr := s
end;

label l1, l2;

begin
  if paramcount <> 2 then begin
    writeln ('Usage: BOOTHDD.EXE <boot_sector_file> <target_disk:> <ды');
    exit;
  end;
  ds := upstr(paramstr(2));
  if (ds[2] <> ':') or not (ds[1] in ['C'..'Z']) then begin
    writeln ('Invalid target disk. It must be C:, D:, etc.');
    exit
  end;

  fillchar (b1, 512, 0);

                            (* LOADING BOOT FILE *)

  writeln ('Loading a boot sector file...');
  assign (f, paramstr(1));
  {$i-} reset (f, 1); {$i+}
  if ioresult <> 0 then begin
    writeln ('  Couldn''t open a file.');
    exit;
  end;
  s := filesize(f);
  if s > 512 then s := 512;
  blockread (f, b1, s, sr);
  close (f);
  if sr <> s then begin
    writeln ('  An error occured.');
    exit
  end;
  writeln ('  OK.');

                          (* READING BOOT SECTOR *)

  writeln ('Reading original boot sector...');
  try := 0;
l1:
  inc (try);
  if not read_boot (ord(ds[1])-ord('A'), b2) then begin
    writeln ('  An error occured.');
    if try = 1 then begin
      writeln ('    trying again...');
      goto l1;
    end
    else begin
      writeln ('  Failed.');
      exit
    end;
  end;
  writeln ('  OK.');

                          (* ALTERING BOOT SECTOR *)

  writeln ('Altering original boot sector...');

  b2.nJump    := b1.nJump;
  b2.OEM      := b1.OEM;
  b2.VolLabel := b1.VolLabel;
  b2.BootCode := b1.BootCode;

  if b1.FileSysID <> b2.FileSysID then begin
    writeln ('  FAT types don''t match.');
    writeln ('    Original FAT type: ', b1.FileSysID);
    writeln ('    New      FAT type: ', b2.FileSysID);
    writeln ('  Failed.');
    exit
  end;

  writeln ('  OK.');

                           (* WRITING BOOT SECTOR *)

  writeln ('Writing changed boot sector...');
  try := 0;
l2:
  inc (try);
  if not write_boot (ord(ds[1])-ord('A'), b2) then begin
    writeln ('  An error occured.');
    if try = 1 then begin
      writeln ('    trying again...');
      goto l2;
    end
    else begin
      writeln ('  Failed.');
      exit
    end;
  end;
  writeln ('  OK.');
end.
