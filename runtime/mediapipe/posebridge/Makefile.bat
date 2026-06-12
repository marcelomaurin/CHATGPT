@echo off
setlocal EnableExtensions EnableDelayedExpansion

echo ============================================================
echo Building MediaPipe Pose Bridge DLLs for Windows x86 and x64
echo ============================================================

set "FPC="
where fpc.exe >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  for /f "delims=" %%I in ('where fpc.exe') do (
    set "FPC=%%I"
  )
)

if "%FPC%"=="" (
  if exist "C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe" (
    set "FPC=C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe"
  )
)

if "%FPC%"=="" (
  echo [ERROR] fpc.exe compiler was not found. Please install Lazarus/FPC or add it to PATH.
  exit /b 1
)

echo Using FPC compiler: %FPC%

rem 1. Compile 32-bit DLL
echo.
echo [1/2] Compiling Windows 32-bit DLL...
set "DLL32=ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win32.dll"
"%FPC%" -MObjFPC -Scghi -O3 -gl -Pi386 -Twin32 -o"%DLL32%" bridge.lpr
if errorlevel 1 (
  echo [WARNING] 32-bit compilation failed.
) else (
  echo Creating directories for x86...
  if not exist "..\windows" mkdir "..\windows"
  if not exist "..\windows\x86" mkdir "..\windows\x86"
  echo Copying 32-bit DLL...
  copy /Y "%DLL32%" "..\windows\"
  copy /Y "%DLL32%" "..\windows\x86\"
  
  set "DEMO_DIR=..\..\..\pacote\samples\AI Native Vision\human_pose_detector_demo"
  if exist "%DEMO_DIR%" (
    copy /Y "%DLL32%" "%DEMO_DIR%\"
  )
)

rem 2. Compile 64-bit DLL
echo.
echo [2/2] Compiling Windows 64-bit DLL...
set "DLL64=ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll"
"%FPC%" -MObjFPC -Scghi -O3 -gl -Px86_64 -Twin64 -o"%DLL64%" bridge.lpr
if errorlevel 1 (
  echo [WARNING] 64-bit compilation failed - cross-compiler ppcx64 or ppcrossx64 might not be installed.
) else (
  echo Creating directories for x64...
  if not exist "..\windows" mkdir "..\windows"
  if not exist "..\windows\x64" mkdir "..\windows\x64"
  echo Copying 64-bit DLL...
  copy /Y "%DLL64%" "..\windows\"
  copy /Y "%DLL64%" "..\windows\x64\"
  
  set "DEMO_DIR=..\..\..\pacote\samples\AI Native Vision\human_pose_detector_demo"
  if exist "%DEMO_DIR%" (
    copy /Y "%DLL64%" "%DEMO_DIR%\"
  )
)

echo.
echo [OK] Execution finished. Check output DLLs in D:\projetos\maurinsoft\CHATGPT\runtime\mediapipe\windows
exit /b 0
