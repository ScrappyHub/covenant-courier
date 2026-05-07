param(
  [string]$RepoRoot = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$ReceiptPath = Join-Path $RepoRoot "proofs\receipts\covenant_courier_product.ndjson"
$ChainPath = Join-Path $RepoRoot "proofs\receipts\covenant_courier_product.chain.ndjson"

function Sha256Hex {
  param([byte[]]$Bytes)

  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return (($sha.ComputeHash($Bytes) | ForEach-Object { $_.ToString("x2") }) -join "")
  } finally {
    $sha.Dispose()
  }
}

if(-not (Test-Path -LiteralPath $ReceiptPath -PathType Leaf)){
  Write-Host "COVENANT_COURIER_RECEIPT_CHAIN_STATUS:MISSING_PRODUCT_RECEIPTS"
  Write-Host "COVENANT_COURIER_RECEIPT_CHAIN_OK"
  exit 0
}

$lines = @(Get-Content -LiteralPath $ReceiptPath -ErrorAction Stop | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if($lines.Count -eq 0){
  Write-Host "COVENANT_COURIER_RECEIPT_CHAIN_STATUS:EMPTY_PRODUCT_RECEIPTS"
  Write-Host "COVENANT_COURIER_RECEIPT_CHAIN_OK"
  exit 0
}

$prevHash = "0" * 64
$outLines = New-Object System.Collections.Generic.List[string]
$index = 0

foreach($line in $lines){
  $obj = $line | ConvertFrom-Json

  foreach($name in @("schema","receipt_id","message_id","event_type","time_utc","frame_id","payload_sha256","decision")){
    if($obj.PSObject.Properties.Name -notcontains $name){
      throw ("COVENANT_COURIER_RECEIPT_CHAIN_FAIL:MISSING_FIELD:" + $index + ":" + $name)
    }
  }

  $lineBytes = [Text.Encoding]::UTF8.GetBytes($line)
  $entryHash = Sha256Hex -Bytes $lineBytes
  $linkBytes = [Text.Encoding]::UTF8.GetBytes(($prevHash + ":" + $entryHash))
  $chainHash = Sha256Hex -Bytes $linkBytes

  $chainEntry = [ordered]@{
    schema = "covenant_courier.product_receipt_chain.v1"
    index = $index
    previous_chain_hash = $prevHash
    receipt_sha256 = $entryHash
    chain_hash = $chainHash
  }

  [void]$outLines.Add(($chainEntry | ConvertTo-Json -Depth 20 -Compress))

  $prevHash = $chainHash
  $index++
}

[IO.File]::WriteAllText($ChainPath, (($outLines.ToArray() -join [string][char]10) + [string][char]10), [Text.UTF8Encoding]::new($false))

# Verify the chain file just written.
$checkLines = @(Get-Content -LiteralPath $ChainPath -ErrorAction Stop | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

if($checkLines.Count -ne $lines.Count){
  throw "COVENANT_COURIER_RECEIPT_CHAIN_FAIL:COUNT_MISMATCH"
}

$verifyPrev = "0" * 64

for($i = 0; $i -lt $checkLines.Count; $i++){
  $chainObj = $checkLines[$i] | ConvertFrom-Json
  $receiptHash = Sha256Hex -Bytes ([Text.Encoding]::UTF8.GetBytes($lines[$i]))
  $expectedChain = Sha256Hex -Bytes ([Text.Encoding]::UTF8.GetBytes(($verifyPrev + ":" + $receiptHash)))

  if([string]$chainObj.previous_chain_hash -ne $verifyPrev){
    throw ("COVENANT_COURIER_RECEIPT_CHAIN_FAIL:PREV_HASH_MISMATCH:" + $i)
  }

  if([string]$chainObj.receipt_sha256 -ne $receiptHash){
    throw ("COVENANT_COURIER_RECEIPT_CHAIN_FAIL:RECEIPT_HASH_MISMATCH:" + $i)
  }

  if([string]$chainObj.chain_hash -ne $expectedChain){
    throw ("COVENANT_COURIER_RECEIPT_CHAIN_FAIL:CHAIN_HASH_MISMATCH:" + $i)
  }

  $verifyPrev = [string]$chainObj.chain_hash
}

Write-Host ("COVENANT_COURIER_RECEIPT_CHAIN_ENTRIES: " + $lines.Count)
Write-Host ("COVENANT_COURIER_RECEIPT_CHAIN_HEAD: " + $verifyPrev)
Write-Host ("COVENANT_COURIER_RECEIPT_CHAIN_PATH: " + $ChainPath)
Write-Host "COVENANT_COURIER_RECEIPT_CHAIN_OK"
