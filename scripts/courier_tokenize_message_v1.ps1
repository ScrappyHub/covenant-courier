param(
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$DictionaryPath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [string]$Context = "internal"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"

$msg  = Read-Json $MessagePath
$dict = Read-Json $DictionaryPath

if(-not $msg){ throw "LEX_TOKEN_FAIL:INVALID_MESSAGE_JSON" }
if(-not $dict){ throw "LEX_TOKEN_FAIL:INVALID_DICTIONARY_JSON" }
if([string]::IsNullOrWhiteSpace([string]$msg.plaintext)){ throw "LEX_TOKEN_FAIL:MISSING_PLAINTEXT" }

$text = [string]$msg.plaintext
$events = New-Object System.Collections.Generic.List[object]
$position = 0

$entries = @($dict.entries | Sort-Object {
  $maxLen = 0
  foreach($sf in $_.surface_forms){
    if(([string]$sf).Length -gt $maxLen){ $maxLen = ([string]$sf).Length }
  }
  -$maxLen
})

foreach($entry in $entries){
  $allowed = @($entry.allowed_contexts | ForEach-Object { ([string]$_).ToLowerInvariant() })
  if($allowed.Count -gt 0 -and ($allowed -notcontains $Context.ToLowerInvariant())){
    continue
  }

  $surfaceForms = @($entry.surface_forms | ForEach-Object { [string]$_ } | Sort-Object { -$_.Length })

  foreach($sf in $surfaceForms){
    $surface = $sf.ToLowerInvariant()
    $pattern = '\b' + [regex]::Escape($surface) + '\b'

    while([regex]::IsMatch($text,$pattern,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)){
      $m = [regex]::Match($text,$pattern,[System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
      $tokenText = "[[" + [string]$entry.token + "]]"
      $text = $text.Substring(0,$m.Index) + $tokenText + $text.Substring($m.Index + $m.Length)

      [void]$events.Add([ordered]@{
        category     = [string]$entry.category
        position     = $position
        surface_form = [string]$sf
        token        = [string]$entry.token
      })
      $position++
    }
  }
}

$out = [ordered]@{
  created_utc    = [string]$msg.created_utc
  dictionary_ref = [string]$dict.dictionary_id
  message_id     = [string]$msg.message_id
  plaintext      = [string]$msg.plaintext
  recipients     = ConvertTo-StableObject $msg.recipients
  schema         = [string]$msg.schema
  sender         = ConvertTo-StableObject $msg.sender
  token_events   = @($events.ToArray() | Sort-Object position)
  tokenized_text = $text
}

Write-JsonCanonical $OutPath $out
Write-Host ("COURIER_LEX_TOKENIZE_OK: " + $OutPath)
