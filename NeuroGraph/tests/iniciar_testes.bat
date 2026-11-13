@echo off
chcp 65001 >nul
title NeuroGraph Tester — Aferidor de Respostas
cd /d "%~dp0"

if exist "lazarus\neurograph_tester.exe" (
    start "" "lazarus\neurograph_tester.exe"
) else (
    python -X utf8 -u avaliador_qa.py %*
    pause
)
