@echo off
setlocal

echo CHATGPT-AI Windows x64 installer

echo Checking architecture...
if not "%PROCESSOR_ARCHITECTURE%"=="AMD64" (
  echo This installer requires Windows x64.
  exit /b 1
)

echo Create the target runtime directory before copying packaged assets.
echo Default path: C:/CHATGPT-AI

echo Next steps implemented by release package:
echo 1. Copy runtime assets.
echo 2. Copy Lazarus packages.
echo 3. Generate chatgpt_ai_runtime.ini.
echo 4. Run runtime validation.
echo 5. Install Lazarus packages with lazbuild.

echo Installer skeleton finished.
endlocal
