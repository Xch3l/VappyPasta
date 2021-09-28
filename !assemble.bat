@echo off
setlocal

for %%D in ("%CD%") do set "ThisDir=%%~nxD"

set outname=%ThisDir%
set prjfile=head.asm
set N=1

:check
if not exist "old\%outname%_%N%.gb" goto backupold

set /A N+=1
goto check

:backupold
if not exist %outname%.gb goto asm
if not exist "old/" mkdir old
move %outname%.gb "old\%outname%_%N%.gb">NUL

:asm
call ..\..\WLADX\assemble.bat gb %prjfile% %outname%.gb

:fin
if "%2" == "" pause > nul
endlocal