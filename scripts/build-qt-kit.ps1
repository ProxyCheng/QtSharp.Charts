param(
    [string]$QtVersion = '6.11.0',
    [string]$Dest = '',
    [switch]$Force
)
# Fetches the Qt pieces this repository needs, on a machine with nothing Qt installed: qtbase and
# qtsvg (the module's headers include QtWidgets, and the glue links QtWidgets/Gui/Core) and the
# QtCharts addon. QtSharp's own tools/build-qt-kit.ps1 does the same for the core binding; this is
# the trimmed copy that keeps this repository self-contained.
#
# It prints QT_DIR and QT_RUNTIME_DIR, and (under GitHub Actions) exports them for the next steps.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location -LiteralPath $root
if (-not $Dest) { $Dest = Join-Path $root 'out\qt-kit' }

$sevenZip = $null
foreach ($candidate in @("$env:ProgramFiles\7-Zip\7z.exe", "${env:ProgramFiles(x86)}\7-Zip\7z.exe")) {
    if (Test-Path -LiteralPath $candidate) { $sevenZip = $candidate }
}
if (-not $sevenZip) { $sevenZip = (Get-Command 7z -ErrorAction SilentlyContinue).Source }
if (-not $sevenZip) { throw '7-Zip was not found. Install it, or point QT_DIR at a kit yourself.' }

$short = $QtVersion.Replace('.', '')
$base = "https://download.qt.io/online/qtsdkrepository/windows_x86/desktop/qt6_$short/qt6_${short}_msvc2022_64"
$sources = @(
    @{ Dir = "$base/qt.qt6.$short.win64_msvc2022_64"; Prefixes = @('qtbase', 'qtsvg') },
    @{ Dir = "$base/qt.qt6.$short.addons.qtcharts.win64_msvc2022_64"; Prefixes = @('qtcharts') }
)

function Get-RemoteFile([string]$Url, [string]$OutFile) {
    & curl.exe -fsSL --ssl-no-revoke --retry 3 --retry-delay 5 -o $OutFile $Url 2>$null
    if ($LASTEXITCODE -eq 0) { return }
    $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 300
    $content = $response.Content
    if ($content -is [byte[]]) { [System.IO.File]::WriteAllBytes($OutFile, $content) }
    else { [System.IO.File]::WriteAllText($OutFile, [string]$content) }
}

$cache = Join-Path $root 'out\qt-cache'
New-Item -ItemType Directory -Path $cache -Force | Out-Null
New-Item -ItemType Directory -Path $Dest -Force | Out-Null

foreach ($source in $sources) {
    Write-Host "listing $($source.Dir)"
    $listingFile = Join-Path $cache ("listing-" + ($source.Dir -replace '[^A-Za-z0-9]', '_') + '.html')
    Get-RemoteFile "$($source.Dir)/" $listingFile
    $listing = Get-Content -LiteralPath $listingFile -Raw
    foreach ($pkg in $source.Prefixes) {
        $match = [regex]::Match($listing, "href=`"([^`"]*$pkg-[^`"]*-X86_64\.7z)`"")
        if (-not $match.Success) { throw "No $pkg archive is published under $($source.Dir)." }
        $name = $match.Groups[1].Value
        $file = Join-Path $cache $name
        if ($Force -or -not (Test-Path -LiteralPath $file)) {
            Write-Host "downloading $name"
            Get-RemoteFile "$($source.Dir)/$name" $file
        }
        Write-Host "extracting $name"
        & $sevenZip x $file "-o$Dest" -y -bso0 -bsp0
        if ($LASTEXITCODE -ne 0) { throw "Extraction failed: $name" }
    }
}

$qobject = Get-ChildItem -Path $Dest -Recurse -Filter 'qobject.h' -File |
    Where-Object { $_.FullName.Replace('\', '/') -like '*/include/QtCore/qobject.h' } | Select-Object -First 1
if (-not $qobject) { throw "The extracted archives do not contain include\QtCore\qobject.h under $Dest." }
$kit = $qobject.Directory.Parent.Parent.FullName

if (-not (Test-Path -LiteralPath (Join-Path $kit 'include\QtCharts\qchart.h'))) {
    $chart = Get-ChildItem -Path $Dest -Recurse -Filter 'qchart.h' -File |
        Where-Object { $_.FullName.Replace('\', '/') -like '*/include/QtCharts/qchart.h' } | Select-Object -First 1
    if (-not $chart) { throw 'The QtCharts archive did not provide include\QtCharts\qchart.h.' }
    $chartsRoot = $chart.Directory.Parent.Parent.FullName
    Copy-Item (Join-Path $chartsRoot 'include\QtCharts') (Join-Path $kit 'include') -Recurse -Force
    Get-ChildItem (Join-Path $chartsRoot 'lib') -Filter 'Qt6Charts*' -File -ErrorAction SilentlyContinue |
        ForEach-Object { Copy-Item $_.FullName (Join-Path $kit 'lib') -Force }
    Get-ChildItem (Join-Path $chartsRoot 'bin') -Filter 'Qt6Charts.dll' -File -ErrorAction SilentlyContinue |
        ForEach-Object { Copy-Item $_.FullName (Join-Path $kit 'bin') -Force }
}

# The DLLs a built test needs at run time: the three core modules plus Charts, and the plugin.
$runtime = Join-Path $root 'out\qt-runtime'
New-Item -ItemType Directory -Path $runtime -Force | Out-Null
foreach ($module in @('Qt6Core', 'Qt6Gui', 'Qt6Widgets', 'Qt6Svg', 'Qt6Network', 'Qt6Charts')) {
    $dll = Join-Path $kit "bin\$module.dll"
    if (Test-Path -LiteralPath $dll) { Copy-Item -LiteralPath $dll -Destination $runtime -Force }
}
Get-ChildItem (Join-Path $kit 'bin') -Filter 'msvcp140*.dll' -File -ErrorAction SilentlyContinue |
    ForEach-Object { Copy-Item $_.FullName $runtime -Force }
Get-ChildItem (Join-Path $kit 'bin') -Filter 'vcruntime140*.dll' -File -ErrorAction SilentlyContinue |
    ForEach-Object { Copy-Item $_.FullName $runtime -Force }
$plugin = Get-ChildItem -Path $kit -Recurse -Filter 'qwindows.dll' -File | Select-Object -First 1
if (-not $plugin) { throw 'qwindows.dll was not found - the tests cannot show a window without it.' }
New-Item -ItemType Directory -Path (Join-Path $runtime 'platforms') -Force | Out-Null
Copy-Item -LiteralPath $plugin.FullName -Destination (Join-Path $runtime 'platforms') -Force

Write-Host "QT_DIR=$kit"
Write-Host "QT_RUNTIME_DIR=$runtime"
if ($env:GITHUB_ENV) {
    "QT_DIR=$kit" >> $env:GITHUB_ENV
    "QT_RUNTIME_DIR=$runtime" >> $env:GITHUB_ENV
}
