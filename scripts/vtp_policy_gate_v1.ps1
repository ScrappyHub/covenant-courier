param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$FrameDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$FrameJson = Join-Path $FrameDir "frame.json"
if(-not (Test-Path -LiteralPath $FrameJson -PathType Leaf)){
  throw "VTP_POLICY_FAIL:MISSING_FRAME_JSON"
}

$frame = Get-Content -LiteralPath $FrameJson -Raw | ConvertFrom-Json

Write-Host "VTP_POLICY_ALLOW"
exit 0