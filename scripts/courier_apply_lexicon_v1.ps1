param(
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$LexiconPath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"

$msg = Read-Json $MessagePath
$lex = Read-Json $LexiconPath

if($null -eq $msg.payload -or [string]::IsNullOrWhiteSpace([string]$msg.payload.content)){
  throw "LEXICON_APPLY_FAIL: MISSING_PAYLOAD_CONTENT"
}

$text = [string]$msg.payload.content
$transforms = New-Object System.Collections.Generic.List[object]

foreach($cat in @($lex.categories)){
  $categoryId = [string]$cat.category_id
  $mode       = [string]$cat.mode

  foreach($termObj in @($cat.terms)){
    $term = [string]$termObj
    if([string]::IsNullOrWhiteSpace($term)){ continue }

    $pattern = '\b' + [regex]::Escape($term) + '\b'
    if([regex]::IsMatch($text,$pattern,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)){
      $token = "[CAT:" + $categoryId + "]"
      $text = [regex]::Replace(
        $text,
        $pattern,
        $token,
        [System.Text.RegularExpressions.RegexOptions]::IgnoreCase
      )

      [void]$transforms.Add([ordered]@{
        category = $categoryId
        mode     = $mode
        term     = $term
      })
    }
  }
}

$msg.payload.content = $text
$msg.lexical_transforms = @($transforms.ToArray())

Write-JsonCanonical $OutPath $msg

Append-Receipt $RepoRoot ([ordered]@{
  schema        = "courier.receipt.v1"
  event_type    = "courier.lexicon.applied.v1"
  message_id    = [string]$msg.message_id
  timestamp_utc = "2026-01-01T00:00:00Z"
  details       = [ordered]@{
    out_path    = $OutPath
    transforms  = @($transforms.ToArray())
    lexicon     = $LexiconPath
  }
})

Write-Host ("COURIER_LEXICON_APPLY_OK: " + $OutPath)