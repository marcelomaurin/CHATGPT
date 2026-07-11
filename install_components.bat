@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem ============================================================
rem TCHATGPT - Lazarus package installer for Windows
rem Author: Marcelo Maurin Martins
rem Repository: https://github.com/marcelomaurin/CHATGPT
rem ============================================================

set "ROOT_DIR=%~dp0"
set "LAZBUILD="
set "MODE=recommended"
set "FAILED=0"

if not "%~1"=="" set "MODE=%~1"
if not "%~2"=="" set "LAZBUILD=%~2"

if /I "%MODE%"=="/h" goto :help
if /I "%MODE%"=="-h" goto :help
if /I "%MODE%"=="--help" goto :help
if /I "%MODE%"=="help" goto :help

call :find_lazbuild
if not exist "%LAZBUILD%" (
  echo.
  echo [ERROR] lazbuild.exe was not found.
  echo.
  echo Usage examples:
  echo   install_components.bat
  echo   install_components.bat core
  echo   install_components.bat all
  echo   install_components.bat recommended "C:\lazarus\lazbuild.exe"
  echo.
  exit /b 1
)

echo.
echo ============================================================
echo TCHATGPT - Component installer for Lazarus / Windows
echo ============================================================
echo Repository path: %ROOT_DIR%
echo lazbuild:       %LAZBUILD%
echo Mode:           %MODE%
echo ============================================================
echo.

echo Building AI Project icons...
if exist "C:\lazarus\tools\lazres.exe" (
  "C:\lazarus\tools\lazres.exe" "%ROOT_DIR%pacote\AI Project\aiproject_icon.lrs" "%ROOT_DIR%pacote\AI Project\TAIProject.png" "%ROOT_DIR%pacote\AI Project\TAIProjectLLMConfig.png" "%ROOT_DIR%pacote\AI Project\TAIProjectStorage.png"
)
echo.

if /I "%MODE%"=="core" (
  call :install_package "pacote\packages\openai_core.lpk"
  goto :finish
)

if /I "%MODE%"=="recommended" (
  call :install_recommended
  goto :finish
)

if /I "%MODE%"=="all" (
  call :install_all
  goto :finish
)

echo [ERROR] Invalid mode: %MODE%
echo.
goto :help

:find_lazbuild
if not "%LAZBUILD%"=="" goto :eof

where lazbuild.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  for /f "delims=" %%I in ('where lazbuild.exe') do (
    set "LAZBUILD=%%I"
    goto :eof
  )
)

if exist "C:\lazarus\lazbuild.exe" set "LAZBUILD=C:\lazarus\lazbuild.exe" & goto :eof
if exist "C:\Lazarus\lazbuild.exe" set "LAZBUILD=C:\Lazarus\lazbuild.exe" & goto :eof
if exist "C:\Program Files\Lazarus\lazbuild.exe" set "LAZBUILD=C:\Program Files\Lazarus\lazbuild.exe" & goto :eof
if exist "C:\Program Files (x86)\Lazarus\lazbuild.exe" set "LAZBUILD=C:\Program Files (x86)\Lazarus\lazbuild.exe" & goto :eof
goto :eof

:install_recommended
call :install_package "pacote\packages\openai_core.lpk"
call :install_package "pacote\packages\openai_python.lpk"
call :install_package "pacote\packages\openai_ml.lpk"
call :install_package "pacote\packages\openai_graph.lpk"
call :install_package "pacote\packages\openai_output.lpk"
call :install_package "pacote\packages\openai_input.lpk"
call :install_package "pacote\packages\openai_hardware.lpk"
call :install_package "pacote\packages\openai_image.lpk"
call :install_package "pacote\packages\openai_simulation.lpk"
call :install_package "pacote\packages\openai_files.lpk"
call :install_package "pacote\packages\openai_aidbase.lpk"
call :install_package "pacote\packages\openai_project.lpk"
goto :eof

:install_all
call :install_package "pacote\packages\openai_core.lpk"
call :install_package "pacote\packages\openai_python.lpk"
call :install_package "pacote\packages\openai_ml.lpk"
call :install_package "pacote\packages\openai_graph.lpk"
call :install_package "pacote\packages\openai_input.lpk"
call :install_package "pacote\packages\openai_output.lpk"
call :install_package "pacote\packages\openai_hardware.lpk"
call :install_package "pacote\packages\openai_vision.lpk"
call :install_package "pacote\packages\openai_image.lpk"
call :install_package "pacote\packages\openai_voice.lpk"
call :install_package "pacote\packages\openai_industrial.lpk"
call :install_package "pacote\packages\openai_graphic.lpk"
call :install_package "pacote\packages\openai_simulation.lpk"
call :install_package "pacote\packages\openai_files.lpk"
call :install_package "pacote\packages\openai_aidbase.lpk"
call :install_package "pacote\packages\openai_project.lpk"
goto :eof

:install_package
set "PKG_REL=%~1"
set "PKG=%ROOT_DIR%%PKG_REL%"

if not exist "%PKG%" (
  echo [WARN] Package not found: %PKG_REL%
  set "FAILED=1"
  goto :eof
)

echo.
echo ------------------------------------------------------------
echo Installing package: %PKG_REL%
echo ------------------------------------------------------------
"%LAZBUILD%" --add-package "%PKG%"
if errorlevel 1 (
  echo [ERROR] Failed to install: %PKG_REL%
  set "FAILED=1"
) else (
  echo [OK] Installed: %PKG_REL%
)
goto :eof

:finish
echo.
echo ============================================================
if "%FAILED%"=="0" (
  echo Installation commands finished successfully.
  echo.
  echo ------------------------------------------------------------
  echo Rebuilding Lazarus IDE with installed packages...
  echo ------------------------------------------------------------
  "%LAZBUILD%" --build-ide=
  if errorlevel 1 (
    echo [ERROR] Lazarus IDE rebuild failed. Open Lazarus and rebuild manually.
    exit /b 1
  ) else (
    echo [OK] Lazarus IDE rebuilt successfully.
  )
) else (
  echo Installation finished with warnings or errors.
  echo Review the messages above before using the components.
)
echo ============================================================
exit /b %FAILED%

:help
echo.
echo TCHATGPT - Windows component installer
echo.
echo Usage:
echo   install_components.bat [mode] [path_to_lazbuild.exe]
echo.
echo Modes:
echo   core         Installs only openai_core.lpk
echo   recommended  Installs the safest base set. Default.
echo   all          Installs all modular packages.
echo.
echo Examples:
echo   install_components.bat
echo   install_components.bat core
echo   install_components.bat all
echo   install_components.bat recommended "C:\lazarus\lazbuild.exe"
echo.
exit /b 0
