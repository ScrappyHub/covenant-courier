param(
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta",
  [string]$To = "node-beta"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Vtp = Join-Path $RepoRoot "vtp.ps1"

function Count-Dirs([string]$Path){
  return @(Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue).Count
}

function Run-Vtp([string[]]$ArgsList){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Vtp @ArgsList
  if($LASTEXITCODE -ne 0){ throw ("VTP_FULL_GREEN_FAIL:CHILD_EXIT:" + ($ArgsList -join " ")) }
}

$accepted = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\accepted")
$before = Count-Dirs $accepted

Run-Vtp @("smoke","-RepoRoot",$RepoRoot,"-NodeId",$NodeId)
Run-Vtp @("send","-RepoRoot",$RepoRoot,"-NodeId",$NodeId,"-To",$To)
Run-Vtp @("node-loop","-RepoRoot",$RepoRoot,"-NodeId",$NodeId)
Run-Vtp @("status","-RepoRoot",$RepoRoot,"-NodeId",$NodeId)

$after = Count-Dirs $accepted
if($after -le $before){
  throw ("VTP_FULL_GREEN_FAIL:ACCEPT_COUNT_NOT_INCREMENTED:BEFORE_" + $before + ":AFTER_" + $after)
}

Write-Host "VTP_FULL_GREEN_OK"