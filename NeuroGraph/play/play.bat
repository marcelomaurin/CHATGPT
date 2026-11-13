@echo off
chcp 65001 >nul
title NeuroGraph Player
cd /d "%~dp0"

echo =================================================================
echo             NEUROGRAPH PLAYER - REPRODUZIR MODELO
echo =================================================================
echo.

python -X utf8 -u play.py %*

if "%~1"=="" (
    pause
)
