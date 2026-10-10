<#
.SYNOPSIS
    Builds the MinGW 13.1 x64 Release configuration of GitEase and deploys it
    (Qt DLLs, QML modules, MinGW runtime, VC++ runtime for archive.dll) into a
    self-contained, ready-to-ship folder.

    MinGW is required: the bundled libgit2, libssh2, OpenSSL, and zlib under
    Ext are MinGW static libraries. libgit2's OpenSSL is linked in, and Qt
    networking uses WinHTTP, so no OpenSSL DLLs are deployed.

.PARAMETER Zip
    Also produce a .zip archive of the deployed package.

.PARAMETER Installer
    Also build a Setup.exe (via Inno Setup) that installs the packaged app.

.EXAMPLE
    .\Scripts\Build-Release.ps1
    .\Scripts\Build-Release.ps1 -Zip
    .\Scripts\Build-Release.ps1 -Installer
#>
param(
    [switch]$Zip,
    [switch]$Installer
)

$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -Scope Global -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$RepoRoot   = Split-Path -Parent $PSScriptRoot
$BuildDir   = Join-Path $RepoRoot "build\Desktop_Qt_6_10_1_MinGW_64_bit-Release"
$QtDir      = "C:\Qt\6.10.1\mingw_64"
$MingwBin   = "C:\Qt\Tools\mingw1310_64\bin"
$PackageDir = Join-Path $RepoRoot "dist\GitEase-Release"
$TargetName = "GitEase"

$Cmake       = "C:\Qt\Tools\CMake_64\bin\cmake.exe"
$Ninja       = "C:\Qt\Tools\Ninja\ninja.exe"
$WinDeployQt = Join-Path $QtDir "bin\windeployqt.exe"
$Gxx         = Join-Path $MingwBin "g++.exe"
$Gcc         = Join-Path $MingwBin "gcc.exe"
$Windres     = Join-Path $MingwBin "windres.exe"

foreach ($tool in @($Cmake, $Ninja, $WinDeployQt, $Gxx, $Gcc, $Windres)) {
    if (-not (Test-Path $tool)) {
        throw "Required tool not found: $tool"
    }
}

# cc1plus loads libwinpthread-1.dll from PATH. Another copy (Android platform-tools)
# is the wrong image and makes the compiler exit before it prints an error.
$env:PATH = "$MingwBin;$QtDir\bin;" + $env:PATH

# 1. Configure (only if not already configured). A CMakeCache.txt left behind by
#    an interrupted configure has no build.ninja and cannot build.
$NinjaBuild = Join-Path $BuildDir "build.ninja"
if (-not (Test-Path $NinjaBuild)) {
    if (Test-Path $BuildDir) {
        Write-Host "Removing incomplete build directory..." -ForegroundColor Cyan
        Remove-Item $BuildDir -Recurse -Force
    }
    Write-Host "Configuring Release build..." -ForegroundColor Cyan
    # Forward slashes: CMake parses this cache as code, and `\Q` in a Windows path is an invalid escape.
    $QtDirFwd    = $QtDir    -replace '\\', '/'
    $NinjaFwd    = $Ninja    -replace '\\', '/'
    $GccFwd      = $Gcc      -replace '\\', '/'
    $GxxFwd      = $Gxx      -replace '\\', '/'
    $WindresFwd  = $Windres  -replace '\\', '/'
    & $Cmake -S $RepoRoot -B $BuildDir -G Ninja `
        -DCMAKE_BUILD_TYPE=Release `
        -DCMAKE_PREFIX_PATH="$QtDirFwd" `
        -DCMAKE_MAKE_PROGRAM="$NinjaFwd" `
        -DCMAKE_C_COMPILER="$GccFwd" `
        -DCMAKE_CXX_COMPILER="$GxxFwd" `
        -DCMAKE_RC_COMPILER="$WindresFwd"
    if ($LASTEXITCODE -ne 0) { throw "CMake configure failed." }
}

# 2. Build
Write-Host "Building Release ($TargetName)..." -ForegroundColor Cyan
& $Cmake --build $BuildDir --target $TargetName
if ($LASTEXITCODE -ne 0) { throw "Build failed." }

$ExePath = Join-Path $BuildDir "$TargetName.exe"
if (-not (Test-Path $ExePath)) { throw "Built executable not found: $ExePath" }

# 3. Assemble a clean deploy folder
Write-Host "Preparing package folder: $PackageDir" -ForegroundColor Cyan
if (Test-Path $PackageDir) {
    Remove-Item $PackageDir -Recurse -Force
}
New-Item -ItemType Directory -Path $PackageDir | Out-Null
Copy-Item $ExePath $PackageDir

# 4. Qt runtime + QML modules via windeployqt
Write-Host "Running windeployqt..." -ForegroundColor Cyan
& $WinDeployQt `
    --release `
    --qmldir (Join-Path $RepoRoot "Qml") `
    --no-translations `
    (Join-Path $PackageDir "$TargetName.exe")
if ($LASTEXITCODE -ne 0) { throw "windeployqt failed." }

# 5. MinGW runtime. windeployqt does not copy these unless asked, and the
#    executable imports them directly.
Write-Host "Copying MinGW runtime DLLs..." -ForegroundColor Cyan
foreach ($dll in @("libgcc_s_seh-1.dll", "libstdc++-6.dll", "libwinpthread-1.dll")) {
    Copy-Item (Join-Path $MingwBin $dll) $PackageDir
    if (-not (Test-Path (Join-Path $PackageDir $dll))) {
        throw "Failed to copy required MinGW runtime DLL: $dll"
    }
}

# 6. libarchive. The app links it dynamically; CMake only copies it next to
#    the build exe, not into this package folder.
Write-Host "Copying libarchive..." -ForegroundColor Cyan
$ArchiveDll = Join-Path $RepoRoot "Ext\libarchive\bin\archive.dll"
if (-not (Test-Path $ArchiveDll)) { throw "archive.dll not found: $ArchiveDll" }
Copy-Item $ArchiveDll $PackageDir

# 7. archive.dll is an MSVC binary (it imports VCRUNTIME140.dll), so the package
#    needs the VC++ CRT even though GitEase itself is built with MinGW.
#    Search any VS year/edition and pick the newest MSVC redist folder.
Write-Host "Copying MSVC runtime DLLs (for archive.dll)..." -ForegroundColor Cyan
$VcRedistCrtDir = Get-ChildItem "C:\Program Files\Microsoft Visual Studio\*\*\VC\Redist\MSVC\*\x64\Microsoft.VC*.CRT" -Directory -ErrorAction SilentlyContinue |
    Sort-Object { $_.Parent.Parent.Name } -Descending | Select-Object -First 1
if (-not $VcRedistCrtDir) {
    throw "Could not locate the VC++ Redistributable CRT folder (vcruntime140.dll). Install Visual Studio or the VC++ Redistributable build tools."
}
Write-Host "  from $($VcRedistCrtDir.FullName)"
Copy-Item (Join-Path $VcRedistCrtDir.FullName "*.dll") $PackageDir
foreach ($dll in @("vcruntime140.dll", "vcruntime140_1.dll", "msvcp140.dll", "msvcp140_1.dll")) {
    if (-not (Test-Path (Join-Path $PackageDir $dll))) {
        throw "Failed to copy required CRT DLL: $dll"
    }
}

# 8. Optional zip
if ($Zip) {
    $ZipPath = "$PackageDir.zip"
    Write-Host "Creating archive: $ZipPath" -ForegroundColor Cyan
    if (Test-Path $ZipPath) { Remove-Item $ZipPath -Force }
    Compress-Archive -Path (Join-Path $PackageDir "*") -DestinationPath $ZipPath
}

# 9. Optional installer
if ($Installer) {
    $IsccCandidates = @(
        "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
        "C:\Program Files\Inno Setup 6\ISCC.exe",
        (Join-Path $env:LOCALAPPDATA "Programs\Inno Setup 6\ISCC.exe")
    )
    $Iscc = $IsccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $Iscc) {
        throw "Inno Setup not found. Install it (winget install JRSoftware.InnoSetup) or adjust the path."
    }

    $Version = "0.9.0"
    $CmakeLists = Get-Content (Join-Path $RepoRoot "CMakeLists.txt") -Raw
    if ($CmakeLists -match 'project\(\s*GitEase\s+VERSION\s+([0-9.]+)') {
        $Version = $Matches[1]
    }

    Write-Host "Building installer..." -ForegroundColor Cyan
    & $Iscc "/DMyAppVersion=$Version" (Join-Path $RepoRoot "installer\GitEase.iss")
    if ($LASTEXITCODE -ne 0) { throw "Inno Setup compile failed." }
}

Write-Host ""
Write-Host "Release package ready at: $PackageDir" -ForegroundColor Green
if ($Zip) { Write-Host "Zipped archive: $PackageDir.zip" -ForegroundColor Green }
if ($Installer) { Write-Host "Installer ready at: $RepoRoot\dist\installer\" -ForegroundColor Green }
