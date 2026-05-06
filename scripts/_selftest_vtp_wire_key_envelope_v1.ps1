param(
  [string]$RepoRoot = ".",
  [string]$To = "node-beta"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Lib = Join-Path $RepoRoot "scripts\vtp_wire_key_envelope_v1.ps1"
. $Lib

$path = Ensure-VtpWireKeyEnvelope -RepoRoot $RepoRoot -RecipientNodeId $To
if(-not (Test-Path -LiteralPath $path -PathType Leaf)){ throw "VTP_WIRE_KEY_ENVELOPE_SELFTEST_FAIL:MISSING_ENVELOPE" }
$envObj = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
if([string]$envObj.schema -ne "vtp.wire_key_envelope.v1"){ throw "VTP_WIRE_KEY_ENVELOPE_SELFTEST_FAIL:BAD_SCHEMA" }
$aes = Get-VtpWireKeyBytes -RepoRoot $RepoRoot -RecipientNodeId $To -Purpose "aes"
$mac = Get-VtpWireKeyBytes -RepoRoot $RepoRoot -RecipientNodeId $To -Purpose "hmac"
if($aes.Length -ne 32){ throw "VTP_WIRE_KEY_ENVELOPE_SELFTEST_FAIL:AES_LEN" }
if($mac.Length -ne 32){ throw "VTP_WIRE_KEY_ENVELOPE_SELFTEST_FAIL:HMAC_LEN" }

Write-Host ("VTP_WIRE_KEY_ENVELOPE_PATH: " + $path)
Write-Host "VTP_WIRE_KEY_ENVELOPE_SELFTEST_OK"
