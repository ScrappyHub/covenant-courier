param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [string]$NodeId = "node-beta",
  [switch]$Once
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Drop = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\inbox\drop")
$Rejected = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\rejected")
$PolicyGate = Join-Path $RepoRoot "scripts\vtp_policy_gate_v1.ps1"
$BaseLoop = Join-Path $RepoRoot "scripts\vtp_node_loop_v1.ps1"

if(-not (Test-Path -LiteralPath $PolicyGate -PathType Leaf)){ throw "VTP_NODE_LOOP_POLICY_FAIL:MISSING_POLICY_GATE" }
if(-not (Test-Path -LiteralPath $BaseLoop -PathType Leaf)){ throw "VTP_NODE_LOOP_POLICY_FAIL:MISSING_BASE_LOOP" }

if(-not (Test-Path -LiteralPath $Rejected)){ [void][IO.Directory]::CreateDirectory($Rejected) }

$frames = @(Get-ChildItem -LiteralPath $Drop -Directory -ErrorAction SilentlyContinue | Sort-Object FullName)

foreach($frame in $frames){
  if(-not (Test-Path -LiteralPath $frame.FullName -PathType Container)){
    continue
  }

  $out = & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $PolicyGate -RepoRoot $RepoRoot -FrameDir $frame.FullName 2>&1
  $text = ($out | Out-String).Trim()
  $code = $LASTEXITCODE

  if($code -eq 42){
    if(-not (Test-Path -LiteralPath $frame.FullName -PathType Container)){
      continue
    }

    $dest = Join-Path $Rejected $frame.Name
    if(Test-Path -LiteralPath $dest){ Remove-Item -LiteralPath $dest -Recurse -Force }

    try {
      Move-Item -LiteralPath $frame.FullName -Destination $dest -Force -ErrorAction Stop
      [IO.File]::WriteAllText((Join-Path $dest "reject_reason.txt"), ($text + "`n"), [Text.UTF8Encoding]::new($false))
      Write-Host ("VTP_POLICY_REJECT_OK: " + $dest)
    } catch {
      if(Test-Path -LiteralPath $dest -PathType Container){
        Write-Host ("VTP_POLICY_REJECT_ALREADY_MOVED_OK: " + $dest)
      } else {
        throw
      }
    }
  } elseif($code -ne 0){
    throw ("VTP_NODE_LOOP_POLICY_FAIL:POLICY_GATE_EXIT_" + $code + ":" + $text)
  } else {
    Write-Host ("VTP_POLICY_ALLOW_OK: " + $frame.FullName)
  }
}

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $BaseLoop -RepoRoot $RepoRoot -NodeId $NodeId -Once
if($LASTEXITCODE -ne 0){ throw "VTP_NODE_LOOP_POLICY_FAIL:BASE_LOOP_FAILED" }

Write-Host ("VTP_NODE_LOOP_POLICY_OK: " + $NodeId)