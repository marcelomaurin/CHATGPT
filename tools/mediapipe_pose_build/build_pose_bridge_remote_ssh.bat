@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: build_pose_bridge_remote_ssh.bat
:: Aciona o build da bridge MediaPipe Pose em uma maquina
:: remota via SSH e copia a DLL de volta via SCP.
::
:: Uso:
::   build_pose_bridge_remote_ssh.bat usuario@maquina [SIM|REAL]
::
:: Exemplos:
::   build_pose_bridge_remote_ssh.bat admin@buildserver REAL
::   build_pose_bridge_remote_ssh.bat admin@buildserver SIM
::   build_pose_bridge_remote_ssh.bat admin@192.168.1.10 REAL
::
:: Pre-requisitos:
::   - OpenSSH client no PATH (Windows 10+ inclui por padrao)
::   - OpenSSH Server instalado e rodando na maquina remota
;;   - Repositorio clonado na maquina remota no mesmo caminho relativo
::   - Chave SSH configurada ou senha disponivel interativamente
:: ============================================================

:: ---- Validar parametros -------------------------------------------------
set SSH_HOST=%~1
set BACKEND=%~2

if "%SSH_HOST%"=="" (
    echo ERRO: informe o host SSH.
    echo Uso: build_pose_bridge_remote_ssh.bat usuario@maquina [SIM^|REAL]
    exit /b 1
)

if "%BACKEND%"=="" set BACKEND=SIM
if /I "%BACKEND%"=="sim"  set BACKEND=SIM
if /I "%BACKEND%"=="real" set BACKEND=REAL

if not "%BACKEND%"=="SIM" if not "%BACKEND%"=="REAL" (
    echo ERRO: backend invalido "%BACKEND%". Use SIM ou REAL.
    exit /b 1
)

:: ---- Variáveis -----------------------------------------------------------
set BRIDGE_VERSION=v1_0_0
set MEDIAPIPE_VERSION=mp0_10_35
set PLATFORM=win64
set DLL_NAME=ai_mediapipe_pose_bridge_%BRIDGE_VERSION%_%MEDIAPIPE_VERSION%_%PLATFORM%.dll

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%..\.."
set ROOT=%CD%

set RUNTIME_DEST=runtime\mediapipe\pose\mp_0_10_35\windows-x86_64
set DEMO_DEST=pacote\samples\AI MediaPipe Vision\pose_detector_demo

:: Caminho remoto (assumindo mesmo layout de diretório na máquina remota)
:: Ajuste REMOTE_ROOT se o projeto estiver em outro caminho na máquina remota.
set REMOTE_ROOT=D:/projetos/maurinsoft/CHATGPT
set REMOTE_DLL=%REMOTE_ROOT%/runtime/mediapipe/pose/mp_0_10_35/windows-x86_64/%DLL_NAME%
set REMOTE_BUILD_SCRIPT=%REMOTE_ROOT%/tools/mediapipe_pose_build/build_pose_bridge_local.bat

echo.
echo ============================================================
echo  MediaPipe Pose Bridge -- Build Remoto via SSH
echo ============================================================
echo  Host SSH      : %SSH_HOST%
echo  Backend       : %BACKEND%
echo  DLL alvo      : %DLL_NAME%
echo  Raiz local    : %ROOT%
echo  Raiz remota   : %REMOTE_ROOT%
echo ============================================================
echo.

:: ---- Validar ssh/scp ----------------------------------------------------
where ssh >nul 2>&1
if errorlevel 1 (
    echo ERRO: ssh nao encontrado no PATH.
    echo       Instale o OpenSSH Client ou adicione-o ao PATH.
    popd & exit /b 1
)

where scp >nul 2>&1
if errorlevel 1 (
    echo ERRO: scp nao encontrado no PATH.
    popd & exit /b 1
)

:: ---- [1/6] Testar conexão SSH -------------------------------------------
echo [1/6] Testando conexao SSH com %SSH_HOST%...
ssh -o BatchMode=yes -o ConnectTimeout=10 "%SSH_HOST%" "echo SSH conectado."
if errorlevel 1 (
    echo ERRO: nao foi possivel conectar ao host %SSH_HOST%.
    echo       Verifique:
    echo         - Host acessivel na rede
    echo         - OpenSSH Server rodando na maquina remota
    echo         - Chave SSH configurada ^(ou use -i para especificar a chave^)
    popd & exit /b 1
)
echo SSH conectado.

:: ---- [2/6] Disparar build remoto ----------------------------------------
echo.
echo [2/6] Iniciando build remoto  (Backend=%BACKEND%)...
ssh "%SSH_HOST%" "cd /d %REMOTE_ROOT% && tools\mediapipe_pose_build\build_pose_bridge_local.bat %BACKEND%"
if errorlevel 1 (
    echo ERRO: build remoto falhou.
    popd & exit /b 1
)
echo Build remoto finalizado.

:: ---- [3/6] Copiar DLL de volta via SCP ----------------------------------
echo.
echo [3/6] Copiando DLL via SCP...

if not exist "%RUNTIME_DEST%" mkdir "%RUNTIME_DEST%"
if not exist "%DEMO_DEST%"    mkdir "%DEMO_DEST%"

scp "%SSH_HOST%:%REMOTE_DLL%" "%RUNTIME_DEST%\%DLL_NAME%"
if errorlevel 1 (
    echo ERRO: scp falhou ao copiar a DLL do host remoto.
    popd & exit /b 1
)
echo DLL copiada via SCP: %RUNTIME_DEST%\%DLL_NAME%

:: ---- [4/6] Copiar para demo local ----------------------------------------
echo.
echo [4/6] Instalando DLL no demo local...
copy /Y "%RUNTIME_DEST%\%DLL_NAME%" "%DEMO_DEST%\%DLL_NAME%" >nul
if errorlevel 1 (
    echo ERRO: falha ao copiar para demo.
    popd & exit /b 1
)
echo DLL instalada: %DEMO_DEST%\%DLL_NAME%

:: ---- [5/6] Verificar exports localmente ----------------------------------
echo.
echo [5/6] Verificando exports da DLL recebida...
call "%SCRIPT_DIR%verify_pose_bridge_exports.bat" "%RUNTIME_DEST%\%DLL_NAME%"
if errorlevel 1 (
    echo ERRO: DLL recebida nao passa na verificacao de exports.
    popd & exit /b 1
)
echo Exports validados.

:: ---- [6/6] Limpar DLLs legadas locais ------------------------------------
echo.
echo [6/6] Limpando DLLs legadas locais...
call "%SCRIPT_DIR%clean_pose_bridge_legacy.bat"

:: ---- Resumo --------------------------------------------------------------
echo.
echo ============================================================
echo  Build remoto concluido.
echo  Host SSH         : %SSH_HOST%
echo  Backend          : %BACKEND%
echo  DLL copiada via SCP: %RUNTIME_DEST%\%DLL_NAME%
echo  DLL instalada no demo: %DEMO_DEST%\%DLL_NAME%
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
