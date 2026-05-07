param(
  [string]$RepoRoot = ".",
  [string]$From = "local/sender/demo",
  [string]$RecipientNodeId = "node-beta",
  [string]$RecipientIdentity = "local/recipient/demo",
  [string]$PayloadText = "hello from covenant courier",
  [string]$PolicyProfile = "default"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"
$Courier = Join-Path $RepoRoot "courier.ps1"
$Vtp = Join-Path $RepoRoot "vtp.ps1"
$ReceiptRoot = Join-Path $RepoRoot "proofs\receipts"
$ProductReceipt = Join-Path $ReceiptRoot "covenant_courier_product.ndjson"

[void][IO.Directory]::CreateDirectory($ReceiptRoot)

if(-not (Test-Path -LiteralPath $Courier -PathType Leaf)){
  throw "COURIER_SEND_FAIL:MISSING_COURIER_CLI"
}

if(-not (Test-Path -LiteralPath $Vtp -PathType Leaf)){
  throw "COURIER_SEND_FAIL:MISSING_VTP_CLI"
}

function Sha256Hex {
  param([byte[]]$Bytes)

  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
  } finally {
    $sha.Dispose()
  }
}

function Run-Child {
  param(
    [Parameter(Mandatory=$true)][string]$Script,
    [Parameter(Mandatory=$true)][string[]]$ChildArgs
  )

  $ps = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
  $out = & $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @ChildArgs 2>&1
  $code = $LASTEXITCODE
  $text = ($out | Out-String)

  Write-Host $text.Trim()

  if($code -ne 0){
    throw ("COURIER_SEND_FAIL:CHILD_EXIT:" + $code + ":" + $Script)
  }

  return $text
}

$prepareText = Run-Child -Script $Courier -ChildArgs @(
  "prepare",
  "-RepoRoot",
  $RepoRoot,
  "-From",
  $From,
  "-To",
  $RecipientIdentity,
  "-PayloadText",
  $PayloadText
)

$messagePath = ""
foreach($line in ($prepareText -split "`n")){
  if($line -match 'COURIER_PREPARE_MESSAGE_OK:\s+(.+)$'){
    $messagePath = $Matches[1].Trim()
  }
}

if([string]::IsNullOrWhiteSpace($messagePath)){
  throw "COURIER_SEND_FAIL:MESSAGE_PATH_NOT_FOUND"
}

if(-not (Test-Path -LiteralPath $messagePath -PathType Leaf)){
  throw ("COURIER_SEND_FAIL:MESSAGE_FILE_MISSING:" + $messagePath)
}

$message = Get-Content -LiteralPath $messagePath -Raw | ConvertFrom-Json

$messageId = [string]$message.message_id
$payloadSha = [string]$message.payload_sha256

if([string]::IsNullOrWhiteSpace($messageId)){
  throw "COURIER_SEND_FAIL:MESSAGE_ID_MISSING"
}

if($payloadSha -notmatch "^[a-f0-9]{64}$"){
  throw "COURIER_SEND_FAIL:BAD_PAYLOAD_SHA256"
}

$sendText = Run-Child -Script $Vtp -ChildArgs @(
  "send",
  "-RepoRoot",
  $RepoRoot,
  "-To",
  $RecipientNodeId
)

$frameId = ""
$framePath = ""

foreach($line in ($sendText -split "`n")){
  if($line -match 'COURIER_TRANSPORT_SEND_OK:\s+(.+)$'){
    $framePath = $Matches[1].Trim()
    $frameId = Split-Path -Leaf $framePath
  }
}

if([string]::IsNullOrWhiteSpace($frameId)){
  throw "COURIER_SEND_FAIL:FRAME_ID_NOT_FOUND"
}

$receiptId = "ccreceipt-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
$receipt = [ordered]@{
  schema = "covenant_courier.product_receipt.v1"
  receipt_id = $receiptId
  message_id = $messageId
  event_type = "covenant_courier.product.send.v1"
  time_utc = (Get-Date).ToUniversalTime().ToString("o")
  frame_id = $frameId
  payload_sha256 = $payloadSha
  decision = "sent"
  reason_code = $null
}

$lineJson = $receipt | ConvertTo-Json -Depth 20 -Compress
[IO.File]::AppendAllText($ProductReceipt, ($lineJson + [string][char]10), [Text.UTF8Encoding]::new($false))

$check = $lineJson | ConvertFrom-Json
foreach($name in @("schema","receipt_id","message_id","event_type","time_utc","frame_id","payload_sha256","decision")){
  if($check.PSObject.Properties.Name -notcontains $name){
    throw ("COURIER_SEND_FAIL:RECEIPT_MISSING_FIELD:" + $name)
  }
}

if([string]$check.schema -ne "covenant_courier.product_receipt.v1"){
  throw "COURIER_SEND_FAIL:RECEIPT_BAD_SCHEMA"
}

if([string]$check.decision -ne "sent"){
  throw "COURIER_SEND_FAIL:RECEIPT_BAD_DECISION"
}

Write-Host ("COURIER_SEND_MESSAGE_ID: " + $messageId)
Write-Host ("COURIER_SEND_FRAME_ID: " + $frameId)
Write-Host ("COURIER_SEND_PAYLOAD_SHA256: " + $payloadSha)
Write-Host ("COURIER_SEND_PRODUCT_RECEIPT_OK: " + $ProductReceipt)
Write-Host "COVENANT_COURIER_SEND_OK"
