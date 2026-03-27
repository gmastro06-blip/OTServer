<#
import_legacy.ps1

Copia el volcado legacy al directorio `migrations/legacy` y, opcionalmente,
lo importa en la base de datos MySQL.

Uso (desde la raíz del repo):
  .\migrations\legacy\import_legacy.ps1 -RunImport -DbName forgottenserver -DbUser root

Opciones:
  -Source    Ruta al volcado original (por defecto: ..\..\TFS 1.2_10_95_rl_map_cam\servidor.sql)
  -Destination Ruta destino (por defecto: .\servidor_from_TFS.sql dentro de este directorio)
  -RunImport Ejecuta el comando de importación tras copiar (pedirá contraseña)

Nota: El script usa `mysql --default-character-set=latin1` para preservar la
codificación original. Recomendado ejecutar primero en entorno de desarrollo.
#>

param(
    [string]$Source = "..\..\TFS 1.2_10_95_rl_map_cam\servidor.sql",
    [string]$Destination = "$PSScriptRoot\servidor_from_TFS.sql",
    [switch]$RunImport,
    [string]$DbName = "forgottenserver",
    [string]$DbUser = "root",
    [string]$DbHost = "localhost",
    [int]$DbPort = 3306
)

Write-Host "Resolving source path: $Source"
$resolved = Resolve-Path -Path $Source -ErrorAction SilentlyContinue
if (-not $resolved) {
    Write-Error "Origen no encontrado: $Source. Sitúate en la raíz del repo o pasa -Source con la ruta correcta."
    exit 1
}

Write-Host "Copiando $($resolved) -> $Destination"
Copy-Item -Path $resolved -Destination $Destination -Force
Write-Host "Copia completada. Archivo en: $Destination"

if ($RunImport) {
    $secure = Read-Host -AsSecureString "Introduce la contraseña MySQL para $DbUser@$DbHost"
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    $plain = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    try {
        $mysqlCmd = "mysql --default-character-set=latin1 -h $DbHost -P $DbPort -u $DbUser -p$plain $DbName < `"$Destination`""
        Write-Host "Ejecutando importación (esto llamará a cmd.exe para soportar redirección):"
        Write-Host $mysqlCmd
        cmd.exe /c $mysqlCmd
    } catch {
        Write-Error "Error durante la importación: $_"
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
        $plain = $null
    }
    Write-Host "Importación finalizada (revisar mensajes anteriores)."
} else {
    Write-Host "Si deseas importar ahora, vuelve a ejecutar con -RunImport -DbName <db> -DbUser <user>."
}
