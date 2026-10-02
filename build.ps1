<#
  Builds a self-contained release and the Inno Setup installer.
  Usage:  .\build.ps1                 # version from src\MCAL\MCAL.csproj
          .\build.ps1 -Version 0.5.0  # override (the release workflow passes the tag)
  Output: artifacts\MCAL-Setup-<version>.exe
#>
param([string]$Version)
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$proj = Join-Path $root 'src\MCAL\MCAL.csproj'
if (-not $Version) {
    $Version = [regex]::Match((Get-Content $proj -Raw), '<Version>(.+?)</Version>').Groups[1].Value
}

$artifacts = Join-Path $root 'artifacts'
$publish = Join-Path $artifacts 'publish'
if (Test-Path $publish) { Remove-Item $publish -Recurse -Force }

dotnet publish $proj -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true `
    -p:DebugType=none -p:Version=$Version -o $publish
if ($LASTEXITCODE) { throw 'dotnet publish failed' }

$iscc = @(
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $iscc) { throw 'Inno Setup 6 not found (winget install JRSoftware.InnoSetup)' }

& $iscc /Q "/DAppVersion=$Version" "/DPublishDir=$publish" "/O$artifacts" (Join-Path $root 'installer\MCAL.iss')
if ($LASTEXITCODE) { throw 'Inno Setup compile failed' }

Get-Item (Join-Path $artifacts "MCAL-Setup-$Version.exe")
