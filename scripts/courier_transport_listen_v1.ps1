param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$ConfigPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"
. "$PSScriptRoot\_lib_courier_receipts_v1.ps1"

function Fail([string]$Code){
  throw $Code
}

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    [void][System.IO.Directory]::CreateDirectory($Path)
  }
}

function Test-FrameIdSeen {
  param(
    [Parameter(Mandatory=$true)][string]$RootPath,
    [Parameter(Mandatory=$true)][string]$FrameId
  )

  if(-not (Test-Path -LiteralPath $RootPath)){ return $false }

  $dirs = @(Get-ChildItem -LiteralPath $RootPath -Directory -ErrorAction SilentlyContinue)
  foreach($d in $dirs){
    $fj = Join-Path $d.FullName "frame.json"
    if(-not (Test-Path -LiteralPath $fj)){ continue }
    try {
      $obj = Read-Json $fj
      if((@($obj.PSObject.Properties.Name) -contains "frame_id") -and ([string]$obj.frame_id -eq $FrameId)){
        return $true
      }
    } catch {
      continue
    }
  }
  return $false
}

function Read-RegistryJson([string]$Path,[string]$FailCode){
  if(-not (Test-Path -LiteralPath $Path -PathType Leaf)){ throw $FailCode }
  return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

$PSExe     = Join-Path $env:WINDIR "System32\WindowsPowerShell\v1.0\powershell.exe"
$VerifySig = Join-Path $PSScriptRoot "courier_verify_signature_v1.ps1"

$config = Read-Json $ConfigPath
if(-not $config){ Fail "COURIER_TRANSPORT_FAIL:INVALID_CONFIG" }

$dropRoot     = Join-Path $RepoRoot ([string]$config.drop_root -replace '/','\')
$acceptedRoot = Join-Path $RepoRoot ([string]$config.accepted_root -replace '/','\')
$rejectedRoot = Join-Path $RepoRoot ([string]$config.rejected_root -replace '/','\')

$nodeRoot    = Join-Path $RepoRoot "registry\nodes"
$networkRoot = Join-Path $RepoRoot "registry\networks"
$sessionRoot = Join-Path $RepoRoot "registry\sessions"

Ensure-Dir $dropRoot
Ensure-Dir $acceptedRoot
Ensure-Dir $rejectedRoot

$frames = @(Get-ChildItem -LiteralPath $dropRoot -Directory | Sort-Object Name)

foreach($frameDir in $frames){
  $frameJson = Join-Path $frameDir.FullName "frame.json"

  try {
    if(-not (Test-Path -LiteralPath $frameJson)){ throw "COURIER_TRANSPORT_FAIL:MISSING_FRAME_JSON" }

    $frame = Read-Json $frameJson
    $topProps = @($frame.PSObject.Properties.Name)

    foreach($req in @(
      "frame_id","created_utc","sender_identity","recipient_identity",
      "sender_node_id","recipient_node_id","network_id","session_id","sender_role",
      "message_rel","signature_rel","payload_sha256"
    )){
      if(-not ($topProps -contains $req)){
        throw ("COURIER_TRANSPORT_FAIL:MISSING_FIELD:" + $req)
      }
    }

    $frameId = [string]$frame.frame_id
    if([string]::IsNullOrWhiteSpace($frameId)){ throw "COURIER_TRANSPORT_FAIL:MISSING_FIELD:frame_id" }

    if((Test-FrameIdSeen -RootPath $acceptedRoot -FrameId $frameId) -or
       (Test-FrameIdSeen -RootPath $rejectedRoot -FrameId $frameId)){
      throw "COURIER_TRANSPORT_FAIL:REPLAY_DETECTED"
    }

    $expectedSender = "courier-local@covenant"
    $senderNodeId = [string]$frame.sender_node_id
    $recipientNodeId = [string]$frame.recipient_node_id
    $networkId = [string]$frame.network_id
    $sessionId = [string]$frame.session_id
    $senderRole = [string]$frame.sender_role

    $senderNode = Read-RegistryJson (Join-Path $nodeRoot ($senderNodeId + ".json")) "COURIER_TRANSPORT_FAIL:UNKNOWN_SENDER_NODE"
    $recipientNode = Read-RegistryJson (Join-Path $nodeRoot ($recipientNodeId + ".json")) "COURIER_TRANSPORT_FAIL:UNKNOWN_RECIPIENT_NODE"
    $network = Read-RegistryJson (Join-Path $networkRoot ($networkId + ".json")) "COURIER_TRANSPORT_FAIL:UNKNOWN_NETWORK"
    $session = Read-RegistryJson (Join-Path $sessionRoot ($sessionId + ".json")) "COURIER_TRANSPORT_FAIL:UNKNOWN_SESSION"

    if([string]$session.status -ne "open"){ throw "COURIER_TRANSPORT_FAIL:SESSION_NOT_OPEN" }
    if([string]$session.sender_node_id -ne $senderNodeId){ throw "COURIER_TRANSPORT_FAIL:SENDER_NODE_MISMATCH" }
    if([string]$session.recipient_node_id -ne $recipientNodeId){ throw "COURIER_TRANSPORT_FAIL:RECIPIENT_NODE_MISMATCH" }
    if([string]$session.network_id -ne $networkId){ throw "COURIER_TRANSPORT_FAIL:NETWORK_MISMATCH" }
    if([string]$session.session_role -ne $senderRole){ throw "COURIER_TRANSPORT_FAIL:SENDER_ROLE_MISMATCH" }
    if([string]$senderNode.status -ne "active"){ throw "COURIER_TRANSPORT_FAIL:SENDER_NODE_INACTIVE" }
    if([string]$recipientNode.status -ne "active"){ throw "COURIER_TRANSPORT_FAIL:RECIPIENT_NODE_INACTIVE" }
    if([string]$network.status -ne "active"){ throw "COURIER_TRANSPORT_FAIL:NETWORK_INACTIVE" }

    $allowedNodes = @($network.allowed_nodes)
    if(($allowedNodes -notcontains $senderNodeId) -or ($allowedNodes -notcontains $recipientNodeId)){
      throw "COURIER_TRANSPORT_FAIL:NODE_NOT_ALLOWED_ON_NETWORK"
    }

    if([string]$frame.sender_identity -ne $expectedSender){
      throw "COURIER_TRANSPORT_FAIL:UNEXPECTED_SENDER_IDENTITY"
    }
    if([string]$senderNode.principal -ne $expectedSender){
      throw "COURIER_TRANSPORT_FAIL:SENDER_PRINCIPAL_MISMATCH"
    }

    $msgPath = Join-Path $frameDir.FullName ([string]$frame.message_rel -replace '/','\')
    $sigPath = Join-Path $frameDir.FullName ([string]$frame.signature_rel -replace '/','\')

    if(-not (Test-Path -LiteralPath $msgPath)){ throw "COURIER_TRANSPORT_FAIL:MISSING_MESSAGE_ARTIFACT" }
    if(-not (Test-Path -LiteralPath $sigPath)){ throw "COURIER_TRANSPORT_FAIL:MISSING_SIGNATURE_ARTIFACT" }

    $actualHash = (Get-FileHash -LiteralPath $msgPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if($actualHash -ne [string]$frame.payload_sha256){
      throw "COURIER_TRANSPORT_FAIL:PAYLOAD_HASH_MISMATCH"
    }

    $verifyOut = Join-Path $env:TEMP "courier_verify_out.txt"
    $verifyErr = Join-Path $env:TEMP "courier_verify_err.txt"
    if(Test-Path -LiteralPath $verifyOut){ Remove-Item -LiteralPath $verifyOut -Force }
    if(Test-Path -LiteralPath $verifyErr){ Remove-Item -LiteralPath $verifyErr -Force }

    $p = Start-Process -FilePath $PSExe -ArgumentList @(
      "-NoProfile","-NonInteractive","-ExecutionPolicy","Bypass",
      "-File",$VerifySig,
      "-RepoRoot",$RepoRoot,
      "-MessagePath",$msgPath,
      "-SignerIdentity",$expectedSender
    ) -NoNewWindow -RedirectStandardOutput $verifyOut -RedirectStandardError $verifyErr -Wait -PassThru

    if($p.ExitCode -ne 0){
      $errText = ""
      if(Test-Path -LiteralPath $verifyErr){
        $errText = (Get-Content -LiteralPath $verifyErr -Raw)
      }
      if([string]::IsNullOrWhiteSpace($errText)){
        throw "COURIER_TRANSPORT_FAIL:VERIFY_FAILED"
      }
      throw ("COURIER_TRANSPORT_FAIL:VERIFY_FAILED:" + $errText.Trim())
    }

    $dest = Join-Path $acceptedRoot $frameDir.Name
    if(Test-Path -LiteralPath $dest){ Remove-Item -LiteralPath $dest -Recurse -Force }
    Move-Item -LiteralPath $frameDir.FullName -Destination $dest

    $receiptPath = Append-CourierReceipt -RepoRoot $RepoRoot -Receipt ([ordered]@{
      schema = "courier.transport.receipt.v1"
      event_type = "courier.transport.accept.v1"
      timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
      details = [ordered]@{
        frame_id = $frameId
        sender_node_id = $senderNodeId
        recipient_node_id = $recipientNodeId
        network_id = $networkId
        session_id = $sessionId
        sender_role = $senderRole
        accepted_root = $dest
        payload_sha256 = $actualHash
      }
    })

    Write-Host ("COURIER_TRANSPORT_LISTEN_ACCEPT_OK: " + $dest)
    Write-Host ("COURIER_TRANSPORT_ACCEPT_RECEIPT_OK: " + $receiptPath)
  }
  catch {
    $dest = Join-Path $rejectedRoot $frameDir.Name
    if(Test-Path -LiteralPath $dest){ Remove-Item -LiteralPath $dest -Recurse -Force }
    Move-Item -LiteralPath $frameDir.FullName -Destination $dest

    $reasonPath = Join-Path $dest "reject_reason.txt"
    $enc = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($reasonPath, ([string]$_.Exception.Message + "`n"), $enc)

    $receiptPath = Append-CourierReceipt -RepoRoot $RepoRoot -Receipt ([ordered]@{
      schema = "courier.transport.receipt.v1"
      event_type = "courier.transport.reject.v1"
      timestamp_utc = (Get-Date).ToUniversalTime().ToString("o")
      details = [ordered]@{
        frame_root = $dest
        reason = [string]$_.Exception.Message
      }
    })

    Write-Host ("COURIER_TRANSPORT_LISTEN_REJECT_OK: " + $dest)
    Write-Host ("COURIER_TRANSPORT_REJECT_RECEIPT_OK: " + $receiptPath)
  }
}

exit 0
