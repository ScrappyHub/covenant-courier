param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$SessionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Path = Join-Path $RepoRoot ("registry\sessions\" + $SessionId + ".json")
if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ throw "COURIER_CLOSE_SESSION_FAIL:UNKNOWN_SESSION" }

$obj = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
$obj.status = "closed"
$obj.closed_utc = (Get-Date).ToUniversalTime().ToString("o")

$enc = New-Object System.Text.UTF8Encoding($false)
$json = $obj | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText($Path, ($json + "`n"), $enc)

Write-Host ("COURIER_CLOSE_SESSION_OK: " + $Path)
