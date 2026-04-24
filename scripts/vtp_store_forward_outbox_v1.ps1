param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$EncryptedPath,
  [Parameter(Mandatory=$true)][string]$QueueRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_lib_vtp_crypto_v1.ps1"

if(-not (Test-Path -LiteralPath $EncryptedPath -PathType Leaf)){ throw "VTP_STORE_FORWARD_FAIL:MISSING_ENCRYPTED" }
Ensure-Dir $QueueRoot

$id = "queued-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
$itemRoot = Join-Path $QueueRoot $id
Ensure-Dir $itemRoot

Copy-Item -LiteralPath $EncryptedPath -Destination (Join-Path $itemRoot "encrypted_payload.json") -Force

$receiptRoot = Join-Path $RepoRoot "proofs\receipts"
Ensure-Dir $receiptRoot
$receipt = [ordered]@{
  schema = "vtp.store_forward.receipt.v1"
  event_type = "vtp.store_forward.enqueue.v1"
  timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
  details = [ordered]@{
    queue_id = $id
    queue_root = $QueueRoot
    encrypted_sha256 = (Get-Sha256HexFile $EncryptedPath)
  }
}
$line = ($receipt | ConvertTo-Json -Depth 20 -Compress)
$path = Join-Path $receiptRoot "vtp_store_forward.ndjson"
Add-Content -LiteralPath $path -Value $line

Write-Host ("VTP_STORE_FORWARD_ITEM: " + $itemRoot)
Write-Host "VTP_STORE_FORWARD_ENQUEUE_OK"
