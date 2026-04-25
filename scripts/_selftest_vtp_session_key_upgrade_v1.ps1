param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Enc = Join-Path $PSScriptRoot "vtp_encrypt_session_payload_v1.ps1"
$Dec = Join-Path $PSScriptRoot "vtp_decrypt_session_payload_v1.ps1"

function Reset-Dir([string]$Path){
  if(Test-Path -LiteralPath $Path){ Remove-Item -LiteralPath $Path -Recurse -Force }
  [void][System.IO.Directory]::CreateDirectory($Path)
}

function Write-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir -and -not (Test-Path -LiteralPath $dir)){ [void][System.IO.Directory]::CreateDirectory($dir) }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

function Expect-Fail([string]$Name,[scriptblock]$Block,[string]$Expected){
  $failed = $false
  $actual = ""
  try { & $Block }
  catch {
    $failed = $true
    $actual = $_.ToString()
  }

  if(-not $failed){ throw ("VTP_SESSION_KEY_SELFTEST_FAIL:" + $Name + ":DID_NOT_FAIL") }
  if($actual -notmatch [regex]::Escape($Expected)){
    throw ("VTP_SESSION_KEY_SELFTEST_FAIL:" + $Name + ":EXPECTED=" + $Expected + ":ACTUAL=" + $actual)
  }

  Write-Host ("SESSION_KEY_NEGATIVE_OK: " + $Name)
}

$Root = Join-Path $RepoRoot "test_vectors\vtp_session_key_upgrade"
Reset-Dir $Root

$JoinCode = "session-key-upgrade-join-code"
$SessionId = "session-key-upgrade-001"
$WrongSessionId = "session-key-upgrade-wrong"
$WrongJoinCode = "wrong-session-join-code"

$Plain = Join-Path $Root "plain.txt"
$Encrypted = Join-Path $Root "session_encrypted_payload.json"
$Decrypted = Join-Path $Root "decrypted.txt"

Write-Utf8NoBomLf $Plain "VTP session key upgrade payload."

& $Enc `
  -RepoRoot $RepoRoot `
  -PlainPath $Plain `
  -JoinCode $JoinCode `
  -SessionId $SessionId `
  -FromNodeId "node-alpha" `
  -ToNodeId "node-beta" `
  -OutPath $Encrypted

& $Dec `
  -RepoRoot $RepoRoot `
  -EncryptedPath $Encrypted `
  -JoinCode $JoinCode `
  -SessionId $SessionId `
  -OutPath $Decrypted

$p1 = Get-Content -LiteralPath $Plain -Raw
$p2 = Get-Content -LiteralPath $Decrypted -Raw
if($p1 -ne $p2){ throw "VTP_SESSION_KEY_SELFTEST_FAIL:ROUNDTRIP_MISMATCH" }

Expect-Fail "wrong_join_code" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath $Encrypted -JoinCode $WrongJoinCode -SessionId $SessionId -OutPath (Join-Path $Root "wrong_join.txt")
} "VTP_SESSION_DECRYPT_FAIL:AUTH_TAG_OR_SESSION_KEY_INVALID"

Expect-Fail "wrong_session_id" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath $Encrypted -JoinCode $JoinCode -SessionId $WrongSessionId -OutPath (Join-Path $Root "wrong_session.txt")
} "VTP_SESSION_DECRYPT_FAIL:SESSION_ID_MISMATCH"

$tampered = Join-Path $Root "tampered_session.json"
Copy-Item -LiteralPath $Encrypted -Destination $tampered -Force
$obj = Get-Content -LiteralPath $tampered -Raw | ConvertFrom-Json
$obj.aad = "vtp.session.payload.v1|tampered|node-alpha|node-beta"
Write-Utf8NoBomLf $tampered (($obj | ConvertTo-Json -Depth 20 -Compress))

Expect-Fail "tampered_aad" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath $tampered -JoinCode $JoinCode -SessionId $SessionId -OutPath (Join-Path $Root "tampered.txt")
} "VTP_SESSION_DECRYPT_FAIL:AUTH_TAG_OR_SESSION_KEY_INVALID"

Write-Host "VTP_SESSION_KEY_UPGRADE_SELFTEST_OK"
