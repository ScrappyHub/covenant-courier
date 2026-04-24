param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Enc = Join-Path $PSScriptRoot "vtp_encrypt_payload_v1.ps1"
$Dec = Join-Path $PSScriptRoot "vtp_decrypt_payload_v1.ps1"

function Fail([string]$Code){ throw $Code }

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){ [void][System.IO.Directory]::CreateDirectory($Path) }
}

function Write-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir){ Ensure-Dir $dir }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

function Reset-Dir([string]$Path){
  if(Test-Path -LiteralPath $Path){ Remove-Item -LiteralPath $Path -Recurse -Force }
  [void][System.IO.Directory]::CreateDirectory($Path)
}

function Run-ExpectFail([string]$Name,[scriptblock]$Block,[string]$ExpectedToken){
  Write-Host ("RUN_CRYPTO_NEGATIVE: " + $Name)
  $failed = $false
  $actual = ""
  try {
    & $Block
  }
  catch {
    $failed = $true
    $actual = $_.ToString()
  }

  if(-not $failed){
    Fail ("VTP_CRYPTO_NEGATIVE_FAIL:" + $Name + ":DID_NOT_FAIL")
  }

  if($actual -notmatch [regex]::Escape($ExpectedToken)){
    Fail ("VTP_CRYPTO_NEGATIVE_FAIL:" + $Name + ":EXPECTED_TOKEN_MISSING:" + $ExpectedToken + ":ACTUAL:" + $actual)
  }

  Write-Host ("CRYPTO_NEGATIVE_OK: " + $Name + " -> " + $ExpectedToken)
}

$Root = Join-Path $RepoRoot "test_vectors\vtp_secure_crypto_negatives"
Reset-Dir $Root

$JoinCode = "crypto-negative-join-code"
$WrongJoinCode = "wrong-join-code"
$Context = "node-alpha|node-beta|session-crypto-negative-001"
$Plain = Join-Path $Root "plain.txt"
$Encrypted = Join-Path $Root "encrypted_payload.json"
$Decrypted = Join-Path $Root "decrypted.txt"

Write-Utf8NoBomLf $Plain "VTP crypto negative payload."

& $Enc -RepoRoot $RepoRoot -PlainPath $Plain -JoinCode $JoinCode -Context $Context -OutPath $Encrypted

Run-ExpectFail "wrong_join_code" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath $Encrypted -JoinCode $WrongJoinCode -OutPath $Decrypted
} "VTP_DECRYPT_FAIL:AUTH_TAG_OR_JOIN_CODE_INVALID"

Run-ExpectFail "missing_encrypted_payload" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath (Join-Path $Root "missing.json") -JoinCode $JoinCode -OutPath $Decrypted
} "VTP_DECRYPT_FAIL:MISSING_ENCRYPTED"

$tamperCipher = Join-Path $Root "tampered_cipher.json"
Copy-Item -LiteralPath $Encrypted -Destination $tamperCipher -Force
$obj = Get-Content -LiteralPath $tamperCipher -Raw | ConvertFrom-Json
$obj.ciphertext_b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes("tampered"))
Write-Utf8NoBomLf $tamperCipher (($obj | ConvertTo-Json -Depth 20 -Compress))

Run-ExpectFail "tampered_ciphertext" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath $tamperCipher -JoinCode $JoinCode -OutPath $Decrypted
} "VTP_DECRYPT_FAIL:AUTH_TAG_OR_JOIN_CODE_INVALID"

$tamperTag = Join-Path $Root "tampered_tag.json"
Copy-Item -LiteralPath $Encrypted -Destination $tamperTag -Force
$obj = Get-Content -LiteralPath $tamperTag -Raw | ConvertFrom-Json
$obj.tag_b64 = [Convert]::ToBase64String((1..32 | ForEach-Object { [byte]0 }))
Write-Utf8NoBomLf $tamperTag (($obj | ConvertTo-Json -Depth 20 -Compress))

Run-ExpectFail "tampered_tag" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath $tamperTag -JoinCode $JoinCode -OutPath $Decrypted
} "VTP_DECRYPT_FAIL:AUTH_TAG_OR_JOIN_CODE_INVALID"

$tamperContext = Join-Path $Root "tampered_context.json"
Copy-Item -LiteralPath $Encrypted -Destination $tamperContext -Force
$obj = Get-Content -LiteralPath $tamperContext -Raw | ConvertFrom-Json
$obj.context = "node-alpha|node-beta|tampered-context"
Write-Utf8NoBomLf $tamperContext (($obj | ConvertTo-Json -Depth 20 -Compress))

Run-ExpectFail "tampered_context" {
  & $Dec -RepoRoot $RepoRoot -EncryptedPath $tamperContext -JoinCode $JoinCode -OutPath $Decrypted
} "VTP_DECRYPT_FAIL:AUTH_TAG_OR_JOIN_CODE_INVALID"

Write-Host "VTP_SECURE_CRYPTO_NEGATIVE_SELFTEST_OK"
