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

var
  b1, b2 : TBootSector;
  f : file;
  r : registers;
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
    writeln ('Usage: BOOTABLE.EXE <boot_sector_file> <target_disk:> <ды');
    exit;
  end;
  ds := upstr(paramstr(2));
  if (ds <> 'A:') and (ds <> 'B:') then begin
    writeln ('Invalid target disk. It must be either A: or B:.');
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
  r.ax := $201; { read fn, 1 sector }
  r.cx := 1;    { track/cyl=0, sector=1 }
  r.dh := 0;    { head=0 }
  r.dl := ord(ds[1])-ord('A'); { disk }
  r.es := seg (b2);
  r.bx := ofs (b2);
  intr ($13, r);
  inc (try);
  if r.flags and fcarry = fcarry then begin
    writeln ('  An error occured. Error code: ', r.ah);
    if try = 1 then begin
      writeln ('    trying again...');
      r.ah := 0;
      r.dl := 0;
      intr ($13, r);
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
  r.ax := $301; { write fn, 1 sector }
  r.cx := 1;    { track/cyl=0, sector=1 }
  r.dh := 0;    { head=0 }
  r.dl := ord(ds[1])-ord('A'); { disk }
  r.es := seg (b2);
  r.bx := ofs (b2);
  intr ($13, r);
  inc (try);
  if r.flags and fcarry = fcarry then begin
    writeln ('  An error occured. Error code: ', r.ah);
    if try = 1 then begin
      writeln ('    trying again...');
      r.ah := 0;
      r.dl := 0;
      intr ($13, r);
      goto l2;
    end
    else begin
      writeln ('  Failed.');
      exit
    end;
  end;
  writeln ('  OK.');
end.
