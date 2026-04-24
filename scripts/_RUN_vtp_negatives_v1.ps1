param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$PSExe  = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$Script = Join-Path $PSScriptRoot "_selftest_vtp_negatives_v1.ps1"

$p = Start-Process -FilePath $PSExe -ArgumentList @(
  "-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass",
  "-File",$Script,
  "-RepoRoot",$RepoRoot
) -Wait -PassThru

if($p.ExitCode -ne 0){
  throw ("VTP_NEGATIVE_RUNNER_FAIL:EXIT_" + $p.ExitCode)
}

Write-Host "VTP_NEGATIVE_RUNNER_OK"
