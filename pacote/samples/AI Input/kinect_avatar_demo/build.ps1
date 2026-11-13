param([string]$Assistente='C:\projetos\maurinsoft\Assistente',
 [string]$ChatGPT='C:\projetos\maurinsoft\CHATGPT',
 [string]$Lazarus='C:\lazarus',
 [string]$Compiler='C:\FPC\3.2.2\bin\i386-Win32\fpc.exe',
 [string]$Target='kinect_avatar_demo.lpr')
$ErrorActionPreference='Stop'
$out=Join-Path $PSScriptRoot 'bin'
$units=Join-Path $PSScriptRoot 'lib'
New-Item -ItemType Directory -Force -Path $out,$units | Out-Null
$argsList=@('-MObjFPC','-Scghi','-O1','-gl','-dLCL','-dLCLwin32','-dCASTLE_ENGINE_LAZARUS_PACKAGE',
 ('-FU'+$units),('-FE'+$out),('-Fu'+$PSScriptRoot),
 ('-Fu'+$Assistente+'\build\professor\units\i386-win32'),('-Fu'+$Assistente+'\src'),
 ('-Fu'+$Assistente+'\vendor\chatgpt-voice'))
foreach($rel in @('lcl\units\i386-win32\win32','lcl\units\i386-win32',
 'components\lazutils\lib\i386-win32','packager\units\i386-win32','components\opengl',
 'components\synedit\units\i386-win32\win32','components\lazcontrols\lib\i386-win32\win32',
 'components\ideintf\units\i386-win32\win32','components\buildintf\units\i386-win32')) {
 $argsList+='-Fu'+(Join-Path $Lazarus $rel)
}
foreach($rel in @('AI Base','AI Input\AIKinect','AI Graphic','AI Audio','AI')) {
 $argsList+='-Fu'+(Join-Path $ChatGPT ('pacote\'+$rel))
}
$argsList+='-Fu'+$ChatGPT
& $Compiler @argsList (Join-Path $PSScriptRoot $Target)
if($LASTEXITCODE -ne 0){throw 'Falha na compilação. Compile primeiro o professor do Assistente com scripts/build_professor.ps1.'}
Write-Output "Executável: $out\kinect_avatar_demo.exe"
