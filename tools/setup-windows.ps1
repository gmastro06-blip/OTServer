<#
Setup script for Windows (PowerShell)
- Instala CMake (winget o descarga portable)
- Clona y bootstrappea vcpkg en ./vcpkg
- Instala dependencias del manifiesto con vcpkg (triplet x64-windows)
- Instala Ninja si es necesario
- Configura y compila el proyecto (Release)

Uso:
powershell -ExecutionPolicy Bypass -NoProfile -File .\tools\setup-windows.ps1
#>

param(
    [switch]$SkipVcpkg,
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
function Write-Log($s) { Write-Host "[setup] $s" }

$repoRoot = (Resolve-Path ".").Path
Write-Log "Repo root: $repoRoot"

# 1) Check for git
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "git not found. Install Git for Windows and retry."
    exit 1
}

# 2) Ensure CMake
if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Write-Log "CMake not found. Trying winget..."
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        try { winget install --id Kitware.CMake -e --silent } catch { Write-Log "winget install failed: $_" }
    }

    if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
        Write-Log "Downloading portable CMake..."
        $cmakeVer = "3.27.6"
        $zipUrl = "https://github.com/Kitware/CMake/releases/download/v$cmakeVer/cmake-$cmakeVer-windows-x86_64.zip"
        $toolsDir = Join-Path $repoRoot ".tools"
        New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
        $zipPath = Join-Path $toolsDir "cmake.zip"
        try {
            Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
            Expand-Archive -LiteralPath $zipPath -DestinationPath $toolsDir -Force
            $cmakeExtractDir = Get-ChildItem -Directory $toolsDir | Where-Object { $_.Name -match '^cmake-\d' } | Select-Object -First 1
            $cmakeBin = Join-Path $cmakeExtractDir.FullName "bin"
            $env:PATH = "$cmakeBin;$env:PATH"
            Write-Log "Added $cmakeBin to PATH for this session."
        } catch {
            Write-Error "Automatic CMake download failed: $_"
            exit 1
        }
    }
}
Write-Log "CMake: $(Get-Command cmake).Path"

# 3) vcpkg
if (-not $SkipVcpkg) {
    $vcpkgRoot = Join-Path $repoRoot "vcpkg"
    if (-not (Test-Path (Join-Path $vcpkgRoot "vcpkg.exe"))) {
        Write-Log "Cloning vcpkg into $vcpkgRoot"
        git clone https://github.com/microsoft/vcpkg.git $vcpkgRoot
        pushd $vcpkgRoot
        Write-Log "Bootstrapping vcpkg..."
        & .\bootstrap-vcpkg.bat
        popd
    } else {
        Write-Log "vcpkg already present at $vcpkgRoot"
    }
    $env:VCPKG_ROOT = $vcpkgRoot
    Write-Log "VCPKG_ROOT set to $env:VCPKG_ROOT"
    try { setx VCPKG_ROOT $vcpkgRoot | Out-Null } catch {}
    $vcpkgExe = Join-Path $vcpkgRoot "vcpkg.exe"
    $triplet = "x64-windows"
    Write-Log "Installing manifest dependencies (triplet: $triplet)..."
    & $vcpkgExe install --triplet $triplet
}

# 4) Ensure generator
$generator = $null
Write-Log "Detecting build generator..."
# check vswhere
$vswherePath = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
if (Test-Path $vswherePath) {
    $vs = & $vswherePath -latest -products * -requires Microsoft.Component.MSBuild -property installationVersion 2>$null
    if ($vs) { $generator = "Visual Studio 17 2022" }
}
if (-not $generator -and (Get-Command vswhere -ErrorAction SilentlyContinue)) {
    $vs = & vswhere -latest -products * -requires Microsoft.Component.MSBuild -property installationVersion 2>$null
    if ($vs) { $generator = "Visual Studio 17 2022" }
}
if (-not $generator) {
    if (Get-Command ninja -ErrorAction SilentlyContinue) {
        $generator = "Ninja Multi-Config"
    } else {
        Write-Log "Ninja not found. Trying to install via winget or vcpkg..."
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            try { winget install --id Kitware.Ninja -e --silent } catch { Write-Log "winget ninja failed: $_" }
        }
        if (-not (Get-Command ninja -ErrorAction SilentlyContinue) -and (Test-Path $vcpkgExe)) {
            Write-Log "Installing ninja with vcpkg..."
            & $vcpkgExe install --triplet $triplet ninja
            $ninjaToolPath = Join-Path $vcpkgRoot "installed\$triplet\tools\ninja"
            if (Test-Path $ninjaToolPath) {
                $env:PATH = "$ninjaToolPath;$env:PATH"
            }
        }
        if (Get-Command ninja -ErrorAction SilentlyContinue) { $generator = "Ninja Multi-Config" }
    }
}
if (-not $generator) {
    Write-Log "Falling back to Visual Studio generator 'Visual Studio 17 2022'."
    $generator = "Visual Studio 17 2022"
}
Write-Log "Selected generator: $generator"

# 5) Configure
$buildDir = Join-Path $repoRoot "build"
if ($generator -eq "Ninja Multi-Config") {
    & cmake -S $repoRoot -B $buildDir -G "Ninja Multi-Config" -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake"
} else {
    & cmake -S $repoRoot -B $buildDir -G "Visual Studio 17 2022" -A x64 -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT\scripts\buildsystems\vcpkg.cmake"
}
if ($LASTEXITCODE -ne 0) { Write-Error "CMake configure failed"; exit $LASTEXITCODE }

if (-not $SkipBuild) {
    Write-Log "Building project..."
    & cmake --build $buildDir --config Release
    if ($LASTEXITCODE -ne 0) { Write-Error "Build failed"; exit $LASTEXITCODE }
    Write-Log "Build completed successfully."
}

Write-Host "Done."