param(
    [string]$QtDir = '',
    [string]$OutDir = ''
)
# Builds the module's native glue (src/QtSharp.Charts.native.cpp) into
# out/native/QtSharp.Charts.Native.dll, links it against Qt6Charts, and copies the Qt Charts
# library beside it so the package has everything a consumer needs.
#
#   powershell -File build-native.ps1
#
# QT_DIR (or -QtDir) points at a Qt kit; VCVARS / VCVARS_VER at a Visual Studio. The defaults are the
# layout the QtSharp repository uses, so a clone laid out the same way works as-is.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $root

if (-not $QtDir) { $QtDir = $env:QT_DIR }
if (-not $QtDir) { $QtDir = Join-Path $root 'Qt\6.11.0\msvc2022_64' }
if (-not $OutDir) { $OutDir = Join-Path $root 'out\native' }

$qtInc = Join-Path $QtDir 'include'
$qtLib = Join-Path $QtDir 'lib'
foreach ($needed in @("$qtInc\QtCharts\qchart.h", "$qtLib\Qt6Charts.lib")) {
    if (-not (Test-Path -LiteralPath $needed)) {
        throw "'$needed' is missing: the Qt kit needs the Charts module (include\QtCharts, lib\Qt6Charts.lib). See README."
    }
}
$source = Join-Path $root 'src\QtSharp.Charts.native.cpp'
if (-not (Test-Path -LiteralPath $source)) { throw "'$source' is missing - it is checked in." }

New-Item -ItemType Directory -Path $OutDir -Force | Out-Null

# ---- a Visual Studio environment (VCVARS overrides, otherwise probe the usual installs) ----
$vcvars = $env:VCVARS
if (-not $vcvars) {
    foreach ($base in @($env:ProgramFiles, ${env:ProgramFiles(x86)}, 'D:\Program Files', 'E:\Program Files')) {
        foreach ($vs in @('2022', '2019', '18')) {
            foreach ($edition in @('Community', 'Professional', 'Enterprise', 'BuildTools', 'Insiders', 'Preview')) {
                if ($vcvars) { continue }
                $candidate = Join-Path $base "Microsoft Visual Studio\$vs\$edition\VC\Auxiliary\Build\vcvarsall.bat"
                if (Test-Path -LiteralPath $candidate) { $vcvars = $candidate }
            }
        }
    }
}
if (-not $vcvars -or -not (Test-Path -LiteralPath $vcvars)) { throw 'vcvarsall.bat was not found. Set VCVARS. See README.' }

Write-Host "[charts] entering the Visual Studio environment from $vcvars"
$toolset = if ($env:VCVARS_VER) { "-vcvars_ver=$($env:VCVARS_VER)" } else { '' }
foreach ($line in (cmd /c "`"$vcvars`" x64 $toolset >nul 2>&1 && set")) {
    $parts = $line.Split('=', 2)
    if ($parts.Count -eq 2) { Set-Item -Path "env:$($parts[0])" -Value $parts[1] }
}

$includes = @('QtCore', 'QtGui', 'QtWidgets', 'QtCharts', 'QtNetwork', 'QtSvg', 'QtSvgWidgets',
              'QtPrintSupport', 'QtXml', 'QtOpenGLWidgets', 'QtOpenGL') | ForEach-Object { "/I$qtInc\$_" }
$versionDir = Get-ChildItem (Join-Path $qtInc 'QtCore') -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -match '^6\.' } | Select-Object -First 1
$privateIncludes = @()
if ($versionDir) { $privateIncludes = @("/I$($versionDir.FullName)", "/I$($versionDir.FullName)\QtCore") }

$out = Join-Path $OutDir 'QtSharp.Charts.Native.dll'
Write-Host "[charts] compiling $source"
& cl /nologo /LD /EHsc /permissive- /std:c++17 /Zc:__cplusplus /utf-8 `
    /DUNICODE /D_UNICODE /DQT_NO_DEBUG /MD /O2 `
    "/Fe$out" "/Fo$OutDir\" `
    $includes $privateIncludes "/I$qtInc" "/I$(Join-Path $root 'native')" `
    $source `
    "/link" "/LIBPATH:$qtLib" Qt6Charts.lib Qt6Widgets.lib Qt6Gui.lib Qt6Core.lib
if ($LASTEXITCODE -ne 0) { throw 'The native build failed.' }

# The library the glue links, so what the package ships is exactly what it was built against.
foreach ($candidate in @("$(Join-Path $QtDir 'bin')\Qt6Charts.dll", (Join-Path $root 'Qt\6.11.0\runtime\Qt6Charts.dll'))) {
    if (Test-Path -LiteralPath $candidate) {
        Copy-Item -LiteralPath $candidate -Destination $OutDir -Force
        Write-Host "[charts] copied $(Split-Path -Leaf $candidate) from $candidate"
        break
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $OutDir 'Qt6Charts.dll'))) {
    throw 'Qt6Charts.dll was not found next to the kit - the package needs it. See README.'
}

Write-Host ("[charts] wrote {0} ({1} KB)" -f $out, [math]::Round((Get-Item -LiteralPath $out).Length / 1KB, 0))
