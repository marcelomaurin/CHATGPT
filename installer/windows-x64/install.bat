@echo off
setlocal EnableExtensions
set "ROOT_DIR=%~dp0..\.."
set "TARGET_DIR=%~1"
set "LAZBUILD=%~2"
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\CHATGPT-AI"

if /I not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  echo [ERRO] Este instalador requer Windows x64.
  exit /b 1
)

python "%ROOT_DIR%\installer\common\create_runtime_ini.py" --platform windows --arch x86_64 --install-dir "%TARGET_DIR%" --lazbuild "%LAZBUILD%" || exit /b 1
python "%ROOT_DIR%\installer\common\install_suite.py" install --profile all --runtime-target "%TARGET_DIR%\runtime\openssl" --lazbuild "%LAZBUILD%" || exit /b 1
python "%ROOT_DIR%\installer\common\check_runtime.py" --profile full --install-dir "%TARGET_DIR%"
exit /b %ERRORLEVEL%
