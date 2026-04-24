param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$FromNodeId,
  [Parameter(Mandatory=$true)][string]$ToNodeId,
  [Parameter(Mandatory=$true)][string]$JoinCode,
  [Parameter(Mandatory=$true)][string]$OutRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_lib_vtp_crypto_v1.ps1"

if(Test-Path -LiteralPath $OutRoot){ Remove-Item -LiteralPath $OutRoot -Recurse -Force }
Ensure-Dir $OutRoot

$salt = New-RandomBytes 16
$key = Derive-KeyFromJoinCode $JoinCode $salt
$challenge = New-RandomBytes 32
$challengeHash = Get-Sha256HexBytes $challenge
$proofBytes = [System.Text.Encoding]::UTF8.GetBytes(($FromNodeId + "|" + $ToNodeId + "|" + $challengeHash))
$hmac = [System.Security.Cryptography.HMACSHA256]::new($key)
try { $proof = (($hmac.ComputeHash($proofBytes) | ForEach-Object { $_.ToString("x2") }) -join "") } finally { $hmac.Dispose() }

$obj = [ordered]@{
  schema = "vtp.join_request.v1"
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
  from_node_id = $FromNodeId
  to_node_id = $ToNodeId
  salt_b64 = [Convert]::ToBase64String($salt)
  challenge_b64 = [Convert]::ToBase64String($challenge)
  challenge_sha256 = $challengeHash
  join_proof_hmac_sha256 = $proof
  note = "Join code is never stored. Receiver verifies HMAC with out-of-band join code."
}

Write-Utf8NoBomLf (Join-Path $OutRoot "vtp_join_request.json") (($obj | ConvertTo-Json -Depth 20 -Compress))
Write-Host ("VTP_JOIN_REQUEST_ROOT: " + $OutRoot)
Write-Host "VTP_JOIN_REQUEST_OK"
