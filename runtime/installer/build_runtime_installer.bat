@echo off
setlocal
set "LAZBUILD="
where lazbuild.exe >nul 2>nul
if %errorlevel%==0 for /f "delims=" %%I in ('where lazbuild.exe') do set "LAZBUILD=%%I"
if not defined LAZBUILD if exist C:\lazarus\lazbuild.exe set "LAZBUILD=C:\lazarus\lazbuild.exe"
if not defined LAZBUILD (
  echo lazbuild.exe nao encontrado.
  exit /b 1
)
set "MODE=%~1"
if "%MODE%"=="" set "MODE=Release64"
"%LAZBUILD%" --build-mode=%MODE% runtime_installer.lpi
exit /b %errorlevel%
