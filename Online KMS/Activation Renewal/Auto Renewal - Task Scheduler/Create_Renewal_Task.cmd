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
title Create Renewal Task
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

mode con cols=98 lines=30

if %Unattended% EQU 1 goto continue

echo. &call :Color 4F "===== Important Info =====" &echo:&echo.

echo Some Anti-virus programs may interfere the process of Activation renewal 
echo via Task Scheduler. (Though it's clean from Windows Defender.)
echo.
echo It's not because of KMS activation but because they find running long script 
echo in background task, suspicious.
echo.
call :Color 0A "Please make sure to add exclusion in your AV for directory" &echo:
echo "%windir%\Online_KMS_Activation_Script"
echo.
echo If you want Anti-virus interference free experience then apply 
echo "Manual Renewal - Desktop Context Menu" or
echo Just run the file "Online_KMS_Activation.cmd" whenever you need it.
echo.

echo ----------------------------------------
echo   Press [A] or [B] button in Keyboard :
echo ----------------------------------------
echo.
choice /C:AB /N /M "[A] Continue [B] Exit : "

if errorlevel 2 exit /b
if errorlevel 1 goto continue

::========================================================================================================================================

:continue
cls
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

set "key=HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Schedule\taskcache\tasks"
reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Renewal" >nul && (
schtasks /delete /tn Online_KMS_Activation_Script-Renewal /f %nul%
)
reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Run_Once" >nul && (
schtasks /delete /tn Online_KMS_Activation_Script-Run_Once /f %nul%
)
If exist "%windir%\Online_KMS_Activation_Script" (
@RD /s /q "%windir%\Online_KMS_Activation_Script" %nul%
)
md "%windir%\Online_KMS_Activation_Script" %nul%

::========================================================================================================================================

if exist "%temp%\MAS" @RD /S /Q "%temp%\MAS" >nul 2>&1
md "%temp%\MAS" >nul 2>&1

call :export info > "%windir%\Online_KMS_Activation_Script\Info.txt"
call :export renewal > "%temp%\MAS\Renewal.xml"

copy /y /b "Online_KMS_Activation.cmd" "%temp%\MAS\Online_KMS_Activation.cmd" %nul%

(
echo @set "Renewal_Task=1"
echo.
)>"%temp%\MAS\1.."

copy /y /b "%temp%\MAS\1.." + "%temp%\MAS\Online_KMS_Activation.cmd" "%windir%\Online_KMS_Activation_Script\Online_KMS_Activation_Script-Renewal.cmd" %nul%
schtasks /create /tn "Online_KMS_Activation_Script-Renewal" /ru "SYSTEM" /xml "%temp%\MAS\Renewal.xml" %nul%

if exist "%temp%\MAS" @RD /S /Q "%temp%\MAS" %nul%

::========================================================================================================================================

reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Renewal" >nul || (set error_=1)
If not exist "%windir%\Online_KMS_Activation_Script\Online_KMS_Activation_Script-Renewal.cmd" (set error_=1)
If not exist "%windir%\Online_KMS_Activation_Script\Info.txt" (set error_=1)

call :Color_Pre
if defined error_ (
reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Renewal" >nul && (
schtasks /delete /tn Online_KMS_Activation_Script-Renewal /f %nul%
)
reg query "%key%" /f Path /s | find /i "\Online_KMS_Activation_Script-Run_Once" >nul && (
schtasks /delete /tn Online_KMS_Activation_Script-Run_Once /f %nul%
)
If exist "%windir%\Online_KMS_Activation_Script" (
@RD /s /q "%windir%\Online_KMS_Activation_Script" %nul%
)
echo ---------------------------------------------
call :Color 0C "Error - Try again" &echo:
echo ---------------------------------------------
) else (
echo ------------------------------------------------------------------------------------------
echo  Files created:
echo  %windir%\Online_KMS_Activation_Script\Online_KMS_Activation_Script-Renewal.cmd
echo  %windir%\Online_KMS_Activation_Script\Info.txt
echo.
echo  Scheduled Task created:
echo  Online_KMS_Activation_Script-Renewal
echo.
echo ------------------------------------------------------------------------------------------
call :Color 0A "Renewal Task was created successfully" &echo:
echo ------------------------------------------------------------------------------------------
)

goto Done

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

:info:[

: =================================================================
:  This script is a part of 'Microsoft Activation Scripts'
:  Maintained by @WindowsAddict
:  Homepage - https://www.nsaneforums.com/topic/316668--/
: =================================================================

The use of this script is to renew your Windows /Server /Office Activation using online KMS.

It stores some files in folder C:\Windows\Online_KMS_Activation_Script
and have scheduled task(s), You can view them in "Task Scheduler"

If you want complete script, updates and more info or want to properly uninstall it then, 
Go to this Script Homepage. 

Enjoy !
:info:]

:renewal:[
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.3" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Source>Microsoft Corporation</Source>
    <Date>1999-01-01T12:00:00.34375</Date>
    <Author>RPO/WindowsAddict</Author>
    <Version>1.0</Version>
    <Description>Online_KMS_Activation_Script-Renewal - Weekly Activation Renewal Task</Description>
    <URI>\Online_KMS_Activation_Script-Renewal</URI>
    <SecurityDescriptor>D:P(A;;FA;;;SY)(A;;FA;;;BA)(A;;FRFX;;;LS)(A;;FRFW;;;S-1-5-80-123231216-2592883651-3715271367-3753151631-4175906628)(A;;FR;;;S-1-5-4)</SecurityDescriptor>
  </RegistrationInfo>
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>1999-01-01T12:00:00</StartBoundary>
      <Enabled>true</Enabled>
      <ScheduleByWeek>
        <DaysOfWeek>
          <Sunday />
        </DaysOfWeek>
        <WeeksInterval>1</WeeksInterval>
      </ScheduleByWeek>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal id="LocalSystem">
      <UserId>S-1-5-18</UserId>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>true</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <DisallowStartOnRemoteAppSession>false</DisallowStartOnRemoteAppSession>
    <UseUnifiedSchedulingEngine>true</UseUnifiedSchedulingEngine>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT10M</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT2M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="LocalSystem">
    <Exec>
      <Command>%windir%\Online_KMS_Activation_Script\Online_KMS_Activation_Script-Renewal.cmd</Command>
    </Exec>
  </Actions>
</Task>
:renewal:]

::========================================================================================================================================

: =============================================================
:  Extract the text from batch script without character issue
:  Written by @AveYo aka @BAU
: =============================================================

:export usage: call :export NAME
setlocal enabledelayedexpansion || Prints all text between lines starting with :NAME:[ and :NAME:] - A pure batch snippet by AveYo
set [=&for /f "delims=:" %%s in ('findstr/nbrc:":%~1:\[" /c:":%~1:\]" "%~f0"') do if defined [ (set/a ]=%%s-3) else set/a [=%%s-1
<"%~fs0" ((for /l %%i in (0 1 %[%) do set /p =)&for /l %%i in (%[% 1 %]%) do (set txt=&set /p txt=&echo(!txt!)) &endlocal &exit/b

::========================================================================================================================================

exit/b --><package><job id="adm"><script language="VBScript">args=CreateObject("WScript.Shell").ExpandEnvironmentStrings("%args%")
RunAs=CreateObject("Shell.Application").ShellExecute("cmd.exe","/c set ?=y&call "&args,,"runas")</script></job></package>
