param(
  [string]$RepoRoot = ".",
  [string]$To = "node-beta",
  [int]$Port = 47733
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"
$RunRoot = Join-Path $RepoRoot ("proofs\wire_negative_selftest\" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ"))
[void][IO.Directory]::CreateDirectory($RunRoot)

$ps = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$send = Join-Path $Scripts "vtp_udp_wire_send_v1.ps1"
$ingest = Join-Path $Scripts "vtp_udp_wire_ingest_once_v1.ps1"
$keyLib = Join-Path $Scripts "vtp_wire_key_envelope_v1.ps1"

if(-not (Test-Path -LiteralPath $send -PathType Leaf)){ throw "VTP_WIRE_NEGATIVE_FAIL:MISSING_SEND" }
if(-not (Test-Path -LiteralPath $ingest -PathType Leaf)){ throw "VTP_WIRE_NEGATIVE_FAIL:MISSING_INGEST" }
if(-not (Test-Path -LiteralPath $keyLib -PathType Leaf)){ throw "VTP_WIRE_NEGATIVE_FAIL:MISSING_KEY_LIB" }
. $keyLib

function Capture-GoodPacket {
  param([string]$OutPath)

  $udp = New-Object Net.Sockets.UdpClient($Port)
  $remote = New-Object Net.IPEndPoint([Net.IPAddress]::Any,0)
  try {
    $async = $udp.BeginReceive($null,$null)
    & $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $send -RepoRoot $RepoRoot -To $To -HostName "127.0.0.1" -Port $Port -PlainText "{""message"":""negative vector base""}"
    if($LASTEXITCODE -ne 0){ throw "VTP_WIRE_NEGATIVE_FAIL:SEND_EXIT" }
    if(-not $async.AsyncWaitHandle.WaitOne(10000)){ throw "VTP_WIRE_NEGATIVE_FAIL:RECEIVE_TIMEOUT" }
    $bytes = $udp.EndReceive($async,[ref]$remote)
  } finally {
    $udp.Close()
  }

  [IO.File]::WriteAllBytes($OutPath,$bytes)
}

function B64([byte[]]$Bytes){
  return [Convert]::ToBase64String($Bytes)
}

function Recompute-Tag {
  param($Packet)

  $headerJson = ($Packet.header | ConvertTo-Json -Depth 20 -Compress)
  $headerBytes = [Text.Encoding]::UTF8.GetBytes($headerJson)
  $iv = [Convert]::FromBase64String([string]$Packet.iv_b64)
  $cipherBytes = [Convert]::FromBase64String([string]$Packet.ciphertext_b64)
  $macKey = Get-VtpWireKeyBytes -RepoRoot $RepoRoot -RecipientNodeId $To -Purpose "hmac"

  $macInput = New-Object byte[] ($headerBytes.Length + $iv.Length + $cipherBytes.Length)
  [Array]::Copy($headerBytes,0,$macInput,0,$headerBytes.Length)
  [Array]::Copy($iv,0,$macInput,$headerBytes.Length,$iv.Length)
  [Array]::Copy($cipherBytes,0,$macInput,$headerBytes.Length + $iv.Length,$cipherBytes.Length)

  $hmac = New-Object Security.Cryptography.HMACSHA256(,$macKey)
  try {
    return $hmac.ComputeHash($macInput)
  } finally {
    $hmac.Dispose()
  }
}

function Write-PacketJson {
  param($Packet,[string]$Path)
  $json = $Packet | ConvertTo-Json -Depth 20 -Compress
  [IO.File]::WriteAllText($Path, ($json + [string][char]10), [Text.UTF8Encoding]::new($false))
}

function Expect-IngestFail {
  param(
    [string]$Name,
    [string]$PacketPath,
    [string]$ExpectedToken
  )

  $safeName = ($Name -replace "[^A-Za-z0-9_.-]","_")
  $stdoutPath = Join-Path $RunRoot ($safeName + ".stdout.txt")
  $stderrPath = Join-Path $RunRoot ($safeName + ".stderr.txt")

  $args = @(
    "-NoProfile",
    "-NonInteractive",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $ingest,
    "-RepoRoot",
    $RepoRoot,
    "-NodeId",
    $To,
    "-PacketPath",
    $PacketPath
  )

  $proc = Start-Process -FilePath $ps -ArgumentList $args -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -PassThru -WindowStyle Hidden
  $proc.WaitForExit()

  $code = $proc.ExitCode
  $stdout = ""
  $stderr = ""

  if(Test-Path -LiteralPath $stdoutPath -PathType Leaf){
    $stdout = Get-Content -LiteralPath $stdoutPath -Raw
  }

  if(Test-Path -LiteralPath $stderrPath -PathType Leaf){
    $stderr = Get-Content -LiteralPath $stderrPath -Raw
  }

  $text = $stdout + "`n" + $stderr

  if($code -eq 0){
    throw ("VTP_WIRE_NEGATIVE_FAIL:" + $Name + ":UNEXPECTED_SUCCESS")
  }

  if($text -notmatch [regex]::Escape($ExpectedToken)){
    Write-Host $text
    throw ("VTP_WIRE_NEGATIVE_FAIL:" + $Name + ":EXPECTED_TOKEN_MISSING:" + $ExpectedToken)
  }

  Write-Host ("VTP_WIRE_NEGATIVE_EXPECTED_FAIL_OK: " + $Name + ":" + $ExpectedToken)
}

$goodPath = Join-Path $RunRoot "good.packet.json"
Capture-GoodPacket -OutPath $goodPath
$goodPacket = Get-Content -LiteralPath $goodPath -Raw | ConvertFrom-Json

$badMagic = Get-Content -LiteralPath $goodPath -Raw | ConvertFrom-Json
$badMagic.header.magic = "BAD1"
$badMagicPath = Join-Path $RunRoot "bad_magic.packet.json"
Write-PacketJson -Packet $badMagic -Path $badMagicPath
Expect-IngestFail -Name "bad-magic" -PacketPath $badMagicPath -ExpectedToken "VTP_UDP_WIRE_INGEST_FAIL:BAD_MAGIC"

$badTag = Get-Content -LiteralPath $goodPath -Raw | ConvertFrom-Json
$badTag.tag_b64 = B64 (New-Object byte[] 32)
$badTagPath = Join-Path $RunRoot "bad_tag.packet.json"
Write-PacketJson -Packet $badTag -Path $badTagPath
Expect-IngestFail -Name "bad-auth-tag" -PacketPath $badTagPath -ExpectedToken "VTP_UDP_WIRE_INGEST_FAIL:BAD_AUTH_TAG"

$badHash = Get-Content -LiteralPath $goodPath -Raw | ConvertFrom-Json
$badHash.header.payload_sha256 = "0000000000000000000000000000000000000000000000000000000000000000"
$badHash.tag_b64 = B64 (Recompute-Tag -Packet $badHash)
$badHashPath = Join-Path $RunRoot "bad_payload_hash.packet.json"
Write-PacketJson -Packet $badHash -Path $badHashPath
Expect-IngestFail -Name "bad-payload-hash" -PacketPath $badHashPath -ExpectedToken "VTP_UDP_WIRE_INGEST_FAIL:PAYLOAD_HASH_MISMATCH"

Write-Host ("VTP_WIRE_NEGATIVE_SELFTEST_RUN: " + $RunRoot)
Write-Host "VTP_WIRE_NEGATIVE_SELFTEST_OK"
