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
      $prop = $Obj.PSObject.Properties[$name]
      if($null -eq $prop){ continue }
      $value = $prop.Value
      if($null -ne $value -and -not [string]::IsNullOrWhiteSpace([string]$value)){
        return [string]$value
      }
    }
  }
  return ""
}

function Get-DetailsObject {
  param([Parameter(Mandatory=$true)]$Obj)
  if($Obj.PSObject.Properties.Name -contains "details"){
    $detailsProp = $Obj.PSObject.Properties["details"]
    if($null -ne $detailsProp -and $null -ne $detailsProp.Value){ return $detailsProp.Value }
  }
  return $null
}

function Add-IfPresent {
  param(
    [Parameter(Mandatory=$true)][System.Collections.Generic.List[string]]$List,
    [Parameter(Mandatory=$true)][string]$Name,
    [AllowNull()][string]$Value
  )
  if(-not [string]::IsNullOrWhiteSpace($Value)){
    [void]$List.Add($Name + "=" + $Value)
  }
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
      $details = Get-DetailsObject -Obj $obj

      $schema = Get-FirstPropValue -Obj $obj -Names @("schema","receipt_schema","type")
      $time = Get-FirstPropValue -Obj $obj -Names @("time_utc","created_utc","timestamp_utc","utc","time")
      $eventType = Get-FirstPropValue -Obj $obj -Names @("event_type","eventType","event","kind","action","decision","status","result")

      $frame = Get-FirstPropValue -Obj $obj -Names @("frame_id","frameId","frame","packet_id","packetId","id")
      $decision = Get-FirstPropValue -Obj $obj -Names @("decision","action","status","result","event","kind")
      $reason = Get-FirstPropValue -Obj $obj -Names @("reason","reason_code","message","detail","error","error_code")
      $pathValue = Get-FirstPropValue -Obj $obj -Names @("path","frame_path","dest","destination","output_path")
      $hashValue = Get-FirstPropValue -Obj $obj -Names @("payload_sha256","sha256","hash","packet_sha256","frame_sha256")

      if($null -ne $details){
        if([string]::IsNullOrWhiteSpace($frame)){
          $frame = Get-FirstPropValue -Obj $details -Names @("frame_id","frameId","frame","packet_id","packetId","id")
        }
        if([string]::IsNullOrWhiteSpace($decision)){
          $decision = Get-FirstPropValue -Obj $details -Names @("decision","action","status","result","event","kind")
        }
        if([string]::IsNullOrWhiteSpace($reason)){
          $reason = Get-FirstPropValue -Obj $details -Names @("reason","reason_code","message","detail","error","error_code")
        }
        if([string]::IsNullOrWhiteSpace($hashValue)){
          $hashValue = Get-FirstPropValue -Obj $details -Names @("payload_sha256","sha256","hash","packet_sha256","frame_sha256")
        }
        if([string]::IsNullOrWhiteSpace($pathValue)){
          $pathValue = Get-FirstPropValue -Obj $details -Names @("accepted_root","rejected_root","frame_root","drop_root","path","frame_path","dest","destination","output_path")
        }
      }

      if(-not [string]::IsNullOrWhiteSpace($eventType)){
        $decision = $eventType
      }

      $summary = New-Object System.Collections.Generic.List[string]
      Add-IfPresent -List $summary -Name "schema" -Value $schema
      Add-IfPresent -List $summary -Name "time" -Value $time
      Add-IfPresent -List $summary -Name "frame" -Value $frame
      Add-IfPresent -List $summary -Name "decision" -Value $decision
      Add-IfPresent -List $summary -Name "reason" -Value $reason
      Add-IfPresent -List $summary -Name "hash" -Value $hashValue
      Add-IfPresent -List $summary -Name "path" -Value $pathValue

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
