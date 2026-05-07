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

function Get-PropValue {
  param(
    [AllowNull()]$Obj,
    [Parameter(Mandatory=$true)][string]$Name
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

function Get-FirstValue {
  param(
    [AllowNull()]$Obj,
    [Parameter(Mandatory=$true)][string[]]$Names
  )
  foreach($name in $Names){
    $v = Get-PropValue -Obj $Obj -Name $name
    if(-not [string]::IsNullOrWhiteSpace($v)){ return $v }
  }
  return ""
}

function Get-Details {
  param([AllowNull()]$Obj)
  if($null -eq $Obj){ return $null }
  foreach($p in @($Obj.PSObject.Properties)){
    if($p.Name -eq "details"){ return $p.Value }
  }
  return $null
}

function Add-Part {
  param(
    [Parameter(Mandatory=$true)][System.Collections.Generic.List[string]]$Parts,
    [Parameter(Mandatory=$true)][string]$Name,
    [AllowNull()][string]$Value
  )
  if(-not [string]::IsNullOrWhiteSpace($Value)){
    [void]$Parts.Add($Name + "=" + $Value)
  }
}

function Format-ReceiptLine {
  param([Parameter(Mandatory=$true)][string]$Line)

  $obj = $Line | ConvertFrom-Json
  $details = Get-Details -Obj $obj

  $schema = Get-FirstValue -Obj $obj -Names @("schema","receipt_schema","type")
  $time = Get-FirstValue -Obj $obj -Names @("time_utc","created_utc","timestamp_utc","utc","time")
  $eventType = Get-FirstValue -Obj $obj -Names @("event_type","eventType","event","kind","action","decision","status","result")

  $frame = Get-FirstValue -Obj $obj -Names @("frame_id","frameId","frame","packet_id","packetId","id")
  $decision = Get-FirstValue -Obj $obj -Names @("decision","action","status","result","event","kind")
  $reason = Get-FirstValue -Obj $obj -Names @("reason","reason_code","message","detail","error","error_code")
  $hashValue = Get-FirstValue -Obj $obj -Names @("payload_sha256","sha256","hash","packet_sha256","frame_sha256")
  $pathValue = Get-FirstValue -Obj $obj -Names @("path","frame_path","dest","destination","output_path")

  if($null -ne $details){
    if([string]::IsNullOrWhiteSpace($frame)){
      $frame = Get-FirstValue -Obj $details -Names @("frame_id","frameId","frame","packet_id","packetId","id")
    }
    if([string]::IsNullOrWhiteSpace($decision)){
      $decision = Get-FirstValue -Obj $details -Names @("decision","action","status","result","event","kind")
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

  if(-not [string]::IsNullOrWhiteSpace($eventType)){
    $decision = $eventType
  }

  $parts = New-Object System.Collections.Generic.List[string]
  Add-Part -Parts $parts -Name "schema" -Value $schema
  Add-Part -Parts $parts -Name "time" -Value $time
  Add-Part -Parts $parts -Name "frame" -Value $frame
  Add-Part -Parts $parts -Name "decision" -Value $decision
  Add-Part -Parts $parts -Name "reason" -Value $reason
  Add-Part -Parts $parts -Name "hash" -Value $hashValue
  Add-Part -Parts $parts -Name "path" -Value $pathValue

  if($parts.Count -gt 0){
    return (($parts.ToArray()) -join " ")
  }

  return ("json=" + ($obj | ConvertTo-Json -Depth 20 -Compress))
}

function Show-LatestReceiptLines {
  param(
    [Parameter(Mandatory=$true)][string]$Label,
    [Parameter(Mandatory=$true)][string]$Path,
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
