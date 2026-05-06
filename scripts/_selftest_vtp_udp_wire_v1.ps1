param(
  [string]$RepoRoot = ".",
  [string]$To = "node-beta",
  [int]$Port = 47731
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"
$RunRoot = Join-Path $RepoRoot ("proofs\wire_udp_selftest\" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffZ"))
[void][IO.Directory]::CreateDirectory($RunRoot)
$outPath = Join-Path $RunRoot "listener.stdout.txt"
$errPath = Join-Path $RunRoot "listener.stderr.txt"
$ps = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$listen = Join-Path $Scripts "vtp_udp_wire_listen_once_v1.ps1"
$send = Join-Path $Scripts "vtp_udp_wire_send_v1.ps1"

$args = @("-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass","-File",$listen,"-RepoRoot",$RepoRoot,"-NodeId",$To,"-Port",[string]$Port,"-TimeoutMs","10000")
$p = Start-Process -FilePath $ps -ArgumentList $args -RedirectStandardOutput $outPath -RedirectStandardError $errPath -PassThru -WindowStyle Hidden
Start-Sleep -Milliseconds 700
& $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $send -RepoRoot $RepoRoot -To $To -HostName "127.0.0.1" -Port $Port
$deadline = (Get-Date).AddSeconds(12)
while(-not $p.HasExited -and (Get-Date) -lt $deadline){ Start-Sleep -Milliseconds 200 }
if(-not $p.HasExited){
  Stop-Process -Id $p.Id -Force
  throw "VTP_UDP_WIRE_SELFTEST_FAIL:LISTENER_TIMEOUT"
}
if($p.ExitCode -ne 0){
  $stderr = ""
  if(Test-Path -LiteralPath $errPath){ $stderr = Get-Content -LiteralPath $errPath -Raw }
  throw ("VTP_UDP_WIRE_SELFTEST_FAIL:LISTENER_EXIT_" + $p.ExitCode + ":" + $stderr)
}
$stdout = Get-Content -LiteralPath $outPath -Raw
if($stdout -notmatch "VTP_UDP_WIRE_LISTEN_OK"){ throw "VTP_UDP_WIRE_SELFTEST_FAIL:NO_LISTEN_OK" }
Write-Host $stdout.Trim()
Write-Host ("VTP_UDP_WIRE_SELFTEST_RUN: " + $RunRoot)
Write-Host "VTP_UDP_WIRE_SELFTEST_OK"
