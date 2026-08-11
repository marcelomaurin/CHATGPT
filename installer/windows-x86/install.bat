@echo off
setlocal EnableExtensions
set "ROOT_DIR=%~dp0..\.."
set "TARGET_DIR=%~1"
set "LAZBUILD=%~2"
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\CHATGPT-AI-x86"
python "%ROOT_DIR%\installer\common\create_runtime_ini.py" --platform windows --arch x86 --install-dir "%TARGET_DIR%" --lazbuild "%LAZBUILD%" || exit /b 1
python "%ROOT_DIR%\installer\common\install_suite.py" install --profile all --arch x86 --runtime-target "%TARGET_DIR%\runtime\openssl" --lazbuild "%LAZBUILD%" || exit /b 1
python "%ROOT_DIR%\installer\common\check_runtime.py" --profile full --install-dir "%TARGET_DIR%"
exit /b %ERRORLEVEL%
