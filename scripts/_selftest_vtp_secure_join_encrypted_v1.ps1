param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$JoinReq = Join-Path $PSScriptRoot "vtp_join_request_v1.ps1"
$JoinApp = Join-Path $PSScriptRoot "vtp_join_approve_v1.ps1"
$Enc     = Join-Path $PSScriptRoot "vtp_encrypt_payload_v1.ps1"
$Dec     = Join-Path $PSScriptRoot "vtp_decrypt_payload_v1.ps1"
$Queue   = Join-Path $PSScriptRoot "vtp_store_forward_outbox_v1.ps1"

$Root = Join-Path $RepoRoot "test_vectors\vtp_secure_join_encrypted"
if(Test-Path -LiteralPath $Root){ Remove-Item -LiteralPath $Root -Recurse -Force }
[void][System.IO.Directory]::CreateDirectory($Root)

$JoinCode = "test-join-code-123456"
$ReqRoot = Join-Path $Root "join_request"
$AppRoot = Join-Path $Root "join_approval"
$Plain = Join-Path $Root "plain.txt"
$Encrypted = Join-Path $Root "encrypted_payload.json"
$Decrypted = Join-Path $Root "decrypted.txt"
$QueueRoot = Join-Path $Root "offline_queue"

$encUtf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Plain,"VTP secure encrypted local selftest payload.`n",$encUtf8)

& $JoinReq -RepoRoot $RepoRoot -FromNodeId "node-alpha" -ToNodeId "node-beta" -JoinCode $JoinCode -OutRoot $ReqRoot
& $JoinApp -RepoRoot $RepoRoot -JoinRequestRoot $ReqRoot -JoinCode $JoinCode -OutRoot $AppRoot
& $Enc -RepoRoot $RepoRoot -PlainPath $Plain -JoinCode $JoinCode -Context "node-alpha|node-beta|session-secure-local-001" -OutPath $Encrypted
& $Queue -RepoRoot $RepoRoot -EncryptedPath $Encrypted -QueueRoot $QueueRoot
& $Dec -RepoRoot $RepoRoot -EncryptedPath $Encrypted -JoinCode $JoinCode -OutPath $Decrypted

$plainText = Get-Content -LiteralPath $Plain -Raw
$decText = Get-Content -LiteralPath $Decrypted -Raw
if($plainText -ne $decText){ throw "VTP_SECURE_JOIN_SELFTEST_FAIL:DECRYPTED_MISMATCH" }

Write-Host "VTP_SECURE_JOIN_ENCRYPTED_SELFTEST_OK"
