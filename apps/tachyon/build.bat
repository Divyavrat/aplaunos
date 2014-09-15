echo Assembling programs...
rem for %%i in (*.asm) do nasm -O0 -fbin %%i
rem for %%i in (*.com) do del %%i
rem for %%i in (*.) do ren %%i %%i.com
fasm display.asm display.com
fasm mouse.asm mouse.com
fasm play.asm play.com
fasm mplay.asm mplay.com
fasm tuneedit.asm tuneedit.com
pause