@echo off
setlocal
set "OUTPATH=%~1"
if "%OUTPATH%"=="" set "OUTPATH=D:\Carrier-Cloud-Product-Versions.csv"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Export-CarrierCloudProductVersions.ps1" "%OUTPATH%"
if errorlevel 1 (
    echo Export failed.
    exit /b 1
)
echo Export completed.
endlocal
