@ECHO OFF
IF EXIST %1 GOTO DO
IF EXIST %1.COM GOTO DO
IF EXIST %1.EXE GOTO DO
ECHO Can't find file '%1', '%1.com', '%1.exe'.
GOTO END
:DO
%1
IF NOT ERRORLEVEL 10 GOTO NE10
ECHO Program '%1' returned errorlevel 10.
GOTO END
:NE10
IF NOT ERRORLEVEL 9 GOTO NE9
ECHO Program '%1' returned errorlevel 9.
GOTO END
:NE9
IF NOT ERRORLEVEL 8 GOTO NE8
ECHO Program '%1' returned errorlevel 8.
GOTO END
:NE8
IF NOT ERRORLEVEL 7 GOTO NE7
ECHO Program '%1' returned errorlevel 7.
GOTO END
:NE7
IF NOT ERRORLEVEL 6 GOTO NE6
ECHO Program '%1' returned errorlevel 6.
GOTO END
:NE6
IF NOT ERRORLEVEL 5 GOTO NE5
ECHO Program '%1' returned errorlevel 5.
GOTO END
:NE5
IF NOT ERRORLEVEL 4 GOTO NE4
ECHO Program '%1' returned errorlevel 4.
GOTO END
:NE4
IF NOT ERRORLEVEL 3 GOTO NE3
ECHO Program '%1' returned errorlevel 3.
GOTO END
:NE3
IF NOT ERRORLEVEL 2 GOTO NE2
ECHO Program '%1' returned errorlevel 2.
GOTO END
:NE2
IF NOT ERRORLEVEL 1 GOTO NE1
ECHO Program '%1' returned errorlevel 1.
GOTO END
:NE1
ECHO Program '%1' returned errorlevel 0 (no error).
:END
