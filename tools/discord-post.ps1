param(
	[Parameter(Mandatory = $true)][string]$Message,
	[ValidateSet("plan", "done", "release", "warn", "info")][string]$Kind = "info"
)
# Posts a short message to the Discord channel (#不具合報告).
# The webhook URL is read from a file OUTSIDE the repository: %USERPROFILE%\.dopagaki-discord.json
#   {"webhook": "https://discord.com/api/webhooks/..."}
$ErrorActionPreference = "Stop"
$config = Join-Path $env:USERPROFILE ".dopagaki-discord.json"
if (-not (Test-Path -LiteralPath $config)) { Write-Host "Discord is not set up ($config is missing). Skipped."; exit 0 }
try {
	$webhook = (Get-Content -LiteralPath $config -Raw -Encoding UTF8 | ConvertFrom-Json).webhook
	if (-not $webhook) { Write-Host "No webhook in the Discord config. Skipped."; exit 0 }
	$label = switch ($Kind) {
		"plan" { "【修正予定】" }
		"done" { "【修正しました】" }
		"release" { "【公開】" }
		"warn" { "【要確認】" }
		default { "" }
	}
	$text = ($label + " " + $Message).Trim()
	if ($text.Length -gt 1900) { $text = $text.Substring(0, 1900) + "..." }
	$json = @{ username = "DOPAGAKI"; content = $text } | ConvertTo-Json -Compress
	Invoke-RestMethod -Uri $webhook -Method Post -ContentType "application/json; charset=utf-8" -Body ([Text.Encoding]::UTF8.GetBytes($json)) | Out-Null
	Write-Host "Posted to Discord."
} catch {
	Write-Host "Discord post failed: $($_.Exception.Message)"
}
exit 0
