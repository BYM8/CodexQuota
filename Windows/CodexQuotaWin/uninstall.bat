@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Process powershell -ErrorAction SilentlyContinue | Where-Object { $_.Path -like '*powershell*' } | Out-Null"
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\CodexQuotaWin.lnk" 2>nul
echo Please right-click the CodexQuotaWin tray icon and choose Exit if it is still running.
echo You may remove this folder after exit:
echo %LOCALAPPDATA%\CodexQuotaWin
pause
