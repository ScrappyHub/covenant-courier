param(
  [Parameter(Position=0)][string]$Command = "help",
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta"
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

if($Command -eq "dev-fast"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $Scripts "_RUN_vtp_dev_fast_v1.ps1") -RepoRoot $RepoRoot
  exit $LASTEXITCODE
}

if($Command -eq "conformance"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File (Join-Path $Scripts "_RUN_vtp_conformance_v1.ps1") -RepoRoot $RepoRoot
  exit $LASTEXITCODE
}

throw "UNKNOWN_VTP_COMMAND:$Command"