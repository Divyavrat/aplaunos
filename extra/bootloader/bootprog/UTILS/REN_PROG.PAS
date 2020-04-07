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
    BootCode  : Array [1..437] of Byte;
    PName     : Array [1..8] of Char;           { Program File Name }
    PExt      : Array [1..3] of Char;           { Program File Name Extension }
    EndID     : Word;
  End;

var
  b : TBootSector;
  f : file;
  r : registers;
  s, sr, try : word;
  ps : pathstr;
  ds : dirstr;
  ns : namestr;
  es : extstr;

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
    writeln ('Usage: REN_PROG.EXE <boot_sector_file> <program_name_to_load> <ды');
    exit;
  end;

  fillchar (b, 512, 0);

                            (* LOADING BOOT FILE *)

  writeln ('Loading a boot sector file...');
  assign (f, paramstr(1));
  {$i-} reset (f, 1); {$i+}
  if ioresult <> 0 then begin
    writeln ('  Couldn''t open a file.');
    exit;
  end;
  blockread (f, b, 512, s);
  close (f);
  if s <> 512 then begin
    writeln ('  An error occured.');
    exit
  end;
  writeln ('  OK.');

                               (* PATCHING *)

  writeln ('Patching...');

  if b.OEM <> 'BootProg' then begin
    writeln ('  Invalid boot sector. It must be a "BootProg" boot sector.');
    writeln ('  Failed.');
    exit
  end;
  writeln ('  Old name: ', b.PName+'.'+b.PExt);
  ps := upstr(paramstr(2));
  fsplit (ps, ds, ns, es);
  delete (es, 1, 1);
  writeln ('  New name: ',ns+'.',es);
  while length(ns) < 8 do ns := ns + ' ';
  while length(es) < 3 do es := es + ' ';
  move (ns[1], b.PName, 8);
  move (es[1], b.PExt, 3);

                            (* SAVING BOOT FILE *)

  writeln ('Saving a boot sector file...');
  assign (f, paramstr(1));
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
  writeln ('  OK.')
end.
