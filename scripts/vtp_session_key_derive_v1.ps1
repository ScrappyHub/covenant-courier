param(
  [Parameter(Mandatory=$true)][string]$JoinCode,
  [Parameter(Mandatory=$true)][string]$SessionId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$bytes = [System.Text.Encoding]::UTF8.GetBytes($JoinCode + "|" + $SessionId)

$sha = [System.Security.Cryptography.SHA256]::Create()
try {
  $key = $sha.ComputeHash($bytes)
}
finally {
  $sha.Dispose()
}

return $key