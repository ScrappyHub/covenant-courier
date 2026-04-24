param(
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"

$msg = Read-Json $MessagePath

if($null -eq $msg.hashes){
  throw "SENDER_CONFIRM_FAIL: MISSING_HASHES"
}
if($null -eq $msg.transport){
  throw "SENDER_CONFIRM_FAIL: MISSING_TRANSPORT"
}
if([string]::IsNullOrWhiteSpace([string]$msg.hashes.author_hash)){
  throw "SENDER_CONFIRM_FAIL: MISSING_AUTHOR_HASH"
}
if([string]::IsNullOrWhiteSpace([string]$msg.hashes.recipient_binding_hash)){
  throw "SENDER_CONFIRM_FAIL: MISSING_RECIPIENT_BINDING_HASH"
}
if([string]::IsNullOrWhiteSpace([string]$msg.transport.sealed_payload_hash)){
  throw "SENDER_CONFIRM_FAIL: MISSING_SEALED_PAYLOAD_HASH"
}

Append-Receipt $RepoRoot ([ordered]@{
  schema        = "courier.receipt.v1"
  event_type    = "courier.sender.confirmation.v1"
  message_id    = [string]$msg.message_id
  timestamp_utc = "2026-01-01T00:00:00Z"
  details       = [ordered]@{
    author_hash             = [string]$msg.hashes.author_hash
    recipient_binding_hash  = [string]$msg.hashes.recipient_binding_hash
    sealed_payload_hash     = [string]$msg.transport.sealed_payload_hash
    message_path            = $MessagePath
  }
})

Write-Host "COURIER_SENDER_CONFIRM_OK"