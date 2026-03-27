<#
Instala Visual Studio Build Tools (C++ workload) silenciosamente.
Requiere ejecutar PowerShell como Administrador.
#>

$ErrorActionPreference = 'Stop'

function Write-Log($m) { Write-Host "[vs-install] $m" }

# Comprueba privilegios de administrador
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script debe ejecutarse como Administrador. Abre PowerShell como Administrador y vuelve a ejecutarlo."
    exit 2
}

$repoRoot = (Resolve-Path ".").Path
$toolsDir = Join-Path $repoRoot ".tools"
New-Item -ItemType Directory -Path $toolsDir -Force | Out-Null
$vsExe = Join-Path $toolsDir "vs_buildtools.exe"

if (-not (Test-Path $vsExe)) {
    Write-Log "Descargando Visual Studio Build Tools..."
    $url = "https://aka.ms/vs/17/release/vs_BuildTools.exe"
    Invoke-WebRequest -Uri $url -OutFile $vsExe -UseBasicParsing
}

$arguments = @(
    '--quiet',
    '--wait',
    '--norestart',
    '--nocache',
    '--add', 'Microsoft.VisualStudio.Workload.VCTools',
    '--add', 'Microsoft.Component.MSBuild',
    '--add', 'Microsoft.VisualStudio.Component.VC.Tools.x86.x64',
    '--includeRecommended'
)

Write-Log "Ejecutando instalador (esto puede tardar mucho)..."
$proc = Start-Process -FilePath $vsExe -ArgumentList $arguments -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Error "El instalador finalizó con código $($proc.ExitCode). Comprueba el instalador manualmente."
    exit $proc.ExitCode
}

Write-Log "Instalación finalizada."
Write-Host "Listo."