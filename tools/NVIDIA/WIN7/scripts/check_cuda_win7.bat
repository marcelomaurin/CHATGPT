@echo off
echo ==========================================
echo NVIDIA / CUDA validation for Windows 7
echo ==========================================
echo.

echo Checking NVIDIA driver...
where nvidia-smi >nul 2>nul
if errorlevel 1 (
  echo [ERROR] nvidia-smi not found in PATH.
  echo Install the NVIDIA driver or check PATH.
) else (
  nvidia-smi
)

echo.
echo Checking CUDA compiler...
where nvcc >nul 2>nul
if errorlevel 1 (
  echo [WARN] nvcc not found in PATH.
  echo CUDA Toolkit may not be installed, or PATH is not configured.
) else (
  nvcc --version
)

echo.
echo Checking CUDA_PATH...
if "%CUDA_PATH%"=="" (
  echo [WARN] CUDA_PATH is not set.
) else (
  echo CUDA_PATH=%CUDA_PATH%
)

echo.
echo Done.
pause
