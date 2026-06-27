@echo off
setlocal enabledelayedexpansion

set BASE=D:\projetos\maurinsoft\CHATGPT\runtime\chromium\windows\win32
set EXTRACT=%BASE%\extract
set BIN=%BASE%\bin

if exist "%BIN%" rmdir /S /Q "%BIN%"
mkdir "%BIN%"

set CEFROOT=

for /d %%d in ("%EXTRACT%\cef_binary_90.5.4*windows32*") do (
  set CEFROOT=%%d
)

if "%CEFROOT%"=="" (
  echo ERRO: Pasta cef_binary_90.5.4*windows32* nao encontrada em:
  echo %EXTRACT%
  exit /b 1
)

echo CEF encontrado em:
echo %CEFROOT%
echo.

if not exist "%CEFROOT%\Release" (
  echo ERRO: Pasta Release nao encontrada.
  exit /b 1
)

if not exist "%CEFROOT%\Resources" (
  echo ERRO: Pasta Resources nao encontrada.
  exit /b 1
)

echo Copiando Release...
xcopy "%CEFROOT%\Release\*" "%BIN%\" /E /I /Y

echo Copiando Resources...
xcopy "%CEFROOT%\Resources\*" "%BIN%\" /E /I /Y

echo.
echo Garantindo pasta swiftshader...
if not exist "%BIN%\swiftshader" mkdir "%BIN%\swiftshader"

if exist "%BIN%\libEGL.dll" (
  copy "%BIN%\libEGL.dll" "%BIN%\swiftshader\libEGL.dll" /Y
)

if exist "%BIN%\libGLESv2.dll" (
  copy "%BIN%\libGLESv2.dll" "%BIN%\swiftshader\libGLESv2.dll" /Y
)

echo.
echo Instalacao concluida em:
echo %BIN%
exit /b 0
