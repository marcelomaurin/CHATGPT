param(
  [string]$FpcPath = 'C:\lazarus\fpc\3.2.2\bin\i386-win32\fpc.exe',
  [string]$LazarusRoot = 'C:\lazarus',
  [string]$Target = 'i386-win32'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$build = Join-Path ([IO.Path]::GetTempPath()) ('chatgpt-marlin-tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory $build | Out-Null
$flags = @('-B', '-gl', '-gh', '-Cr', '-Co', "-FU$build", "-FE$build",
  "-Fu$repo\pacote\AI", "-Fu$repo\pacote\AI Simulation\Marlin",
  "-Fu$repo\pacote\AI Input\AIVirtualSerial")
foreach ($test in @('test_marlin_components', 'test_virtualserial_backend', 'test_marlin_serial_component')) {
  $extra = @()
  if ($test -eq 'test_marlin_serial_component') {
    $extra = @("-Fu$repo\pacote\AI Input\AISerial", "-Fu$LazarusRoot\lcl\units\$Target",
      "-Fu$LazarusRoot\lcl\units\$Target\win32", "-Fu$LazarusRoot\components\lazutils\lib\$Target")
  }
  & $FpcPath @flags @extra (Join-Path $PSScriptRoot ($test + '.lpr'))
  if ($LASTEXITCODE -ne 0) { throw "Compilation failed: $test" }
  & (Join-Path $build ($test + '.exe'))
  if ($LASTEXITCODE -ne 0) { throw "Test failed: $test" }
}
Write-Output "All Marlin component tests passed. Build artifacts: $build"
