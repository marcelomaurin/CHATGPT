@echo off
chcp 65001 > nul
echo ============================================================================
echo Compilando NeuroGraph v8 Native (100%% Free Pascal / Lazarus — Zero Python)
echo ============================================================================
C:\lazarus\lazbuild.exe --build-all "%~dp0neurograph_native.lpi"
if %ERRORLEVEL% EQU 0 (
    echo [SUCESSO] Executavel gerado em: %~dp0neurograph_native.exe
) else (
    echo [ERRO] Falha na compilacao.
)
