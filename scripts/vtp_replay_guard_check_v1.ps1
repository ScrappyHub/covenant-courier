param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$FrameDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

function Get-Sha256Hex([byte[]]$Bytes){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  try { $h=$sha.ComputeHash($Bytes) } finally { $sha.Dispose() }
  return (($h | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Read-Utf8NoBom([string]$Path){
  $b=[System.IO.File]::ReadAllBytes($Path)
  $enc=New-Object System.Text.UTF8Encoding($false,$true)
  return $enc.GetString($b)
}

$frameJsonPath = Join-Path $FrameDir "frame.json"
if(-not (Test-Path -LiteralPath $frameJsonPath -PathType Leaf)){
  throw "VTP_REPLAY_GUARD_FAIL:MISSING_FRAME_JSON"
}

# Canonical bytes = exact file bytes (consistent with your other hashing rules)
$bytes = [System.IO.File]::ReadAllBytes($frameJsonPath)
$frameId = Get-Sha256Hex $bytes

$StateRoot = Join-Path $RepoRoot "proofs\state\replay_guard"
$IndexPath = Join-Path $StateRoot "seen_frame_ids.ndjson"
Ensure-Dir $StateRoot

# Build in-memory set
$seen = New-Object 'System.Collections.Generic.HashSet[string]'
if(Test-Path -LiteralPath $IndexPath){
  $lines = @(Get-Content -LiteralPath $IndexPath | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
  foreach($l in $lines){
    try {
      $o = $l | ConvertFrom-Json
      if($o.frame_id){ [void]$seen.Add([string]$o.frame_id) }
    } catch {}
  }
}

if($seen.Contains($frameId)){
  $receiptRoot = Join-Path $RepoRoot "proofs\receipts"
  Ensure-Dir $receiptRoot
  $r = [ordered]@{
    schema = "vtp.replay_guard.receipt.v1"
    event_type = "vtp.replay_guard.reject.v1"
    timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
    details = [ordered]@{
      frame_id = $frameId
      frame_dir = $FrameDir
      reason = "replay_detected"
    }
  }
  Add-Content -LiteralPath (Join-Path $receiptRoot "vtp_replay_guard.ndjson") -Value ($r | ConvertTo-Json -Depth 20 -Compress)
  throw "VTP_REPLAY_DETECTED"
}

# Record new frame id (append-only)
$entry = [ordered]@{
  frame_id = $frameId
  first_seen_utc = (Get-Date).ToUniversalTime().ToString("o")
  frame_dir = $FrameDir
}
Add-Content -LiteralPath $IndexPath -Value ($entry | ConvertTo-Json -Depth 20 -Compress)

$receiptRoot = Join-Path $RepoRoot "proofs\receipts"
Ensure-Dir $receiptRoot
$r2 = [ordered]@{
  schema = "vtp.replay_guard.receipt.v1"
  event_type = "vtp.replay_guard.accept.v1"
  timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
  details = [ordered]@{
    frame_id = $frameId
    frame_dir = $FrameDir
  }
}
Add-Content -LiteralPath (Join-Path $receiptRoot "vtp_replay_guard.ndjson") -Value ($r2 | ConvertTo-Json -Depth 20 -Compress)

Write-Host ("VTP_REPLAY_GUARD_ACCEPT: " + $frameId)
