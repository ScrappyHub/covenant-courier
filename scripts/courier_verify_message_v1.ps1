param(
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"

function Fail([string]$Code){
  throw $Code
}

$msg = Read-Json $MessagePath

if(-not $msg){
  Fail "VERIFY_FAIL:INVALID_JSON"
}

$topProps = @($msg.PSObject.Properties.Name)

if([string]::IsNullOrWhiteSpace([string]$msg.message_id)){
  Fail "VERIFY_FAIL:MISSING_MESSAGE_ID"
}
if(-not ($topProps -contains "hashes")){
  Fail "VERIFY_FAIL:MISSING_HASHES"
}
if(-not ($topProps -contains "payload")){
  Fail "VERIFY_FAIL:MISSING_PAYLOAD"
}
if(-not ($topProps -contains "transport")){
  Fail "VERIFY_FAIL:MISSING_TRANSPORT"
}
if(-not ($topProps -contains "lexical_transforms")){
  Fail "VERIFY_FAIL:MISSING_LEXICAL_TRANSFORMS"
}
if(-not ($topProps -contains "recipients")){
  Fail "VERIFY_FAIL:MISSING_RECIPIENTS"
}
if(-not ($topProps -contains "sender")){
  Fail "VERIFY_FAIL:MISSING_SENDER"
}

$h = $msg.hashes
$hashProps = @($h.PSObject.Properties.Name)

if(-not ($hashProps -contains "payload_hash")){
  Fail "VERIFY_FAIL:MISSING_PAYLOAD_HASH"
}
if(-not ($hashProps -contains "lexical_transform_hash")){
  Fail "VERIFY_FAIL:MISSING_LEXICAL_TRANSFORM_HASH"
}
if(-not ($hashProps -contains "author_hash")){
  Fail "VERIFY_FAIL:MISSING_AUTHOR_HASH"
}
if(-not ($hashProps -contains "recipient_binding_hash")){
  Fail "VERIFY_FAIL:MISSING_RECIPIENT_BINDING_HASH"
}

$transportProps = @($msg.transport.PSObject.Properties.Name)
if(-not ($transportProps -contains "sealed_payload_hash")){
  Fail "VERIFY_FAIL:MISSING_SEALED_PAYLOAD_HASH"
}

$expectedPayloadHash          = [string]$msg.hashes.payload_hash
$expectedLexHash              = [string]$msg.hashes.lexical_transform_hash
$expectedAuthorHash           = [string]$msg.hashes.author_hash
$expectedRecipientBindingHash = [string]$msg.hashes.recipient_binding_hash
$expectedSealedPayloadHash    = [string]$msg.transport.sealed_payload_hash

if([string]::IsNullOrWhiteSpace($expectedPayloadHash)){
  Fail "VERIFY_FAIL:MISSING_PAYLOAD_HASH"
}
if([string]::IsNullOrWhiteSpace($expectedLexHash)){
  Fail "VERIFY_FAIL:MISSING_LEXICAL_TRANSFORM_HASH"
}
if([string]::IsNullOrWhiteSpace($expectedAuthorHash)){
  Fail "VERIFY_FAIL:MISSING_AUTHOR_HASH"
}
if([string]::IsNullOrWhiteSpace($expectedRecipientBindingHash)){
  Fail "VERIFY_FAIL:MISSING_RECIPIENT_BINDING_HASH"
}
if([string]::IsNullOrWhiteSpace($expectedSealedPayloadHash)){
  Fail "VERIFY_FAIL:MISSING_SEALED_PAYLOAD_HASH"
}

$payloadStable = ConvertTo-StableObject $msg.payload
$payloadJson   = $payloadStable | ConvertTo-Json -Depth 100 -Compress
$actualPayloadHash = Sha256Hex $payloadJson

if($actualPayloadHash -ne $expectedPayloadHash){
  Fail "VERIFY_FAIL:PAYLOAD_HASH_MISMATCH"
}

$lexStable = ConvertTo-StableObject $msg.lexical_transforms
$lexJson   = $lexStable | ConvertTo-Json -Depth 100 -Compress
$actualLexHash = Sha256Hex $lexJson

if($actualLexHash -ne $expectedLexHash){
  Fail "VERIFY_FAIL:LEXICAL_TRANSFORM_HASH_MISMATCH"
}

$authorBasis = [ordered]@{
  created_utc  = [string]$msg.created_utc
  lex_hash     = $actualLexHash
  payload_hash = $actualPayloadHash
  sender       = ConvertTo-StableObject $msg.sender
}

$authorBasisJson = (ConvertTo-StableObject $authorBasis | ConvertTo-Json -Depth 100 -Compress)
$actualAuthorHash = Sha256Hex $authorBasisJson

if($actualAuthorHash -ne $expectedAuthorHash){
  Fail "VERIFY_FAIL:AUTHOR_HASH_MISMATCH"
}

$recipientBasis = [ordered]@{
  author_hash = $actualAuthorHash
  recipients  = ConvertTo-StableObject $msg.recipients
}

$recipientBasisJson = (ConvertTo-StableObject $recipientBasis | ConvertTo-Json -Depth 100 -Compress)
$actualRecipientBindingHash = Sha256Hex $recipientBasisJson

if($actualRecipientBindingHash -ne $expectedRecipientBindingHash){
  Fail "VERIFY_FAIL:RECIPIENT_BINDING_HASH_MISMATCH"
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
$actualSealedPayloadHash = Sha256Hex $sealedBasisJson

if($actualSealedPayloadHash -ne $expectedSealedPayloadHash){
  Fail "VERIFY_FAIL:SEALED_PAYLOAD_HASH_MISMATCH"
}

Append-Receipt $RepoRoot ([ordered]@{
  schema        = "courier.receipt.v1"
  event_type    = "courier.message.verified.v1"
  message_id    = [string]$msg.message_id
  timestamp_utc = [DateTime]::UtcNow.ToString("o")
  details       = [ordered]@{
    message_path           = $MessagePath
    payload_hash           = $actualPayloadHash
    lexical_transform_hash = $actualLexHash
    author_hash            = $actualAuthorHash
    recipient_binding_hash = $actualRecipientBindingHash
    sealed_payload_hash    = $actualSealedPayloadHash
  }
})

Write-Host ("COURIER_VERIFY_OK: " + $MessagePath)