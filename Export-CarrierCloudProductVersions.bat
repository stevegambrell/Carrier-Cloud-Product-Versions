@echo off
setlocal
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Export-CarrierCloudProductVersions.ps1" %*
if errorlevel 1 (
    echo Export failed.
    exit /b 1
)
echo Export completed.
endlocal
