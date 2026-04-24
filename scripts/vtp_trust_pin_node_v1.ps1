param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$InviteRoot,
  [Parameter(Mandatory=$true)][string]$ExpectedFingerprintSha256
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Code){ throw $Code }
function Ensure-Dir([string]$Path){ if(-not (Test-Path -LiteralPath $Path)){ [void][System.IO.Directory]::CreateDirectory($Path) } }
function Write-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir){ Ensure-Dir $dir }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}
function Append-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir){ Ensure-Dir $dir }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  $fs = [System.IO.File]::Open($Path,[System.IO.FileMode]::Append,[System.IO.FileAccess]::Write,[System.IO.FileShare]::Read)
  try { $b=$enc.GetBytes($t); $fs.Write($b,0,$b.Length); $fs.Flush() } finally { $fs.Dispose() }
}

$invitePath = Join-Path $InviteRoot "vtp_identity_invite.json"
if(-not (Test-Path -LiteralPath $invitePath -PathType Leaf)){ Fail "VTP_TRUST_PIN_FAIL:MISSING_INVITE" }

$invite = Get-Content -LiteralPath $invitePath -Raw | ConvertFrom-Json
$actual = [string]$invite.public_key_sha256
if($actual -ne $ExpectedFingerprintSha256){
  Fail ("VTP_TRUST_PIN_FAIL:FINGERPRINT_MISMATCH:EXPECTED=" + $ExpectedFingerprintSha256 + ":ACTUAL=" + $actual)
}

$trustRoot = Join-Path $RepoRoot "proofs\trust"
Ensure-Dir $trustRoot

$allowed = Join-Path $trustRoot "allowed_signers"
$line = ([string]$invite.principal) + " " + ([string]$invite.public_key)
Append-Utf8NoBomLf $allowed $line

$receiptRoot = Join-Path $RepoRoot "proofs\receipts"
Ensure-Dir $receiptRoot
$receipt = [ordered]@{
  schema = "vtp.trust_pin.receipt.v1"
  event_type = "vtp.trust.pin_node.v1"
  timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
  details = [ordered]@{
    node_id = [string]$invite.node_id
    principal = [string]$invite.principal
    public_key_sha256 = $actual
    allowed_signers = $allowed
  }
}
Append-Utf8NoBomLf (Join-Path $receiptRoot "vtp_trust.ndjson") (($receipt | ConvertTo-Json -Depth 20 -Compress))

Write-Host ("VTP_TRUST_PINNED_NODE: " + [string]$invite.node_id)
Write-Host ("VTP_TRUST_PINNED_PRINCIPAL: " + [string]$invite.principal)
Write-Host "VTP_TRUST_PIN_NODE_OK"
