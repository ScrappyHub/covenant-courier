param(
  [Parameter(Position=0)][string]$Command = "help",
  [string]$RepoRoot = ".",
  [string]$To = "node-beta",
  [string]$Message = "",
  [string]$NodeId = "node-beta"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"

if($Command -eq "help"){
  Write-Host "VTP commands:"
  Write-Host "  .\vtp.ps1 dev-fast"
  Write-Host "  .\vtp.ps1 status"
  Write-Host "  .\vtp.ps1 node-loop -NodeId node-beta"
  Write-Host "  .\vtp.ps1 conformance"
  exit 0
}

if($Command -eq "dev-fast"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File (Join-Path $Scripts "_RUN_vtp_dev_fast_v1.ps1") `
    -RepoRoot $RepoRoot
  exit $LASTEXITCODE
}

if($Command -eq "conformance"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File (Join-Path $Scripts "_RUN_vtp_conformance_v1.ps1") `
    -RepoRoot $RepoRoot
  exit $LASTEXITCODE
}

if($Command -eq "node-loop"){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
    -File (Join-Path $Scripts "vtp_node_loop_v1.ps1") `
    -RepoRoot $RepoRoot `
    -NodeId $NodeId `
    -Once
  exit $LASTEXITCODE
}

if($Command -eq "status"){
  $outbox = @(Get-ChildItem -LiteralPath (Join-Path $RepoRoot "test_vectors") -Recurse -Filter "queue_item.json" -ErrorAction SilentlyContinue)
  $receipts = Join-Path $RepoRoot "proofs\receipts"

  Write-Host "VTP STATUS"
  Write-Host ("Repo: " + $RepoRoot)
  Write-Host ("Outbox items: " + $outbox.Count)

  if(Test-Path $receipts){
    Write-Host ("Receipts: " + $receipts)
    Get-ChildItem $receipts -Filter "*.ndjson" | ForEach-Object {
      Write-Host (" - " + $_.Name)
    }
  } else {
    Write-Host "Receipts: none"
  }

  exit 0
}

throw "UNKNOWN_VTP_COMMAND:$Command"