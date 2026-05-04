param(
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Vtp = Join-Path $RepoRoot "vtp.ps1"

$Drop = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\inbox\drop")
$Rejected = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\rejected")
$FrameName = "frame-dlp-negative-blocked-role"
$FrameDir = Join-Path $Drop $FrameName

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][IO.Directory]::CreateDirectory($Path)
  }
}

function Reset-Dir([string]$Path){
  if(Test-Path -LiteralPath $Path){
    Remove-Item -LiteralPath $Path -Recurse -Force
  }
  [void][IO.Directory]::CreateDirectory($Path)
}

Ensure-Dir $Drop
Ensure-Dir $Rejected
Reset-Dir $FrameDir

$frame = [ordered]@{
  schema = "courier.transport_frame.v2"
  frame_id = $FrameName
  created_utc = "2026-01-01T00:00:00.0000000Z"
  sender_identity = "courier-local@covenant"
  recipient_identity = "courier-local@covenant"
  sender_node_id = "node-alpha"
  recipient_node_id = $NodeId
  network_id = "courier-internal-net-v1"
  session_id = "session-alpha-beta-001"
  sender_role = "blocked"
  message_rel = "payload/message.tokenized.json"
  signature_rel = "payload/message.tokenized.json.sig"
  payload_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"
}

[IO.File]::WriteAllText(
  (Join-Path $FrameDir "frame.json"),
  (($frame | ConvertTo-Json -Depth 20 -Compress) + "`n"),
  [Text.UTF8Encoding]::new($false)
)

& powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass `
  -File $Vtp `
  node-loop `
  -RepoRoot $RepoRoot `
  -NodeId $NodeId

if($LASTEXITCODE -ne 0){
  throw "VTP_DLP_NEGATIVE_FAIL:NODE_LOOP_EXIT"
}

$RejectedDir = Join-Path $Rejected $FrameName
$ReasonPath = Join-Path $RejectedDir "reject_reason.txt"

if(-not (Test-Path -LiteralPath $RejectedDir -PathType Container)){
  throw "VTP_DLP_NEGATIVE_FAIL:FRAME_NOT_REJECTED"
}

if(-not (Test-Path -LiteralPath $ReasonPath -PathType Leaf)){
  throw "VTP_DLP_NEGATIVE_FAIL:MISSING_REJECT_REASON"
}

$reason = Get-Content -LiteralPath $ReasonPath -Raw
if($reason -notmatch "VTP_POLICY_DENY:SENDER_ROLE_DENIED:blocked"){
  throw ("VTP_DLP_NEGATIVE_FAIL:WRONG_REASON:" + $reason)
}

Write-Host "VTP_DLP_NEGATIVE_REJECT_OK"