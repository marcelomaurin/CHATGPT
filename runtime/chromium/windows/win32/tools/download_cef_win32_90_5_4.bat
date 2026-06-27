@echo off
setlocal

set BASE=D:\projetos\maurinsoft\CHATGPT\runtime\chromium\windows\win32
set DOWNLOAD_DIR=%BASE%\downloads
set URL=https://cef-builds.spotifycdn.com/cef_binary_90.5.4%%2Bgc6a4331%%2Bchromium-90.0.4430.72_windows32.tar.bz2
set OUT=%DOWNLOAD_DIR%\cef_binary_90.5.4_windows32.tar.bz2

if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

echo Baixando CEF 90.5.4 Windows 32 bits...
echo %URL%
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "Invoke-WebRequest -Uri '%URL%' -OutFile '%OUT%'"

if not exist "%OUT%" (
  echo ERRO: Download nao gerou o arquivo:
  echo %OUT%
  exit /b 1
)

echo.
echo OK: Download concluido:
echo %OUT%
exit /b 0
