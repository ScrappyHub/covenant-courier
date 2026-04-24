Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

function Write-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir){ Ensure-Dir $dir }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

function Append-CourierReceipt {
  param(
    [Parameter(Mandatory=$true)][string]$RepoRoot,
    [Parameter(Mandatory=$true)][hashtable]$Receipt
  )

  $proofRoot = Join-Path $RepoRoot "proofs\receipts"
  Ensure-Dir $proofRoot

  $path = Join-Path $proofRoot "courier_transport.ndjson"
  $json = ($Receipt | ConvertTo-Json -Depth 50 -Compress)
  $line = $json + "`n"

  $enc = New-Object System.Text.UTF8Encoding($false)
  $fs = [System.IO.File]::Open($path, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::Read)
  try {
    $bytes = $enc.GetBytes($line)
    $fs.Write($bytes, 0, $bytes.Length)
    $fs.Flush()
  }
  finally {
    $fs.Dispose()
  }

  return $path
}
