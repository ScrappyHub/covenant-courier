param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$SenderIdentity,
  [Parameter(Mandatory=$true)][string]$RecipientIdentity,
  [Parameter(Mandatory=$true)][string]$SenderNodeId,
  [Parameter(Mandatory=$true)][string]$RecipientNodeId,
  [Parameter(Mandatory=$true)][string]$NetworkId,
  [Parameter(Mandatory=$true)][string]$SessionId,
  [Parameter(Mandatory=$true)][string]$SenderRole,
  [Parameter(Mandatory=$true)][string]$DropRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_receipts_v1.ps1"

function Fail([string]$Code){
  throw $Code
}

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

if(-not (Test-Path -LiteralPath $MessagePath -PathType Leaf)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_MESSAGE" }
$sigPath = $MessagePath + ".sig"
if(-not (Test-Path -LiteralPath $sigPath -PathType Leaf)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_SIGNATURE" }

if([string]::IsNullOrWhiteSpace($SenderIdentity)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_SENDER_IDENTITY" }
if([string]::IsNullOrWhiteSpace($RecipientIdentity)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_RECIPIENT_IDENTITY" }
if([string]::IsNullOrWhiteSpace($SenderNodeId)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_SENDER_NODE_ID" }
if([string]::IsNullOrWhiteSpace($RecipientNodeId)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_RECIPIENT_NODE_ID" }
if([string]::IsNullOrWhiteSpace($NetworkId)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_NETWORK_ID" }
if([string]::IsNullOrWhiteSpace($SessionId)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_SESSION_ID" }
if([string]::IsNullOrWhiteSpace($SenderRole)){ Fail "COURIER_TRANSPORT_SEND_FAIL:MISSING_SENDER_ROLE" }

Ensure-Dir $DropRoot

$frameId = "frame-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
$frameDir = Join-Path $DropRoot $frameId
$payloadDir = Join-Path $frameDir "payload"
Ensure-Dir $payloadDir

$msgName = [System.IO.Path]::GetFileName($MessagePath)
$sigName = [System.IO.Path]::GetFileName($sigPath)
$destMsg = Join-Path $payloadDir $msgName
$destSig = Join-Path $payloadDir $sigName

Copy-Item -LiteralPath $MessagePath -Destination $destMsg -Force
Copy-Item -LiteralPath $sigPath -Destination $destSig -Force

$payloadSha = (Get-FileHash -LiteralPath $destMsg -Algorithm SHA256).Hash.ToLowerInvariant()

$frame = [ordered]@{
  schema = "courier.transport_frame.v2"
  frame_id = $frameId
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
  sender_identity = $SenderIdentity
  recipient_identity = $RecipientIdentity
  sender_node_id = $SenderNodeId
  recipient_node_id = $RecipientNodeId
  network_id = $NetworkId
  session_id = $SessionId
  sender_role = $SenderRole
  message_rel = ("payload/" + $msgName)
  signature_rel = ("payload/" + $sigName)
  payload_sha256 = $payloadSha
}

$enc = New-Object System.Text.UTF8Encoding($false)
$frameJson = $frame | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText((Join-Path $frameDir "frame.json"), ($frameJson + "`n"), $enc)

$receiptPath = Append-CourierReceipt -RepoRoot $RepoRoot -Receipt ([ordered]@{
  schema = "courier.transport.receipt.v1"
  event_type = "courier.transport.send.v1"
  timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
  details = [ordered]@{
    frame_id = $frameId
    sender_identity = $SenderIdentity
    recipient_identity = $RecipientIdentity
    sender_node_id = $SenderNodeId
    recipient_node_id = $RecipientNodeId
    network_id = $NetworkId
    session_id = $SessionId
    sender_role = $SenderRole
    drop_root = $DropRoot
    frame_root = $frameDir
    payload_sha256 = $payloadSha
  }
})

Write-Host ("COURIER_TRANSPORT_SEND_OK: " + $frameDir)
Write-Host ("COURIER_TRANSPORT_SEND_RECEIPT_OK: " + $receiptPath)
