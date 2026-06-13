# Instala CMake no Windows via winget ou choco
# Execute como Administrador para melhor resultado

Write-Host ""
Write-Host "============================================================"
Write-Host "  Instalacao do CMake"
Write-Host "============================================================"

# 1) Verificar se cmake ja esta no PATH
try {
    $ver = (cmake --version 2>$null) | Select-String "cmake version"
    if ($ver) {
        Write-Host "CMake ja instalado: $ver"
        Write-Host "Nenhuma acao necessaria."
        Read-Host "Pressione Enter para sair"
        exit 0
    }
} catch {}

# 2) Tentar winget
Write-Host ""
Write-Host "[1/3] Tentando winget..."
try {
    $null = Get-Command winget -ErrorAction Stop
    winget install --id Kitware.CMake --accept-source-agreements --accept-package-agreements
    if ($LASTEXITCODE -eq 0) {
        Write-Host "CMake instalado via winget."
        Write-Host ""
        Write-Host "IMPORTANTE: Feche e reabra qualquer terminal para o PATH ser atualizado."
        Read-Host "Pressione Enter para sair"
        exit 0
    }
} catch {
    Write-Host "winget nao disponivel, tentando choco..."
}

# 3) Tentar choco
Write-Host ""
Write-Host "[2/3] Tentando Chocolatey..."
try {
    $null = Get-Command choco -ErrorAction Stop
    choco install cmake -y --installargs 'ADD_CMAKE_TO_PATH=System'
    if ($LASTEXITCODE -eq 0) {
        Write-Host "CMake instalado via Chocolatey."
        Write-Host ""
        Write-Host "IMPORTANTE: Feche e reabra qualquer terminal para o PATH ser atualizado."
        Read-Host "Pressione Enter para sair"
        exit 0
    }
} catch {
    Write-Host "Chocolatey nao disponivel."
}

# 4) Download direto do instalador MSI
Write-Host ""
Write-Host "[3/3] Baixando instalador MSI do CMake 3.29.6..."
$InstallerUrl = "https://github.com/Kitware/CMake/releases/download/v3.29.6/cmake-3.29.6-windows-x86_64.msi"
$InstallerPath = "$env:TEMP\cmake-3.29.6-windows-x86_64.msi"

try {
    Write-Host "Baixando $InstallerUrl ..."
    Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing
    Write-Host "Download concluido: $InstallerPath"
    Write-Host ""
    Write-Host "Instalando MSI (modo silencioso com PATH do sistema)..."
    Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" /quiet /norestart ADD_CMAKE_TO_PATH=System" -Wait
    Write-Host ""
    Write-Host "CMake instalado com sucesso!"
    Write-Host "IMPORTANTE: Feche e reabra qualquer terminal para o PATH ser atualizado."
} catch {
    Write-Host ""
    Write-Host "ERRO: Falha no download/instalacao: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "Instale manualmente em: https://cmake.org/download/"
    Write-Host "Marque a opcao 'Add CMake to the system PATH for all users' durante a instalacao."
}

Read-Host "Pressione Enter para sair"
