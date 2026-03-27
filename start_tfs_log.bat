@echo off
rem Start Forgotten Server and redirect stdout/stderr to tfs.log
set "SCRIPT_DIR=%~dp0"
set "VCPKG_BIN=%SCRIPT_DIR%build-msvc\vcpkg_installed\x64-windows\bin"
set "PATH=%VCPKG_BIN%;%PATH%"
cd /d "%SCRIPT_DIR%"
start "tfs" /b cmd /c "build-msvc\tfs.exe > tfs.log 2>&1"
exit /b 0
