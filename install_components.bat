@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT_DIR=%~dp0"
set "MODE=%~1"
set "LAZBUILD=%~2"
if "%MODE%"=="" set "MODE=recommended"

if /I "%MODE%"=="help" goto :help
if /I "%MODE%"=="--help" goto :help
if /I "%MODE%"=="-h" goto :help

set "PYTHON_BIN="
set "PYTHON_ARGS="

if not "%PYTHON_EXE%"=="" (
  set "PYTHON_BIN=%PYTHON_EXE%"
  goto :validate_python
)

where py.exe >nul 2>nul
if not errorlevel 1 (
  set "PYTHON_BIN=py"
  set "PYTHON_ARGS=-3"
  goto :validate_python
)

where python3.exe >nul 2>nul
if not errorlevel 1 (
  set "PYTHON_BIN=python3"
  goto :validate_python
)

where python.exe >nul 2>nul
if not errorlevel 1 (
  set "PYTHON_BIN=python"
  goto :validate_python
)

echo [ERRO] Python 3 nao foi encontrado.
echo        Instale Python 3.8 ou superior ou defina PYTHON_EXE.
exit /b 1

:validate_python
"%PYTHON_BIN%" %PYTHON_ARGS% -c "import sys; sys.exit(0 if sys.version_info >= (3,8) else 1)" >nul 2>nul
if errorlevel 1 (
  echo [ERRO] O interpretador selecionado nao e Python 3.8 ou superior.
  echo        Executavel: %PYTHON_BIN% %PYTHON_ARGS%
  echo        Defina PYTHON_EXE apontando para um Python 3.8+ valido.
  exit /b 1
)

for /f "delims=" %%V in ('"%PYTHON_BIN%" %PYTHON_ARGS% -c "import sys; print(sys.version.split()[0])"') do set "PYTHON_VERSION=%%V"
echo [OK] Python !PYTHON_VERSION!: %PYTHON_BIN% %PYTHON_ARGS%

if "%LAZBUILD%"=="" (
  "%PYTHON_BIN%" %PYTHON_ARGS% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%"
) else (
  "%PYTHON_BIN%" %PYTHON_ARGS% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%" --lazbuild "%LAZBUILD%"
)
exit /b %ERRORLEVEL%

:help
echo Uso: install_components.bat [core^|recommended^|all] [caminho_lazbuild.exe]
echo Requisito: Python 3.8 ou superior.
echo Variaveis opcionais: PYTHON_EXE, ZEOS_ROOT, DCPCRYPT_ROOT, CEF4DELPHI_ROOT e GLSCENE_ROOT.
exit /b 0
