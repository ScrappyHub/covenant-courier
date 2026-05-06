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
      $schema = ""
      $time = ""
      $frame = ""
      $decision = ""
      $reason = ""

      if($obj.PSObject.Properties.Name -contains "schema"){ $schema = [string]$obj.schema }
      if($obj.PSObject.Properties.Name -contains "time_utc"){ $time = [string]$obj.time_utc }
      elseif($obj.PSObject.Properties.Name -contains "created_utc"){ $time = [string]$obj.created_utc }
      elseif($obj.PSObject.Properties.Name -contains "timestamp_utc"){ $time = [string]$obj.timestamp_utc }
      if($obj.PSObject.Properties.Name -contains "frame_id"){ $frame = [string]$obj.frame_id }
      elseif($obj.PSObject.Properties.Name -contains "frameId"){ $frame = [string]$obj.frameId }
      if($obj.PSObject.Properties.Name -contains "decision"){ $decision = [string]$obj.decision }
      elseif($obj.PSObject.Properties.Name -contains "action"){ $decision = [string]$obj.action }
      elseif($obj.PSObject.Properties.Name -contains "status"){ $decision = [string]$obj.status }
      if($obj.PSObject.Properties.Name -contains "reason"){ $reason = [string]$obj.reason }
      elseif($obj.PSObject.Properties.Name -contains "result"){ $reason = [string]$obj.result }

      Write-Host ("schema=" + $schema + " time=" + $time + " frame=" + $frame + " decision=" + $decision + " reason=" + $reason)
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
