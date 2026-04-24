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
  Fail "ENCRYPT_FAIL:MISSING_PAYLOAD"
}
if([string]::IsNullOrWhiteSpace([string]$msg.payload.type)){
  Fail "ENCRYPT_FAIL:MISSING_PAYLOAD_TYPE"
}
if([string]$msg.payload.type -ne "sealed"){
  Fail "ENCRYPT_FAIL:UNEXPECTED_PAYLOAD_TYPE"
}
if($null -eq $msg.hashes){
  Fail "ENCRYPT_FAIL:MISSING_HASHES"
}
if([string]::IsNullOrWhiteSpace([string]$msg.hashes.payload_hash)){
  Fail "ENCRYPT_FAIL:MISSING_PAYLOAD_HASH"
}
if([string]::IsNullOrWhiteSpace([string]$msg.hashes.lexical_transform_hash)){
  Fail "ENCRYPT_FAIL:MISSING_LEXICAL_TRANSFORM_HASH"
}
if([string]::IsNullOrWhiteSpace([string]$msg.hashes.author_hash)){
  Fail "ENCRYPT_FAIL:MISSING_AUTHOR_HASH"
}
if([string]::IsNullOrWhiteSpace([string]$msg.hashes.recipient_binding_hash)){
  Fail "ENCRYPT_FAIL:MISSING_RECIPIENT_BINDING_HASH"
}

$sealedBasis = [ordered]@{
  created_utc        = [string]$msg.created_utc
  expires_utc        = [string]$msg.expires_utc
  hashes             = ConvertTo-StableObject $msg.hashes
  lexical_transforms = ConvertTo-StableObject $msg.lexical_transforms
  message_id         = [string]$msg.message_id
  payload            = ConvertTo-StableObject $msg.payload
  recipients         = ConvertTo-StableObject $msg.recipients
  schema             = [string]$msg.schema
  sender             = ConvertTo-StableObject $msg.sender
  sensitivity        = [string]$msg.sensitivity
}

$sealedBasisJson = (ConvertTo-StableObject $sealedBasis | ConvertTo-Json -Depth 100 -Compress)
$sealedHash = Sha256Hex $sealedBasisJson

$outObj = [ordered]@{
  created_utc        = [string]$msg.created_utc
  expires_utc        = [string]$msg.expires_utc
  hashes             = ConvertTo-StableObject $msg.hashes
  lexical_transforms = ConvertTo-StableObject $msg.lexical_transforms
  message_id         = [string]$msg.message_id
  payload            = ConvertTo-StableObject $msg.payload
  recipients         = ConvertTo-StableObject $msg.recipients
  schema             = [string]$msg.schema
  sender             = ConvertTo-StableObject $msg.sender
  sensitivity        = [string]$msg.sensitivity
  transport          = [ordered]@{
    type                = "sealed"
    sealed_payload_hash = $sealedHash
  }
}

Write-JsonCanonical $OutPath $outObj

Append-Receipt $RepoRoot ([ordered]@{
  schema        = "courier.receipt.v1"
  event_type    = "courier.encrypted.v1"
  message_id    = [string]$msg.message_id
  timestamp_utc = "2026-01-01T00:00:00Z"
  details       = [ordered]@{
    message_path           = $MessagePath
    out_path               = $OutPath
    payload_hash           = [string]$msg.hashes.payload_hash
    author_hash            = [string]$msg.hashes.author_hash
    recipient_binding_hash = [string]$msg.hashes.recipient_binding_hash
    sealed_payload_hash    = $sealedHash
  }
})

Write-Host ("COURIER_ENCRYPT_OK: " + $OutPath)