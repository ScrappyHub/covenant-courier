param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$FrameRoot,
  [Parameter(Mandatory=$true)][string]$QueueRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

function Write-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir){ Ensure-Dir $dir }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

function Get-Sha256HexFile([string]$Path){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  $fs=[System.IO.File]::OpenRead($Path)
  try { $h=$sha.ComputeHash($fs) } finally { $fs.Dispose(); $sha.Dispose() }
  return (($h | ForEach-Object { $_.ToString("x2") }) -join "")
}

if(-not (Test-Path -LiteralPath $FrameRoot -PathType Container)){
  throw "VTP_OUTBOX_ENQUEUE_FAIL:MISSING_FRAME_ROOT"
}

Ensure-Dir $QueueRoot

$itemId = "outbox-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
$itemRoot = Join-Path $QueueRoot $itemId
Ensure-Dir $itemRoot

$frameDest = Join-Path $itemRoot "frame"
Copy-Item -LiteralPath $FrameRoot -Destination $frameDest -Recurse -Force

$meta = [ordered]@{
  schema = "vtp.outbox.item.v1"
  queue_id = $itemId
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
  status = "queued"
  attempts = 0
  next_attempt_utc = (Get-Date).ToUniversalTime().ToString("o")
  last_attempt_utc = $null
  last_error = $null
  frame_root = "frame"
}

Write-Utf8NoBomLf (Join-Path $itemRoot "queue_item.json") (($meta | ConvertTo-Json -Depth 20 -Compress))

$receiptRoot = Join-Path $RepoRoot "proofs\receipts"
Ensure-Dir $receiptRoot
$receipt = [ordered]@{
  schema = "vtp.outbox.receipt.v1"
  event_type = "vtp.outbox.enqueue.v1"
  timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
  details = [ordered]@{
    queue_id = $itemId
    queue_root = $QueueRoot
    frame_root = $FrameRoot
  }
}
Add-Content -LiteralPath (Join-Path $receiptRoot "vtp_outbox.ndjson") -Value ($receipt | ConvertTo-Json -Depth 20 -Compress)

Write-Host ("VTP_OUTBOX_ITEM: " + $itemRoot)
Write-Host "VTP_OUTBOX_ENQUEUE_OK"
