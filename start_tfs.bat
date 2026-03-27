@echo off
rem Start Forgotten Server with vcpkg DLLs in PATH
set "SCRIPT_DIR=%~dp0"
set "VCPKG_BIN=%SCRIPT_DIR%build-msvc\vcpkg_installed\x64-windows\bin"
set "PATH=%VCPKG_BIN%;%PATH%"
cd /d "%SCRIPT_DIR%"
start "tfs" /b build-msvc\tfs.exe
exit /b 0
