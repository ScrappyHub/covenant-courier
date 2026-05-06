param(
  [string]$RepoRoot = ".",
  [string]$To = "node-beta",
  [int]$Port = 47732
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"
$RunRoot = Join-Path $RepoRoot ("proofs\wire_ingest_selftest\" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ"))
[void][IO.Directory]::CreateDirectory($RunRoot)
$ps = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$ingest = Join-Path $Scripts "vtp_udp_wire_ingest_once_v1.ps1"
$send = Join-Path $Scripts "vtp_udp_wire_send_v1.ps1"
$packetPath = Join-Path $RunRoot "captured.packet.json"
$ingestOut = Join-Path $RunRoot "ingest.stdout.txt"
$ingestErr = Join-Path $RunRoot "ingest.stderr.txt"
$enc = [Text.UTF8Encoding]::new($false)

if(-not (Test-Path -LiteralPath $ingest -PathType Leaf)){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:MISSING_INGEST" }
if(-not (Test-Path -LiteralPath $send -PathType Leaf)){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:MISSING_SEND" }

$udp = New-Object Net.Sockets.UdpClient($Port)
$remote = New-Object Net.IPEndPoint([Net.IPAddress]::Any,0)
try {
  $async = $udp.BeginReceive($null,$null)
  & $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $send -RepoRoot $RepoRoot -To $To -HostName "127.0.0.1" -Port $Port -PlainText "{""message"":""wire ingest hello""}"
  if($LASTEXITCODE -ne 0){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:SEND_EXIT" }
  if(-not $async.AsyncWaitHandle.WaitOne(10000)){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:RECEIVE_TIMEOUT" }
  $bytes = $udp.EndReceive($async,[ref]$remote)
} finally {
  $udp.Close()
}

[IO.File]::WriteAllBytes($packetPath,$bytes)

& $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $ingest -RepoRoot $RepoRoot -NodeId $To -PacketPath $packetPath *> $ingestOut
$code = $LASTEXITCODE
if($code -ne 0){
  $stdout = ""
  if(Test-Path -LiteralPath $ingestOut){ $stdout = Get-Content -LiteralPath $ingestOut -Raw }
  throw ("VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:INGEST_EXIT_" + $code + ":" + $stdout)
}

$stdout = Get-Content -LiteralPath $ingestOut -Raw
if($stdout -notmatch "VTP_UDP_WIRE_INGEST_ACCEPT_OK"){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:NO_ACCEPT_OK" }
if($stdout -notmatch "VTP_UDP_WIRE_INGEST_RECEIPT_OK"){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:NO_RECEIPT_OK" }

Write-Host $stdout.Trim()
Write-Host ("VTP_UDP_WIRE_INGEST_CAPTURED_PACKET: " + $packetPath)
Write-Host ("VTP_UDP_WIRE_INGEST_SELFTEST_RUN: " + $RunRoot)
Write-Host "VTP_UDP_WIRE_INGEST_SELFTEST_OK"
