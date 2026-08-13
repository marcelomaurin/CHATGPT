@echo off
setlocal EnableExtensions

set "ROOT_DIR=%~dp0"
set "MODE=%~1"
set "LAZBUILD=%~2"
if "%MODE%"=="" set "MODE=recommended"

if /I "%MODE%"=="help" goto :help
if /I "%MODE%"=="--help" goto :help
if /I "%MODE%"=="-h" goto :help

call :find_python
if errorlevel 1 exit /b 2

if "%LAZBUILD%"=="" (
  "%PYTHON_BIN%" %PYTHON_ARGS% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%"
) else (
  "%PYTHON_BIN%" %PYTHON_ARGS% "%ROOT_DIR%installer\common\install_suite.py" install --profile "%MODE%" --lazbuild "%LAZBUILD%"
)
exit /b %ERRORLEVEL%

:help
echo Uso: install_components.bat [core^|recommended^|all] [caminho_lazbuild.exe]
echo Variaveis opcionais: PYTHON_EXE, ZEOS_ROOT, CEF4DELPHI_ROOT e GLSCENE_ROOT.
exit /b 0

:find_python
set "PYTHON_BIN="
set "PYTHON_ARGS="

if defined PYTHON_EXE (
  call :try_python "%PYTHON_EXE%" ""
  if not errorlevel 1 exit /b 0
)

where py.exe >nul 2>nul
if not errorlevel 1 (
  call :try_python "py" "-3"
  if not errorlevel 1 exit /b 0
)

where python3.exe >nul 2>nul
if not errorlevel 1 (
  call :try_python "python3" ""
  if not errorlevel 1 exit /b 0
)

where python.exe >nul 2>nul
if not errorlevel 1 (
  call :try_python "python" ""
  if not errorlevel 1 exit /b 0
)

echo [ERRO] Python 3.8 ou superior nao encontrado.
echo        O instalador nao funciona com Python 2.
echo        No Windows 7 SP1, instale o Python 3.8.10 com o launcher e o PATH habilitados.
echo        Como alternativa, informe o executavel:
echo        set "PYTHON_EXE=C:\caminho\para\python.exe"
exit /b 1

:try_python
"%~1" %~2 -c "import sys; raise SystemExit(0 if sys.version_info ^>= (3, 8) else 1)" >nul 2>nul
if errorlevel 1 exit /b 1
set "PYTHON_BIN=%~1"
set "PYTHON_ARGS=%~2"
exit /b 0
