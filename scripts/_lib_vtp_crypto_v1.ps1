Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Dir([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){ [void][System.IO.Directory]::CreateDirectory($Path) }
}

function Write-Utf8NoBomLf([string]$Path,[string]$Text){
  $dir = Split-Path -Parent $Path
  if($dir){ Ensure-Dir $dir }
  $t = ($Text -replace "`r`n","`n") -replace "`r","`n"
  if(-not $t.EndsWith("`n")){ $t += "`n" }
  $enc = New-Object System.Text.UTF8Encoding($false)
  [System.IO.File]::WriteAllText($Path,$t,$enc)
}

function Get-Sha256HexBytes([byte[]]$Bytes){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  try { $h=$sha.ComputeHash($Bytes) } finally { $sha.Dispose() }
  return (($h | ForEach-Object { $_.ToString("x2") }) -join "")
}

function Get-Sha256HexFile([string]$Path){
  $sha=[System.Security.Cryptography.SHA256]::Create()
  $fs=[System.IO.File]::OpenRead($Path)
  try { $h=$sha.ComputeHash($fs) } finally { $fs.Dispose(); $sha.Dispose() }
  return (($h | ForEach-Object { $_.ToString("x2") }) -join "")
}

function New-RandomBytes([int]$Count){
  $b = New-Object byte[] $Count
  $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
  try { $rng.GetBytes($b) } finally { $rng.Dispose() }
  return $b
}

function Derive-KeyFromJoinCode([string]$JoinCode,[byte[]]$Salt){
  $kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($JoinCode,$Salt,200000)
  try { return $kdf.GetBytes(64) } finally { $kdf.Dispose() }
}

function Protect-BytesAesGcm([byte[]]$Plain,[byte[]]$Key,[byte[]]$Nonce,[byte[]]$Aad){
  # PS5.1/.NET Framework compatible fallback:
  # AES-256-CBC + HMAC-SHA256, encrypt-then-MAC.
  $encKey = New-Object byte[] 32
  $macKey = New-Object byte[] 32
  [Array]::Copy($Key,0,$encKey,0,32)
  [Array]::Copy($Key,32,$macKey,0,32)

  $aes = [System.Security.Cryptography.Aes]::Create()
  $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
  $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
  $aes.KeySize = 256
  $aes.Key = $encKey
  $ivMaterial = [System.Security.Cryptography.SHA256]::Create().ComputeHash($Nonce)
$cbcIv = New-Object byte[] 16
[Array]::Copy($ivMaterial,0,$cbcIv,0,16)
$aes.IV = $cbcIv

  try {
    $encryptor = $aes.CreateEncryptor()
    try {
      $cipher = $encryptor.TransformFinalBlock($Plain,0,$Plain.Length)
    }
    finally { $encryptor.Dispose() }
  }
  finally { $aes.Dispose() }

  $macInput = New-Object byte[] ($Aad.Length + $Nonce.Length + $cipher.Length)
  [Array]::Copy($Aad,0,$macInput,0,$Aad.Length)
  [Array]::Copy($Nonce,0,$macInput,$Aad.Length,$Nonce.Length)
  [Array]::Copy($cipher,0,$macInput,($Aad.Length+$Nonce.Length),$cipher.Length)

  $hmac = [System.Security.Cryptography.HMACSHA256]::new($macKey)
  try { $tag = $hmac.ComputeHash($macInput) } finally { $hmac.Dispose() }

  return @{ cipher=$cipher; tag=$tag }
}

function Unprotect-BytesAesGcm([byte[]]$Cipher,[byte[]]$Key,[byte[]]$Nonce,[byte[]]$Tag,[byte[]]$Aad){
  $encKey = New-Object byte[] 32
  $macKey = New-Object byte[] 32
  [Array]::Copy($Key,0,$encKey,0,32)
  [Array]::Copy($Key,32,$macKey,0,32)

  $macInput = New-Object byte[] ($Aad.Length + $Nonce.Length + $Cipher.Length)
  [Array]::Copy($Aad,0,$macInput,0,$Aad.Length)
  [Array]::Copy($Nonce,0,$macInput,$Aad.Length,$Nonce.Length)
  [Array]::Copy($Cipher,0,$macInput,($Aad.Length+$Nonce.Length),$Cipher.Length)

  $hmac = [System.Security.Cryptography.HMACSHA256]::new($macKey)
  try { $actualTag = $hmac.ComputeHash($macInput) } finally { $hmac.Dispose() }

  if($actualTag.Length -ne $Tag.Length){ throw "AUTH_TAG_MISMATCH" }
  $diff = 0
  for($i=0; $i -lt $actualTag.Length; $i++){
    $diff = $diff -bor ($actualTag[$i] -bxor $Tag[$i])
  }
  if($diff -ne 0){ throw "AUTH_TAG_MISMATCH" }

  $aes = [System.Security.Cryptography.Aes]::Create()
  $aes.Mode = [System.Security.Cryptography.CipherMode]::CBC
  $aes.Padding = [System.Security.Cryptography.PaddingMode]::PKCS7
  $aes.KeySize = 256
  $aes.Key = $encKey
  $ivMaterial = [System.Security.Cryptography.SHA256]::Create().ComputeHash($Nonce)
$cbcIv = New-Object byte[] 16
[Array]::Copy($ivMaterial,0,$cbcIv,0,16)
$aes.IV = $cbcIv

  try {
    $decryptor = $aes.CreateDecryptor()
    try {
      return $decryptor.TransformFinalBlock($Cipher,0,$Cipher.Length)
    }
    finally { $decryptor.Dispose() }
  }
  finally { $aes.Dispose() }
}
