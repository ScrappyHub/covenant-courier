param([Parameter(Mandatory=$true)][string]$RepoRoot)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RegSelf = Join-Path $PSScriptRoot "_selftest_courier_registry_v1.ps1"
$OpenSes = Join-Path $PSScriptRoot "courier_open_session_v1.ps1"
$Bootstrap = Join-Path $PSScriptRoot "courier_bootstrap_local_trust_v1.ps1"
$Pipeline = Join-Path $PSScriptRoot "courier_cli_run_pipeline_v1.ps1"
$Send = Join-Path $PSScriptRoot "courier_transport_send_v1.ps1"
$Guard = Join-Path $PSScriptRoot "vtp_replay_guard_check_v1.ps1"

function Reset-Dir([string]$Path){
  if(Test-Path -LiteralPath $Path){ Remove-Item -LiteralPath $Path -Recurse -Force }
  [void][System.IO.Directory]::CreateDirectory($Path)
}

$Root = Join-Path $RepoRoot "test_vectors\vtp_replay_guard"
$Drop = Join-Path $Root "drop"

Reset-Dir $Root
[void][System.IO.Directory]::CreateDirectory($Drop)

& $RegSelf -RepoRoot $RepoRoot
& $OpenSes -RepoRoot $RepoRoot -SessionId "session-replay-001" -SenderNodeId "node-alpha" -RecipientNodeId "node-beta" -NetworkId "courier-internal-net-v1" -SessionRole "message-delivery"
& $Bootstrap -RepoRoot $RepoRoot
& $Pipeline -RepoRoot $RepoRoot -InputDir (Join-Path $RepoRoot "test_vectors\courier_v1\transport_hardening\prep")

$MessagePath = Join-Path $RepoRoot "test_vectors\courier_v1\transport_hardening\prep\message.tokenized.json"

& $Send `
  -RepoRoot $RepoRoot `
  -MessagePath $MessagePath `
  -SenderIdentity "courier-local@covenant" `
  -RecipientIdentity "courier-local@covenant" `
  -SenderNodeId "node-alpha" `
  -RecipientNodeId "node-beta" `
  -NetworkId "courier-internal-net-v1" `
  -SessionId "session-replay-001" `
  -SenderRole "message-delivery" `
  -DropRoot $Drop

$frame = @(Get-ChildItem -LiteralPath $Drop -Directory | Select-Object -First 1)
if($frame.Count -ne 1){ throw "VTP_REPLAY_SELFTEST_FAIL:NO_FRAME" }

# First pass should accept
& $Guard -RepoRoot $RepoRoot -FrameDir $frame.FullName

# Second pass should fail
$failed = $false
try {
  & $Guard -RepoRoot $RepoRoot -FrameDir $frame.FullName
} catch {
  if($_.ToString().Contains("VTP_REPLAY_DETECTED")){
    $failed = $true
  } else {
    throw
  }
}

if(-not $failed){
  throw "VTP_REPLAY_SELFTEST_FAIL:SECOND_PASS_NOT_BLOCKED"
}

Write-Host "VTP_REPLAY_GUARD_SELFTEST_OK"
