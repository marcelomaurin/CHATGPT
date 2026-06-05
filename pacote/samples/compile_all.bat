@echo off
set "LAZBUILD=C:\lazarus\lazbuild.exe"
if not exist "%LAZBUILD%" (
    echo Error: lazbuild.exe not found at %LAZBUILD%
    exit /b 1
)

echo Scanning and compiling Lazarus projects...
setlocal enabledelayedexpansion
set "FAILED_COUNT=0"
set "SUCCESS_COUNT=0"
set "FAILED_LIST="

for /r %%i in (*.lpi) do (
    set "filepath=%%i"
    echo !filepath! | findstr /i "\\backup\\" >nul
    if !errorlevel! neq 0 (
        echo !filepath! | findstr /i "\\lib\\" >nul
        if !errorlevel! neq 0 (
            echo ==================================================
            echo Compiling: %%i
            echo ==================================================
            "%LAZBUILD%" "%%i"
            if !errorlevel! equ 0 (
                echo SUCCESS: %%i
                set /a SUCCESS_COUNT+=1
            ) else (
                echo FAILED: %%i
                set /a FAILED_COUNT+=1
                set "FAILED_LIST=!FAILED_LIST! %%~nxi"
            )
        )
    )
)

echo ==================================================
echo Compilation Summary:
echo Success: %SUCCESS_COUNT%
echo Failed: %FAILED_COUNT%
if %FAILED_COUNT% gtr 0 (
    echo Failed projects: %FAILED_LIST%
    echo Some projects failed to compile.
    exit /b 1
) else (
    echo All projects compiled successfully!
    exit /b 0
)
