param(
  [string]$RepoRoot = ".",
  [int]$Tail = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$ReceiptPath = Join-Path $RepoRoot "proofs\receipts\covenant_courier_product.ndjson"

function Get-Prop {
  param(
    [AllowNull()]$Obj,
    [string]$Name
  )

  if($null -eq $Obj){ return "" }

  foreach($p in @($Obj.PSObject.Properties)){
    if($p.Name -eq $Name){
      if($null -eq $p.Value){ return "" }
      return [string]$p.Value
    }
  }

  return ""
}

Write-Host "COVENANT COURIER RECEIPTS"
Write-Host ("Repo: " + $RepoRoot)
Write-Host ("Path: " + $ReceiptPath)
Write-Host ("Tail: " + $Tail)

if(-not (Test-Path -LiteralPath $ReceiptPath -PathType Leaf)){
  Write-Host "Status: missing"
  Write-Host "COVENANT_COURIER_RECEIPTS_OK"
  exit 0
}

$lines = @(Get-Content -LiteralPath $ReceiptPath -Tail $Tail -ErrorAction Stop)

if($lines.Count -eq 0){
  Write-Host "Status: empty"
  Write-Host "COVENANT_COURIER_RECEIPTS_OK"
  exit 0
}

foreach($line in $lines){
  if([string]::IsNullOrWhiteSpace($line)){ continue }

  try {
    $obj = $line | ConvertFrom-Json

    $schema = Get-Prop -Obj $obj -Name "schema"
    $time = Get-Prop -Obj $obj -Name "time_utc"
    $messageId = Get-Prop -Obj $obj -Name "message_id"
    $frameId = Get-Prop -Obj $obj -Name "frame_id"
    $eventType = Get-Prop -Obj $obj -Name "event_type"
    $decision = Get-Prop -Obj $obj -Name "decision"
    $reason = Get-Prop -Obj $obj -Name "reason_code"
    $hash = Get-Prop -Obj $obj -Name "payload_sha256"

    $parts = New-Object System.Collections.Generic.List[string]

    if(-not [string]::IsNullOrWhiteSpace($schema)){ [void]$parts.Add("schema=" + $schema) }
    if(-not [string]::IsNullOrWhiteSpace($time)){ [void]$parts.Add("time=" + $time) }
    if(-not [string]::IsNullOrWhiteSpace($messageId)){ [void]$parts.Add("message=" + $messageId) }
    if(-not [string]::IsNullOrWhiteSpace($frameId)){ [void]$parts.Add("frame=" + $frameId) }
    if(-not [string]::IsNullOrWhiteSpace($eventType)){ [void]$parts.Add("event=" + $eventType) }
    if(-not [string]::IsNullOrWhiteSpace($decision)){ [void]$parts.Add("decision=" + $decision) }
    if(-not [string]::IsNullOrWhiteSpace($reason)){ [void]$parts.Add("reason=" + $reason) }
    if(-not [string]::IsNullOrWhiteSpace($hash)){ [void]$parts.Add("hash=" + $hash) }

    if($parts.Count -gt 0){
      Write-Host (($parts.ToArray()) -join " ")
    } else {
      Write-Host ("json=" + ($obj | ConvertTo-Json -Depth 20 -Compress))
    }
  } catch {
    Write-Host ("parse_error=" + $_.Exception.Message)
    Write-Host ("raw=" + $line)
    throw "COVENANT_COURIER_RECEIPTS_FAIL:PARSE_ERROR"
  }
}

Write-Host "COVENANT_COURIER_RECEIPTS_OK"
