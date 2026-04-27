param(
  [Parameter(Position=0)][string]$Command = "help",
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta",
  [string]$To = "node-beta",
  [string]$Message = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"

if($Command -eq "help"){
  Write-Host "VTP commands:"
  Write-Host "  .\vtp.ps1 smoke"
  Write-Host "  .\vtp.ps1 status"
  Write-Host "  .\vtp.ps1 install-node -NodeId node-beta"
  Write-Host "  .\vtp.ps1 node-loop -NodeId node-beta"
  Write-Host "  .\vtp.ps1 send -To node-beta -Message `"hello`""
  Write-Host "  .\vtp.ps1 dev-fast"
  Write-Host "  .\vtp.ps1 conformance"
  exit 0
}

if($Command -eq "smoke"){
  foreach($rel in @("scripts\vtp_node_loop_v1.ps1","scripts\vtp_install_node_task_v1.ps1","scripts\_RUN_vtp_dev_fast_v1.ps1","scripts\_RUN_vtp_conformance_v1.ps1")){
    if(-not (Test-Path -LiteralPath (Join-Path $RepoRoot $rel) -PathType Leaf)){ throw "VTP_SMOKE_FAIL:MISSING:$rel" }
  }
  $task = Get-ScheduledTask -TaskName "VTP Node Loop" -ErrorAction SilentlyContinue
  if($null -eq $task){ Write-Host "VTP_SMOKE_WARN:NO_SCHEDULED_TASK" } else { Write-Host ("VTP_TASK_STATE: " + $task.State) }
  Write-Host "VTP_SMOKE_PASS"
  exit 0
}

if($Command -eq "status"){
  Write-Host "VTP STATUS"
  Write-Host ("Repo: " + $RepoRoot)
  Write-Host ("Receipts: " + (Join-Path $RepoRoot "proofs\receipts"))
  exit 0
}

if($Command -eq "install-node"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $Scripts "vtp_install_node_task_v1.ps1") -RepoRoot $RepoRoot -NodeId $NodeId
  exit $LASTEXITCODE
}

if($Command -eq "node-loop"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $Scripts "vtp_node_loop_v1.ps1") -RepoRoot $RepoRoot -NodeId $NodeId -Once
  exit $LASTEXITCODE
}

if($Command -eq "send"){
  $messagePath = Join-Path $RepoRoot "test_vectors\courier_v1\transport_hardening\prep\message.tokenized.json"

  if(-not (Test-Path -LiteralPath $messagePath -PathType Leaf)){
    throw "VTP_SEND_FAIL:MISSING_PREPARED_MESSAGE"
  }

  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File (Join-Path $Scripts "courier_transport_send_v1.ps1") `
    -RepoRoot $RepoRoot `
    -MessagePath $messagePath `
    -SenderIdentity "courier-local@covenant" `
    -RecipientIdentity "courier-local@covenant" `
    -SenderNodeId "node-alpha" `
    -RecipientNodeId $To `
    -NetworkId "courier-internal-net-v1" `
    -SessionId "session-alpha-beta-001" `
    -SenderRole "message-delivery" `
    -DropRoot "runtime\nodes\node-beta\inbox\drop"

  if($LASTEXITCODE -ne 0){ throw "VTP_SEND_FAIL:TRANSPORT_SEND_FAILED" }

  Write-Host "VTP_SEND_OK"
  exit 0
}

if($Command -eq "dev-fast"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $Scripts "_RUN_vtp_dev_fast_v1.ps1") -RepoRoot $RepoRoot
  exit $LASTEXITCODE
}

if($Command -eq "conformance"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $Scripts "_RUN_vtp_conformance_v1.ps1") -RepoRoot $RepoRoot
  exit $LASTEXITCODE
}

throw "UNKNOWN_VTP_COMMAND:$Command"
