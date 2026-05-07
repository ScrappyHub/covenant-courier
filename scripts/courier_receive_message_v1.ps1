param(
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Courier = Join-Path $RepoRoot "courier.ps1"
$Vtp = Join-Path $RepoRoot "vtp.ps1"
$ReceiptRoot = Join-Path $RepoRoot "proofs\receipts"
$ProductReceipt = Join-Path $ReceiptRoot "covenant_courier_product.ndjson"

[void][IO.Directory]::CreateDirectory($ReceiptRoot)

if(-not (Test-Path -LiteralPath $Vtp -PathType Leaf)){
  throw "COURIER_RECEIVE_FAIL:MISSING_VTP_CLI"
}

if(-not (Test-Path -LiteralPath $ProductReceipt -PathType Leaf)){
  throw "COURIER_RECEIVE_FAIL:MISSING_PRODUCT_RECEIPTS"
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
    throw ("COURIER_RECEIVE_FAIL:CHILD_EXIT:" + $code + ":" + $Script)
  }

  return $text
}

$lines = @(Get-Content -LiteralPath $ProductReceipt -ErrorAction Stop)
$receipts = @()

foreach($line in $lines){
  if([string]::IsNullOrWhiteSpace($line)){ continue }
  $obj = $line | ConvertFrom-Json
  $receipts += $obj
}

$acceptedFrames = New-Object 'System.Collections.Generic.HashSet[string]'

foreach($r in $receipts){
  $decision = ""
  $frame = ""

  if($r.PSObject.Properties.Name -contains "decision"){
    $decision = [string]$r.decision
  }

  if($r.PSObject.Properties.Name -contains "frame_id"){
    $frame = [string]$r.frame_id
  }

  if($decision -eq "accepted" -and -not [string]::IsNullOrWhiteSpace($frame)){
    [void]$acceptedFrames.Add($frame)
  }
}

$target = $null

for($i = @($receipts).Count - 1; $i -ge 0; $i--){
  $r = $receipts[$i]

  $decision = ""
  $frame = ""

  if($r.PSObject.Properties.Name -contains "decision"){
    $decision = [string]$r.decision
  }

  if($r.PSObject.Properties.Name -contains "frame_id"){
    $frame = [string]$r.frame_id
  }

  if($decision -eq "sent" -and -not [string]::IsNullOrWhiteSpace($frame)){
    if(-not $acceptedFrames.Contains($frame)){
      $target = $r
      break
    }
  }
}

if($null -eq $target){
  throw "COURIER_RECEIVE_FAIL:NO_UNACCEPTED_SENT_PRODUCT_FRAME"
}

$messageId = [string]$target.message_id
$frameId = [string]$target.frame_id
$payloadSha = [string]$target.payload_sha256

if([string]::IsNullOrWhiteSpace($messageId)){
  throw "COURIER_RECEIVE_FAIL:MESSAGE_ID_MISSING"
}

if([string]::IsNullOrWhiteSpace($frameId)){
  throw "COURIER_RECEIVE_FAIL:FRAME_ID_MISSING"
}

if($payloadSha -notmatch "^[a-f0-9]{64}$"){
  throw "COURIER_RECEIVE_FAIL:BAD_PAYLOAD_SHA256"
}

Run-Child -Script $Vtp -ChildArgs @(
  "node-loop",
  "-RepoRoot",
  $RepoRoot,
  "-NodeId",
  $NodeId
)

$acceptedPath = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\accepted\" + $frameId)
$dropPath = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\inbox\drop\" + $frameId)
$rejectedPath = Join-Path $RepoRoot ("runtime\nodes\" + $NodeId + "\rejected\" + $frameId)

if(-not (Test-Path -LiteralPath $acceptedPath -PathType Container)){
  Write-Host ("COURIER_RECEIVE_FRAME: " + $frameId)
  Write-Host ("COURIER_RECEIVE_ACCEPTED_EXISTS: " + (Test-Path -LiteralPath $acceptedPath))
  Write-Host ("COURIER_RECEIVE_DROP_EXISTS: " + (Test-Path -LiteralPath $dropPath))
  Write-Host ("COURIER_RECEIVE_REJECTED_EXISTS: " + (Test-Path -LiteralPath $rejectedPath))
  throw ("COURIER_RECEIVE_FAIL:FRAME_NOT_ACCEPTED:" + $frameId)
}

$receiptId = "ccreceipt-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
$receipt = [ordered]@{
  schema = "covenant_courier.product_receipt.v1"
  receipt_id = $receiptId
  message_id = $messageId
  event_type = "covenant_courier.product.accept.v1"
  time_utc = (Get-Date).ToUniversalTime().ToString("o")
  frame_id = $frameId
  payload_sha256 = $payloadSha
  decision = "accepted"
  reason_code = "VTP_POLICY_ALLOW"
}

$lineJson = $receipt | ConvertTo-Json -Depth 20 -Compress
[IO.File]::AppendAllText($ProductReceipt, ($lineJson + [string][char]10), [Text.UTF8Encoding]::new($false))

Write-Host ("COURIER_RECEIVE_MESSAGE_ID: " + $messageId)
Write-Host ("COURIER_RECEIVE_FRAME_ID: " + $frameId)
Write-Host ("COURIER_RECEIVE_ACCEPTED_PATH: " + $acceptedPath)
Write-Host ("COURIER_RECEIVE_PRODUCT_RECEIPT_OK: " + $ProductReceipt)
Write-Host "COVENANT_COURIER_RECEIVE_OK"
