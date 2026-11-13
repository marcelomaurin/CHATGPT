@echo off
chcp 65001 >nul
title Compilador NeuroGraph Player (Lazarus)
cd /d "%~dp0"

echo =================================================================
echo        COMPILANDO NEUROGRAPH PLAYER VIA LAZBUILD (LAZARUS)
echo =================================================================

if exist "C:\lazarus\lazbuild.exe" (
    set LAZBUILD="C:\lazarus\lazbuild.exe"
) else (
    set LAZBUILD=lazbuild
)

%LAZBUILD% --build-all neurograph_player.lpi

if %ERRORLEVEL% equ 0 (
    echo.
    echo [SUCESSO] Aplicativo compilado: neurograph_player.exe
) else (
    echo.
    echo [ERRO] Falha na compilacao com lazbuild.
)
pause
