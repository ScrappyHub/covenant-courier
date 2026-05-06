param(
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta",
  [int]$Port = 47732,
  [int]$TimeoutMs = 10000
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$PolicyGate = Join-Path $RepoRoot "scripts\vtp_policy_gate_v1.ps1"
$Runtime = Join-Path $RepoRoot ("runtime\wire_ingest\nodes\" + $NodeId)
$Drop = Join-Path $Runtime "drop"
$Accepted = Join-Path $Runtime "accepted"
$Rejected = Join-Path $Runtime "rejected"
$Receipts = Join-Path $RepoRoot "proofs\receipts"
$ReceiptPath = Join-Path $Receipts "vtp_udp_wire_ingest.ndjson"
$enc = [Text.UTF8Encoding]::new($false)

foreach($dir in @($Runtime,$Drop,$Accepted,$Rejected,$Receipts)){
  if(-not (Test-Path -LiteralPath $dir)){ [void][IO.Directory]::CreateDirectory($dir) }
}
if(-not (Test-Path -LiteralPath $PolicyGate -PathType Leaf)){ throw "VTP_UDP_WIRE_INGEST_FAIL:MISSING_POLICY_GATE" }

function Sha256Hex([byte[]]$Bytes){
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    $hash = $sha.ComputeHash($Bytes)
    return ([BitConverter]::ToString($hash).Replace("-","").ToLowerInvariant())
  } finally {
    $sha.Dispose()
  }
}

function Derive-Key([string]$Purpose){
  $material = "vtp-wire-dev-key|session-alpha-beta-001|node-alpha|" + $NodeId + "|" + $Purpose
  $bytes = [Text.Encoding]::UTF8.GetBytes($material)
  $sha = [Security.Cryptography.SHA256]::Create()
  try {
    return $sha.ComputeHash($bytes)
  } finally {
    $sha.Dispose()
  }
}

function Write-Receipt([string]$FrameId,[string]$Decision,[string]$Reason,[string]$PathValue,[string]$PayloadSha256){
  $obj = [ordered]@{}
  $obj.schema = "vtp.udp_wire_ingest.receipt.v1"
  $obj.time_utc = (Get-Date).ToUniversalTime().ToString("o")
  $obj.node_id = $NodeId
  $obj.frame_id = $FrameId
  $obj.decision = $Decision
  $obj.reason = $Reason
  $obj.path = $PathValue
  $obj.payload_sha256 = $PayloadSha256
  $json = $obj | ConvertTo-Json -Depth 20 -Compress
  [IO.File]::AppendAllText($ReceiptPath, ($json + [string][char]10), $enc)
}

$udp = New-Object Net.Sockets.UdpClient($Port)
$udp.Client.ReceiveTimeout = $TimeoutMs
$remote = New-Object Net.IPEndPoint([Net.IPAddress]::Any,0)
try {
  $bytes = $udp.Receive([ref]$remote)
} finally {
  $udp.Close()
}

$json = [Text.Encoding]::UTF8.GetString($bytes)
$packet = $json | ConvertFrom-Json
if([string]$packet.header.magic -ne "VTP1"){ throw "VTP_UDP_WIRE_INGEST_FAIL:BAD_MAGIC" }

$headerJson = ($packet.header | ConvertTo-Json -Depth 20 -Compress)
$headerBytes = [Text.Encoding]::UTF8.GetBytes($headerJson)
$iv = [Convert]::FromBase64String([string]$packet.iv_b64)
$cipherBytes = [Convert]::FromBase64String([string]$packet.ciphertext_b64)
$tag = [Convert]::FromBase64String([string]$packet.tag_b64)
$macKey = Derive-Key "hmac"
$macInput = New-Object byte[] ($headerBytes.Length + $iv.Length + $cipherBytes.Length)
[Array]::Copy($headerBytes,0,$macInput,0,$headerBytes.Length)
[Array]::Copy($iv,0,$macInput,$headerBytes.Length,$iv.Length)
[Array]::Copy($cipherBytes,0,$macInput,$headerBytes.Length + $iv.Length,$cipherBytes.Length)
$hmac = New-Object Security.Cryptography.HMACSHA256(,$macKey)
try {
  $expectedTag = $hmac.ComputeHash($macInput)
} finally {
  $hmac.Dispose()
}
if((Sha256Hex $expectedTag) -ne (Sha256Hex $tag)){ throw "VTP_UDP_WIRE_INGEST_FAIL:BAD_AUTH_TAG" }

$aesKey = Derive-Key "aes"
$aes = [Security.Cryptography.Aes]::Create()
$aes.Mode = [Security.Cryptography.CipherMode]::CBC
$aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
$aes.KeySize = 256
$aes.Key = $aesKey
$aes.IV = $iv
$decryptor = $aes.CreateDecryptor()
try {
  $plainBytes = $decryptor.TransformFinalBlock($cipherBytes,0,$cipherBytes.Length)
} finally {
  $decryptor.Dispose()
  $aes.Dispose()
}

$plainHash = Sha256Hex $plainBytes
if($plainHash -ne [string]$packet.header.payload_sha256){ throw "VTP_UDP_WIRE_INGEST_FAIL:PAYLOAD_HASH_MISMATCH" }

$frameId = [string]$packet.header.frame_id
$FrameDir = Join-Path $Drop $frameId
if(Test-Path -LiteralPath $FrameDir){ Remove-Item -LiteralPath $FrameDir -Recurse -Force }
[void][IO.Directory]::CreateDirectory($FrameDir)
[void][IO.Directory]::CreateDirectory((Join-Path $FrameDir "payload"))

$frame = [ordered]@{}
$frame.schema = "courier.transport_frame.v2"
$frame.frame_id = $frameId
$frame.created_utc = (Get-Date).ToUniversalTime().ToString("o")
$frame.sender_identity = "wire@covenant"
$frame.recipient_identity = "courier-local@covenant"
$frame.sender_node_id = "node-alpha"
$frame.recipient_node_id = $NodeId
$frame.network_id = "courier-internal-net-v1"
$frame.session_id = "session-alpha-beta-001"
$frame.sender_role = "message-delivery"
$frame.message_rel = "payload/message.tokenized.json"
$frame.signature_rel = "payload/wire.verified"
$frame.payload_sha256 = $plainHash

[IO.File]::WriteAllText((Join-Path $FrameDir "frame.json"), (($frame | ConvertTo-Json -Depth 20 -Compress) + [string][char]10), $enc)
[IO.File]::WriteAllText((Join-Path $FrameDir "payload\message.tokenized.json"), ([Text.Encoding]::UTF8.GetString($plainBytes) + [string][char]10), $enc)
[IO.File]::WriteAllText((Join-Path $FrameDir "payload\wire.verified"), "wire-auth-ok" + [string][char]10, $enc)
[IO.File]::WriteAllText((Join-Path $FrameDir "wire_packet.json"), ($json + [string][char]10), $enc)

$policyOut = & powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $PolicyGate -RepoRoot $RepoRoot -FrameDir $FrameDir 2>&1
$policyText = ($policyOut | Out-String).Trim()
$policyCode = $LASTEXITCODE

if($policyCode -eq 42){
  $dest = Join-Path $Rejected $frameId
  if(Test-Path -LiteralPath $dest){ Remove-Item -LiteralPath $dest -Recurse -Force }
  Move-Item -LiteralPath $FrameDir -Destination $dest -ErrorAction Stop
  [IO.File]::WriteAllText((Join-Path $dest "reject_reason.txt"), ($policyText + [string][char]10), $enc)
  Write-Receipt $frameId "rejected" $policyText $dest $plainHash
  Write-Host ("VTP_UDP_WIRE_INGEST_REJECT_OK: " + $dest)
  exit 0
}

if($policyCode -ne 0){
  throw ("VTP_UDP_WIRE_INGEST_FAIL:POLICY_GATE_EXIT_" + $policyCode + ":" + $policyText)
}

$dest = Join-Path $Accepted $frameId
if(Test-Path -LiteralPath $dest){ Remove-Item -LiteralPath $dest -Recurse -Force }
Move-Item -LiteralPath $FrameDir -Destination $dest -ErrorAction Stop
Write-Receipt $frameId "accepted" "VTP_POLICY_ALLOW" $dest $plainHash
Write-Host ("VTP_UDP_WIRE_INGEST_ACCEPT_OK: " + $dest)
Write-Host ("VTP_UDP_WIRE_INGEST_RECEIPT_OK: " + $ReceiptPath)
