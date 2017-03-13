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
REM // Ensure that the script is running as administrator.
REM //

>nul 2>&1 "%SystemRoot%\system32\cacls.exe" "%SystemRoot%\system32\config\system"

if errorlevel 1 (
    echo This script must be run as the administrator.
    exit /b 1
)

REM //
REM // Abort if a drive with mount point letter X already exists on this system to prevent
REM // accidental data loss.
REM //

if exist X:\ (
    echo A drive with letter 'X' already exists on this system. Please dismount X: drive.
    exit /b 6969
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
REM // Initialise operating parameters.
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
REM // Ensure that the specified disk image does not already exist.
REM //

if exist "%VDiskPath%" (
    echo Disk image file already exists. Script execution aborted.
    exit /b 3
)

REM //
REM // Create a disk image.
REM //
REM // (1) Create virtual disk file.
REM // (2) Initialize disk partition table.
REM // (3) Create partition.
REM // (4) Mount partition.
REM //

(
echo automount disable
echo automount scrub
echo create vdisk file="%VDiskPath%" maximum=%VDiskSize% type=expandable
echo select vdisk file="%VDiskPath%"
echo attach vdisk
echo convert %VDiskPtType%
echo create partition primary
echo select partition 1
echo assign letter=X
) > %Temp%\CreateDiskImage.DiskPartScript

diskpart /s %Temp%\CreateDiskImage.DiskPartScript

REM //
REM // (5) Format partition.
REM //

format /y x: /q /fs:%VDiskFsType% /v:OpenNT

REM //
REM // (6) Dismount partition.
REM // (7) Detach virtual disk file.
REM //

(
echo select vdisk file="%VDiskPath%"
echo select partition 1
echo remove
echo detach vdisk
) > %Temp%\CreateDiskImage.DiskPartScript

diskpart /s %Temp%\CreateDiskImage.DiskPartScript

del %Temp%\CreateDiskImage.DiskPartScript

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

exit /b 2
