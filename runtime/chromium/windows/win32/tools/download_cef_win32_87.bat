@echo off
setlocal

set BASE=D:\projetos\maurinsoft\CHATGPT\runtime\chromium\windows\win32
set DOWNLOAD_DIR=%BASE%\downloads
set URL=https://cef-builds.spotifycdn.com/cef_binary_87.1.13%%2Bg481a82a%%2Bchromium-87.0.4280.141_windows32.tar.bz2
set OUT=%DOWNLOAD_DIR%\cef_binary_87.1.13_windows32.tar.bz2

if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%"

echo Baixando CEF Windows 32 bits...
echo URL:
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
