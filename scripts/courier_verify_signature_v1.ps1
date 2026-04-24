param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$SignerIdentity,
  [string]$Namespace = "courier/message"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Code){
  throw $Code
}

$Allowed = Join-Path $RepoRoot "proofs\trust\allowed_signers"
$SigPath = $MessagePath + ".sig"
$SSHKeygen = Join-Path $env:WINDIR "System32\OpenSSH\ssh-keygen.exe"

if(-not (Test-Path -LiteralPath $SSHKeygen)){
  Fail ("COURIER_VERIFY_FAIL:MISSING_SSH_KEYGEN:" + $SSHKeygen)
}
if(-not (Test-Path -LiteralPath $Allowed)){
  Fail "COURIER_VERIFY_FAIL:ALLOWED_SIGNERS_MISSING"
}
if(-not (Test-Path -LiteralPath $MessagePath)){
  Fail "COURIER_VERIFY_FAIL:MISSING_MESSAGE"
}
if(-not (Test-Path -LiteralPath $SigPath)){
  Fail "COURIER_VERIFY_FAIL:MISSING_SIGNATURE"
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $SSHKeygen
$psi.Arguments = ('-Y verify -f "{0}" -I "{1}" -n "{2}" -s "{3}"' -f $Allowed, $SignerIdentity, $Namespace, $SigPath)
$psi.UseShellExecute = $false
$psi.RedirectStandardInput  = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError  = $true
$psi.CreateNoWindow = $true

$p = New-Object System.Diagnostics.Process
$p.StartInfo = $psi
[void]$p.Start()

$bytes = [System.IO.File]::ReadAllBytes($MessagePath)
$stdin = $p.StandardInput.BaseStream
$stdin.Write($bytes, 0, $bytes.Length)
$stdin.Flush()
$stdin.Close()

$stdout = $p.StandardOutput.ReadToEnd()
$stderr = $p.StandardError.ReadToEnd()
$p.WaitForExit()

if($p.ExitCode -ne 0){
  $msg = ($stdout + "`n" + $stderr).Trim()
  if($msg.Length -gt 0){
    Fail ("COURIER_VERIFY_FAIL:SSH_VERIFY_EXIT_" + $p.ExitCode + ":" + $msg)
  }
  else {
    Fail ("COURIER_VERIFY_FAIL:SSH_VERIFY_EXIT_" + $p.ExitCode)
  }
}

Write-Host "COURIER_SIGNATURE_VERIFY_OK"
exit 0
