@echo off
setlocal
title Cinematic Loading Screen

set "installer=%~dp0INSTALL.ps1"

if not exist "%installer%" (
    set "installer="

    for /f "delims=" %%I in ('powershell.exe -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $roots=[System.Collections.Generic.List[string]]::new(); foreach($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam')){$item=Get-ItemProperty $key -ErrorAction SilentlyContinue; if($item){foreach($name in @('SteamPath','InstallPath')){$value=$item.$name; if($value -and (Test-Path $value)){$roots.Add([IO.Path]::GetFullPath($value))}}}}; foreach($root in @($roots)){$vdf=Join-Path $root 'steamapps\libraryfolders.vdf'; if(Test-Path $vdf){$text=[IO.File]::ReadAllText($vdf); foreach($match in [regex]::Matches($text,'\"path\"\s+\"([^\"]+)\"')){$path=$match.Groups[1].Value -replace '\\\\','\'; if(Test-Path $path){$roots.Add([IO.Path]::GetFullPath($path))}}}}; $found=@(); foreach($root in ($roots | Select-Object -Unique)){$workshop=Join-Path $root 'steamapps\workshop\content\108600'; if(Test-Path $workshop){foreach($item in Get-ChildItem $workshop -Directory){$modInfo=Join-Path $item.FullName 'mods\CinematicLoadingScreen\42.0\mod.info'; $script=Join-Path $item.FullName 'INSTALL.ps1'; if((Test-Path $modInfo) -and (Test-Path $script) -and ((Get-Content $modInfo) -contains 'id=CinematicLoadingScreen')){$found += $item}}}}; $selected=$found | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($selected){Join-Path $selected.FullName 'INSTALL.ps1'}"') do set "installer=%%I"
)

if not defined installer (
    echo.
    echo Cinematic Loading Screen was not found
    echo.
    echo Subscribe to the Steam Workshop item and wait for Steam to finish downloading it
    echo Then run this file again
    echo.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%installer%"
set "exitCode=%ERRORLEVEL%"

echo.

if not "%exitCode%"=="0" (
    echo Installation failed
    echo Exit code: %exitCode%
    echo.
    pause
    exit /b %exitCode%
)

echo Installation complete
echo.
echo You can now start Project Zomboid
echo.
pause

exit /b 0
