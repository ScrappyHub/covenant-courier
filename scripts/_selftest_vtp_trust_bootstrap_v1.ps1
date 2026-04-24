param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Export = Join-Path $PSScriptRoot "vtp_identity_invite_export_v1.ps1"
$Import = Join-Path $PSScriptRoot "vtp_identity_invite_import_v1.ps1"
$Pin    = Join-Path $PSScriptRoot "vtp_trust_pin_node_v1.ps1"

$trustRoot = Join-Path $RepoRoot "proofs\trust"
$keyRoot = Join-Path $RepoRoot "proofs\keys\vtp_invite_selftest"
if(Test-Path -LiteralPath $keyRoot){ Remove-Item -LiteralPath $keyRoot -Recurse -Force }
[void][System.IO.Directory]::CreateDirectory($keyRoot)

$keyPath = Join-Path $keyRoot "selftest_ed25519"
$pubPath = $keyPath + ".pub"
$ssh = Join-Path $env:WINDIR "System32\OpenSSH\ssh-keygen.exe"
& $ssh -t ed25519 -N "" -f $keyPath -C "vtp-selftest@local" | Out-Null
if($LASTEXITCODE -ne 0){ throw "VTP_TRUST_BOOTSTRAP_SELFTEST_FAIL:KEYGEN" }

$inviteRoot = Join-Path $RepoRoot "test_vectors\vtp_trust_bootstrap\invite"
& $Export -RepoRoot $RepoRoot -NodeId "node-selftest" -Principal "vtp-selftest@local" -PublicKeyPath $pubPath -OutRoot $inviteRoot
if($LASTEXITCODE -ne 0){ throw "VTP_TRUST_BOOTSTRAP_SELFTEST_FAIL:EXPORT" }

& $Import -RepoRoot $RepoRoot -InviteRoot $inviteRoot
if($LASTEXITCODE -ne 0){ throw "VTP_TRUST_BOOTSTRAP_SELFTEST_FAIL:IMPORT" }

$invite = Get-Content -LiteralPath (Join-Path $inviteRoot "vtp_identity_invite.json") -Raw | ConvertFrom-Json
& $Pin -RepoRoot $RepoRoot -InviteRoot $inviteRoot -ExpectedFingerprintSha256 ([string]$invite.public_key_sha256)
if($LASTEXITCODE -ne 0){ throw "VTP_TRUST_BOOTSTRAP_SELFTEST_FAIL:PIN" }

Write-Host "VTP_TRUST_BOOTSTRAP_SELFTEST_OK"
