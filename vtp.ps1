param(
  [Parameter(Position=0)][string]$Command = "help",
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta",
  [string]$To = "node-beta"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"

function Run-PS([string]$Script,[string[]]$ArgsList){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @ArgsList
  if($LASTEXITCODE -ne 0){
    throw ("VTP_CHILD_FAIL:" + $Script)
  }
}

if($Command -eq "help"){
  Write-Host "VTP commands:"
  Write-Host "  .\vtp.ps1 smoke"
  Write-Host "  .\vtp.ps1 status"
  Write-Host "  .\vtp.ps1 transmit -To node-beta"
  Write-Host "  .\vtp.ps1 send -To node-beta"
  Write-Host "  .\vtp.ps1 node-loop -NodeId node-beta"
  Write-Host "  .\vtp.ps1 dlp-test"
  Write-Host "  .\vtp.ps1 full-green"
  Write-Host "  .\vtp.ps1 run-node -NodeId node-beta"
  Write-Host "  .\vtp.ps1 install-node -NodeId node-beta"
  Write-Host "  .\vtp.ps1 dev-fast"
  Write-Host "  .\vtp.ps1 conformance"
  exit 0
}

if($Command -eq "smoke"){
  foreach($rel in @(
    "scripts\vtp_node_loop_v1.ps1",
    "scripts\vtp_node_loop_policy_v1.ps1",
    "scripts\vtp_node_loop_forever_v1.ps1",
    "scripts\vtp_policy_gate_v1.ps1",
    "scripts\_selftest_vtp_dlp_negative_v1.ps1",
    "scripts\vtp_install_node_task_v1.ps1",
    "scripts\_RUN_vtp_dev_fast_v1.ps1",
    "scripts\_RUN_vtp_conformance_v1.ps1"
  )){
    if(-not (Test-Path -LiteralPath (Join-Path $RepoRoot $rel) -PathType Leaf)){
      throw "VTP_SMOKE_FAIL:MISSING:$rel"
    }
  }

  $task = Get-ScheduledTask -TaskName "VTP Node Loop" -ErrorAction SilentlyContinue
  if($null -eq $task){
    Write-Host "VTP_SMOKE_WARN:NO_SCHEDULED_TASK"
  } else {
    Write-Host ("VTP_TASK_STATE: " + $task.State)
  }

  Write-Host "VTP_SMOKE_PASS"
  exit 0
}

if($Command -eq "status"){
  $drop = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\inbox\drop")
  $accepted = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\accepted")
  $rejected = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\rejected")
  $receipts = Join-Path $RepoRoot "proofs\receipts"

  $dropItems = @(Get-ChildItem -LiteralPath $drop -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  $acceptedItems = @(Get-ChildItem -LiteralPath $accepted -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
  $rejectedItems = @(Get-ChildItem -LiteralPath $rejected -Directory -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)

  Write-Host "VTP STATUS"
  Write-Host ("Repo: " + $RepoRoot)
  Write-Host ("Node: " + $NodeId)
  Write-Host ("Inbox drop: " + $dropItems.Count)
  if($dropItems.Count -gt 0){ Write-Host ("Latest drop: " + $dropItems[0].Name) }
  Write-Host ("Accepted: " + $acceptedItems.Count)
  if($acceptedItems.Count -gt 0){ Write-Host ("Latest accepted: " + $acceptedItems[0].Name) }
  Write-Host ("Rejected: " + $rejectedItems.Count)
  if($rejectedItems.Count -gt 0){
    Write-Host ("Latest rejected: " + $rejectedItems[0].Name)
    $reason = Join-Path $rejectedItems[0].FullName "reject_reason.txt"
    if(Test-Path -LiteralPath $reason -PathType Leaf){
      $reasonText = (Get-Content -LiteralPath $reason -Raw).Trim()
      if(-not [string]::IsNullOrWhiteSpace($reasonText)){
        Write-Host ("Latest reject reason: " + $reasonText)
      }
    }
  }
  Write-Host ("Receipts: " + $receipts)

  $task = Get-ScheduledTask -TaskName "VTP Node Loop" -ErrorAction SilentlyContinue
  if($null -eq $task){
    Write-Host "Task: missing"
  } else {
    $info = Get-ScheduledTaskInfo -TaskName "VTP Node Loop"
    Write-Host ("Task state: " + $task.State)
    Write-Host ("Last run: " + $info.LastRunTime)
    Write-Host ("Next run: " + $info.NextRunTime)
    Write-Host ("Last result: " + $info.LastTaskResult)
  }

  exit 0
}

if($Command -eq "install-node"){
  Run-PS (Join-Path $Scripts "vtp_install_node_task_v1.ps1") @("-RepoRoot",$RepoRoot,"-NodeId",$NodeId)
  exit 0
}

if($Command -eq "run-node"){
  Write-Host ("VTP_RUN_NODE_START: " + $NodeId)
  Write-Host "VTP_RUN_NODE_MODE: foreground-silent"
  Write-Host "VTP_RUN_NODE_STOP: Ctrl+C"

  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File (Join-Path $Scripts "vtp_node_loop_forever_v1.ps1") `
    -RepoRoot $RepoRoot `
    -NodeId $NodeId

  if($LASTEXITCODE -ne 0){
    throw "VTP_RUN_NODE_FAIL"
  }

  exit 0
}

if($Command -eq "node-loop"){
  Run-PS (Join-Path $Scripts "vtp_node_loop_policy_v1.ps1") @("-RepoRoot",$RepoRoot,"-NodeId",$NodeId,"-Once")
  exit 0
}

if($Command -eq "send"){
  $messagePath = Join-Path $RepoRoot "test_vectors\courier_v1\transport_hardening\prep\message.tokenized.json"

  if(-not (Test-Path -LiteralPath $messagePath -PathType Leaf)){
    throw "VTP_SEND_FAIL:MISSING_PREPARED_MESSAGE"
  }

  Run-PS (Join-Path $Scripts "courier_open_session_v1.ps1") @(
    "-RepoRoot",$RepoRoot,
    "-SessionId","session-alpha-beta-001",
    "-SenderNodeId","node-alpha",
    "-RecipientNodeId",$To,
    "-NetworkId","courier-internal-net-v1",
    "-SessionRole","message-delivery"
  )

  Run-PS (Join-Path $Scripts "courier_transport_send_v1.ps1") @(
    "-RepoRoot",$RepoRoot,
    "-MessagePath",$messagePath,
    "-SenderIdentity","courier-local@covenant",
    "-RecipientIdentity","courier-local@covenant",
    "-SenderNodeId","node-alpha",
    "-RecipientNodeId",$To,
    "-NetworkId","courier-internal-net-v1",
    "-SessionId","session-alpha-beta-001",
    "-SenderRole","message-delivery",
    "-DropRoot",("runtime\nodes\" + $To + "\inbox\drop")
  )

  Write-Host "VTP_SEND_OK"
  exit 0
}

if($Command -eq "transmit"){
  $accepted = Join-Path $RepoRoot ("runtime\nodes\" + $To + "\accepted")
  $drop = Join-Path $RepoRoot ("runtime\nodes\" + $To + "\inbox\drop")
  $beforeAccepted = @(Get-ChildItem -LiteralPath $accepted -Directory -ErrorAction SilentlyContinue).Count

  Run-PS $PSCommandPath @("send","-RepoRoot",$RepoRoot,"-NodeId",$NodeId,"-To",$To)
  Run-PS $PSCommandPath @("node-loop","-RepoRoot",$RepoRoot,"-NodeId",$To)
  Run-PS $PSCommandPath @("status","-RepoRoot",$RepoRoot,"-NodeId",$To)

  $afterAccepted = @(Get-ChildItem -LiteralPath $accepted -Directory -ErrorAction SilentlyContinue).Count
  $dropCount = @(Get-ChildItem -LiteralPath $drop -Directory -ErrorAction SilentlyContinue).Count

  if($afterAccepted -le $beforeAccepted){
    throw ("VTP_TRANSMIT_FAIL:ACCEPT_NOT_INCREMENTED:BEFORE_" + $beforeAccepted + ":AFTER_" + $afterAccepted)
  }

  if($dropCount -ne 0){
    throw ("VTP_TRANSMIT_FAIL:DROP_NOT_EMPTY:" + $dropCount)
  }

  Write-Host "VTP_TRANSMIT_OK"
  exit 0
}

if($Command -eq "dlp-test"){
  Run-PS (Join-Path $Scripts "_selftest_vtp_dlp_negative_v1.ps1") @("-RepoRoot",$RepoRoot,"-NodeId",$NodeId)
  Write-Host "VTP_DLP_TEST_OK"
  exit 0
}

if($Command -eq "full-green"){
  Run-PS (Join-Path $RepoRoot "vtp_full_green.ps1") @("-RepoRoot",$RepoRoot,"-NodeId",$NodeId,"-To",$To)
  Write-Host "VTP_CLI_FULL_GREEN_OK"
  exit 0
}

if($Command -eq "dev-fast"){
  Run-PS (Join-Path $Scripts "_RUN_vtp_dev_fast_v1.ps1") @("-RepoRoot",$RepoRoot)
  exit 0
}

if($Command -eq "conformance"){
  Run-PS (Join-Path $Scripts "_RUN_vtp_conformance_v1.ps1") @("-RepoRoot",$RepoRoot)
  exit 0
}


if($Command -eq "wire-smoke"){
 Run-PS (Join-Path $Scripts "_selftest_vtp_udp_wire_v1.ps1") @("-RepoRoot",$RepoRoot,"-To",$To)
 Write-Host "VTP_WIRE_SMOKE_OK"
 exit 0
}
throw "UNKNOWN_VTP_COMMAND:$Command"