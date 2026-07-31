@echo off
setlocal
cd /d "%~dp0"
echo Starting CodexQuotaWin...
echo.
echo This package does not use hidden startup, network download, or execution policy bypass.
echo You can close this window after the tray icon appears.
echo.
powershell.exe -NoProfile -File "%~dp0CodexQuotaWin.ps1"
pause
