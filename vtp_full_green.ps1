param(
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta",
  [string]$To = "node-beta"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Vtp = Join-Path $RepoRoot "vtp.ps1"
$Accepted = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\accepted")
$Drop = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\inbox\drop")

function Count-Dirs([string]$Path){
  return @(Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue).Count
}

function Latest-DirName([string]$Path){
  $item = Get-ChildItem -LiteralPath $Path -Directory -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if($null -eq $item){ return "" }
  return [string]$item.Name
}

function Run-Vtp([string[]]$ArgsList){
  & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Vtp @ArgsList
  if($LASTEXITCODE -ne 0){
    throw ("VTP_FULL_GREEN_FAIL:CHILD_EXIT:" + ($ArgsList -join " "))
  }
}

$beforeAccepted = Count-Dirs $Accepted

Run-Vtp @("smoke","-RepoRoot",$RepoRoot,"-NodeId",$NodeId)
Run-Vtp @("dlp-test","-RepoRoot",$RepoRoot,"-NodeId",$NodeId)
Run-Vtp @("send","-RepoRoot",$RepoRoot,"-NodeId",$NodeId,"-To",$To)
Run-Vtp @("node-loop","-RepoRoot",$RepoRoot,"-NodeId",$NodeId)
Run-Vtp @("status","-RepoRoot",$RepoRoot,"-NodeId",$NodeId)

$afterAccepted = Count-Dirs $Accepted
$dropCount = Count-Dirs $Drop
$latestAccepted = Latest-DirName $Accepted

if($afterAccepted -le $beforeAccepted){
  throw ("VTP_FULL_GREEN_FAIL:ACCEPT_COUNT_NOT_INCREMENTED:BEFORE_" + $beforeAccepted + ":AFTER_" + $afterAccepted)
}

if($dropCount -ne 0){
  throw ("VTP_FULL_GREEN_FAIL:DROP_NOT_EMPTY:COUNT_" + $dropCount)
}

if([string]::IsNullOrWhiteSpace($latestAccepted)){
  throw "VTP_FULL_GREEN_FAIL:NO_LATEST_ACCEPTED"
}

Write-Host ("VTP_FULL_GREEN_LATEST_ACCEPTED: " + $latestAccepted)
Write-Host "VTP_FULL_GREEN_OK"