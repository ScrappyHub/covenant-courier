param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$NodeId,
  [Parameter(Mandatory=$true)][string]$NodeName,
  [Parameter(Mandatory=$true)][string]$NodeRole,
  [Parameter(Mandatory=$true)][string]$Principal,
  [string[]]$AllowedNamespaces = @("courier/message"),
  [string[]]$Tags = @()
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

$RegRoot = Join-Path $RepoRoot "registry\nodes"
Ensure-Dir $RegRoot

if([string]::IsNullOrWhiteSpace($NodeId)){ throw "COURIER_NODE_FAIL:MISSING_NODE_ID" }
if([string]::IsNullOrWhiteSpace($NodeName)){ throw "COURIER_NODE_FAIL:MISSING_NODE_NAME" }
if([string]::IsNullOrWhiteSpace($NodeRole)){ throw "COURIER_NODE_FAIL:MISSING_NODE_ROLE" }
if([string]::IsNullOrWhiteSpace($Principal)){ throw "COURIER_NODE_FAIL:MISSING_PRINCIPAL" }

$Path = Join-Path $RegRoot ($NodeId + ".json")

$obj = [ordered]@{
  schema = "courier.node_registry.v1"
  node_id = $NodeId
  node_name = $NodeName
  node_role = $NodeRole
  principal = $Principal
  status = "active"
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
  last_seen_utc = $null
  allowed_namespaces = @($AllowedNamespaces)
  tags = @($Tags)
}

$enc = New-Object System.Text.UTF8Encoding($false)
$json = $obj | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText($Path, ($json + "`n"), $enc)

Write-Host ("COURIER_REGISTER_NODE_OK: " + $Path)
