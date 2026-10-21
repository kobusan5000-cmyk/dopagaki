param(
	[string]$DriveDir = "G:\マイドライブ\DOPA",
	[switch]$DryRun,
	[switch]$Yes
)
# Takes the newest project ZIP from the shared Google Drive folder, shows what would change,
# and (after confirmation) publishes it: copy into the repo -> git push -> GitHub builds the release.
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$doneDir = Join-Path $DriveDir "取り込み済み"
$protectedDirs = @(".git", ".github", ".godot", "ci", "tools", "docs")
$protectedFiles = @("README.md", ".gitignore", "export_presets.cfg")

function Fail([string]$message) {
	Write-Host ""
	Write-Host "[NG] $message" -ForegroundColor Red
	exit 1
}

function Get-Rel([string]$root, [string]$path) {
	return $path.Substring($root.Length).TrimStart('\')
}

function Test-Protected([string]$rel) {
	$first = $rel.Split('\')[0]
	if ($rel.Contains('\')) { return $protectedDirs -contains $first }
	return ($protectedFiles -contains $rel) -or ($protectedDirs -contains $rel)
}

function Get-HashMap([string]$root) {
	$map = @{}
	Get-ChildItem $root -Recurse -File -Force | ForEach-Object {
		$rel = Get-Rel $root $_.FullName
		if (-not (Test-Protected $rel)) {
			$map[$rel] = (Get-FileHash $_.FullName -Algorithm MD5).Hash
		}
	}
	return $map
}

function Get-TopBlock([string]$file) {
	if (-not (Test-Path $file)) { return "" }
	$lines = @()
	foreach ($line in (Get-Content $file -Encoding UTF8)) {
		if ([string]::IsNullOrWhiteSpace($line)) { if ($lines.Count -gt 0) { break } else { continue } }
		$lines += $line
	}
	return ($lines -join "`n")
}

Write-Host "=== DOPAGAKI publish ===" -ForegroundColor Cyan
if (-not (Test-Path $DriveDir)) { Fail "Drive folder not found: $DriveDir  (Is Google Drive running?)" }
$zips = @(Get-ChildItem $DriveDir -Filter *.zip -File | Sort-Object LastWriteTime -Descending)
if ($zips.Count -eq 0) {
	Write-Host "No ZIP file in the Drive folder. Nothing to publish."
	exit 0
}
$zip = $zips[0]
if ($zips.Count -gt 1) { Write-Host "Note: $($zips.Count) ZIP files found. Using the newest: $($zip.Name)" -ForegroundColor Yellow }
Write-Host "ZIP: $($zip.Name)  ($([math]::Round($zip.Length / 1MB, 1)) MB, $($zip.LastWriteTime))"

$tmp = Join-Path $env:TEMP ("dopagaki_in_" + [guid]::NewGuid().ToString("N"))
try {
	Expand-Archive -LiteralPath $zip.FullName -DestinationPath $tmp -Force
} catch {
	Fail "Could not open the ZIP (still syncing or broken?): $($_.Exception.Message)"
}

$projects = @(Get-ChildItem $tmp -Recurse -Filter project.godot -File | Where-Object {
	$_.FullName -notmatch '\\\.godot\\' -and $_.FullName -notmatch '\\tools\\'
})
if ($projects.Count -eq 0) { Fail "project.godot was not found inside the ZIP." }
if ($projects.Count -gt 1) { Fail "The ZIP contains more than one project.godot (nested projects?)." }
$src = $projects[0].DirectoryName

$incoming = Get-HashMap $src
$current = Get-HashMap $repo
$added = @($incoming.Keys | Where-Object { -not $current.ContainsKey($_) } | Sort-Object)
$removed = @($current.Keys | Where-Object { -not $incoming.ContainsKey($_) } | Sort-Object)
$changed = @($incoming.Keys | Where-Object { $current.ContainsKey($_) -and $current[$_] -ne $incoming[$_] } | Sort-Object)

Write-Host ""
Write-Host "Added: $($added.Count)   Changed: $($changed.Count)   Removed: $($removed.Count)"
foreach ($f in $added) { Write-Host "  + $f" -ForegroundColor Green }
foreach ($f in $changed) { Write-Host "  ~ $f" -ForegroundColor Cyan }
foreach ($f in $removed) { Write-Host "  - $f  (will be DELETED)" -ForegroundColor Yellow }

if ($added.Count + $changed.Count + $removed.Count -eq 0) {
	Write-Host "`nNo differences from the current version. Nothing to publish." -ForegroundColor Green
	Remove-Item $tmp -Recurse -Force
	exit 0
}

$newNotes = Get-TopBlock (Join-Path $src "CHANGELOG.txt")
$oldNotes = Get-TopBlock (Join-Path $repo "CHANGELOG.txt")
Write-Host ""
if ([string]::IsNullOrEmpty($newNotes)) {
	Write-Host "[!] CHANGELOG.txt is missing. The tester will see no update notes." -ForegroundColor Yellow
} elseif ($newNotes -eq $oldNotes) {
	Write-Host "[!] CHANGELOG.txt top block is the SAME as the previous version - the notes were probably not updated." -ForegroundColor Yellow
} else {
	Write-Host "Update notes the tester will see:" -ForegroundColor Cyan
	Write-Host $newNotes
}
if ($removed.Count -gt 0) {
	Write-Host "`n[!] Files would be deleted. If the sender worked from an OLD copy, fixes could be lost." -ForegroundColor Yellow
}

if ($DryRun) {
	Write-Host "`n(dry run - nothing was changed)" -ForegroundColor Cyan
	Remove-Item $tmp -Recurse -Force
	exit 0
}
if (-not $Yes) {
	$answer = Read-Host "`nPublish this to the testers? (y/N)"
	if ($answer -ne "y" -and $answer -ne "Y") {
		Write-Host "Cancelled. Nothing was changed."
		Remove-Item $tmp -Recurse -Force
		exit 0
	}
}

$xd = @()
foreach ($d in $protectedDirs) { $xd += (Join-Path $src $d); $xd += (Join-Path $repo $d) }
robocopy $src $repo /MIR /XD @xd /XF @protectedFiles /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { Fail "File copy failed (robocopy code $LASTEXITCODE)." }

Push-Location $repo
try {
	git add -A
	$status = git status --porcelain
	if (-not $status) { Write-Host "Nothing to commit."; exit 0 }
	git -c user.name=kouta -c user.email=kobusan5000-cmyk@users.noreply.github.com commit -q -m "Drive upload: $($zip.Name)"
	if ($LASTEXITCODE -ne 0) { Fail "git commit failed." }
	git push -q origin main
	if ($LASTEXITCODE -ne 0) { Fail "git push failed (not logged in to GitHub?)." }
	Write-Host "`nPushed. Waiting for GitHub to build..." -ForegroundColor Cyan
	Start-Sleep -Seconds 12
	$runId = gh run list --limit 1 --json databaseId -q ".[0].databaseId"
	gh run watch $runId --exit-status | Out-Null
	if ($LASTEXITCODE -ne 0) { Fail "The build FAILED. Open GitHub > Actions to see why. The testers still have the previous version." }
	$tag = gh release list --limit 1 --json tagName -q ".[0].tagName"
	Write-Host "`n[OK] Published as $tag. Testers get it the next time they start the launcher." -ForegroundColor Green
} finally {
	Pop-Location
}

if (-not (Test-Path $doneDir)) { New-Item -ItemType Directory $doneDir | Out-Null }
Move-Item -LiteralPath $zip.FullName -Destination (Join-Path $doneDir $zip.Name) -Force
Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "The ZIP was moved to: $doneDir"
