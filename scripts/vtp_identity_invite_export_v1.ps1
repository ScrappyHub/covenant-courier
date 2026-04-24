param(
  [Parameter(Mandatory=$true)][string]$RepoRoot,
  [Parameter(Mandatory=$true)][string]$NodeId,
  [Parameter(Mandatory=$true)][string]$Principal,
  [Parameter(Mandatory=$true)][string]$PublicKeyPath,
  [Parameter(Mandatory=$true)][string]$OutRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Code){ throw $Code }
function Ensure-Dir([string]$Path){ if(-not (Test-Path -LiteralPath $Path)){ [void][System.IO.Directory]::CreateDirectory($Path) } }
function Write-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir){ Ensure-Dir $dir }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}
function Get-Sha256Hex([string]$Path){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  $fs=[System.IO.File]::OpenRead($Path)
  try{ $h=$sha.ComputeHash($fs) } finally { $fs.Dispose(); $sha.Dispose() }
  return (($h | ForEach-Object { $_.ToString("x2") }) -join "")
}

if(-not (Test-Path -LiteralPath $PublicKeyPath -PathType Leaf)){ Fail "VTP_INVITE_EXPORT_FAIL:MISSING_PUBLIC_KEY" }

if(Test-Path -LiteralPath $OutRoot){ Remove-Item -LiteralPath $OutRoot -Recurse -Force }
Ensure-Dir $OutRoot

$pub = (Get-Content -LiteralPath $PublicKeyPath -Raw).Trim()
$tmpPub = Join-Path $OutRoot "node_public_key.pub"
Write-Utf8NoBomLf $tmpPub $pub
$fingerprint = Get-Sha256Hex $tmpPub

$invite = [ordered]@{
  schema = "vtp.identity_invite.v1"
  created_utc = (Get-Date).ToUniversalTime().ToString("o")
  node_id = $NodeId
  principal = $Principal
  public_key = $pub
  public_key_sha256 = $fingerprint
  trust_instruction = "Verify this fingerprint out-of-band before pinning trust."
}

Write-Utf8NoBomLf (Join-Path $OutRoot "vtp_identity_invite.json") (($invite | ConvertTo-Json -Depth 20 -Compress))

$shaPath = Join-Path $OutRoot "sha256sums.txt"
$files = @(Get-ChildItem -LiteralPath $OutRoot -File | Where-Object { $_.FullName -ne $shaPath } | Sort-Object Name)
$lines = New-Object System.Collections.Generic.List[string]
foreach($f in $files){ [void]$lines.Add((Get-Sha256Hex $f.FullName) + "  " + $f.Name) }
Write-Utf8NoBomLf $shaPath (($lines.ToArray()) -join "`n")

Write-Host ("VTP_INVITE_EXPORT_ROOT: " + $OutRoot)
Write-Host ("VTP_INVITE_FINGERPRINT_SHA256: " + $fingerprint)
Write-Host "VTP_IDENTITY_INVITE_EXPORT_OK"
