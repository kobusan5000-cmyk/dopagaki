param(
	[string]$Out = (Join-Path $env:USERPROFILE "Downloads\DOPAGAKI_upload.zip")
)
# Makes an upload ZIP of the current project folder (for the admin) that the cloud ingest can MERGE with the other
# developer's work: it contains BASE_VERSION.txt = the commit this folder started from.
#   powershell -File tools\make-zip.ps1 [-Out C:\path\name.zip]
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$protectedDirs = @(".git", ".github", ".godot", "ci", "tools", "docs", "build")
$protectedFiles = @("README.md", ".gitignore", "export_presets.cfg", "BASE_VERSION.txt")
Push-Location $repo
try { $sha = (git rev-parse HEAD).Trim() } finally { Pop-Location }
$stage = Join-Path $env:TEMP ("dopagaki_zip_" + [guid]::NewGuid().ToString("N"))
$inner = Join-Path $stage "DOPAGAKI"
New-Item -ItemType Directory $inner | Out-Null
$xd = @(); foreach ($d in $protectedDirs) { $xd += (Join-Path $repo $d) }
robocopy $repo $inner /E /XD @xd /XF @protectedFiles *.import *.uid *.tmp /NFL /NDL /NJH /NJS /NP | Out-Null
[IO.File]::WriteAllText((Join-Path $inner "BASE_VERSION.txt"), "$sha`n", (New-Object Text.UTF8Encoding($false)))
if (Test-Path $Out) { Remove-Item $Out }
& (Join-Path $env:SystemRoot "System32\tar.exe") -a -c -f $Out -C $stage DOPAGAKI
Remove-Item $stage -Recurse -Force
Write-Host "ZIP: $Out   (base $sha)"
