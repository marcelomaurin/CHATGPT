$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$SourceDir = Join-Path $Root 'build'
$BuildDir = Join-Path $SourceDir 'build_sim'
$BridgeRuntimeDir = Join-Path $RepoRoot 'bridge\runtime\mediapipe\pose\mp_0_10_35\windows-x86_64'
$RuntimeDir = Join-Path $RepoRoot 'runtime\mediapipe\pose\mp_0_10_35\windows-x86_64'
$DllName = 'ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll'

Write-Host 'Configuring SIM build...'
cmake -S $SourceDir -B $BuildDir -DMP_POSE_BUILD=ON -DMP_BRIDGE_BACKEND=SIM

Write-Host 'Building SIM bridge...'
cmake --build $BuildDir --config Release

$BuiltDll = Get-ChildItem -Path $BuildDir -Recurse -Filter $DllName | Select-Object -First 1
if (-not $BuiltDll) {
  throw "Built DLL not found: $DllName"
}

New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null
Copy-Item -Force $BuiltDll.FullName (Join-Path $RuntimeDir $DllName)

if (Test-Path (Join-Path $BridgeRuntimeDir 'bridge.json')) {
  Copy-Item -Force (Join-Path $BridgeRuntimeDir 'bridge.json') $RuntimeDir
}
if (Test-Path (Join-Path $BridgeRuntimeDir 'models')) {
  New-Item -ItemType Directory -Force -Path (Join-Path $RuntimeDir 'models') | Out-Null
  Copy-Item -Force (Join-Path $BridgeRuntimeDir 'models\*') (Join-Path $RuntimeDir 'models')
}

Write-Host "SIM build complete: $BuildDir"
Write-Host "SIM runtime copied to: $RuntimeDir"
