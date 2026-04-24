param(
  [Parameter(Mandatory=$true)][string]$DictionaryPath,
  [Parameter(Mandatory=$true)][string]$OutPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. "$PSScriptRoot\_lib_courier_v1.ps1"

$dict = Read-Json $DictionaryPath

if(-not $dict){ throw "LEX_DICT_FAIL:INVALID_JSON" }
if([string]::IsNullOrWhiteSpace([string]$dict.dictionary_id)){ throw "LEX_DICT_FAIL:MISSING_DICTIONARY_ID" }
if($null -eq $dict.entries){ throw "LEX_DICT_FAIL:MISSING_ENTRIES" }

$normalizedEntries = New-Object System.Collections.Generic.List[object]
$seenTokens = @{}
$seenForms  = @{}

foreach($entry in @($dict.entries)){
  $token = [string]$entry.token
  $category = [string]$entry.category
  $meaning = [string]$entry.meaning
  $sensitivity = [string]$entry.sensitivity

  if([string]::IsNullOrWhiteSpace($token)){ throw "LEX_DICT_FAIL:MISSING_TOKEN" }
  if([string]::IsNullOrWhiteSpace($category)){ throw "LEX_DICT_FAIL:MISSING_CATEGORY" }
  if([string]::IsNullOrWhiteSpace($meaning)){ throw "LEX_DICT_FAIL:MISSING_MEANING" }
  if($seenTokens.ContainsKey($token)){ throw ("LEX_DICT_FAIL:DUPLICATE_TOKEN:" + $token) }
  $seenTokens[$token] = $true

  $forms = New-Object System.Collections.Generic.List[string]
  foreach($f in @($entry.surface_forms)){
    $s = ([string]$f).Trim().ToLowerInvariant()
    if([string]::IsNullOrWhiteSpace($s)){ continue }
    if($seenForms.ContainsKey($s)){ throw ("LEX_DICT_FAIL:DUPLICATE_SURFACE_FORM:" + $s) }
    $seenForms[$s] = $true
    [void]$forms.Add($s)
  }

  $ctx = New-Object System.Collections.Generic.List[string]
  foreach($c in @($entry.allowed_contexts)){
    $x = ([string]$c).Trim().ToLowerInvariant()
    if([string]::IsNullOrWhiteSpace($x)){ continue }
    [void]$ctx.Add($x)
  }

  [void]$normalizedEntries.Add([ordered]@{
    allowed_contexts = @($ctx.ToArray())
    category         = $category
    meaning          = $meaning
    sensitivity      = $sensitivity
    surface_forms    = @($forms.ToArray() | Sort-Object)
    token            = $token
  })
}

$out = [ordered]@{
  dictionary_id = [string]$dict.dictionary_id
  entries       = @($normalizedEntries.ToArray() | Sort-Object token)
  schema        = [string]$dict.schema
  version       = [string]$dict.version
}

Write-JsonCanonical $OutPath $out
Write-Host ("COURIER_LEX_DICT_BUILD_OK: " + $OutPath)
