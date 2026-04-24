param(
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"

function Fail([string]$Code){
  throw $Code
}

$msg = Read-Json $MessagePath

if($null -eq $msg.payload){
  Fail "COMMIT_FAIL:MISSING_PAYLOAD"
}
if($null -eq $msg.sender){
  Fail "COMMIT_FAIL:MISSING_SENDER"
}
if($null -eq $msg.recipients){
  Fail "COMMIT_FAIL:MISSING_RECIPIENTS"
}
if([string]::IsNullOrWhiteSpace([string]$msg.message_id)){
  Fail "COMMIT_FAIL:MISSING_MESSAGE_ID"
}

# Commit hashes must reflect the transport-visible governed object that will later verify.
# That means payload is committed as { type = "sealed" }.
$committedPayload = [ordered]@{
  type = "sealed"
}

$payloadStable = ConvertTo-StableObject $committedPayload
$payloadJson   = $payloadStable | ConvertTo-Json -Depth 100 -Compress
$payloadHash   = Sha256Hex $payloadJson

$lexStable = ConvertTo-StableObject $msg.lexical_transforms
$lexJson   = $lexStable | ConvertTo-Json -Depth 100 -Compress
$lexHash   = Sha256Hex $lexJson

$authorBasis = [ordered]@{
  created_utc  = [string]$msg.created_utc
  lex_hash     = $lexHash
  payload_hash = $payloadHash
  sender       = ConvertTo-StableObject $msg.sender
}

$authorBasisJson = (ConvertTo-StableObject $authorBasis | ConvertTo-Json -Depth 100 -Compress)
$authorHash = Sha256Hex $authorBasisJson

$recipientBasis = [ordered]@{
  author_hash = $authorHash
  recipients  = ConvertTo-StableObject $msg.recipients
}

$recipientBasisJson = (ConvertTo-StableObject $recipientBasis | ConvertTo-Json -Depth 100 -Compress)
$recipientBindingHash = Sha256Hex $recipientBasisJson

$outObj = [ordered]@{
  created_utc         = [string]$msg.created_utc
  expires_utc         = [string]$msg.expires_utc
  hashes              = [ordered]@{
    author_hash             = $authorHash
    lexical_transform_hash  = $lexHash
    payload_hash            = $payloadHash
    recipient_binding_hash  = $recipientBindingHash
  }
  lexical_transforms  = ConvertTo-StableObject $msg.lexical_transforms
  message_id          = [string]$msg.message_id
  payload             = $committedPayload
  recipients          = ConvertTo-StableObject $msg.recipients
  schema              = [string]$msg.schema
  sender              = ConvertTo-StableObject $msg.sender
  sensitivity         = [string]$msg.sensitivity
}

Write-JsonCanonical $OutPath $outObj

Append-Receipt $RepoRoot ([ordered]@{
  schema        = "courier.receipt.v1"
  event_type    = "courier.message.committed.v1"
  message_id    = [string]$msg.message_id
  timestamp_utc = "2026-01-01T00:00:00Z"
  details       = [ordered]@{
    message_path            = $MessagePath
    out_path                = $OutPath
    payload_hash            = $payloadHash
    lexical_transform_hash  = $lexHash
    author_hash             = $authorHash
    recipient_binding_hash  = $recipientBindingHash
  }
})

Write-Host ("COURIER_COMMIT_OK: " + $OutPath)