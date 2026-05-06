param(
  [string]$RepoRoot = ".",
  [string]$To = "node-beta",
  [string]$HostName = "127.0.0.1",
  [int]$Port = 47731,
  [string]$PlainText = "hello from VTP UDP wire adapter"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "vtp_wire_key_envelope_v1.ps1")

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Runtime = Join-Path $RepoRoot "runtime\wire_udp"
if(-not (Test-Path -LiteralPath $Runtime)){ [void][IO.Directory]::CreateDirectory($Runtime) }
$enc = [Text.UTF8Encoding]::new($false)

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
  return Get-VtpWireKeyBytes -RepoRoot $RepoRoot -RecipientNodeId $To -Purpose $Purpose
}

function B64([byte[]]$Bytes){
  return [Convert]::ToBase64String($Bytes)
}

$frameId = "frame-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ")
$plainBytes = [Text.Encoding]::UTF8.GetBytes($PlainText)
$payloadHash = Sha256Hex $plainBytes

$header = [ordered]@{}
$header.magic = "VTP1"
$header.version = 1
$header.frame_id = $frameId
$header.session_id_hash = Sha256Hex ([Text.Encoding]::UTF8.GetBytes("session-alpha-beta-001"))
$header.sender_node_id_hash = Sha256Hex ([Text.Encoding]::UTF8.GetBytes("node-alpha"))
$header.recipient_node_id_hash = Sha256Hex ([Text.Encoding]::UTF8.GetBytes($To))
$header.network_id_hash = Sha256Hex ([Text.Encoding]::UTF8.GetBytes("courier-internal-net-v1"))
$header.payload_sha256 = $payloadHash
$header.cipher_suite = "AES-CBC-256-HMAC-SHA256-DEV"
$header.policy_mode = "enforce"

$headerJson = ($header | ConvertTo-Json -Depth 20 -Compress)
$headerBytes = [Text.Encoding]::UTF8.GetBytes($headerJson)

$aesKey = Derive-Key "aes"
$macKey = Derive-Key "hmac"
$aes = [Security.Cryptography.Aes]::Create()
$aes.Mode = [Security.Cryptography.CipherMode]::CBC
$aes.Padding = [Security.Cryptography.PaddingMode]::PKCS7
$aes.KeySize = 256
$aes.Key = $aesKey
$aes.GenerateIV()
$iv = $aes.IV
$encryptor = $aes.CreateEncryptor()
try {
  $cipherBytes = $encryptor.TransformFinalBlock($plainBytes,0,$plainBytes.Length)
} finally {
  $encryptor.Dispose()
  $aes.Dispose()
}

$macInput = New-Object byte[] ($headerBytes.Length + $iv.Length + $cipherBytes.Length)
[Array]::Copy($headerBytes,0,$macInput,0,$headerBytes.Length)
[Array]::Copy($iv,0,$macInput,$headerBytes.Length,$iv.Length)
[Array]::Copy($cipherBytes,0,$macInput,$headerBytes.Length + $iv.Length,$cipherBytes.Length)
$hmac = New-Object Security.Cryptography.HMACSHA256(,$macKey)
try {
  $tag = $hmac.ComputeHash($macInput)
} finally {
  $hmac.Dispose()
}

$packet = [ordered]@{}
$packet.header = $header
$packet.iv_b64 = B64 $iv
$packet.ciphertext_b64 = B64 $cipherBytes
$packet.tag_b64 = B64 $tag
$packetJson = ($packet | ConvertTo-Json -Depth 20 -Compress)
$packetBytes = [Text.Encoding]::UTF8.GetBytes($packetJson)

$outPath = Join-Path $Runtime ($frameId + ".packet.json")
[IO.File]::WriteAllText($outPath, ($packetJson + [string][char]10), $enc)

$udp = New-Object Net.Sockets.UdpClient
try {
  [void]$udp.Send($packetBytes, $packetBytes.Length, $HostName, $Port)
} finally {
  $udp.Close()
}

Write-Host ("VTP_UDP_WIRE_SEND_OK: " + $frameId)
Write-Host ("VTP_UDP_WIRE_PACKET: " + $outPath)
