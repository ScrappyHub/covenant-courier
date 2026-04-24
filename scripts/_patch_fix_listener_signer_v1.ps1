param(
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$Listener = Join-Path $RepoRoot "scripts\courier_transport_listen_v1.ps1"

if(-not (Test-Path -LiteralPath $Listener)){
  throw "PATCH_FAIL:LISTENER_NOT_FOUND"
}

$lines = @(Get-Content -LiteralPath $Listener)

$out = New-Object System.Collections.Generic.List[string]

foreach($l in $lines){

  if($l -match 'foreach\(\$line in \$allowedLines\)'){
    # SKIP old insecure loop
    continue
  }

  if($l -match 'verify -SignerIdentity'){
    continue
  }

  $out.Add($l)
}

# Append correct signer verification block
$out.Add('')
$out.Add('# === SIGNER EXTRACTION FIX V1 ===')
$out.Add('$PSExe = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"')
$out.Add('$VerifySig = Join-Path $PSScriptRoot "courier_verify_signature_v1.ps1"')
$out.Add('$tmpOut = Join-Path $env:TEMP "courier_verify_out.txt"')
$out.Add('$tmpErr = Join-Path $env:TEMP "courier_verify_err.txt"')
$out.Add('')
$out.Add('if(Test-Path -LiteralPath $tmpOut){ Remove-Item $tmpOut -Force }')
$out.Add('if(Test-Path -LiteralPath $tmpErr){ Remove-Item $tmpErr -Force }')
$out.Add('')
$out.Add('$p = Start-Process -FilePath $PSExe -ArgumentList @(')
$out.Add('  "-NoProfile",')
$out.Add('  "-NonInteractive",')
$out.Add('  "-ExecutionPolicy","Bypass",')
$out.Add('  "-File",$VerifySig,')
$out.Add('  "-RepoRoot",$RepoRoot,')
$out.Add('  "-MessagePath",$msgPath')
$out.Add(') -NoNewWindow -RedirectStandardOutput $tmpOut -RedirectStandardError $tmpErr -Wait -PassThru')
$out.Add('')
$out.Add('if($p.ExitCode -ne 0){')
$out.Add('  throw "COURIER_TRANSPORT_FAIL:VERIFY_FAILED"')
$out.Add('}')
$out.Add('')
$out.Add('$actualSigner = (Get-Content -LiteralPath $tmpOut -Raw).Trim()')
$out.Add('')
$out.Add('if([string]::IsNullOrWhiteSpace($actualSigner)){')
$out.Add('  throw "COURIER_TRANSPORT_FAIL:NO_SIGNER_EXTRACTED"')
$out.Add('}')
$out.Add('')
$out.Add('if($actualSigner -ne $expectedSender){')
$out.Add('  throw ("COURIER_TRANSPORT_FAIL:SIGNER_MISMATCH:" + $actualSigner + "!=" + $expectedSender)')
$out.Add('}')
$out.Add('# === END SIGNER FIX ===')

$text = (@($out.ToArray()) -join "`n") + "`n"

$enc = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($Listener,$text,$enc)

Write-Host "PATCH_LISTENER_SIGNER_OK" -ForegroundColor Green
