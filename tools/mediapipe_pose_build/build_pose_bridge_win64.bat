@echo off
setlocal enabledelayedexpansion

:: ============================================================
::  build_pose_bridge_win64.bat
::  Compila, instala e valida a bridge MediaPipe Pose (Win64).
::
::  Uso:
::    build_pose_bridge_win64.bat [SIM|REAL]
::    (padrao: SIM)
::
::  Pode ser executado de duas formas:
::    A) Da raiz do projeto:
::       tools\mediapipe_pose_build\build_pose_bridge_win64.bat SIM
::    B) Copiado para a raiz do projeto:
::       build_pose_bridge_win64.bat SIM
:: ============================================================


:: ================================================================
::  SECAO 1 — Variaveis fixas da bridge
:: ================================================================
set "BRIDGE_VERSION=v1_0_0"
set "MEDIAPIPE_VERSION=mp0_10_35"
set "PLATFORM=win64"
set "OFFICIAL_DLL=ai_mediapipe_pose_bridge_%BRIDGE_VERSION%_%MEDIAPIPE_VERSION%_%PLATFORM%.dll"
set "LEGACY_DLL=mp_pose_bridge.dll"


:: ================================================================
::  SECAO 2 — Parametro BACKEND
:: ================================================================
set "BACKEND=%~1"
if "!BACKEND!"=="" set "BACKEND=SIM"
if /I "!BACKEND!"=="sim"  set "BACKEND=SIM"
if /I "!BACKEND!"=="real" set "BACKEND=REAL"

if not "!BACKEND!"=="SIM" if not "!BACKEND!"=="REAL" (
    echo.
    echo [ERRO] Backend invalido.
    echo Use SIM ou REAL.
    echo.
    exit /b 1
)


:: ================================================================
::  SECAO 3 — Resolver raiz do projeto
::  O script pode estar em tools\mediapipe_pose_build\ ou na raiz.
:: ================================================================
set "SCRIPT_DIR=%~dp0"

:: Testar se estamos dentro de tools\mediapipe_pose_build\
set "ROOT_CANDIDATE=%SCRIPT_DIR%..\.."
if exist "%ROOT_CANDIDATE%\bridge\mediapipe_pose\build\CMakeLists.txt" (
    pushd "%ROOT_CANDIDATE%"
    set "ROOT=%CD%"
    popd
    goto :RootFound
)

:: Testar se o script foi copiado direto para a raiz
if exist "%SCRIPT_DIR%bridge\mediapipe_pose\build\CMakeLists.txt" (
    pushd "%SCRIPT_DIR%"
    set "ROOT=%CD%"
    popd
    goto :RootFound
)

:: Se nenhum dos dois, usar o diretório atual de trabalho
if exist "%CD%\bridge\mediapipe_pose\build\CMakeLists.txt" (
    set "ROOT=%CD%"
    goto :RootFound
)

echo.
echo [ERRO] Nao foi possivel localizar a raiz do projeto.
echo        Esperado: bridge\mediapipe_pose\build\CMakeLists.txt
echo.
exit /b 1

:RootFound
cd /d "!ROOT!"


:: ================================================================
::  SECAO 4 — Caminhos derivados
:: ================================================================
set "CMAKE_SOURCE=bridge\mediapipe_pose\build"
set "BUILD_DIR=bridge\mediapipe_pose\build_win64_!BACKEND!"
set "RUNTIME_DEST=runtime\mediapipe\pose\mp_0_10_35\windows-x86_64"
set "DEMO_DEST=pacote\samples\AI MediaPipe Vision\pose_detector_demo"
set "MANIFEST_FILE=!RUNTIME_DEST!\bridge_manifest.json"
set "REPORT_FILE=!RUNTIME_DEST!\build_report_!BACKEND!.txt"


:: ================================================================
::  SECAO 5 — Cabecalho
:: ================================================================
echo.
echo ============================================================
echo  MediaPipe Pose Bridge -- Build Windows 64-bit
echo ============================================================
echo  Backend          : !BACKEND!
echo  DLL oficial      : !OFFICIAL_DLL!
echo  Raiz do projeto  : !ROOT!
echo  Fonte CMake      : !CMAKE_SOURCE!
echo  Pasta de build   : !BUILD_DIR!
echo  Destino runtime  : !RUNTIME_DEST!
echo  Destino demo     : !DEMO_DEST!
echo ============================================================
echo.


:: ================================================================
::  SECAO 6 — Validar pre-requisitos
:: ================================================================
echo [PRE] Validando pre-requisitos...

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
    echo [ERRO] cmake nao encontrado no PATH.
    echo        Instale o CMake 3.16+ e adicione-o ao PATH.
    exit /b 1
)
for /f "tokens=3" %%V in ('cmake --version 2^>^&1 ^| findstr /i "cmake version"') do (
    echo        cmake: %%V
)

if not exist "!CMAKE_SOURCE!\CMakeLists.txt" (
    echo [ERRO] CMakeLists.txt nao encontrado em: !CMAKE_SOURCE!
    exit /b 1
)
echo        CMakeLists.txt: OK


:: ================================================================
::  SECAO 7 — Detectar gerador CMake (VS2022 -> VS2019 -> padrao)
:: ================================================================
set "CMAKE_GENERATOR="
set "CMAKE_GENERATOR_LABEL=padrao"

:: Tentar detectar via vswhere
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "!VSWHERE!" set "VSWHERE=%ProgramFiles%\Microsoft Visual Studio\Installer\vswhere.exe"

if exist "!VSWHERE!" (
    for /f "usebackq delims=" %%V in (
        `"!VSWHERE!" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationVersion 2^>nul`
    ) do set "VS_VERSION=%%V"

    if defined VS_VERSION (
        for /f "tokens=1 delims=." %%M in ("!VS_VERSION!") do set "VS_MAJOR=%%M"
        if "!VS_MAJOR!"=="17" (
            set "CMAKE_GENERATOR=Visual Studio 17 2022"
            set "CMAKE_GENERATOR_LABEL=Visual Studio 17 2022"
        ) else if "!VS_MAJOR!"=="16" (
            set "CMAKE_GENERATOR=Visual Studio 16 2019"
            set "CMAKE_GENERATOR_LABEL=Visual Studio 16 2019"
        )
    )
)

:: Se vswhere nao achou, tentar cmake --help para detectar disponibilidade
if not defined CMAKE_GENERATOR (
    cmake --help 2>nul | findstr /i "Visual Studio 17" >nul 2>&1
    if not errorlevel 1 (
        set "CMAKE_GENERATOR=Visual Studio 17 2022"
        set "CMAKE_GENERATOR_LABEL=Visual Studio 17 2022"
    )
)
if not defined CMAKE_GENERATOR (
    cmake --help 2>nul | findstr /i "Visual Studio 16" >nul 2>&1
    if not errorlevel 1 (
        set "CMAKE_GENERATOR=Visual Studio 16 2019"
        set "CMAKE_GENERATOR_LABEL=Visual Studio 16 2019"
    )
)

echo        Gerador CMake: !CMAKE_GENERATOR_LABEL!


:: ================================================================
::  SECAO 8 — CMake Configure
:: ================================================================
echo.
echo [1/7] CMake configure (Backend=!BACKEND!)...

if defined CMAKE_GENERATOR (
    cmake -S "!CMAKE_SOURCE!" ^
          -B "!BUILD_DIR!" ^
          -G "!CMAKE_GENERATOR!" ^
          -A x64 ^
          -DMP_BRIDGE_BACKEND=!BACKEND! ^
          -DMP_POSE_BUILD=ON
) else (
    cmake -S "!CMAKE_SOURCE!" ^
          -B "!BUILD_DIR!" ^
          -DMP_BRIDGE_BACKEND=!BACKEND! ^
          -DMP_POSE_BUILD=ON
)

if errorlevel 1 (
    if "!BACKEND!"=="REAL" (
        echo.
        echo [ERRO] Backend REAL nao compilou.
        echo Verifique a configuracao do MediaPipe C API / Bazel / dependencias nativas.
    ) else (
        echo.
        echo [ERRO] cmake configure falhou.
    )
    exit /b 1
)


:: ================================================================
::  SECAO 9 — CMake Build
:: ================================================================
echo.
echo [2/7] CMake build...
cmake --build "!BUILD_DIR!" --config Release

if errorlevel 1 (
    if "!BACKEND!"=="REAL" (
        echo.
        echo [ERRO] Backend REAL nao compilou.
        echo Verifique a configuracao do MediaPipe C API / Bazel / dependencias nativas.
    ) else (
        echo.
        echo [ERRO] cmake --build falhou.
    )
    exit /b 1
)


:: ================================================================
::  SECAO 10 — Localizar DLL gerada
:: ================================================================
echo.
echo [3/7] Localizando DLL gerada...

set "DLL_SRC="

:: Candidatos em ordem de prioridade
for %%F in (
    "!BUILD_DIR!\bin\Release\!OFFICIAL_DLL!"
    "!BUILD_DIR!\bin\Release\!LEGACY_DLL!"
    "!BUILD_DIR!\Release\!OFFICIAL_DLL!"
    "!BUILD_DIR!\Release\!LEGACY_DLL!"
    "!BUILD_DIR!\!OFFICIAL_DLL!"
    "!BUILD_DIR!\!LEGACY_DLL!"
) do (
    if "!DLL_SRC!"=="" if exist "%%~F" set "DLL_SRC=%%~F"
)

:: Busca recursiva pelo nome oficial
if "!DLL_SRC!"=="" (
    for /r "!BUILD_DIR!" %%F in (!OFFICIAL_DLL!) do (
        if "!DLL_SRC!"=="" set "DLL_SRC=%%~F"
    )
)

:: Busca recursiva pelo nome legado
if "!DLL_SRC!"=="" (
    for /r "!BUILD_DIR!" %%F in (!LEGACY_DLL!) do (
        if "!DLL_SRC!"=="" set "DLL_SRC=%%~F"
    )
)

:: Busca recursiva por qualquer DLL
if "!DLL_SRC!"=="" (
    for /r "!BUILD_DIR!" %%F in (*.dll) do (
        if "!DLL_SRC!"=="" set "DLL_SRC=%%~F"
    )
)

if "!DLL_SRC!"=="" (
    echo.
    echo [ERRO] Nenhuma DLL foi encontrada na pasta de build.
    echo        Procurado em: !BUILD_DIR!
    exit /b 1
)

echo        DLL encontrada: !DLL_SRC!


:: ================================================================
::  SECAO 11 — Copiar para runtime e demo (com nome versionado)
:: ================================================================
echo.
echo [4/7] Instalando DLL...

if not exist "!RUNTIME_DEST!" mkdir "!RUNTIME_DEST!"
if not exist "!DEMO_DEST!"    mkdir "!DEMO_DEST!"

copy /Y "!DLL_SRC!" "!RUNTIME_DEST!\!OFFICIAL_DLL!" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao copiar DLL para runtime.
    exit /b 1
)
echo        DLL runtime : !RUNTIME_DEST!\!OFFICIAL_DLL!

copy /Y "!DLL_SRC!" "!DEMO_DEST!\!OFFICIAL_DLL!" >nul
if errorlevel 1 (
    echo [ERRO] Falha ao copiar DLL para demo.
    exit /b 1
)
echo        DLL demo    : !DEMO_DEST!\!OFFICIAL_DLL!


:: ================================================================
::  SECAO 12 — Remover DLLs legadas
:: ================================================================
echo.
echo [5/7] Removendo DLLs legadas...

set "LEGACY_REMOVED=nenhuma"
set "_ANY_REMOVED=0"

for %%D in ("!RUNTIME_DEST!" "!DEMO_DEST!") do (
    for %%L in (
        "mp_pose_bridge.dll"
        "pose_bridge.dll"
        "mediapipe_pose.dll"
        "old_mp_pose_bridge.dll"
    ) do (
        if exist "%%~D\%%~L" (
            echo        Removida: %%~D\%%~L
            del /F /Q "%%~D\%%~L"
            set "_ANY_REMOVED=1"
        )
    )
)

if "!_ANY_REMOVED!"=="0" echo        Nenhuma DLL legada encontrada.


:: ================================================================
::  SECAO 13 — Verificar exports obrigatorios
:: ================================================================
echo.
echo [6/7] Verificando exports...

set "REQUIRED_EXPORTS=mp_pose_get_info mp_pose_create mp_pose_destroy mp_pose_detect mp_pose_free_result mp_pose_last_error"
set "DUMP_TOOL="
set "TMPEXPORTS=%TEMP%\mp_pose_exp_%RANDOM%.txt"

:: Detectar ferramenta
where dumpbin >nul 2>&1 && set "DUMP_TOOL=dumpbin"

if not defined DUMP_TOOL (
    :: Tentar ativar MSVC via vswhere
    if exist "!VSWHERE!" (
        for /f "usebackq delims=" %%I in (
            `"!VSWHERE!" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2^>nul`
        ) do (
            set "VCVARS=%%I\VC\Auxiliary\Build\vcvars64.bat"
        )
        if defined VCVARS if exist "!VCVARS!" (
            call "!VCVARS!" >nul 2>&1
            where dumpbin >nul 2>&1 && set "DUMP_TOOL=dumpbin"
        )
    )
)

if not defined DUMP_TOOL (
    where llvm-objdump >nul 2>&1 && set "DUMP_TOOL=llvm-objdump"
)
if not defined DUMP_TOOL (
    where objdump >nul 2>&1 && set "DUMP_TOOL=objdump"
)

if not defined DUMP_TOOL (
    echo        [AVISO] Nao foi possivel validar exports porque dumpbin/objdump nao foi encontrado.
    set "EXPORTS_STATUS=NAO VERIFICADO (ferramenta ausente)"
    goto :ExportsSkipped
)

echo        Ferramenta: !DUMP_TOOL!

:: Executar dump
if "!DUMP_TOOL!"=="dumpbin" (
    dumpbin /exports "!RUNTIME_DEST!\!OFFICIAL_DLL!" > "!TMPEXPORTS!" 2>&1
) else (
    !DUMP_TOOL! -p "!RUNTIME_DEST!\!OFFICIAL_DLL!" > "!TMPEXPORTS!" 2>&1
)

:: Verificar cada export
set "_EXPORTS_OK=1"
set "_MISSING="
for %%E in (!REQUIRED_EXPORTS!) do (
    findstr /c:"%%E" "!TMPEXPORTS!" >nul 2>&1
    if errorlevel 1 (
        echo        [ERRO] export ausente: %%E
        set "_EXPORTS_OK=0"
        set "_MISSING=!_MISSING! %%E"
    )
)

if exist "!TMPEXPORTS!" del /F /Q "!TMPEXPORTS!"

if "!_EXPORTS_OK!"=="0" (
    echo.
    echo [ERRO] Exports ausentes:!_MISSING!
    echo A DLL pode nao ser a bridge correta ou estar corrompida.
    exit /b 1
)

echo        OK: todos os exports obrigatorios encontrados.
set "EXPORTS_STATUS=OK"

:ExportsSkipped


:: ================================================================
::  SECAO 14 — Coletar tamanho e SHA256 da DLL
:: ================================================================
set "DLL_SIZE=N/A"
set "DLL_SHA256=N/A"
set "BUILD_DATE=N/A"

for /f "usebackq delims=" %%S in (
    `powershell -NoProfile -Command "(Get-Item '!RUNTIME_DEST!\!OFFICIAL_DLL!').Length" 2^>nul`
) do set "DLL_SIZE=%%S"

for /f "usebackq delims=" %%H in (
    `powershell -NoProfile -Command "Get-FileHash '!RUNTIME_DEST!\!OFFICIAL_DLL!' -Algorithm SHA256 | Select-Object -ExpandProperty Hash" 2^>nul`
) do set "DLL_SHA256=%%H"

for /f "usebackq delims=" %%D in (
    `powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'" 2^>nul`
) do set "BUILD_DATE=%%D"


:: ================================================================
::  SECAO 15 — Gerar bridge_manifest.json
:: ================================================================
echo.
echo [7/7] Gerando manifesto e relatorio...

(
echo {
echo   "name": "AI MediaPipe Pose Bridge",
echo   "component": "TAIHumanPoseDetector",
echo   "bridge_version": "1.0.0",
echo   "bridge_abi_version": 1,
echo   "compatible_mediapipe_version": "0.10.35",
echo   "backend": "!BACKEND!",
echo   "platform": "windows",
echo   "arch": "x86_64",
echo   "binary": "!OFFICIAL_DLL!",
echo   "models": {
echo     "lite":  "models/pose_landmarker_lite.task",
echo     "full":  "models/pose_landmarker_full.task",
echo     "heavy": "models/pose_landmarker_heavy.task"
echo   },
echo   "default_model": "full",
echo   "landmark_count": 33
echo }
) > "!MANIFEST_FILE!"
echo        !MANIFEST_FILE!


:: ================================================================
::  SECAO 16 — Gerar build_report_<BACKEND>.txt
:: ================================================================
(
echo Build date        : !BUILD_DATE!
echo Backend           : !BACKEND!
echo Bridge version    : 1.0.0
echo MediaPipe version : 0.10.35
echo Official DLL      : !OFFICIAL_DLL!
echo Built DLL         : !DLL_SRC!
echo Runtime DLL       : !ROOT!\!RUNTIME_DEST!\!OFFICIAL_DLL!
echo Demo DLL          : !ROOT!\!DEMO_DEST!\!OFFICIAL_DLL!
echo DLL size          : !DLL_SIZE! bytes
echo SHA256            : !DLL_SHA256!
echo Exports check     : !EXPORTS_STATUS!
echo Manifest          : !ROOT!\!MANIFEST_FILE!
echo Legacy DLLs removed: ver saida do script
) > "!REPORT_FILE!"
echo        !REPORT_FILE!


:: ================================================================
::  SECAO 17 — Resumo final
:: ================================================================
echo.
echo ============================================================
echo  BUILD FINALIZADO
echo  Backend          : !BACKEND!
echo  DLL runtime      : !RUNTIME_DEST!\!OFFICIAL_DLL!
echo  DLL demo         : !DEMO_DEST!\!OFFICIAL_DLL!
echo  Manifest         : !MANIFEST_FILE!
echo  Relatorio        : !REPORT_FILE!
echo  SHA256           : !DLL_SHA256!
echo  Exports          : !EXPORTS_STATUS!
echo ============================================================
echo.
echo Proximo teste:
echo.
echo   1. Abra o demo pose_detector_demo.
echo   2. Selecione a DLL versionada:
echo      !OFFICIAL_DLL!
echo   3. Se BACKEND=REAL, selecione pose_landmarker_full.task.
echo   4. Clique em Carregar / Re-inicializar.
echo   5. Confirme no log: Backend: SIM ou REAL.
echo   6. Carregue duas imagens diferentes.
echo   7. Rode Detectar Pose.
echo   8. Se REAL, os landmarks devem mudar e acompanhar o corpo.
echo.
echo DLL compilada.
echo DLL copiada.
if "!EXPORTS_STATUS!"=="OK" echo Exports encontrados.
echo Pronta para validacao no demo.
echo.

exit /b 0
