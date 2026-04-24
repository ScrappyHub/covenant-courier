param(
  [Parameter(Mandatory=$true)][string]$MessagePath,
  [Parameter(Mandatory=$true)][string]$DictionaryPath,
  [Parameter(Mandatory=$true)][string]$OutPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"

$msg  = Read-Json $MessagePath
$dict = Read-Json $DictionaryPath

if([string]::IsNullOrWhiteSpace([string]$msg.tokenized_text)){ throw "LEX_DECODE_FAIL:MISSING_TOKENIZED_TEXT" }

$text = [string]$msg.tokenized_text
foreach($entry in @($dict.entries)){
  $token = "[[" + [string]$entry.token + "]]"
  $meaning = [string]$entry.meaning
  $text = $text.Replace($token,$meaning)
}

$out = [ordered]@{
  decoded_text = $text
  dictionary_ref = [string]$dict.dictionary_id
  message_id = [string]$msg.message_id
  schema = "courier.lexical_decode_result.v1"
  tokenized_text = [string]$msg.tokenized_text
}

Write-JsonCanonical $OutPath $out
Write-Host ("COURIER_LEX_DECODE_OK: " + $OutPath)
