param(
  [string]$RepoRoot = "."
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RepoRoot = (Resolve-Path $RepoRoot).Path
$Schemas = Join-Path $RepoRoot "schemas"

$Expected = @(
  "covenant_courier.message.v1.json",
  "covenant_courier.notification.v1.json",
  "covenant_courier.policy_decision.v1.json",
  "covenant_courier.product_receipt.v1.json"
)

function Require-Prop {
  param(
    [Parameter(Mandatory=$true)]$Obj,
    [Parameter(Mandatory=$true)][string]$Name,
    [Parameter(Mandatory=$true)][string]$FileName
  )

  if($Obj.PSObject.Properties.Name -notcontains $Name){
    throw ("COVENANT_COURIER_SCHEMA_TEST_FAIL:MISSING_PROP:" + $FileName + ":" + $Name)
  }
}

foreach($fileName in $Expected){
  $path = Join-Path $Schemas $fileName

  if(-not (Test-Path -LiteralPath $path -PathType Leaf)){
    throw ("COVENANT_COURIER_SCHEMA_TEST_FAIL:MISSING_SCHEMA:" + $fileName)
  }

  $raw = Get-Content -LiteralPath $path -Raw
  $schema = $raw | ConvertFrom-Json

  Require-Prop -Obj $schema -Name '$schema' -FileName $fileName
  Require-Prop -Obj $schema -Name '$id' -FileName $fileName
  Require-Prop -Obj $schema -Name 'type' -FileName $fileName
  Require-Prop -Obj $schema -Name 'required' -FileName $fileName
  Require-Prop -Obj $schema -Name 'properties' -FileName $fileName

  if([string]$schema.type -ne "object"){
    throw ("COVENANT_COURIER_SCHEMA_TEST_FAIL:TYPE_NOT_OBJECT:" + $fileName)
  }

  if($schema.PSObject.Properties.Name -contains "additionalProperties"){
    if([bool]$schema.additionalProperties -ne $false){
      throw ("COVENANT_COURIER_SCHEMA_TEST_FAIL:ADDITIONAL_PROPERTIES_NOT_FALSE:" + $fileName)
    }
  } else {
    throw ("COVENANT_COURIER_SCHEMA_TEST_FAIL:MISSING_ADDITIONAL_PROPERTIES:" + $fileName)
  }

  Write-Host ("COVENANT_COURIER_SCHEMA_OK: " + $fileName)
}

Write-Host "COVENANT_COURIER_SCHEMA_TEST_OK"
