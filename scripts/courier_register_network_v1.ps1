param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$NetworkId,
  [Parameter(Mandatory=$true)][string]$NetworkName,
  [Parameter(Mandatory=$true)][string]$TransportKind,
  [Parameter(Mandatory=$true)][int]$ListenerPort,
  [string]$BindingMode = "dedicated",
  [string]$Visibility = "private",
  [string]$Status = "active",
  [string]$AllowedNodesCsv = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

$RegRoot = Join-Path $RepoRoot "registry\networks"
Ensure-Dir $RegRoot

if([string]::IsNullOrWhiteSpace($NetworkId)){ throw "COURIER_NETWORK_FAIL:MISSING_NETWORK_ID" }
if([string]::IsNullOrWhiteSpace($NetworkName)){ throw "COURIER_NETWORK_FAIL:MISSING_NETWORK_NAME" }
if([string]::IsNullOrWhiteSpace($TransportKind)){ throw "COURIER_NETWORK_FAIL:MISSING_TRANSPORT_KIND" }
if($ListenerPort -le 0){ throw "COURIER_NETWORK_FAIL:INVALID_LISTENER_PORT" }

$allowedNodes = @()
if(-not [string]::IsNullOrWhiteSpace($AllowedNodesCsv)){
  $allowedNodes = @($AllowedNodesCsv.Split(",") | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

$Path = Join-Path $RegRoot ($NetworkId + ".json")

$obj = [ordered]@{
  schema = "courier.network_registry.v1"
  network_id = $NetworkId
  network_name = $NetworkName
  transport_kind = $TransportKind
  listener_port = $ListenerPort
  binding_mode = $BindingMode
  visibility = $Visibility
  status = $Status
  allowed_nodes = @($allowedNodes)
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
}

$enc = New-Object System.Text.UTF8Encoding($false)
$json = $obj | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText($Path, ($json + "`n"), $enc)

Write-Host ("COURIER_REGISTER_NETWORK_OK: " + $Path)
