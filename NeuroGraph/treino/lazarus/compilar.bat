@echo off
setlocal
title Compilando NeuroGraph Studio (Lazarus)

cd /d "%~dp0"

set "LAZBUILD="
if exist "C:\lazarus\lazbuild.exe" set "LAZBUILD=C:\lazarus\lazbuild.exe"
if exist "C:\Lazarus\lazbuild.exe" set "LAZBUILD=C:\Lazarus\lazbuild.exe"

if "%LAZBUILD%"=="" (
    where lazbuild.exe >nul 2>nul
    if %ERRORLEVEL% equ 0 set "LAZBUILD=lazbuild.exe"
)

if "%LAZBUILD%"=="" (
    echo [ERRO] lazbuild.exe nao foi encontrado em C:\lazarus nem no PATH.
    pause
    exit /b 1
)

echo Compilando neurograph_studio.lpi usando %LAZBUILD%...
"%LAZBUILD%" --build-mode=Default neurograph_studio.lpi
if errorlevel 1 (
    echo [ERRO] Falha na compilacao.
    pause
    exit /b 1
)

echo [OK] Compilacao concluida com sucesso!
echo Executavel gerado em: %~dp0neurograph_studio.exe
pause
exit /b 0
