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
title  Add Online KMS Desktop Context Menu
if /i "%*" EQU "/u" (set Unattended=1) else (set Unattended=0)
for /f "tokens=6 delims=[]. " %%G in ('ver') do set winbuild=%%G
set "nul=>nul 2>&1"
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
cd /d "%~dp0"
pushd "%~dp0"

cd ..
cd ..

if not exist "Online_KMS_Activation.cmd" (
%ELine%
echo File [Online KMS\Online_KMS_Activation.cmd] does not exist.
echo It's required for the Task Creation.
goto Done
)

::========================================================================================================================================

:continue

Reg delete "HKCR\DesktopBackground\shell\Activate Windows - Office" /f %nul%
if exist "%ProgramData%\Online_KMS_Activation.cmd" del /f /q "%ProgramData%\Online_KMS_Activation.cmd" %nul%

reg query "HKCR\DesktopBackground\shell\Activate Windows - Office" %nul% && (set error_1=1)
if exist "%ProgramData%\Online_KMS_Activation.cmd" %nul% (set error_1=1)

Reg add "HKCR\DesktopBackground\shell\Activate Windows - Office" /v "Icon" /t REG_SZ /d "%SystemRoot%%\System32\shell32.dll,71" /f >nul 2>&1 || (set error_1=1)
Reg add "HKCR\DesktopBackground\shell\Activate Windows - Office\command" /ve /t REG_SZ /d "\"%ProgramData%\Online_KMS_Activation.cmd\"" /f %nul% || (set error_1=1)

copy /y /b "Online_KMS_Activation.cmd" "%ProgramData%\Online_KMS_Activation.cmd" %nul% 
if not exist "%ProgramData%\Online_KMS_Activation.cmd" (set error_1=1)
reg query "HKCR\DesktopBackground\shell\Activate Windows - Office" %nul% || (set error_1=1)

if defined error_1 (
Reg delete "HKCR\DesktopBackground\shell\Activate Windows - Office" /f %nul%
if exist "%ProgramData%\Online_KMS_Activation.cmd" del /f /q "%ProgramData%\Online_KMS_Activation.cmd" %nul%
echo ---------------------------------------------
call :Color 0C "Error - Try again" &echo:
echo ---------------------------------------------
) else (
echo ------------------------------------------------------------------------------------------
call :Color 0A "File created-" &echo:
echo %ProgramData%\Online_KMS_Activation.cmd
echo.
call :Color 0A "Registry entry added-" &echo:
echo HKCR\DesktopBackground\shell\Activate Windows - Office
echo HKCR\DesktopBackground\shell\Activate Windows - Office\command
echo ------------------------------------------------------------------------------------------
call :Color 0A "Desktop context menu entry for Online KMS Activation was created successfully" &echo:
echo ------------------------------------------------------------------------------------------
)
echo.

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
