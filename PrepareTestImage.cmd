@echo off

REM /*++
REM
REM Copyright (c) 2017  OpenNT Project
REM 
REM Module Name:
REM
REM     PrepareTestImage.cmd
REM
REM Abstract:
REM
REM     This script prepares a test image for NT operating system.
REM
REM Author:
REM
REM     Stephanos Ioannidis (stephanosio)  11-Mar-17
REM
REM Revision History:
REM
REM --*/

REM //
REM // Ensure that the script is running as administrator and request administrator privilege if
REM // if required.
REM //

>nul 2>&1 "%SystemRoot%\system32\cacls.exe" "%SystemRoot%\system32\config\system"

if errorlevel 1 (
    echo Administrator privilege required. Re-launching as the administrator.
    
    echo Set UAC = CreateObject^("Shell.Application"^) > "%Temp%\RunAsAdmin.vbs"
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %1 %2", "", "runas", 1 >> "%Temp%\RunAsAdmin.vbs"

    "%Temp%\RunAsAdmin.vbs"
    del "%Temp%\RunAsAdmin.vbs"
    exit /b
)

REM //
REM // Save environment and change current directory to the script file directory.
REM //

setlocal
pushd %~dp0

REM //
REM // Check input parameters.
REM //

if "%1" equ "" goto DisplayUsage
if "%2" equ "" goto DisplayUsage

REM //
REM // Initialise operating parameters.
REM //

set ImageFilePath=%1
set NtTreePath=%2

REM //
REM // Ensure that the NT tree path exists.
REM //

if not exist "%NtTreePath%" (
    echo The specified NtTreePath does not exist.
    exit /b 2
)

REM //
REM // Create a disk image.
REM //

if exist "%1" del "%1"

call CreateDiskImage.cmd %1 512 mbr ntfs

if errorlevel 1 (
    echo Failed to create a disk image. Aborted.
    exit /b 3
)

REM //
REM // Mount disk image.
REM //

(
echo select vdisk file="%ImageFilePath%"
echo attach vdisk
echo select partition 1
echo assign letter=X
) > %Temp%\PrepareTestImage.DiskPartScript

diskpart /s %Temp%\PrepareTestImage.DiskPartScript

REM //
REM // Write boot code.
REM //
REM // NOTE: We use /nt60 parameter that writes the NT 6.0 boot code because it loads NTLDR if
REM //       BOOTMGR is not available anyway.
REM //

bootsect /nt60 X: /mbr

REM //
REM // Create system directory structure.
REM //

mkdir "X:\Windows"
mkdir "X:\Windows\System32"
mkdir "X:\Windows\System32\Config"

REM //
REM // Copy NTLDR, NTDETECT.COM and write boot.ini.
REM //

echo Copying NTLDR ...
copy /y "%NtTreePath%\ntldr" "X:\ntldr"

echo Copying NTDETECT.COM ...
copy /y "%NtTreePath%\ntdetect.com" "X:\ntdetect.com"

echo Writing boot.ini ...

(
echo [boot loader]
echo timeout=30
echo default=multi^(0^)disk^(0^)rdisk^(0^)partition^(1^)\Windows
echo.
echo [operating systems]
echo multi^(0^)disk^(0^)rdisk^(0^)partition^(1^)\Windows="OpenNT"
) > X:\boot.ini

REM //
REM // Copy kernel and HAL.
REM //

echo Copying kernel ...
copy /y "%NtTreePath%\ntkrnlmp.exe" "X:\Windows\System32\ntoskrnl.exe"

echo Copying HAL ...
copy /y "%NtTreePath%\halmps.dll" "X:\Windows\System32\hal.dll"

REM //
REM // Generate SYSTEM registry hive.
REM //

echo Generating SYSTEM registry hive ...

REM // TODO: Write code that generates SYSTEM registry hive.
copy /y "%NtTreePath%\system" "X:\Windows\System32\Config\system"

REM //
REM // Dismount disk image.
REM //

(
echo select vdisk file="%ImageFilePath%"
echo select partition 1
echo active
echo remove
echo detach vdisk
) > %Temp%\PrepareTestImage.DiskPartScript

diskpart /s %Temp%\PrepareTestImage.DiskPartScript

del %Temp%\PrepareTestImage.DiskPartScript

REM //
REM // Restore environment.
REM //

popd
endlocal

exit /b 0

REM //
REM // Display script usage if invalid parameters are supplied.
REM //

:DisplayUsage
echo.
echo Usage:
echo  PrepareTestImage.cmd [ImageFilePath] [NtTreePath]
echo.
echo  ImageFilePath = Path to the test disk image file to be created
echo  NtTreePath = Path to the NT flat binary tree
echo.
echo Example:
echo  PrepareTestImage.cmd C:\test.vhd C:\OpenNT\Binaries\MinNT.master\x86chk
echo.

exit /b 1
