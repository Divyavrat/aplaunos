echo Assembling programs...
 for %%i in (*.asm) do nasm -O5 -fbin %%i
for %%i in (*.com) do del %%i
for %%i in (*.) do ren %%i %%i.com
pause