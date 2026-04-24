param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [string]$NodeId = "node-beta",
  [int]$SleepSeconds = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Loop = Join-Path $PSScriptRoot "vtp_node_loop_v1.ps1"
if(-not (Test-Path -LiteralPath $Loop -PathType Leaf)){
  throw "VTP_SERVICE_WRAPPER_FAIL:MISSING_NODE_LOOP"
}

Write-Host "VTP_SERVICE_WRAPPER_START"

while($true){
  try {
    & $Loop -RepoRoot $RepoRoot -NodeId $NodeId -Once
  }
  catch {
    Write-Host ("VTP_SERVICE_WRAPPER_TICK_FAIL: " + $_.ToString())
  }

  Start-Sleep -Seconds $SleepSeconds
}
