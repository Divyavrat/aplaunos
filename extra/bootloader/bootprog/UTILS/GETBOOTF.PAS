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
  b : TBootSector;
  f : file;
  r : registers;
  s, try : word;
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
    writeln ('Usage: GETBOOTF.EXE <source_disk:> <boot_sector_file> <ды');
    exit;
  end;
  ds := upstr(paramstr(1));
  if (ds <> 'A:') and (ds <> 'B:') then begin
    writeln ('Invalid source disk. It must be either A: or B:.');
    exit
  end;

                          (* READING BOOT SECTOR *)

  writeln ('Reading original boot sector...');
  try := 0;
l1:
  r.ax := $201; { read fn, 1 sector }
  r.cx := 1;    { track/cyl=0, sector=1 }
  r.dh := 0;    { head=0 }
  r.dl := ord(ds[1])-ord('A'); { disk }
  r.es := seg (b);
  r.bx := ofs (b);
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

                            (* SAVING BOOT FILE *)

  writeln ('Saving a boot sector file...');
  assign (f, paramstr(2));
  {$i-} rewrite (f, 1); {$i+}
  if ioresult <> 0 then begin
    writeln ('  Couldn''t create a file.');
    exit;
  end;
  blockwrite (f, b, 512, s);
  close (f);
  if s <> 512 then begin
    writeln ('  An error occured.');
    exit
  end;
  writeln ('  OK.');
end.
