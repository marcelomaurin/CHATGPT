@echo off
setlocal

set BIN=D:\projetos\maurinsoft\CHATGPT\runtime\chromium\windows\win32\bin
set SWIFT=%BIN%\swiftshader

echo Validando runtime CEF 90.5.4 Windows 32 bits...
echo Pasta:
echo %BIN%
echo.

call :check_file "%BIN%\libcef.dll"
call :check_file "%BIN%\chrome_elf.dll"
call :check_file "%BIN%\icudtl.dat"
call :check_file "%BIN%\snapshot_blob.bin"
call :check_file "%BIN%\cef.pak"
call :check_file "%BIN%\cef_100_percent.pak"
call :check_file "%BIN%\cef_200_percent.pak"
call :check_file "%BIN%\resources.pak"
call :check_file "%SWIFT%\libEGL.dll"
call :check_file "%SWIFT%\libGLESv2.dll"

if not exist "%BIN%\locales" (
  echo ERRO: Pasta locales ausente:
  echo %BIN%\locales
  exit /b 1
)

echo.
echo OK: Arquivos principais encontrados.
echo ATENCAO: confirmar em execucao se a mensagem mudou para:
echo Expected libcef.dll version : 90.5.4.0
echo Found libcef.dll version    : 90.5.4.0
exit /b 0

:check_file
if not exist "%~1" (
  echo ERRO: Arquivo ausente:
  echo %~1
  exit /b 1
)
exit /b 0
