@echo off
setlocal

call "%~dp0download_cef_win64_90_5_4.bat"
if errorlevel 1 exit /b 1

call "%~dp0extract_cef_win64_90_5_4.bat"
if errorlevel 1 exit /b 1

call "%~dp0install_cef_win64_90_5_4.bat"
if errorlevel 1 exit /b 1

call "%~dp0check_cef_win64_90_5_4.bat"
if errorlevel 1 exit /b 1

echo.
echo ==========================================
echo Runtime CEF 90.5.4 Windows 64 bits OK.
echo ==========================================
exit /b 0
