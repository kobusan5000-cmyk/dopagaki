# Starts the game headless and reports OK / NG. Run before every push:  powershell -File tools\check.ps1
# Godot is taken from -Godot, the GODOT env var, PATH, or the usual WinGet / Downloads locations.
param([string]$Godot = "")
$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot

if (-not $Godot) { $Godot = $env:GODOT }
if (-not $Godot) {
    $cmd = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $Godot = $cmd.Source }
}
if (-not $Godot) {
    $hit = Get-ChildItem "$env:LOCALAPPDATA\Microsoft\WinGet\Packages", "$env:USERPROFILE\Downloads", "$env:USERPROFILE\Desktop" -Recurse -Filter "Godot*console*.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { $Godot = $hit.FullName }
}
if (-not $Godot -or -not (Test-Path $Godot)) {
    Write-Host "NG: Godot が見つかりません。 -Godot で Godot_*_console.exe の場所を渡してください。" -ForegroundColor Red
    exit 2
}

Push-Location $root
& $Godot --headless --import 2>&1 | Out-Null
$out = & $Godot --headless --quit-after 300 2>&1 | Out-String
Pop-Location

if ($out -match "SCRIPT ERROR|Parse Error|Failed to load script") {
    Write-Host "NG: ゲームを起動できません。このまま push しないでください。" -ForegroundColor Red
    ($out -split "`r?`n") | Where-Object { $_ -match "ERROR|at:" } | Select-Object -First 12 | ForEach-Object { Write-Host $_ }
    exit 1
}
Write-Host "OK: ゲームは起動できました。" -ForegroundColor Green
