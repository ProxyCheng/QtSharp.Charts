param(
    [string]$Version = '0.1.0',
    [string]$Source = ''
)
# Puts the core binding's package where nuget.config looks for it (packages\).
#
# QtSharp.Api is not on nuget.org - every QtSharp release publishes it as a GitHub Release asset - so
# a fresh clone runs this before it can restore:
#
#   powershell -File scripts\Fetch-Core.ps1            # download it from the release
#   powershell -File scripts\Fetch-Core.ps1 -Source D:\QtSharp\out\packages   # from a local build
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$packages = Join-Path $root 'packages'
New-Item -ItemType Directory -Path $packages -Force | Out-Null

$file = Join-Path $packages "QtSharp.Api.$Version.nupkg"
if (Test-Path -LiteralPath $file) {
    Write-Host "already there: $file"
    exit 0
}

if ($Source) {
    $from = Join-Path $Source "QtSharp.Api.$Version.nupkg"
    if (-not (Test-Path -LiteralPath $from)) { throw "'$from' does not exist." }
    Copy-Item -LiteralPath $from -Destination $file
    Write-Host "copied $from"
    exit 0
}

$url = "https://github.com/ProxyCheng/QtSharp/releases/download/v$Version/QtSharp.Api.$Version.nupkg"
Write-Host "downloading $url"
& curl.exe -fsSL --ssl-no-revoke --retry 3 -o $file $url
if ($LASTEXITCODE -ne 0) {
    throw "The download failed. Pass -Source <a folder holding QtSharp.Api.$Version.nupkg> instead."
}
Write-Host "wrote $file"
