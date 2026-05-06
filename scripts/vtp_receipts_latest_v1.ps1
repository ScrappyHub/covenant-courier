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

function Get-FirstPropValue {
  param(
    [Parameter(Mandatory=$true)]$Obj,
    [Parameter(Mandatory=$true)][string[]]$Names
  )
  foreach($name in $Names){
    if($Obj.PSObject.Properties.Name -contains $name){
      $value = $Obj.$name
      if($null -ne $value -and -not [string]::IsNullOrWhiteSpace([string]$value)){
        return [string]$value
      }
    }
  }
  return ""
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
      $obj = $line | ConvertFrom-Json

      $schema = Get-FirstPropValue -Obj $obj -Names @("schema","receipt_schema","type")
      $time = Get-FirstPropValue -Obj $obj -Names @("time_utc","created_utc","timestamp_utc","utc","time")
      $frame = Get-FirstPropValue -Obj $obj -Names @("frame_id","frameId","frame","packet_id","packetId","id")
      $decision = Get-FirstPropValue -Obj $obj -Names @("decision","action","status","result","event","kind")
      $reason = Get-FirstPropValue -Obj $obj -Names @("reason","reason_code","message","detail","error","error_code")
      $pathValue = Get-FirstPropValue -Obj $obj -Names @("path","frame_path","dest","destination","output_path")
      $hashValue = Get-FirstPropValue -Obj $obj -Names @("payload_sha256","sha256","hash","packet_sha256","frame_sha256")

      $summary = New-Object System.Collections.Generic.List[string]
      if(-not [string]::IsNullOrWhiteSpace($schema)){ [void]$summary.Add("schema=" + $schema) }
      if(-not [string]::IsNullOrWhiteSpace($time)){ [void]$summary.Add("time=" + $time) }
      if(-not [string]::IsNullOrWhiteSpace($frame)){ [void]$summary.Add("frame=" + $frame) }
      if(-not [string]::IsNullOrWhiteSpace($decision)){ [void]$summary.Add("decision=" + $decision) }
      if(-not [string]::IsNullOrWhiteSpace($reason)){ [void]$summary.Add("reason=" + $reason) }
      if(-not [string]::IsNullOrWhiteSpace($hashValue)){ [void]$summary.Add("hash=" + $hashValue) }
      if(-not [string]::IsNullOrWhiteSpace($pathValue)){ [void]$summary.Add("path=" + $pathValue) }

      if($summary.Count -gt 2){
        Write-Host (($summary.ToArray()) -join " ")
      } else {
        $compact = $obj | ConvertTo-Json -Depth 20 -Compress
        Write-Host ("json=" + $compact)
      }
    } catch {
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
