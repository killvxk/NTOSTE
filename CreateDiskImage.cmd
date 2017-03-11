@echo off

REM /*++
REM
REM Copyright (c) 2017  OpenNT Project
REM 
REM Module Name:
REM
REM     CreateDiskImage.cmd
REM
REM Abstract:
REM
REM     This script creates a disk image with a pre-formatted partition for testing.
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
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %1 %2 %3 %4", "", "runas", 1 >> "%Temp%\RunAsAdmin.vbs"

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
if "%3" equ "" goto DisplayUsage
if "%4" equ "" goto DisplayUsage

REM //
REM // Virtual Disk Image Parameters
REM //

REM set VDiskPath=C:\OpenNT\Repositories\NTOSTE.master\test.vhd
REM set VDiskSize=512
REM set VDiskPtType=mbr
REM set VDiskFsType=ntfs

set VDiskPath=%1
set VDiskSize=%2
set VDiskPtType=%3
set VDiskFsType=%4

REM //
REM // (1) Create virtual disk file.
REM // (2) Initialize disk partition table.
REM // (3) Create partition.
REM // (4) Format partition.
REM // (5) Mount partition.
REM // (6) Dismount partition.
REM // (7) Set partition as active boot partition.
REM // (8) Detach virtual disk file.
REM //
REM // NOTE: automount enable is required; otherwise, format step would fail.
REM //

(
echo automount enable
echo create vdisk file="%VDiskPath%" maximum=%VDiskSize% type=expandable
echo select vdisk file="%VDiskPath%"
echo attach vdisk
echo convert %VDiskPtType%
echo create partition primary
echo select partition 1
echo format fs=ntfs quick label="OpenNT"
echo active
echo detach vdisk
) > %Temp%\CreateTestImage.DiskPartScript

diskpart /s %Temp%\CreateTestImage.DiskPartScript

del %Temp%\CreateTestImage.DiskPartScript

REM //
REM // Restore environment.
REM //

popd
endlocal

exit /b

REM //
REM // Display script usage if invalid parameters are supplied.
REM //

:DisplayUsage
echo.
echo Usage:
echo  CreateDiskImage.cmd [FilePath] [MaximumSize] [PartitionTableType] [FilesystemType]
echo.
echo  FilePath = Path to the disk image file to be created
echo  MaximumSize = Maximum size of the disk image in megabytes
echo  PartitionTableType = Partition table type (mbr or gpt)
echo  FilesystemType = Filesystem type (fat, fat32, ntfs)
echo.
echo Example:
echo  CreateDiskImage.cmd C:\test.vhd 512 mbr ntfs
echo.

exit /b
