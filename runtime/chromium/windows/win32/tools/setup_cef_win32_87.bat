@echo off
setlocal

call "%~dp0download_cef_win32_87.bat"
if errorlevel 1 exit /b 1

call "%~dp0extract_cef_win32_87.bat"
if errorlevel 1 exit /b 1

call "%~dp0install_cef_win32_87.bat"
if errorlevel 1 exit /b 1

call "%~dp0check_cef_win32_runtime.bat"
if errorlevel 1 exit /b 1

echo.
echo ==========================================
echo Runtime Chromium/CEF Windows 32 bits OK.
echo ==========================================
exit /b 0
