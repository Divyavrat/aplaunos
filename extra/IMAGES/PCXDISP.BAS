'I quickly put this together so it might not run on all systems.
'If you fix it to run on your system, please let me know and I
'will fix this original version to be more portable. (thanks)
'Also, this technique is extremely slow.  It is used to show
'show a PCX file is used.  Not for speed.
'

TYPE PCXheader
  Manufacturer AS STRING * 1
  Version AS STRING * 1
  Encoding AS STRING * 1
  Bitsppxl AS STRING * 1
  Xmin AS INTEGER
  Ymin AS INTEGER
  XMax AS INTEGER
  YMax AS INTEGER
  Hres AS INTEGER
  Vres AS INTEGER
  Egapalette AS STRING * 48
  Reserved AS STRING * 1
  Clrplns AS STRING * 1
  Bytespline AS INTEGER
  Palettetype AS INTEGER
  Filler AS STRING * 58
END TYPE

DIM TheHdr AS PCXheader
DIM Cpalette%(48), PalArray&(16)
DIM Buffer AS STRING * 17753  ' (len of file - 128)
DIM Byte AS STRING * 1

OPEN "demo.pcx" FOR BINARY AS 1
  GET #1, 1, TheHdr
  IF ASC(TheHdr.Manufacturer) <> &HA THEN
    PRINT "This is not a PCX file!"
    END
  END IF
  GET #1, , Buffer     ' get rest of file
  FilePos% = 1
CLOSE

FOR I% = 0 TO 47
  Cpalette%(I%) = ASC(MID$(TheHdr.Egapalette, I% + 1, 1))
NEXT I%

SELECT CASE TheHdr.Vres
  CASE 350
    SCREEN 9, , 0
    FOR J% = 0 TO 15
      Red% = Cpalette%(J% * 3) / 85
      Green% = Cpalette%((J% * 3) + 1) / 85
      Blue% = Cpalette%((J% * 3) + 2) / 85
      Red% = ((Red% AND 1) * 32) OR ((Red% AND 2) * 2)
      Green% = ((Green% AND 1) * 16) OR (Green% AND 2)
      Blue% = ((Blue% AND 1) * 8) OR ((Blue% AND 2) \ 2)
      Hue% = Red% OR Green% OR Blue%
      PalArray&(J%) = Hue%
    NEXT J%

  CASE 480
    SCREEN 12, , 0
    FOR J% = 0 TO 15
      Red% = Cpalette%(J% * 3) / 4
      Green% = Cpalette%((J% * 3) + 1) / 4
      Blue% = Cpalette%((J% * 3) + 2) / 4
      PalArray&(J%) = 65536 * Blue% + 256 * Green% + Red%
    NEXT J%
 
  CASE ELSE
    PRINT "I don't know how to display this file."
    END
END SELECT

PALETTE USING PalArray&(0)

DEF SEG = &HA000
  FOR K& = TheHdr.Ymin TO TheHdr.YMax
    Addr& = 80 * K&
    LineEnd& = Addr& + TheHdr.Bytespline
    J% = 1
    DO WHILE J% <= 4
      B% = J%
      IF J% = 3 THEN B% = 4
      IF J% = 4 THEN B% = 8
      OUT &H3C4, 2: OUT &H3C5, B%
      Byte = MID$(Buffer, FilePos%, 1)
      FilePos% = FilePos% + 1
      Byte1% = ASC(Byte)
      IF (Byte1% AND 192) <> 192 THEN
        POKE Addr&, Byte1%
        Addr& = Addr& + 1
        IF Addr& >= LineEnd& THEN
          Addr& = 80 * K&
          J% = J% + 1
        END IF
      ELSE
        Byte1% = Byte1% AND 63
        Byte = MID$(Buffer, FilePos%, 1)
        FilePos% = FilePos% + 1
        Byte2% = ASC(Byte)
        FOR m% = 1 TO Byte1%
          B% = J%
          IF J% = 3 THEN B% = 4
          IF J% = 4 THEN B% = 8
          OUT &H3C4, 2: OUT &H3C5, B%
          POKE Addr&, Byte2%
          Addr& = Addr& + 1
          IF Addr& >= LineEnd& THEN
            Addr& = 80 * K&
            J% = J% + 1
          END IF
        NEXT m%
      END IF
    LOOP
  NEXT K&
  OUT &H3C4, 2: OUT &H3C5, &HF
DEF SEG

DO: LOOP UNTIL INKEY$ <> ""
SCREEN 0
CLS
END

