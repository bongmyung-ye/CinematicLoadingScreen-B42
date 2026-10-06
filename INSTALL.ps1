$ErrorActionPreference = 'Stop'

function Get-SteamRoots {
    $roots = [System.Collections.Generic.List[string]]::new()

    foreach ($key in @(
        'HKCU:\Software\Valve\Steam',
        'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam',
        'HKLM:\SOFTWARE\Valve\Steam'
    )) {
        $item = Get-ItemProperty $key -ErrorAction SilentlyContinue
        if (-not $item) { continue }

        foreach ($name in @('SteamPath', 'InstallPath')) {
            $value = $item.$name
            if ($value -and (Test-Path $value)) {
                $roots.Add([IO.Path]::GetFullPath($value))
            }
        }
    }

    $default = Join-Path ${env:ProgramFiles(x86)} 'Steam'
    if (Test-Path $default) {
        $roots.Add([IO.Path]::GetFullPath($default))
    }

    foreach ($root in @($roots)) {
        $vdf = Join-Path $root 'steamapps\libraryfolders.vdf'
        if (-not (Test-Path $vdf)) { continue }

        $text = [IO.File]::ReadAllText($vdf)
        foreach ($match in [regex]::Matches($text, '"path"\s+"([^"]+)"')) {
            $path = $match.Groups[1].Value -replace '\\\\', '\'
            if (Test-Path $path) {
                $roots.Add([IO.Path]::GetFullPath($path))
            }
        }
    }

    $roots | Select-Object -Unique
}

function Get-GamePath {
    foreach ($root in Get-SteamRoots) {
        $path = Join-Path $root 'steamapps\common\ProjectZomboid'
        if (Test-Path (Join-Path $path 'ProjectZomboid64.json')) {
            return $path
        }
    }

    throw 'Project Zomboid installation not found.'
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Remove-AgentArgument([string]$Text) {
    [regex]::Replace(
        $Text,
        '(?m)^[ \t]*"-javaagent:[^"\r\n]*CinematicLoadingScreenAgent\.jar"[ \t]*,?[ \t]*\r?\n?',
        ''
    )
}

function Set-AgentArgument([string]$JsonPath, [string]$Argument) {
    $text = [IO.File]::ReadAllText($JsonPath)
    $clean = Remove-AgentArgument $text
    $null = $clean | ConvertFrom-Json

    $match = [regex]::Match($clean, '(?m)^([ \t]*)"vmArgs"\s*:\s*\[')
    if (-not $match.Success) {
        throw 'vmArgs was not found in ProjectZomboid64.json.'
    }

    $lineBreak = if ($clean.Contains("`r`n")) { "`r`n" } else { "`n" }
    $indent = $match.Groups[1].Value + '    '
    $position = $match.Index + $match.Length
    $tail = $clean.Substring($position)
    $comma = if ($tail -match '^\s*\]') { '' } else { ',' }
    $insert = $lineBreak + $indent + '"' + $Argument + '"' + $comma
    $updated = $clean.Insert($position, $insert)
    $null = $updated | ConvertFrom-Json

    if ($updated -ne $text) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        Copy-Item $JsonPath "$JsonPath.cinematic-loading-backup-$stamp" -Force
        Write-Utf8NoBom $JsonPath $updated
    }
}

if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) {
    throw 'Close Project Zomboid before installing.'
}

$game = Get-GamePath
$json = Join-Path $game 'ProjectZomboid64.json'
$runtimeRoot = Join-Path $env:USERPROFILE 'Zomboid\CinematicLoadingScreen'
$statePath = Join-Path $runtimeRoot 'state.json'
$payloadRoot = if ((Split-Path $PSScriptRoot -Leaf) -ieq 'installer') {
    [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
} else {
    $PSScriptRoot
}
$sourceAgent = Join-Path $payloadRoot 'runtime\CinematicLoadingScreenAgent.jar'
$agentPath = Join-Path $runtimeRoot 'CinematicLoadingScreenAgent.jar'
$assetRoot = Join-Path $runtimeRoot 'assets'
$frameRoot = Join-Path $runtimeRoot 'frames'
$sourceAudio = Join-Path $payloadRoot 'runtime\loading_audio.ogg'
$sourceFrames = Join-Path $payloadRoot 'runtime\frames'
$modSource = $payloadRoot
$modTarget = Join-Path $env:USERPROFILE 'Zomboid\mods\CinematicLoadingScreen'

if (-not (Test-Path $sourceAgent)) { throw "Missing runtime: $sourceAgent" }
if (-not (Test-Path $sourceAudio)) { throw "Missing audio: $sourceAudio" }
if (-not (Test-Path $sourceFrames)) { throw "Missing frames: $sourceFrames" }
if (-not (Test-Path (Join-Path $modSource '42.0\mod.info'))) { throw 'Mod metadata is missing.' }

$frameCount = (Get-ChildItem $sourceFrames -Filter 'frame_*.jpg' -File).Count
if ($frameCount -ne 3696) {
    throw "Expected 3696 video frames, found $frameCount."
}

$runtimeHash = (Get-FileHash $sourceAgent -Algorithm SHA256).Hash
Write-Host ''
Write-Host 'Cinematic Loading Screen'
Write-Host "Game:          $game"
Write-Host "Runtime SHA-256: $runtimeHash"
Write-Host ''

$state = $null
if (Test-Path $statePath) {
    try {
        $state = Get-Content $statePath -Raw | ConvertFrom-Json
    } catch {
        $state = $null
    }
}

New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
Copy-Item $sourceAgent $agentPath -Force

New-Item -ItemType Directory -Path $assetRoot -Force | Out-Null
Copy-Item $sourceAudio (Join-Path $assetRoot 'loading_audio.ogg') -Force

if (Test-Path $frameRoot) {
    Remove-Item $frameRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $frameRoot -Force | Out-Null
Copy-Item (Join-Path $sourceFrames 'frame_*.jpg') $frameRoot -Force
$isWorkshopInstall = $payloadRoot -match '(?i)[\\/]steamapps[\\/]workshop[\\/]content[\\/]108600[\\/]\d+(?:[\\/]|$)'
$localModInstalled = $false

if (-not $isWorkshopInstall) {
    if (Test-Path $modTarget) {
        Remove-Item $modTarget -Recurse -Force
    }
    New-Item -ItemType Directory -Path $modTarget -Force | Out-Null
    Copy-Item (Join-Path $modSource '*') $modTarget -Recurse -Force
    $localModInstalled = $true
}

$agentArgument = '-javaagent:' + ($agentPath -replace '\\', '/')
Set-AgentArgument $json $agentArgument

$pzoptPath = Join-Path $env:USERPROFILE 'Zomboid\pzopt\options.ini'
$pzoptChanged = $false
if ($state -and $state.pzoptChanged) {
    $pzoptChanged = $true
}

if (Test-Path $pzoptPath) {
    $options = [IO.File]::ReadAllText($pzoptPath)
    if ($options -match '(?im)^noLoadingScreen\s*=\s*true\s*$') {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        Copy-Item $pzoptPath "$pzoptPath.cinematic-loading-backup-$stamp" -Force
        $options = [regex]::Replace(
            $options,
            '(?im)^noLoadingScreen\s*=\s*true\s*$',
            'noLoadingScreen=false'
        )
        Write-Utf8NoBom $pzoptPath $options
        $pzoptChanged = $true
    }
}

$stateObject = [ordered]@{
    gamePath = $game
    agentArgument = $agentArgument
    runtimeHash = $runtimeHash
    pzoptChanged = $pzoptChanged
    localModInstalled = $localModInstalled
}
Write-Utf8NoBom $statePath ($stateObject | ConvertTo-Json)

Write-Host ''
Write-Host 'Installation complete.'
Write-Host 'Mod ID: CinematicLoadingScreen'
Write-Host 'Restart Project Zomboid and enable Cinematic Loading Screen in the global Mods list.'
