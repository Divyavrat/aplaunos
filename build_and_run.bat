@echo off
echo ===================================
echo   Aplaun OS Build ^& Run Script
echo ===================================

echo.
echo [1/4] Compiling BOOT and Kernel...
toolchain\nasm src\boot\BOOT.ASM -O1 -o build\BOOT.IMG
toolchain\nasm src\kernel\kernel.ASM -O1 -o build\kernel.COM

echo.
echo [2/4] Building System Apps and Utilities...
python toolchain\build_apps.py

echo.
echo [3/4] Building File System...
python toolchain\mkfloppy.py
python toolchain\inject_files.py

echo.
echo [4/4] Booting OS in VirtualBox...
call toolchain\run_vbox.bat

echo.
echo === Build and Execution Finished ===
pause
