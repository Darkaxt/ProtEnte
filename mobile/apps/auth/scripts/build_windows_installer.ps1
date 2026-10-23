# Compatibility entry point for the fork's Windows packaging recipe.
param(
    [Parameter(Mandatory = $true)][string] $SourceDir,
    [Parameter(Mandatory = $true)][string] $InstallerPath
)
$ErrorActionPreference = 'Stop'
& (Join-Path $PSScriptRoot '../../../../protente/build-installer.ps1') -SourceDir $SourceDir -InstallerPath $InstallerPath
