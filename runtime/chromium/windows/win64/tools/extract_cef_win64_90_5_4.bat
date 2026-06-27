@echo off
setlocal

set BASE=D:\projetos\maurinsoft\CHATGPT\runtime\chromium\windows\win64
set DOWNLOAD=%BASE%\downloads\cef_binary_90.5.4_windows64.tar.bz2
set EXTRACT=%BASE%\extract
set SEVENZIP=C:\Program Files\7-Zip\7z.exe

if not exist "%DOWNLOAD%" (
  echo ERRO: Arquivo nao encontrado:
  echo %DOWNLOAD%
  exit /b 1
)

if exist "%EXTRACT%" rmdir /S /Q "%EXTRACT%"
mkdir "%EXTRACT%"

if exist "%SEVENZIP%" (
  echo Extraindo .bz2 com 7-Zip...
  "%SEVENZIP%" x "%DOWNLOAD%" -o"%EXTRACT%" -y

  echo Extraindo .tar...
  for %%f in ("%EXTRACT%\*.tar") do "%SEVENZIP%" x "%%f" -o"%EXTRACT%" -y
) else (
  echo 7-Zip nao encontrado. Tentando tar do Windows...
  tar -xjf "%DOWNLOAD%" -C "%EXTRACT%"
)

echo.
echo Conteudo extraido em:
echo %EXTRACT%
exit /b 0
