Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_vtp_crypto_v1.ps1"

function Get-VtpSessionKeyMaterial(
  [string]$JoinCode,
  [string]$SessionId,
  [byte[]]$Salt
){
  if([string]::IsNullOrWhiteSpace($JoinCode)){ throw "VTP_SESSION_KEY_FAIL:MISSING_JOIN_CODE" }
  if([string]::IsNullOrWhiteSpace($SessionId)){ throw "VTP_SESSION_KEY_FAIL:MISSING_SESSION_ID" }

  $scopedSecret = "vtp.session.v1|" + $SessionId + "|" + $JoinCode
  return Derive-KeyFromJoinCode $scopedSecret $Salt
}
