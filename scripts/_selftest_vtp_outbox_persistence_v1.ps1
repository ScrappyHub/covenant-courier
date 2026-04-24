param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RegSelf = Join-Path $PSScriptRoot "_selftest_courier_registry_v1.ps1"
$OpenSes = Join-Path $PSScriptRoot "courier_open_session_v1.ps1"
$Bootstrap = Join-Path $PSScriptRoot "courier_bootstrap_local_trust_v1.ps1"
$Pipeline = Join-Path $PSScriptRoot "courier_cli_run_pipeline_v1.ps1"
$Send = Join-Path $PSScriptRoot "courier_transport_send_v1.ps1"
$Enqueue = Join-Path $PSScriptRoot "vtp_outbox_enqueue_v1.ps1"
$Process = Join-Path $PSScriptRoot "vtp_outbox_process_v1.ps1"

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

function Reset-Dir([string]$Path){
  if(Test-Path -LiteralPath $Path){
    Remove-Item -LiteralPath $Path -Recurse -Force
  }
  [void][System.IO.Directory]::CreateDirectory($Path)
}

$Root = Join-Path $RepoRoot "test_vectors\vtp_outbox_persistence"
$SendDrop = Join-Path $Root "send_drop"
$QueueRoot = Join-Path $Root "outbox_queue"
$DestinationDrop = Join-Path $Root "destination_drop"

Reset-Dir $Root
Ensure-Dir $SendDrop
Ensure-Dir $QueueRoot
Ensure-Dir $DestinationDrop

& $RegSelf -RepoRoot $RepoRoot
& $OpenSes -RepoRoot $RepoRoot -SessionId "session-outbox-001" -SenderNodeId "node-alpha" -RecipientNodeId "node-beta" -NetworkId "courier-internal-net-v1" -SessionRole "message-delivery"
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
  -SessionId "session-outbox-001" `
  -SenderRole "message-delivery" `
  -DropRoot $SendDrop

$frame = @(Get-ChildItem -LiteralPath $SendDrop -Directory | Select-Object -First 1)
if($frame.Count -ne 1){
  throw "VTP_OUTBOX_SELFTEST_FAIL:NO_FRAME"
}

& $Enqueue -RepoRoot $RepoRoot -FrameRoot $frame.FullName -QueueRoot $QueueRoot
& $Process -RepoRoot $RepoRoot -QueueRoot $QueueRoot -DestinationDropRoot $DestinationDrop

$delivered = @(Get-ChildItem -LiteralPath $DestinationDrop -Directory -ErrorAction SilentlyContinue)
if($delivered.Count -ne 1){
  throw ("VTP_OUTBOX_SELFTEST_FAIL:EXPECTED_ONE_DELIVERED:COUNT_" + $delivered.Count)
}

$itemMeta = @(Get-ChildItem -LiteralPath $QueueRoot -Recurse -Filter "queue_item.json" | Select-Object -First 1)
if($itemMeta.Count -ne 1){
  throw "VTP_OUTBOX_SELFTEST_FAIL:MISSING_QUEUE_META"
}

$meta = Get-Content -LiteralPath $itemMeta.FullName -Raw | ConvertFrom-Json
if([string]$meta.status -ne "delivered"){
  throw ("VTP_OUTBOX_SELFTEST_FAIL:QUEUE_NOT_DELIVERED:" + [string]$meta.status)
}

Write-Host "VTP_OUTBOX_PERSISTENCE_SELFTEST_OK"
