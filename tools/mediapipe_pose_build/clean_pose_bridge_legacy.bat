@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: clean_pose_bridge_legacy.bat
:: Remove DLLs legadas da bridge MediaPipe Pose que podem ser
:: carregadas por engano no lugar da versao oficial versionada.
::
:: Regras:
::   - NAO remove: ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll
::   - NAO remove: *.task (modelos MediaPipe)
::   - Remove: nomes legados conhecidos nas pastas de runtime e demo
::
:: Pode ser chamado de forma independente ou pelo build local.
:: ============================================================

set SCRIPT_DIR=%~dp0
pushd "%SCRIPT_DIR%..\.."

set RUNTIME_DIR=runtime\mediapipe\pose\mp_0_10_35\windows-x86_64
set DEMO_DIR=pacote\samples\AI MediaPipe Vision\pose_detector_demo
set PROTECTED_DLL=ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll

:: Nomes legados conhecidos
set LEGACY_NAMES=mp_pose_bridge.dll pose_bridge.dll mediapipe_pose.dll old_mp_pose_bridge.dll libmp_pose_bridge.dll libpose_bridge.dll

set FOUND_ANY=0

for %%D in ("%RUNTIME_DIR%" "%DEMO_DIR%") do (
    if exist "%%~D" (
        for %%L in (%LEGACY_NAMES%) do (
            if exist "%%~D\%%L" (
                if /I not "%%L"=="%PROTECTED_DLL%" (
                    echo DLL legada removida: %%~D\%%L
                    del /F /Q "%%~D\%%L"
                    set FOUND_ANY=1
                )
            )
        )
    )
)

if "!FOUND_ANY!"=="0" (
    echo Nenhuma DLL legada encontrada.
)

:: Paranoia: garantir que os modelos .task nao foram afetados
for %%D in ("%RUNTIME_DIR%\models") do (
    if exist "%%~D" (
        for %%T in (pose_landmarker_lite.task pose_landmarker_full.task pose_landmarker_heavy.task) do (
            if exist "%%~D\%%T" (
                echo    Modelo preservado: %%~D\%%T
            )
        )
    )
)

popd
exit /b 0
