@echo off
setlocal

for %%D in ("%CD%") do set "ThisDir=%%~nxD"
set outfile=%ThisDir%.gb
if not exist %outfile% goto as
echo Cleaning up
del /s *.lst *.sym %outfile%>NUL
echo.

:as
call !assemble.bat
endlocal