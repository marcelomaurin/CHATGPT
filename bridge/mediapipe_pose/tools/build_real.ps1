$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$RepoRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
$SourceDir = Join-Path $Root 'build'
$BuildDir = Join-Path $SourceDir 'build_real'
$BridgeRuntimeDir = Join-Path $RepoRoot 'bridge\runtime\mediapipe\pose\mp_0_10_35\windows-x86_64'
$RuntimeDir = Join-Path $RepoRoot 'runtime\mediapipe\pose\mp_0_10_35\windows-x86_64'
$DllName = 'ai_mediapipe_pose_bridge_v1_0_0_mp0_10_35_win64.dll'

Write-Host 'Configuring REAL build...'
cmake -S $SourceDir -B $BuildDir -DMP_POSE_BUILD=ON -DMP_BRIDGE_BACKEND=REAL

Write-Host 'Building REAL bridge...'
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

if (-not (Test-Path (Join-Path $RuntimeDir 'models\pose_landmarker_full.task'))) {
  Write-Warning 'REAL runtime tree does not contain pose_landmarker_full.task.'
}

Write-Host "REAL build complete: $BuildDir"
Write-Host "REAL runtime copied to: $RuntimeDir"
