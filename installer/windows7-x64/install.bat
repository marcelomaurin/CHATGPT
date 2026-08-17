@echo off
setlocal EnableExtensions
set "ROOT_DIR=%~dp0..\.."
set "TARGET_DIR=%~1"
set "LAZBUILD=%~2"
set "PYTHON_EXE=%~dp0python\python.exe"

if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\CHATGPT-AI-Win7"

if /I not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  echo [ERRO] Este instalador requer Windows 7 x64.
  exit /b 1
)

if not exist "%PYTHON_EXE%" (
  echo [ERRO] Python 3.8 x64 empacotado nao encontrado em:
  echo        %PYTHON_EXE%
  echo [ERRO] O pacote Windows 7 deve incluir o runtime Python 3.8 local.
  exit /b 2
)

"%PYTHON_EXE%" -c "import sys; raise SystemExit(0 if sys.version_info[:2] == (3,8) and sys.maxsize > 2**32 else 1)" || (
  echo [ERRO] O runtime empacotado deve ser Python 3.8 x64.
  exit /b 3
)

"%PYTHON_EXE%" "%ROOT_DIR%\installer\common\create_runtime_ini.py" --platform windows --arch x86_64 --install-dir "%TARGET_DIR%" --lazbuild "%LAZBUILD%" || exit /b 1
"%PYTHON_EXE%" "%ROOT_DIR%\installer\common\install_suite.py" install --profile all --arch x86_64 --runtime-target "%TARGET_DIR%\runtime\openssl" --lazbuild "%LAZBUILD%" || exit /b 1
"%PYTHON_EXE%" "%ROOT_DIR%\installer\common\check_runtime.py" --profile full --install-dir "%TARGET_DIR%"
exit /b %ERRORLEVEL%
