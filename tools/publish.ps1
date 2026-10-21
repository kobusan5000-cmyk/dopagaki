param(
	[string]$DriveDir = "G:\マイドライブ\DOPA",
	[switch]$DryRun,
	[switch]$Yes,
	[switch]$Auto,
	[switch]$RefreshLatestOnly
)
# Takes the newest project ZIP from the shared Google Drive folder, shows what would change,
# and publishes it: copy into the repo -> git push -> GitHub builds the release.
#   (no switch)  interactive: shows the differences and asks for confirmation
#   -Auto        unattended (scheduled task): publishes by itself, but holds back anything suspicious
$ErrorActionPreference = "Stop"
$repo = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$doneDir = Join-Path $DriveDir "取り込み済み"
$failDir = Join-Path $DriveDir "失敗"
$holdDir = Join-Path $DriveDir "要確認"
$oldDir = Join-Path $DriveDir "古いZIP"
$statusFile = Join-Path $DriveDir "配信状況.txt"
$logFile = Join-Path $PSScriptRoot "publish.log"
$protectedDirs = @(".git", ".github", ".godot", "ci", "tools", "docs")
$protectedFiles = @("README.md", ".gitignore", "export_presets.cfg")
$script:zip = $null
$script:tmp = $null
if ($Auto) { $Yes = $true }

function Log([string]$message, [string]$color = "") {
	if ($color) { Write-Host $message -ForegroundColor $color } else { Write-Host $message }
	try { Add-Content -LiteralPath $logFile -Value ("{0:yyyy-MM-dd HH:mm:ss}  {1}" -f (Get-Date), $message) -Encoding UTF8 } catch { }
}

# Short status lines for everyone who uses the Drive folder (newest first, last 30).
function Set-Status([string]$text) {
	try {
		$line = "{0:yyyy-MM-dd HH:mm}  {1}" -f (Get-Date), $text
		$old = @()
		if (Test-Path -LiteralPath $statusFile) { $old = @(Get-Content -LiteralPath $statusFile -Encoding UTF8 | Select-Object -First 29) }
		Set-Content -LiteralPath $statusFile -Value (@($line) + $old) -Encoding UTF8
	} catch { }
}

function Move-ZipTo([string]$dir) {
	if ($script:zip -and (Test-Path -LiteralPath $script:zip.FullName)) {
		if (-not (Test-Path $dir)) { New-Item -ItemType Directory $dir | Out-Null }
		Move-Item -LiteralPath $script:zip.FullName -Destination (Join-Path $dir $script:zip.Name) -Force
	}
}

function Clear-Temp {
	if ($script:tmp -and (Test-Path $script:tmp)) { Remove-Item $script:tmp -Recurse -Force -ErrorAction SilentlyContinue }
}

function Fail([string]$message) {
	Log ""
	Log "[NG] $message" "Red"
	if ($Auto -and $script:zip) {
		Set-Status ("失敗: {0} -> {1}" -f $script:zip.Name, $message)
		try { Move-ZipTo $failDir } catch { }
	}
	Clear-Temp
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

# Puts a ZIP of the current project into Drive "最新版" so the other developer always starts from the newest copy.
function Update-LatestZip {
	$latestDir = Join-Path $DriveDir "最新版"
	if (-not (Test-Path $latestDir)) { New-Item -ItemType Directory $latestDir | Out-Null }
	$stage = Join-Path $env:TEMP ("dopagaki_latest_" + [guid]::NewGuid().ToString("N"))
	$inner = Join-Path $stage "DOPAGAKI"
	New-Item -ItemType Directory $inner | Out-Null
	$xd = @()
	foreach ($d in $protectedDirs) { $xd += (Join-Path $repo $d) }
	robocopy $repo $inner /E /XD @xd /XF @protectedFiles /NFL /NDL /NJH /NJS /NP | Out-Null
	$target = Join-Path $latestDir "DOPAGAKI_latest.zip"
	if (Test-Path $target) { Remove-Item $target -Force }
	Compress-Archive -Path $inner -DestinationPath $target
	Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
	Log "Latest copy for the other developer: $target"
}

# Only one publish at a time (the scheduled task can overlap with a manual run).
$mutex = New-Object System.Threading.Mutex($false, "Global\DOPAGAKI_publish")
if (-not $mutex.WaitOne(0)) {
	if (-not $Auto) { Write-Host "Another publish is already running." }
	exit 0
}

if (-not $Auto) { Write-Host "=== DOPAGAKI publish ===" -ForegroundColor Cyan }
if (-not (Test-Path $DriveDir)) {
	if ($Auto) { exit 0 } # Drive not mounted (PC just started); try again at the next run
	Fail "Drive folder not found: $DriveDir  (Is Google Drive running?)"
}
if ($RefreshLatestOnly) { Update-LatestZip; exit 0 }
$zips = @(Get-ChildItem -LiteralPath $DriveDir -Filter *.zip -File | Sort-Object LastWriteTime -Descending)
if ($zips.Count -eq 0) {
	if (-not $Auto) { Write-Host "No ZIP file in the Drive folder. Nothing to publish." }
	exit 0
}
$script:zip = $zips[0]
$zip = $script:zip
# A ZIP that is still being uploaded/synced must not be used: wait until it is a few seconds old,
# stops growing and can be opened for reading.
if ($Auto) {
	if (((Get-Date) - $zip.LastWriteTime).TotalSeconds -lt 10) { exit 0 }
	$sizeBefore = $zip.Length
	Start-Sleep -Seconds 4
	try {
		$probe = [IO.File]::Open($zip.FullName, 'Open', 'Read', 'None')
		$sizeAfter = $probe.Length
		$probe.Close()
	} catch { exit 0 }
	if ($sizeAfter -ne $sizeBefore -or $sizeAfter -lt 1000) { exit 0 }
}
if ($zips.Count -gt 1) { Log "Note: $($zips.Count) ZIP files found. Using the newest: $($zip.Name)" "Yellow" }
Log "ZIP: $($zip.Name)  ($([math]::Round($zip.Length / 1MB, 1)) MB, $($zip.LastWriteTime))"

# Make sure the local clone is current and has no unrelated local edits before touching it.
Push-Location $repo
try {
	if ($Auto -or -not $DryRun) {
		$dirty = git status --porcelain
		if ($dirty) {
			if ($Auto) { Log "Skipped: the repo has local uncommitted changes ($repo)." "Yellow"; exit 0 }
			Fail "The repo has local uncommitted changes. Commit or discard them first."
		}
		git pull -q --rebase origin main
		if ($LASTEXITCODE -ne 0) { Fail "git pull failed." }
	}
} finally {
	Pop-Location
}

$script:tmp = Join-Path $env:TEMP ("dopagaki_in_" + [guid]::NewGuid().ToString("N"))
$tmp = $script:tmp
try {
	Expand-Archive -LiteralPath $zip.FullName -DestinationPath $tmp -Force
} catch {
	if ($Auto) { Log "Could not open the ZIP yet (still syncing?): $($_.Exception.Message)" "Yellow"; Clear-Temp; exit 0 }
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
Log "Added: $($added.Count)   Changed: $($changed.Count)   Removed: $($removed.Count)"
foreach ($f in $added) { Write-Host "  + $f" -ForegroundColor Green }
foreach ($f in $changed) { Write-Host "  ~ $f" -ForegroundColor Cyan }
foreach ($f in $removed) { Write-Host "  - $f  (will be DELETED)" -ForegroundColor Yellow }

if ($added.Count + $changed.Count + $removed.Count -eq 0) {
	Log "No differences from the current version. Nothing to publish." "Green"
	if ($Auto) { Move-ZipTo $doneDir; Set-Status ("変更なし: {0}" -f $zip.Name) }
	Clear-Temp
	exit 0
}

$newNotes = Get-TopBlock (Join-Path $src "CHANGELOG.txt")
$oldNotes = Get-TopBlock (Join-Path $repo "CHANGELOG.txt")

# The other developer also keeps per-version notes (CHANGELOG_v0.12.2.txt). If the newest one is not at the top
# of CHANGELOG.txt, use it as the release notes and put it on top (as one block) when publishing.
$prependNotes = ""
$verFiles = @(Get-ChildItem $src -Filter "CHANGELOG_v*.txt" -File | Sort-Object {
	try { [version]($_.BaseName -replace '^CHANGELOG_v', '') } catch { [version]"0.0" }
} -Descending)
if ($verFiles.Count -gt 0) {
	$verLines = @(Get-Content $verFiles[0].FullName -Encoding UTF8 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -First 25)
	if ($verLines.Count -gt 0 -and -not $newNotes.StartsWith($verLines[0])) {
		$prependNotes = $verLines -join "`n"
		$newNotes = $prependNotes
	}
}
Write-Host ""
if ([string]::IsNullOrEmpty($newNotes)) {
	Log "[!] CHANGELOG.txt is missing. The tester will see no update notes." "Yellow"
} elseif ($newNotes -eq $oldNotes) {
	Log "[!] CHANGELOG.txt top block is the SAME as the previous version - the notes were probably not updated." "Yellow"
} else {
	Write-Host "Update notes the tester will see:" -ForegroundColor Cyan
	Write-Host $newNotes
}

# Removing generated Godot files (.import / .uid) is normal; removing anything else may mean an outdated copy.
$suspicious = @($removed | Where-Object { $_ -notmatch '\.import$' -and $_ -notmatch '\.uid$' })
if ($suspicious.Count -gt 0) {
	Write-Host "`n[!] Files would be deleted. If the sender worked from an OLD copy, fixes could be lost." -ForegroundColor Yellow
	if ($Auto) {
		Log ("HELD for review - would delete: " + (($suspicious | Select-Object -First 8) -join ", ")) "Yellow"
		Set-Status ("要確認: {0} は {1} 個のファイルを削除する内容のため、公開を保留しました(管理者が確認します)" -f $zip.Name, $suspicious.Count)
		Move-ZipTo $holdDir
		Clear-Temp
		exit 0
	}
}

if ($DryRun) {
	Write-Host "`n(dry run - nothing was changed)" -ForegroundColor Cyan
	Clear-Temp
	exit 0
}
if (-not $Yes) {
	$answer = Read-Host "`nPublish this to the testers? (y/N)"
	if ($answer -ne "y" -and $answer -ne "Y") {
		Write-Host "Cancelled. Nothing was changed."
		Clear-Temp
		exit 0
	}
}

$xd = @()
foreach ($d in $protectedDirs) { $xd += (Join-Path $src $d); $xd += (Join-Path $repo $d) }
robocopy $src $repo /MIR /XD @xd /XF @protectedFiles /NFL /NDL /NJH /NJS /NP | Out-Null
if ($LASTEXITCODE -ge 8) { Fail "File copy failed (robocopy code $LASTEXITCODE)." }
if ($prependNotes) {
	$clPath = Join-Path $repo "CHANGELOG.txt"
	$existing = if (Test-Path $clPath) { [IO.File]::ReadAllText($clPath) } else { "" }
	[IO.File]::WriteAllText($clPath, $prependNotes + "`n`n" + $existing, (New-Object Text.UTF8Encoding($false)))
}

Push-Location $repo
try {
	git add -A
	$status = git status --porcelain
	if (-not $status) {
		Log "Nothing to commit (only line-ending differences)."
		if ($Auto) { Move-ZipTo $doneDir; Set-Status ("変更なし: {0}" -f $zip.Name) }
		Clear-Temp
		exit 0
	}
	git -c user.name=kouta -c user.email=kobusan5000-cmyk@users.noreply.github.com commit -q -m "Drive upload: $($zip.Name)"
	if ($LASTEXITCODE -ne 0) { Fail "git commit failed." }
	git push -q origin main
	if ($LASTEXITCODE -ne 0) { Fail "git push failed (not logged in to GitHub?)." }
	Log "Pushed. Waiting for GitHub to build..." "Cyan"
	# Find the build that belongs to the commit we just pushed (poll instead of a fixed wait).
	$sha = (git rev-parse HEAD).Trim()
	$runId = ""
	for ($i = 0; $i -lt 40 -and -not $runId; $i++) {
		$runId = gh run list --commit $sha --limit 1 --json databaseId -q ".[0].databaseId"
		if (-not $runId) { Start-Sleep -Seconds 2 }
	}
	if (-not $runId) { Fail "GitHub did not start a build for the pushed commit." }
	gh run watch $runId --exit-status --interval 3 | Out-Null
	if ($LASTEXITCODE -ne 0) { Fail "The build FAILED (the game has errors?). Open GitHub > Actions to see why. The testers still have the previous version." }
	$tag = gh release list --limit 1 --json tagName -q ".[0].tagName"
	Log "[OK] Published as $tag. Testers get it the next time they start the launcher." "Green"
	Set-Status ("公開しました: {0} ({1}) -> テスターに配信" -f $tag, $zip.Name)
} finally {
	Pop-Location
}

Move-ZipTo $doneDir
# Older ZIPs that were still lying around must never be published later (they would roll the game back).
foreach ($old in ($zips | Select-Object -Skip 1)) {
	if (Test-Path -LiteralPath $old.FullName) {
		if (-not (Test-Path $oldDir)) { New-Item -ItemType Directory $oldDir | Out-Null }
		Move-Item -LiteralPath $old.FullName -Destination (Join-Path $oldDir $old.Name) -Force
	}
}
Clear-Temp
Log "The ZIP was moved to: $doneDir"
Update-LatestZip
