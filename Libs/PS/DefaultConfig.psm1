# DefaultConfig.psm1

$script:ModuleRoot = $PSScriptRoot

$script:RootDir = Split-Path (Split-Path $script:ModuleRoot -Parent) -Parent


$script:Defaults = [PSCustomObject]@{
  RootDir                = $RootDir
  EnvironmentPath        = Join-Path $RootDir "Config/BaseConfig.env"
  BinaryMetadataFileName = "info.json"
}

function Get-Defaults {
  return $script:Defaults
}

Export-ModuleMember -Function Get-Defaults