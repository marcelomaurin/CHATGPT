@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: verify_pose_bridge_exports.bat
:: Verifica se uma DLL da bridge MediaPipe Pose exporta todas
:: as funcoes obrigatorias esperadas pelo binding Pascal.
::
:: Uso:
::   verify_pose_bridge_exports.bat <caminho_completo_da_dll>
::
:: Retorna:
::   0  -- todos os exports encontrados
::   1  -- um ou mais exports ausentes / DLL invalida
:: ============================================================

set DLL_PATH=%~1
if "%DLL_PATH%"=="" (
    echo ERRO: informe o caminho da DLL.
    echo Uso: verify_pose_bridge_exports.bat ^<caminho_da_dll^>
    exit /b 1
)
if not exist "%DLL_PATH%" (
    echo ERRO: DLL nao encontrada: %DLL_PATH%
    exit /b 1
)

echo Verificando exports de: %DLL_PATH%

:: ---- Exports obrigatórios -----------------------------------------------
set REQUIRED=mp_pose_get_info mp_pose_create mp_pose_destroy mp_pose_detect mp_pose_free_result mp_pose_last_error

:: ---- Descobrir ferramenta disponível ------------------------------------
set DUMP_TOOL=

:: 1. dumpbin (MSVC — mais confiável no Windows)
where dumpbin >nul 2>&1 && set DUMP_TOOL=dumpbin

:: 2. Se não achou, tentar localizar via vcvarsall
if "%DUMP_TOOL%"=="" (
    for %%V in (
        "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
        "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
        "C:\Program Files\Microsoft Visual Studio\2022\Professional\VC\Auxiliary\Build\vcvars64.bat"
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
        "C:\Program Files (x86)\Microsoft Visual Studio\2019\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
        "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvars64.bat"
        "C:\Program Files (x86)\Microsoft Visual Studio\2019\Professional\VC\Auxiliary\Build\vcvars64.bat"
        "C:\Program Files (x86)\Microsoft Visual Studio\2019\Enterprise\VC\Auxiliary\Build\vcvars64.bat"
    ) do (
        if "!DUMP_TOOL!"=="" if exist "%%~V" (
            call "%%~V" >nul 2>&1
            where dumpbin >nul 2>&1 && set DUMP_TOOL=dumpbin
        )
    )
)

:: 3. llvm-objdump (LLVM/Clang toolchain)
if "%DUMP_TOOL%"=="" (
    where llvm-objdump >nul 2>&1 && set DUMP_TOOL=llvm-objdump
)

:: 4. objdump (MinGW/GCC)
if "%DUMP_TOOL%"=="" (
    where objdump >nul 2>&1 && set DUMP_TOOL=objdump
)

if "%DUMP_TOOL%"=="" (
    echo AVISO: nenhuma ferramenta de dump disponivel ^(dumpbin / objdump / llvm-objdump^).
    echo        Instale o MSVC Build Tools, LLVM ou MinGW para verificar exports.
    echo        Pulando verificacao de exports.
    exit /b 0
)

echo Ferramenta: %DUMP_TOOL%

:: ---- Executar dump e salvar em arquivo temporário -----------------------
set TMPFILE=%TEMP%\mp_pose_exports_%RANDOM%.txt

if "%DUMP_TOOL%"=="dumpbin" (
    dumpbin /exports "%DLL_PATH%" > "%TMPFILE%" 2>&1
) else if "%DUMP_TOOL%"=="llvm-objdump" (
    llvm-objdump -p "%DLL_PATH%" > "%TMPFILE%" 2>&1
) else if "%DUMP_TOOL%"=="objdump" (
    objdump -p "%DLL_PATH%" > "%TMPFILE%" 2>&1
)

if not exist "%TMPFILE%" (
    echo ERRO: falha ao executar %DUMP_TOOL%.
    exit /b 1
)

:: ---- Verificar cada export ----------------------------------------------
set ALL_OK=1
set MISSING_LIST=

for %%E in (%REQUIRED%) do (
    findstr /c:"%%E" "%TMPFILE%" >nul 2>&1
    if errorlevel 1 (
        echo ERRO: export ausente: %%E
        set ALL_OK=0
        set MISSING_LIST=!MISSING_LIST! %%E
    )
)

if exist "%TMPFILE%" del /F /Q "%TMPFILE%"

if "%ALL_OK%"=="1" (
    echo OK: todos os exports obrigatorios encontrados.
    echo   mp_pose_get_info   mp_pose_create   mp_pose_destroy
    echo   mp_pose_detect     mp_pose_free_result   mp_pose_last_error
    exit /b 0
) else (
    echo ERRO: exports ausentes:%MISSING_LIST%
    echo A DLL pode nao ser a bridge correta ou estar corrompida.
    exit /b 1
)
