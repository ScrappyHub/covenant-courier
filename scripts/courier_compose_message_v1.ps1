param(
  [Parameter(Mandatory=$true)][string]$ComposePath,
  [Parameter(Mandatory=$true)][string]$OutPath,
  [Parameter(Mandatory=$true)][string]$RepoRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Fail([string]$Code){
  throw $Code
}

function Read-JsonStrict([string]$Path){
  if(-not (Test-Path -LiteralPath $Path)){
    Fail "COURIER_COMPOSE_FAIL:MISSING_INPUT"
  }
  try {
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop)
  }
  catch {
    Fail "COURIER_COMPOSE_FAIL:INVALID_JSON"
  }
}

function Has-Prop($Obj,[string]$Name){
  return @($Obj.PSObject.Properties.Name) -contains $Name
}

$in = Read-JsonStrict $ComposePath

if(-not (Has-Prop $in "message_id")){ Fail "COURIER_COMPOSE_FAIL:MISSING_MESSAGE_ID" }
if(-not (Has-Prop $in "created_utc")){ Fail "COURIER_COMPOSE_FAIL:MISSING_CREATED_UTC" }
if(-not (Has-Prop $in "sender")){ Fail "COURIER_COMPOSE_FAIL:MISSING_SENDER" }
if(-not (Has-Prop $in "recipients")){ Fail "COURIER_COMPOSE_FAIL:MISSING_RECIPIENTS" }
if(-not (Has-Prop $in "plaintext")){ Fail "COURIER_COMPOSE_FAIL:MISSING_PLAINTEXT" }
if(-not (Has-Prop $in "dictionary_ref")){ Fail "COURIER_COMPOSE_FAIL:MISSING_DICTIONARY_REF" }

$messageId = [string]$in.message_id
$created   = [string]$in.created_utc
$plaintext = [string]$in.plaintext
$dictRef   = [string]$in.dictionary_ref

if([string]::IsNullOrWhiteSpace($messageId)){ Fail "COURIER_COMPOSE_FAIL:MISSING_MESSAGE_ID" }
if([string]::IsNullOrWhiteSpace($created)){ Fail "COURIER_COMPOSE_FAIL:MISSING_CREATED_UTC" }
if([string]::IsNullOrWhiteSpace($plaintext)){ Fail "COURIER_COMPOSE_FAIL:MISSING_PLAINTEXT" }
if([string]::IsNullOrWhiteSpace($dictRef)){ Fail "COURIER_COMPOSE_FAIL:MISSING_DICTIONARY_REF" }
if($null -eq $in.sender){ Fail "COURIER_COMPOSE_FAIL:MISSING_SENDER" }
if($null -eq $in.recipients){ Fail "COURIER_COMPOSE_FAIL:MISSING_RECIPIENTS" }

$out = [ordered]@{
  schema         = "courier.lexical_message.v1"
  message_id     = $messageId
  created_utc    = $created
  sender         = $in.sender
  recipients     = $in.recipients
  plaintext      = $plaintext
  dictionary_ref = $dictRef
  tokenized_text = ""
  token_events   = @()
}

$json = $out | ConvertTo-Json -Depth 50 -Compress
$enc  = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($OutPath, ($json + "`n"), $enc)

Write-Host ("COURIER_COMPOSE_OK: " + $OutPath)
exit 0
