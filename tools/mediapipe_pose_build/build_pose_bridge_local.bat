@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: build_pose_bridge_local.bat
:: Compila a bridge MediaPipe Pose localmente no Windows.
::
:: Uso:
::   build_pose_bridge_local.bat [SIM|REAL]
::
:: Padrao: SIM
:: ============================================================

:: ---- Variáveis da bridge ------------------------------------------------
set BRIDGE_VERSION=v1_0_0
set MEDIAPIPE_VERSION=mp0_10_35
set PLATFORM=win64
set DLL_NAME=ai_mediapipe_pose_bridge_%BRIDGE_VERSION%_%MEDIAPIPE_VERSION%_%PLATFORM%.dll

:: ---- Backend -------------------------------------------------------------
set BACKEND=%~1
if "%BACKEND%"=="" set BACKEND=SIM
if /I "%BACKEND%"=="sim"  set BACKEND=SIM
if /I "%BACKEND%"=="real" set BACKEND=REAL

if not "%BACKEND%"=="SIM" if not "%BACKEND%"=="REAL" (
    echo ERRO: backend invalido "%BACKEND%". Use SIM ou REAL.
    exit /b 1
)

:: ---- Raiz do projeto (duas pastas acima de tools\mediapipe_pose_build) ---
set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%..\.."
set ROOT=%CD%

echo.
echo ============================================================
echo  MediaPipe Pose Bridge -- Build Local Windows x86_64
echo ============================================================
echo  Backend       : %BACKEND%
echo  DLL alvo      : %DLL_NAME%
echo  Raiz projeto  : %ROOT%
echo ============================================================
echo.

:: ---- Caminhos ------------------------------------------------------------
set CMAKE_SOURCE=bridge\mediapipe_pose\build
set BUILD_DIR=bridge\mediapipe_pose\build_win64_%BACKEND%
set RUNTIME_DEST=runtime\mediapipe\pose\mp_0_10_35\windows-x86_64
set DEMO_DEST=pacote\samples\AI MediaPipe Vision\pose_detector_demo
set TOOLS_DIR=%SCRIPT_DIR%

:: ---- [PRE] Validar CMake -------------------------------------------------
where cmake >nul 2>&1
if errorlevel 1 (
    if exist "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" (
        set "PATH=C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%"
    ) else if exist "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe" (
        set "PATH=C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin;%PATH%"
    )
)

where cmake >nul 2>&1
if errorlevel 1 (
    echo ERRO: cmake nao encontrado no PATH.
    echo       Instale o CMake 3.16+ e adicione-o ao PATH.
    popd & exit /b 1
)
for /f "tokens=3" %%V in ('cmake --version 2^>^&1 ^| findstr /i "cmake version"') do (
    echo cmake: %%V
)

:: ---- [1/6] CMake configure -----------------------------------------------
echo.
echo [1/6] Configurando CMake  (Backend=%BACKEND%)...
cmake -B "%BUILD_DIR%" ^
      -S "%CMAKE_SOURCE%" ^
      -DMP_BRIDGE_BACKEND=%BACKEND% ^
      -DMP_POSE_BUILD=ON ^
      -DCMAKE_BUILD_TYPE=Release
if errorlevel 1 (
    echo ERRO: cmake configure falhou. Verifique o CMakeLists e as dependencias.
    popd & exit /b 1
)

:: ---- [2/6] Compilar ------------------------------------------------------
echo.
echo [2/6] Compilando...
cmake --build "%BUILD_DIR%" --config Release
if errorlevel 1 (
    echo ERRO: cmake --build falhou.
    popd & exit /b 1
)

:: ---- Localizar DLL gerada (procura hierarquicamente) --------------------
set DLL_SRC=

:: Candidatos mais prováveis primeiro
for %%F in ("%BUILD_DIR%\Release\%DLL_NAME%"
            "%BUILD_DIR%\%DLL_NAME%"
            "%BUILD_DIR%\Release\mp_pose_bridge.dll"
            "%BUILD_DIR%\mp_pose_bridge.dll") do (
    if "!DLL_SRC!"=="" if exist "%%~F" set DLL_SRC=%%~F
)

:: Busca recursiva pelo nome versionado
if "!DLL_SRC!"=="" (
    for /r "%BUILD_DIR%" %%F in (%DLL_NAME%) do (
        if "!DLL_SRC!"=="" set DLL_SRC=%%~F
    )
)

:: Busca recursiva por qualquer DLL
if "!DLL_SRC!"=="" (
    for /r "%BUILD_DIR%" %%F in (*.dll) do (
        if "!DLL_SRC!"=="" set DLL_SRC=%%~F
    )
)

if "!DLL_SRC!"=="" (
    echo ERRO: nenhuma DLL encontrada em "%BUILD_DIR%".
    popd & exit /b 1
)
echo DLL gerada: !DLL_SRC!

:: ---- Normalizar nome para versionado -------------------------------------
for %%F in ("!DLL_SRC!") do set DLL_BASENAME=%%~nxF
if /I not "!DLL_BASENAME!"=="%DLL_NAME%" (
    echo Renomeando !DLL_BASENAME! para %DLL_NAME%...
    for %%F in ("!DLL_SRC!") do set DLL_RENAME_DIR=%%~dpF
    copy /Y "!DLL_SRC!" "!DLL_RENAME_DIR!%DLL_NAME%" >nul
    if not errorlevel 1 set DLL_SRC=!DLL_RENAME_DIR!%DLL_NAME%
)

:: ---- [3/6] Copiar para runtime e demo ------------------------------------
echo.
echo [3/6] Copiando DLL...

if not exist "%RUNTIME_DEST%" mkdir "%RUNTIME_DEST%"
if not exist "%DEMO_DEST%"    mkdir "%DEMO_DEST%"

copy /Y "!DLL_SRC!" "%RUNTIME_DEST%\%DLL_NAME%" >nul
if errorlevel 1 ( echo ERRO: copia para runtime falhou. & popd & exit /b 1 )
echo    DLL copiada para runtime : %RUNTIME_DEST%\%DLL_NAME%

copy /Y "!DLL_SRC!" "%DEMO_DEST%\%DLL_NAME%" >nul
if errorlevel 1 ( echo ERRO: copia para demo falhou. & popd & exit /b 1 )
echo    DLL copiada para demo    : %DEMO_DEST%\%DLL_NAME%

:: ---- [4/6] Verificar exports ---------------------------------------------
echo.
echo [4/6] Verificando exports obrigatorios...
call "%TOOLS_DIR%verify_pose_bridge_exports.bat" "%RUNTIME_DEST%\%DLL_NAME%"
if errorlevel 1 (
    echo ERRO: verificacao de exports falhou. DLL pode estar corrompida.
    popd & exit /b 1
)

:: ---- [5/6] Limpar DLLs legadas -------------------------------------------
echo.
echo [5/6] Limpando DLLs legadas...
call "%TOOLS_DIR%clean_pose_bridge_legacy.bat"

:: ---- [6/6] Manifesto e relatorio -----------------------------------------
echo.
echo [6/6] Gerando manifesto e relatorio de build...
call :GenerateManifest
call :GenerateReport

:: ---- Resumo final --------------------------------------------------------
echo.
echo ============================================================
echo  Build finalizado.
echo  Backend          : %BACKEND%
echo  DLL gerada       : !DLL_SRC!
echo  DLL copiada para runtime : %RUNTIME_DEST%\%DLL_NAME%
echo  DLL copiada para demo    : %DEMO_DEST%\%DLL_NAME%
echo ============================================================
echo.
echo Agora abra:
echo   %DEMO_DEST%
echo.
echo   1. Selecione a DLL versionada.
echo   2. Selecione pose_landmarker_full.task  (somente se backend REAL).
echo   3. Clique em Carregar / Re-inicializar.
echo   4. Confirme no log:
echo        Backend: REAL ou SIM.
echo.
echo DLL compilada.
echo DLL copiada.
echo Exports encontrados.
echo Pronta para validacao no demo.
echo.

popd
exit /b 0


:: ============================================================
:: :GenerateManifest  --  escreve bridge_manifest.json
:: ============================================================
:GenerateManifest
set MANIFEST=%RUNTIME_DEST%\bridge_manifest.json
(
echo {
echo   "name": "AI MediaPipe Pose Bridge",
echo   "component": "TAIHumanPoseDetector",
echo   "bridge_version": "1.0.0",
echo   "bridge_abi_version": 1,
echo   "compatible_mediapipe_version": "0.10.35",
echo   "backend": "%BACKEND%",
echo   "platform": "windows",
echo   "arch": "x86_64",
echo   "binary": "%DLL_NAME%",
echo   "models": {
echo     "lite":  "models/pose_landmarker_lite.task",
echo     "full":  "models/pose_landmarker_full.task",
echo     "heavy": "models/pose_landmarker_heavy.task"
echo   },
echo   "default_model": "full",
echo   "landmark_count": 33
echo }
) > "%MANIFEST%"
echo    bridge_manifest.json -> %MANIFEST%
goto :eof


:: ============================================================
:: :GenerateReport  --  escreve build_report.txt
:: ============================================================
:GenerateReport
set REPORT=%RUNTIME_DEST%\build_report.txt
set DLL_FULL=%RUNTIME_DEST%\%DLL_NAME%

set DLL_SIZE=N/A
set DLL_SHA256=N/A
set BUILD_DATE=N/A

for /f "usebackq delims=" %%S in (
    `powershell -NoProfile -Command "(Get-Item '%DLL_FULL%').Length" 2^>nul`
) do set DLL_SIZE=%%S

for /f "usebackq delims=" %%H in (
    `powershell -NoProfile -Command "Get-FileHash '%DLL_FULL%' -Algorithm SHA256 | Select-Object -ExpandProperty Hash" 2^>nul`
) do set DLL_SHA256=%%H

for /f "usebackq delims=" %%D in (
    `powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'" 2^>nul`
) do set BUILD_DATE=%%D

(
echo Build date        : %BUILD_DATE%
echo Backend           : %BACKEND%
echo Bridge version    : 1.0.0
echo MediaPipe version : 0.10.35
echo Output DLL        : %DLL_NAME%
echo DLL size          : %DLL_SIZE% bytes
echo SHA256            : %DLL_SHA256%
echo Exports OK        : YES
echo Copied to runtime : %RUNTIME_DEST%\%DLL_NAME%
echo Copied to demo    : %DEMO_DEST%\%DLL_NAME%
echo Legacy DLLs removed: see clean_pose_bridge_legacy.bat output
) > "%REPORT%"
echo    build_report.txt  -> %REPORT%
goto :eof
