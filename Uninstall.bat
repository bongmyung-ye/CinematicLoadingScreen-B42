@echo off
setlocal
title Cinematic Loading Screen

set "script=%~dp0UNINSTALL.ps1"

if not exist "%script%" (
    echo.
    echo UNINSTALL.ps1 was not found
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%script%"
set "exitCode=%ERRORLEVEL%"

echo.

if not "%exitCode%"=="0" (
    echo Uninstall failed
    echo Exit code: %exitCode%
    echo.
    pause
    exit /b %exitCode%
)

echo Uninstall complete
echo.
pause

exit /b 0
