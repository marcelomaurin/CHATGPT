@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0"
set "MODE=%~1"
set "LAZBUILD=%~2"
if "%MODE%"=="" set "MODE=recommended"

if /I "%MODE%"=="help" goto :help
if /I "%MODE%"=="--help" goto :help
if /I "%MODE%"=="-h" goto :help

set "PYTHON_BIN=python"
where py.exe >nul 2>nul && set "PYTHON_BIN=py -3"

if "%LAZBUILD%"=="" (
  %PYTHON_BIN% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%"
) else (
  %PYTHON_BIN% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%" --lazbuild "%LAZBUILD%"
)
exit /b %ERRORLEVEL%

:help
echo Uso: install_components.bat [core^|recommended^|all] [caminho_lazbuild.exe]
echo Variaveis opcionais: ZEOS_ROOT, CEF4DELPHI_ROOT e GLSCENE_ROOT.
exit /b 0
