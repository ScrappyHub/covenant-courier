param(
  [string]$RepoRoot = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Courier = Join-Path $RepoRoot "courier.ps1"
$Vtp = Join-Path $RepoRoot "vtp.ps1"

if(-not (Test-Path -LiteralPath $Courier -PathType Leaf)){
  throw "COVENANT_COURIER_VERIFY_FAIL:MISSING_COURIER_CLI"
}

if(-not (Test-Path -LiteralPath $Vtp -PathType Leaf)){
  throw "COVENANT_COURIER_VERIFY_FAIL:MISSING_VTP_CLI"
}

function Run-Step {
  param(
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$Script,
    [Parameter(Mandatory=$true)][string[]]$ChildArgs,
    [Parameter(Mandatory=$true)][string]$ExpectedToken
  )

  Write-Host ("COVENANT_COURIER_VERIFY_STEP_START: " + $Name)

  $ps = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
  $out = & $ps -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $Script @ChildArgs 2>&1
  $code = $LASTEXITCODE
  $text = ($out | Out-String)

  Write-Host $text.Trim()

  if($code -ne 0){
    throw ("COVENANT_COURIER_VERIFY_FAIL:" + $Name + ":EXIT_" + $code)
  }

  if($text -notmatch [regex]::Escape($ExpectedToken)){
    throw ("COVENANT_COURIER_VERIFY_FAIL:" + $Name + ":TOKEN_MISSING:" + $ExpectedToken)
  }

  Write-Host ("COVENANT_COURIER_VERIFY_STEP_OK: " + $Name)
}

Run-Step -Name "schema-test" -Script $Courier -ChildArgs @("schema-test","-RepoRoot",$RepoRoot) -ExpectedToken "COVENANT_COURIER_SCHEMA_TEST_OK"
Run-Step -Name "prepare" -Script $Courier -ChildArgs @("prepare","-RepoRoot",$RepoRoot) -ExpectedToken "COVENANT_COURIER_PREPARE_OK"
Run-Step -Name "send" -Script $Courier -ChildArgs @("send","-RepoRoot",$RepoRoot) -ExpectedToken "COVENANT_COURIER_SEND_OK"
Run-Step -Name "receive" -Script $Courier -ChildArgs @("receive","-RepoRoot",$RepoRoot) -ExpectedToken "COVENANT_COURIER_RECEIVE_OK"
Run-Step -Name "receipts" -Script $Courier -ChildArgs @("receipts","-RepoRoot",$RepoRoot) -ExpectedToken "COVENANT_COURIER_RECEIPTS_OK"
Run-Step -Name "vtp-verify" -Script $Vtp -ChildArgs @("verify","-RepoRoot",$RepoRoot) -ExpectedToken "VTP_VERIFY_ALL_OK"

Write-Host "COVENANT_COURIER_VERIFY_OK"
