param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Script = Join-Path $PSScriptRoot "_selftest_vtp_cross_node_v1.ps1"

try {
  & $Script -RepoRoot $RepoRoot
}
catch {
  throw ("VTP_CROSS_NODE_RUNNER_FAIL:" + $_.ToString())
}

Write-Host "VTP_CROSS_NODE_RUNNER_OK"
