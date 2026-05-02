param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [string]$NodeId = "node-beta",
  [int]$IntervalSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Vtp = Join-Path $RepoRoot "vtp.ps1"

while($true){
  try {
    & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Vtp node-loop -RepoRoot $RepoRoot -NodeId $NodeId
  } catch {
    Write-Host ("VTP_NODE_LOOP_FOREVER_ERROR: " + $_.Exception.Message)
  }
  Start-Sleep -Seconds $IntervalSeconds
}