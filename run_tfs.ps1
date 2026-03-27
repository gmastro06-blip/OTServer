param(
    [int]$DbTimeoutSeconds = 60
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$VcpkgBin = Join-Path $ScriptDir "build-msvc\vcpkg_installed\x64-windows\bin"
$env:PATH = "$VcpkgBin;$env:PATH"
Push-Location $ScriptDir

# Wait for MariaDB on 127.0.0.1:3306 (optional, avoids startup race)
$deadline = (Get-Date).AddSeconds($DbTimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    try {
        $t = Test-NetConnection -ComputerName 127.0.0.1 -Port 3306 -WarningAction SilentlyContinue
        if ($t -and $t.TcpTestSucceeded) { break }
    } catch { }
    Write-Output "Waiting for DB on 127.0.0.1:3306..."
    Start-Sleep -Seconds 2
}
if ((Get-Date) -ge $deadline) { Write-Warning "Timeout waiting for DB on 127.0.0.1:3306" }

$logFile = Join-Path $ScriptDir "tfs.log"
"=== Starting tfs at $(Get-Date -Format o) ===" | Out-File -FilePath $logFile -Append

if (-Not (Test-Path "build-msvc\tfs.exe")) {
    Write-Error "build-msvc\tfs.exe not found. Build the project first (see README)."
    Pop-Location
    exit 1
}

# Run in foreground and append stdout/stderr to log (also show live output)
& .\build-msvc\tfs.exe 2>&1 | Tee-Object -FilePath $logFile

Pop-Location
