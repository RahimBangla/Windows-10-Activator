<!-- :: 
@echo off

:: For unattended mode, run the script with /u parameter.




::========================================================================================================================================

: =================================================================
:  This script is a part of 'Microsoft Activation Scripts'
:  Maintained by @WindowsAddict
:  Homepage - https://www.nsaneforums.com/topic/316668--/
: =================================================================

::========================================================================================================================================




















::========================================================================================================================================

cls
title Online KMS Complete Uninstall
if /i "%*" EQU "/u" (set Unattended=1) else (set Unattended=0)
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set "ELine=echo. &call :Color 4F "==== ERROR ====" &echo:&echo."
setlocal EnableDelayedExpansion
call :Color_Pre

::========================================================================================================================================

: ===========================================================
:  Check if the file path name contains special characters
:  https://stackoverflow.com/a/33626625
:  Written by @jeb (stackoverflow)
:  Thanks to @abbodi1406 (MDL) for the help.
: ===========================================================

setlocal
setlocal DisableDelayedExpansion
set "param=%~f0"
cmd /v:on /c echo(^^!param^^!| findstr /R "[| ` ~ ! @ %% \^ & ( ) \[ \] { } + = ; ' , |]*^"
endlocal
if %errorlevel% EQU 0 (
%ELine%
echo Disallowed special characters detected in file path name.
echo Make sure file path name do not have following special characters,
echo ^` ^~ ^! ^@ %% ^^ ^& ^( ^) [ ] { } ^+ ^= ^; ^' ^,
goto Done
)

::========================================================================================================================================

if %winbuild% LSS 7600 (
%ELine%
echo Unsupported OS version Detected.
echo Project is supported only for Windows 7/8/8.1/10 and their Server equivalent.
goto Done
)

::========================================================================================================================================

: ==========================================================
:  self-elevate passing args and preventing loop
:  using wsf - needs the 1st and the last 2 lines in place)
:  Written by @AveYo aka @BAU
: ==========================================================

reg query HKU\S-1-5-19 >nul 2>nul && goto GotPrivileges
if "%?%" equ "y" goto ElevationError

set "args="%~f0" %*"
call cscript /nologo "%~f0?.wsf" //job:adm && exit /b

:ElevationError
%ELine%
echo Right click on this file and select 'Run as administrator'
goto Done

:GotPrivileges

::========================================================================================================================================

mode con: cols=98 lines=30
set "key=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\taskcache\tasks"

reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Renewal" >nul && (
echo Deleting [Task] Online_KMS_Activation_Script-Renewal
schtasks /delete /tn Online_KMS_Activation_Script-Renewal /f 1>nul 2>nul
)

reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Run_Once" >nul && (
echo Deleting [Task] Online_KMS_Activation_Script-Run_Once
schtasks /delete /tn Online_KMS_Activation_Script-Run_Once /f 1>nul 2>nul
)

If exist "%windir%\Online_KMS_Activation_Script" (
echo Deleting [Folder] %windir%\Online_KMS_Activation_Script
@RD /s /q "%windir%\Online_KMS_Activation_Script" >nul 2>&1
)

if exist "%ProgramData%\Online_KMS_Activation.cmd" (
echo Deleting [Context Menu File] %ProgramData%\Online_KMS_Activation.cmd
del /f /q "%ProgramData%\Online_KMS_Activation.cmd" >nul 2>&1
)

reg query "HKCR\DesktopBackground\shell\Activate Windows - Office" >nul 2>&1 && (
echo Deleting [Context Menu Registry] HKCR\DesktopBackground\shell\Activate Windows - Office
Reg delete "HKCR\DesktopBackground\shell\Activate Windows - Office" /f >nul 2>&1
)

echo.

::========================================================================================================================================

: ==================================================
:  Clear-KMS-Cache.cmd  
:  https://forums.mydigitallife.net/posts/1511883
:  Written by @abbodi1406 (MDL)
: ==================================================

set "SysPath=%Windir%\System32"
if exist "%Windir%\Sysnative\reg.exe" (set "SysPath=%Windir%\Sysnative")
set "Path=%SysPath%;%Windir%;%SysPath%\Wbem;%SysPath%\WindowsPowerShell\v1.0\"
set "OSPP=SOFTWARE\Microsoft\OfficeSoftwareProtectionPlatform"
set "SPPk=SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
wmic path SoftwareLicensingProduct where (Description like '%%KMSCLIENT%%') get Name 2>nul | findstr /i Windows 1>nul && (set SppHook=1) || (set SppHook=0)
wmic path SoftwareLicensingProduct where (Description like '%%KMSCLIENT%%') get Name 2>nul | findstr /i Office 1>nul && (set SppHook=1)
wmic path OfficeSoftwareProtectionService get Version >nul 2>&1 && (set OsppHook=1) || (set OsppHook=0)
if %SppHook% NEQ 0 call :cKMS SoftwareLicensingProduct SoftwareLicensingService SPP
if %OsppHook% NEQ 0 call :cKMS OfficeSoftwareProtectionProduct OfficeSoftwareProtectionService OSPP
call :cREG >nul 2>&1
echo.
goto Verify

:cKMS
echo Clearing %3 KMS Cache...
set spp=%1
set sps=%2
for /f "tokens=2 delims==" %%G in ('"wmic path %spp% where (Description like '%%KMSCLIENT%%') get ID /VALUE" 2^>nul') do (set app=%%G&call :cAPP)
for /f "tokens=2 delims==" %%A in ('"wmic path %sps% get Version /VALUE"') do set ver=%%A
wmic path %sps% where version='%ver%' call ClearKeyManagementServiceMachine >nul 2>&1
wmic path %sps% where version='%ver%' call ClearKeyManagementServicePort >nul 2>&1
wmic path %sps% where version='%ver%' call DisableKeyManagementServiceDnsPublishing 1 >nul 2>&1
wmic path %sps% where version='%ver%' call DisableKeyManagementServiceHostCaching 1 >nul 2>&1
goto :eof

:cAPP
wmic path %spp% where ID='%app%' call ClearKeyManagementServiceMachine >nul 2>&1
wmic path %spp% where ID='%app%' call ClearKeyManagementServicePort >nul 2>&1
goto :eof

:cREG
reg delete "HKLM\%SPPk%\55c92734-d682-4d71-983e-d6ec3f16059f" /f
reg delete "HKLM\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f
reg delete "HKLM\%SPPk%" /f /v KeyManagementServiceName
reg delete "HKLM\%SPPk%" /f /v KeyManagementServicePort
reg delete "HKU\S-1-5-20\%SPPk%\55c92734-d682-4d71-983e-d6ec3f16059f" /f
reg delete "HKU\S-1-5-20\%SPPk%\0ff1ce15-a989-479d-af46-f275c6370663" /f
reg delete "HKLM\%OSPP%\59a52881-a989-479d-af46-f275c6370663" /f
reg delete "HKLM\%OSPP%\0ff1ce15-a989-479d-af46-f275c6370663" /f
reg delete "HKLM\%OSPP%" /f /v KeyManagementServiceName
reg delete "HKLM\%OSPP%" /f /v KeyManagementServicePort
if %OsppHook% NEQ 1 (
reg delete "HKLM\%OSPP%" /f
reg delete "HKU\S-1-5-20\%OSPP%" /f
)
goto :eof

::========================================================================================================================================

:Verify

reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Renewal" >nul && (set error_=1)
reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Run_Once" >nul && (set error_=1)
If exist "%windir%\Online_KMS_Activation_Script" (set error_=1)

reg query "HKCR\DesktopBackground\shell\Activate Windows - Office" >nul 2>&1 && (set error_=1)
if exist "%ProgramData%\Online_KMS_Activation.cmd" (set error_=1)

if defined error_ (
echo ---------------------------------------------
call :Color 0C "Error - Try again" &echo:
echo ---------------------------------------------
) else (
echo --------------------------------------------
call :Color 0A "Complete Uninstall was done successfully" &echo:
echo --------------------------------------------
)

::========================================================================================================================================

:Done

echo.
if %Unattended% EQU 1 (
echo Exiting in 5 seconds...
if %winbuild% LSS 7600 (ping -n 5 127.0.0.1 > nul) else (timeout /t 5)
exit /b
)
echo Press any key to exit...
pause >nul
exit /b

::========================================================================================================================================

: ======================================================
:  Multicolor outputs without any external programs
:  https://stackoverflow.com/a/5344911
:  Written by @jeb (stackoverflow)
: ======================================================

:Color_Pre
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (set "DEL=%%a") &exit /b

:color
pushd "%temp%"
<nul set /p ".=%DEL%" > "%~2" &findstr /v /a:%1 /R "^$" "%~2" nul &del "%~2" > nul 2>&1 &popd &exit /b

::========================================================================================================================================

exit/b --><package><job id="adm"><script language="VBScript">args=CreateObject("WScript.Shell").ExpandEnvironmentStrings("%args%")
RunAs=CreateObject("Shell.Application").ShellExecute("cmd.exe","/c set ?=y&call "&args,,"runas")</script></job></package>
