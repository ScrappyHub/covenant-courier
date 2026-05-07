param(
  [Parameter(Position=0)][string]$Command = "help",
  [string]$RepoRoot = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Scripts = Join-Path $RepoRoot "scripts"

function Run-PS {
  param(
    [Parameter(Mandatory=$true)][string]$Script,
    [string[]]$Args = @()
  )

  $ps = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"

  & $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @Args

  if($LASTEXITCODE -ne 0){
    throw ("COURIER_CHILD_FAIL:" + $Script)
  }
}

if($Command -eq "help"){
  Write-Host "Covenant Courier"
  Write-Host "Product CLI"
  Write-Host ""
  Write-Host "Commands:"
  Write-Host "  .\courier.ps1 help"
  Write-Host "  .\courier.ps1 schema-test"
  Write-Host ""
  Write-Host "Protocol substrate:"
  Write-Host "  .\vtp.ps1 verify"
  exit 0
}

if($Command -eq "schema-test"){
  Run-PS (Join-Path $Scripts "courier_schema_test_v1.ps1") @("-RepoRoot",$RepoRoot)
  exit 0
}

throw ("UNKNOWN_COURIER_COMMAND:" + $Command)
