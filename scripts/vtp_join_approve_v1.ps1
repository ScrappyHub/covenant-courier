param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$JoinRequestRoot,
  [Parameter(Mandatory=$true)][string]$JoinCode,
  [Parameter(Mandatory=$true)][string]$OutRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. "$PSScriptRoot\_lib_vtp_crypto_v1.ps1"

$reqPath = Join-Path $JoinRequestRoot "vtp_join_request.json"
if(-not (Test-Path -LiteralPath $reqPath -PathType Leaf)){ throw "VTP_JOIN_APPROVE_FAIL:MISSING_JOIN_REQUEST" }

$req = Get-Content -LiteralPath $reqPath -Raw | ConvertFrom-Json
$salt = [Convert]::FromBase64String([string]$req.salt_b64)
$key = Derive-KeyFromJoinCode $JoinCode $salt

$proofBytes = [System.Text.Encoding]::UTF8.GetBytes(([string]$req.from_node_id + "|" + [string]$req.to_node_id + "|" + [string]$req.challenge_sha256))
$hmac = [System.Security.Cryptography.HMACSHA256]::new($key)
try { $actual = (($hmac.ComputeHash($proofBytes) | ForEach-Object { $_.ToString("x2") }) -join "") } finally { $hmac.Dispose() }

if($actual -ne [string]$req.join_proof_hmac_sha256){
  throw "VTP_JOIN_APPROVE_FAIL:JOIN_CODE_PROOF_MISMATCH"
}

if(Test-Path -LiteralPath $OutRoot){ Remove-Item -LiteralPath $OutRoot -Recurse -Force }
Ensure-Dir $OutRoot

$approved = [ordered]@{
  schema = "vtp.join_approval.v1"
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
  from_node_id = [string]$req.from_node_id
  to_node_id = [string]$req.to_node_id
  challenge_sha256 = [string]$req.challenge_sha256
  approval_status = "approved"
}

Write-Utf8NoBomLf (Join-Path $OutRoot "vtp_join_approval.json") (($approved | ConvertTo-Json -Depth 20 -Compress))
Write-Host ("VTP_JOIN_APPROVAL_ROOT: " + $OutRoot)
Write-Host "VTP_JOIN_APPROVE_OK"
