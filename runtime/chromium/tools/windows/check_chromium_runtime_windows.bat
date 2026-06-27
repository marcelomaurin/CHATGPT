@echo off
set "TARGET=%~1"
if "%TARGET%"=="" (
    echo Uso: check_chromium_runtime_windows.bat "D:\caminho\do\sample\bin"
    exit /b 1
)
if not exist "%TARGET%\libcef.dll" (
    echo [ERRO] libcef.dll ausente em %TARGET%
    exit /b 1
)
if not exist "%TARGET%\chrome_elf.dll" (
    echo [ERRO] chrome_elf.dll ausente em %TARGET%
    exit /b 1
)
echo Runtime basico validado no destino.
