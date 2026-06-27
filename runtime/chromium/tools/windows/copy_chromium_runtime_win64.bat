@echo off
set "TARGET=%~1"
if "%TARGET%"=="" (
    echo Uso: copy_chromium_runtime_win64.bat "D:\caminho\do\sample\bin"
    exit /b 1
)
if not exist "%TARGET%" mkdir "%TARGET%"
xcopy /E /Y /I "%~dp0..\..\windows\win64\bin\*" "%TARGET%"
echo Runtime Windows 64 bits copiado para %TARGET%
