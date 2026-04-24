param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$SessionId,
  [Parameter(Mandatory=$true)][string]$MessageId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir($p){
  if(-not (Test-Path $p)){ [void][System.IO.Directory]::CreateDirectory($p) }
}

$LedgerRoot = Join-Path $RepoRoot "proofs\replay_ledger"
Ensure-Dir $LedgerRoot

$LedgerPath = Join-Path $LedgerRoot ($SessionId + ".ndjson")

if(Test-Path $LedgerPath){
  $existing = Get-Content $LedgerPath | ConvertFrom-Json
  foreach($e in $existing){
    if($e.message_id -eq $MessageId){
      throw "VTP_REPLAY_DETECTED"
    }
  }
}

$entry = [ordered]@{
  message_id = $MessageId
  seen_utc = (Get-Date).ToUniversalTime().ToString("o")
}

Add-Content -LiteralPath $LedgerPath -Value ($entry | ConvertTo-Json -Compress)

Write-Host "VTP_REPLAY_OK"