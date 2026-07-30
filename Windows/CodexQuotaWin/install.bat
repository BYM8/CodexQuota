@echo off
setlocal
set "APPDIR=%LOCALAPPDATA%\CodexQuotaWin"
mkdir "%APPDIR%" 2>nul
copy /Y "%~dp0CodexQuotaWin.ps1" "%APPDIR%\CodexQuotaWin.ps1" >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Startup')+'\CodexQuotaWin.lnk'); $s.TargetPath='powershell.exe'; $s.Arguments='-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""%LOCALAPPDATA%\CodexQuotaWin\CodexQuotaWin.ps1""'; $s.WorkingDirectory='%LOCALAPPDATA%\CodexQuotaWin'; $s.Save()"
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%APPDIR%\CodexQuotaWin.ps1"
echo CodexQuotaWin installed.
pause
