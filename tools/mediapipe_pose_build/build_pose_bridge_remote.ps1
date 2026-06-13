<#
.SYNOPSIS
    Build remoto da bridge MediaPipe Pose.
    Este script e chamado pela maquina local via SSH na maquina remota.

.DESCRIPTION
    Valida CMake e MSVC, depois chama build_pose_bridge_local.bat.
    Retorna exit code diferente de zero se qualquer etapa falhar.

.PARAMETER Backend
    Backend de compilacao: SIM ou REAL. Padrao: SIM.

.PARAMETER ProjectRoot
    Caminho raiz do projeto. Se vazio, usa o diretorio do script.

.EXAMPLE
    .\build_pose_bridge_remote.ps1 -Backend REAL
    .\build_pose_bridge_remote.ps1 -Backend SIM -ProjectRoot "D:\projetos\maurinsoft\CHATGPT"
#>

param(
    [ValidateSet("SIM", "REAL", "sim", "real")]
    [string]$Backend = "SIM",

    [string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"

# ---- Normalizar backend -----------------------------------------------
$Backend = $Backend.ToUpper()

# ---- Resolver raiz do projeto ----------------------------------------
if ($ProjectRoot -eq "") {
    # script fica em tools\mediapipe_pose_build\ → subir 2 níveis
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $ProjectRoot = (Get-Item (Join-Path $ScriptDir "..\..")).FullName
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  MediaPipe Pose Bridge -- Build Remoto (PowerShell)"
Write-Host "============================================================"
Write-Host "  Backend      : $Backend"
Write-Host "  Raiz projeto : $ProjectRoot"
Write-Host "============================================================"
Write-Host ""

# ---- [1/4] Validar CMake ---------------------------------------------
Write-Host "[1/4] Validando CMake..."
try {
    $cmakeVersion = & cmake --version 2>&1 | Select-String "cmake version" | ForEach-Object { $_.Line }
    if (-not $cmakeVersion) { throw "cmake --version retornou saida inesperada." }
    Write-Host "  $cmakeVersion"
} catch {
    Write-Error "ERRO: cmake nao encontrado ou falhou. Instale o CMake 3.16+ e adicione ao PATH."
    exit 1
}

# ---- [2/4] Validar MSVC (compilador C++) ----------------------------
Write-Host "[2/4] Validando compilador C++ (MSVC / cl.exe)..."
$clFound = $false

# Tentar cl.exe direto no PATH
try {
    $null = & cl 2>&1
    $clFound = $true
    Write-Host "  cl.exe encontrado no PATH."
} catch { }

# Tentar via vswhere
if (-not $clFound) {
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    if (-not (Test-Path $vsWhere)) {
        $vsWhere = "${env:ProgramFiles}\Microsoft Visual Studio\Installer\vswhere.exe"
    }
    if (Test-Path $vsWhere) {
        $vsInstallPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null
        if ($vsInstallPath) {
            $vcvars = Join-Path $vsInstallPath "VC\Auxiliary\Build\vcvars64.bat"
            if (Test-Path $vcvars) {
                Write-Host "  Visual Studio encontrado: $vsInstallPath"
                $clFound = $true
            }
        }
    }
}

if (-not $clFound) {
    Write-Warning "AVISO: cl.exe nao encontrado no PATH."
    Write-Warning "       CMake pode usar outro gerador (Ninja+clang, MinGW, etc.)."
    Write-Warning "       Se o build falhar, instale o MSVC Build Tools."
}

# ---- [3/4] Entrar na raiz do projeto --------------------------------
Write-Host "[3/4] Entrando no diretorio do projeto..."
Set-Location $ProjectRoot
Write-Host "  Diretorio atual: $(Get-Location)"

# ---- [4/4] Chamar build local ----------------------------------------
Write-Host ""
Write-Host "[4/4] Chamando build_pose_bridge_local.bat $Backend ..."
$batPath = Join-Path $ProjectRoot "tools\mediapipe_pose_build\build_pose_bridge_local.bat"

if (-not (Test-Path $batPath)) {
    Write-Error "ERRO: $batPath nao encontrado."
    exit 1
}

$proc = Start-Process -FilePath "cmd.exe" `
    -ArgumentList "/c `"$batPath`" $Backend" `
    -Wait -PassThru -NoNewWindow

if ($proc.ExitCode -ne 0) {
    Write-Error "ERRO: build_pose_bridge_local.bat retornou exit code $($proc.ExitCode)."
    exit $proc.ExitCode
}

Write-Host ""
Write-Host "============================================================"
Write-Host "  Build remoto concluido com sucesso."
Write-Host "  Backend: $Backend"
Write-Host "============================================================"
exit 0
