param(
  [string]$RepoRoot = ".",
  [string]$NodeId = "node-beta",
  [int]$Port = 47731,
  [int]$TimeoutMs = 10000
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
  return Get-VtpWireKeyBytes -RepoRoot $RepoRoot -RecipientNodeId $NodeId -Purpose $Purpose
}

$udp = New-Object Net.Sockets.UdpClient($Port)
$udp.Client.ReceiveTimeout = $TimeoutMs
try {
  $remote = New-Object Net.IPEndPoint([Net.IPAddress]::Any,0)
  $bytes = $udp.Receive([ref]$remote)
} finally {
  $udp.Close()
}

$json = [Text.Encoding]::UTF8.GetString($bytes)
$packet = $json | ConvertFrom-Json
if([string]$packet.header.magic -ne "VTP1"){ throw "VTP_UDP_WIRE_LISTEN_FAIL:BAD_MAGIC" }

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
if((Sha256Hex $expectedTag) -ne (Sha256Hex $tag)){ throw "VTP_UDP_WIRE_LISTEN_FAIL:BAD_AUTH_TAG" }

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
if($plainHash -ne [string]$packet.header.payload_sha256){ throw "VTP_UDP_WIRE_LISTEN_FAIL:PAYLOAD_HASH_MISMATCH" }

$frameId = [string]$packet.header.frame_id
$packetPath = Join-Path $Runtime ($frameId + ".received.packet.json")
$plainPath = Join-Path $Runtime ($frameId + ".plaintext.txt")
[IO.File]::WriteAllText($packetPath, ($json + [string][char]10), $enc)
[IO.File]::WriteAllText($plainPath, ([Text.Encoding]::UTF8.GetString($plainBytes) + [string][char]10), $enc)

Write-Host ("VTP_UDP_WIRE_LISTEN_OK: " + $frameId)
Write-Host ("VTP_UDP_WIRE_RECEIVED_PACKET: " + $packetPath)
