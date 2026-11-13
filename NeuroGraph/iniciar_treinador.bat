@echo off
setlocal
title NeuroGraph Studio - Lazarus Desktop

cd /d "%~dp0treino"

if exist "lazarus\neurograph_studio.exe" (
    echo Iniciando interface Lazarus nativa...
    start "" "lazarus\neurograph_studio.exe"
    exit /b 0
)

echo Executavel nativo ainda nao encontrado. Compilando com lazbuild...
call "lazarus\compilar.bat"
if exist "lazarus\neurograph_studio.exe" (
    start "" "lazarus\neurograph_studio.exe"
    exit /b 0
)

pause
exit /b 1
