@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0"
set "MODE=%~1"
set "LAZBUILD=%~2"
if "%MODE%"=="" set "MODE=recommended"

if /I "%MODE%"=="help" goto :help
if /I "%MODE%"=="--help" goto :help
if /I "%MODE%"=="-h" goto :help

set "PYTHON_BIN=%PYTHON_EXE%"
if "%PYTHON_BIN%"=="" (
  where py.exe >nul 2>nul
  if not errorlevel 1 (
    set "PYTHON_BIN=py -3"
  ) else (
    set "PYTHON_BIN=python"
  )
)

%PYTHON_BIN% -c "import sys; sys.exit(0 if sys.version_info[0] >= 3 else 1)" >nul 2>nul
if errorlevel 1 (
  echo [ERRO] Python 3 nao foi encontrado ou o executavel atual e Python 2.
  echo        O instalador exige Python 3.6 ou superior.
  echo        Instale o Python 3 ou defina a variavel de ambiente PYTHON_EXE.
  exit /b 1
)

if "%LAZBUILD%"=="" (
  %PYTHON_BIN% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%"
) else (
  %PYTHON_BIN% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%" --lazbuild "%LAZBUILD%"
)
exit /b %ERRORLEVEL%

:help
echo Uso: install_components.bat [core^|recommended^|all] [caminho_lazbuild.exe]
echo Variaveis opcionais: PYTHON_EXE, ZEOS_ROOT, CEF4DELPHI_ROOT e GLSCENE_ROOT.
exit /b 0
