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

    return $null
}

function Write-Utf8NoBom([string]$Path, [string]$Text) {
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

if (Get-Process ProjectZomboid64 -ErrorAction SilentlyContinue) {
    throw 'Close Project Zomboid before uninstalling.'
}

$runtimeRoot = Join-Path $env:USERPROFILE 'Zomboid\CinematicLoadingScreen'
$statePath = Join-Path $runtimeRoot 'state.json'
$state = $null

if (Test-Path $statePath) {
    try {
        $state = Get-Content $statePath -Raw | ConvertFrom-Json
    } catch {
        $state = $null
    }
}

$game = if ($state -and $state.gamePath -and (Test-Path $state.gamePath)) {
    $state.gamePath
} else {
    Get-GamePath
}

if ($game) {
    $json = Join-Path $game 'ProjectZomboid64.json'
    if (Test-Path $json) {
        $text = [IO.File]::ReadAllText($json)
        $updated = [regex]::Replace(
            $text,
            '(?m)^[ \t]*"-javaagent:[^"\r\n]*CinematicLoadingScreenAgent\.jar"[ \t]*,?[ \t]*\r?\n?',
            ''
        )

        if ($updated -ne $text) {
            $null = $updated | ConvertFrom-Json
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            Copy-Item $json "$json.cinematic-loading-uninstall-backup-$stamp" -Force
            Write-Utf8NoBom $json $updated
        }
    }
}

if ($state -and $state.pzoptChanged) {
    $pzoptPath = Join-Path $env:USERPROFILE 'Zomboid\pzopt\options.ini'
    if (Test-Path $pzoptPath) {
        $options = [IO.File]::ReadAllText($pzoptPath)
        if ($options -match '(?im)^noLoadingScreen\s*=\s*false\s*$') {
            $options = [regex]::Replace(
                $options,
                '(?im)^noLoadingScreen\s*=\s*false\s*$',
                'noLoadingScreen=true'
            )
            Write-Utf8NoBom $pzoptPath $options
        }
    }
}

if ($state -and $state.localModInstalled) {
    $modTarget = Join-Path $env:USERPROFILE 'Zomboid\mods\CinematicLoadingScreen'
    if (Test-Path $modTarget) {
        Remove-Item $modTarget -Recurse -Force
    }
}

if (Test-Path $runtimeRoot) {
    Remove-Item $runtimeRoot -Recurse -Force
}

Write-Host 'Cinematic Loading Screen removed.'
