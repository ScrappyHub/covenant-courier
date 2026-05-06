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
$outPath = Join-Path $RunRoot "ingest.stdout.txt"
$errPath = Join-Path $RunRoot "ingest.stderr.txt"
$ps = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$ingest = Join-Path $Scripts "vtp_udp_wire_ingest_once_v1.ps1"
$send = Join-Path $Scripts "vtp_udp_wire_send_v1.ps1"

$args = @("-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass","-File",$ingest,"-RepoRoot",$RepoRoot,"-NodeId",$To,"-Port",[string]$Port,"-TimeoutMs","10000")
$p = Start-Process -FilePath $ps -ArgumentList $args -RedirectStandardOutput $outPath -RedirectStandardError $errPath -PassThru -WindowStyle Hidden
Start-Sleep -Milliseconds 700
& $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $send -RepoRoot $RepoRoot -To $To -HostName "127.0.0.1" -Port $Port -PlainText "{""message"":""wire ingest hello""}"
if($LASTEXITCODE -ne 0){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:SEND_EXIT" }
$deadline = (Get-Date).AddSeconds(12)
while(-not $p.HasExited -and (Get-Date) -lt $deadline){ Start-Sleep -Milliseconds 200 }
if(-not $p.HasExited){
  Stop-Process -Id $p.Id -Force
  throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:INGEST_TIMEOUT"
}
if($p.ExitCode -ne 0){
  $stderr = ""
  if(Test-Path -LiteralPath $errPath){ $stderr = Get-Content -LiteralPath $errPath -Raw }
  throw ("VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:INGEST_EXIT_" + $p.ExitCode + ":" + $stderr)
}
$stdout = Get-Content -LiteralPath $outPath -Raw
if($stdout -notmatch "VTP_UDP_WIRE_INGEST_ACCEPT_OK"){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:NO_ACCEPT_OK" }
if($stdout -notmatch "VTP_UDP_WIRE_INGEST_RECEIPT_OK"){ throw "VTP_UDP_WIRE_INGEST_SELFTEST_FAIL:NO_RECEIPT_OK" }
Write-Host $stdout.Trim()
Write-Host ("VTP_UDP_WIRE_INGEST_SELFTEST_RUN: " + $RunRoot)
Write-Host "VTP_UDP_WIRE_INGEST_SELFTEST_OK"
