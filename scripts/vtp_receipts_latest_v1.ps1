param(
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta",
  [int]$Tail = 5
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$ReceiptRoot = Join-Path $RepoRoot "proofs\receipts"
$TransportReceipt = Join-Path $ReceiptRoot "courier_transport.ndjson"
$WireIngestReceipt = Join-Path $ReceiptRoot "vtp_udp_wire_ingest.ndjson"

function Get-ValueByName {
  param(
    [AllowNull()]$Obj,
    [string]$Name
  )
  if($null -eq $Obj){ return "" }
  foreach($prop in @($Obj.PSObject.Properties)){
    if($prop.Name -eq $Name){
      if($null -eq $prop.Value){ return "" }
      return [string]$prop.Value
    }
  }
  return ""
}

function Get-FirstValue {
  param(
    [AllowNull()]$Obj,
    [string[]]$Names
  )
  foreach($name in @($Names)){
    $value = Get-ValueByName -Obj $Obj -Name $name
    if(-not [string]::IsNullOrWhiteSpace($value)){ return $value }
  }
  return ""
}

function Get-DetailsObject {
  param([AllowNull()]$Obj)
  if($null -eq $Obj){ return $null }
  foreach($prop in @($Obj.PSObject.Properties)){
    if($prop.Name -eq "details"){ return $prop.Value }
  }
  return $null
}

function Format-ReceiptLine {
  param([string]$Line)

  $obj = $Line | ConvertFrom-Json
  $details = Get-DetailsObject -Obj $obj

  $schema = Get-FirstValue -Obj $obj -Names @("schema","receipt_schema","type")
  $time = Get-FirstValue -Obj $obj -Names @("time_utc","created_utc","timestamp_utc","utc","time")
  $decision = Get-FirstValue -Obj $obj -Names @("event_type","eventType","decision","action","status","result","event","kind")
  $frame = Get-FirstValue -Obj $obj -Names @("frame_id","frameId","frame","packet_id","packetId","id")
  $reason = Get-FirstValue -Obj $obj -Names @("reason","reason_code","message","detail","error","error_code")
  $hashValue = Get-FirstValue -Obj $obj -Names @("payload_sha256","sha256","hash","packet_sha256","frame_sha256")
  $pathValue = Get-FirstValue -Obj $obj -Names @("path","frame_path","dest","destination","output_path")

  if($null -ne $details){
    if([string]::IsNullOrWhiteSpace($frame)){
      $frame = Get-FirstValue -Obj $details -Names @("frame_id","frameId","frame","packet_id","packetId","id")
    }
    if([string]::IsNullOrWhiteSpace($reason)){
      $reason = Get-FirstValue -Obj $details -Names @("reason","reason_code","message","detail","error","error_code")
    }
    if([string]::IsNullOrWhiteSpace($hashValue)){
      $hashValue = Get-FirstValue -Obj $details -Names @("payload_sha256","sha256","hash","packet_sha256","frame_sha256")
    }
    if([string]::IsNullOrWhiteSpace($pathValue)){
      $pathValue = Get-FirstValue -Obj $details -Names @("accepted_root","rejected_root","frame_root","drop_root","path","frame_path","dest","destination","output_path")
    }
  }

  $parts = New-Object System.Collections.Generic.List[string]
  if(-not [string]::IsNullOrWhiteSpace($schema)){ [void]$parts.Add("schema=" + $schema) }
  if(-not [string]::IsNullOrWhiteSpace($time)){ [void]$parts.Add("time=" + $time) }
  if(-not [string]::IsNullOrWhiteSpace($frame)){ [void]$parts.Add("frame=" + $frame) }
  if(-not [string]::IsNullOrWhiteSpace($decision)){ [void]$parts.Add("decision=" + $decision) }
  if(-not [string]::IsNullOrWhiteSpace($reason)){ [void]$parts.Add("reason=" + $reason) }
  if(-not [string]::IsNullOrWhiteSpace($hashValue)){ [void]$parts.Add("hash=" + $hashValue) }
  if(-not [string]::IsNullOrWhiteSpace($pathValue)){ [void]$parts.Add("path=" + $pathValue) }

  if($parts.Count -gt 0){ return (($parts.ToArray()) -join " ") }
  return ("json=" + ($obj | ConvertTo-Json -Depth 20 -Compress))
}

function Show-LatestReceiptLines {
  param(
    [string]$Label,
    [string]$Path,
    [int]$Tail = 5
  )

  Write-Host ("== " + $Label + " ==")
  Write-Host ("Path: " + $Path)

  if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){
    Write-Host "Status: missing"
    return
  }

  $lines = @(Get-Content -LiteralPath $Path -Tail $Tail -ErrorAction Stop)
  if($lines.Count -eq 0){
    Write-Host "Status: empty"
    return
  }

  foreach($line in $lines){
    if([string]::IsNullOrWhiteSpace($line)){ continue }
    try {
      Write-Host (Format-ReceiptLine -Line $line)
    } catch {
      Write-Host ("parse_error=" + $_.Exception.Message)
      Write-Host ("raw=" + $line)
    }
  }
}

Write-Host "VTP RECEIPTS LATEST"
Write-Host ("Repo: " + $RepoRoot)
Write-Host ("Node: " + $NodeId)
Write-Host ("Tail: " + $Tail)

Show-LatestReceiptLines -Label "transport" -Path $TransportReceipt -Tail $Tail
Show-LatestReceiptLines -Label "udp-wire-ingest" -Path $WireIngestReceipt -Tail $Tail

Write-Host "VTP_RECEIPTS_LATEST_OK"
