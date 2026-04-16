@echo off
set VBOX="C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
set VMNAME="AplaunOS_Emu"
set IMAGE="%~dp0..\fat16.img"

echo Stopping VM if running...
%VBOX% controlvm %VMNAME% poweroff >nul 2>&1
timeout /t 2 /nobreak >nul
taskkill /IM VirtualBoxVM.exe /F >nul 2>&1
timeout /t 1 /nobreak >nul

echo Checking if VM exists...
%VBOX% showvminfo %VMNAME% >nul 2>&1
IF ERRORLEVEL 1 (
    echo Creating new VM...
    %VBOX% createvm --name %VMNAME% --ostype "Other" --register
    %VBOX% modifyvm %VMNAME% --memory 64 --boot1 floppy
    %VBOX% storagectl %VMNAME% --name "Floppy" --add floppy
    %VBOX% storageattach %VMNAME% --storagectl "Floppy" --port 0 --device 0 --type fdd --medium %IMAGE%
) ELSE (
    echo VM already exists. We will just start it!
    rem Re-attaching just in case:
    %VBOX% storageattach %VMNAME% --storagectl "Floppy" --port 0 --device 0 --type fdd --medium %IMAGE% >nul 2>&1
)

echo Starting VM...
%VBOX% startvm %VMNAME%
