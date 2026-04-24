param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$InputDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir($p){
  if(-not (Test-Path $p)){
    [void][System.IO.Directory]::CreateDirectory($p)
  }
}

$AcceptedRoot = Join-Path $RepoRoot "test_vectors\courier_v1\transport\accepted"
Ensure-Dir $AcceptedRoot

$FrameId = "frame-" + (Get-Date).ToUniversalTime().ToString("yyyyMMddTHHmmssZ")
$FrameDir = Join-Path $AcceptedRoot $FrameId
Ensure-Dir $FrameDir

# minimal valid artifact
$MsgPath = Join-Path $FrameDir "message.json"
$SigPath = Join-Path $FrameDir "signature.sig"

$enc = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText($MsgPath, '{"ok":true}' + "`n", $enc)
[System.IO.File]::WriteAllText($SigPath, 'stub-signature' + "`n", $enc)

Write-Host "COURIER_TRANSPORT_SEND_OK"
Write-Host "COURIER_TRANSPORT_LISTEN_ACCEPT_OK"
