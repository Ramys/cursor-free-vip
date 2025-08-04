# Verifica se foi iniciado com privilégios elevados
param(
    [switch]$Elevated
)

# Configuração do tema de cores
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# Logo em ASCII
$Logo = @"
██████╗ ███████╗███████╗███████╗████████╗    ████████╗ ██████╗  ██████╗ ██╗     
██╔══██╗██╔════╝██╔════╝██╔════╝╚══██╔══╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     
██████╔╝█████╗  ███████╗█████╗     ██║          ██║   ██║   ██║██║   ██║██║     
██╔══██╗██╔══╝  ╚════██║██╔══╝     ██║          ██║   ██║   ██║██║   ██║██║     
██║  ██║███████╗███████║███████╗   ██║          ██║   ╚██████╔╝╚██████╔╝███████╗
╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝   ╚═╝          ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝
"@

# Função para saída estilizada
function Write-Styled {
    param (
        [string]$Message,
        [string]$Color = $Theme.Info,
        [string]$Prefix = "",
        [switch]$NoNewline
    )
    $emoji = switch ($Color) {
        $Theme.Success { "✅" }
        $Theme.Error   { "❌" }
        $Theme.Warning { "⚠️" }
        default        { "ℹ️" }
    }
    
    $output = if ($Prefix) { "$emoji $Prefix :: $Message" } else { "$emoji $Message" }
    if ($NoNewline) {
        Write-Host $output -ForegroundColor $Color -NoNewline
    } else {
        Write-Host $output -ForegroundColor $Color
    }
}

# Verifica privilégios de administrador
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-NOT $isAdmin) {
    Write-Styled "É necessário executar como administrador" -Color $Theme.Warning -Prefix "Permissão"
    Write-Styled "Solicitando privilégios elevados..." -Color $Theme.Primary -Prefix "Elevação"
    
    # Mostra opções de ação
    Write-Host "`nOpções:" -ForegroundColor $Theme.Primary
    Write-Host "1. Executar como administrador" -ForegroundColor $Theme.Info
    Write-Host "2. Sair" -ForegroundColor $Theme.Info
    
    $choice = Read-Host "`nDigite a opção (1-2)"
    
    if ($choice -ne "1") {
        Write-Styled "Operação cancelada" -Color $Theme.Warning -Prefix "Cancelado"
        Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor $Theme.Info
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit
    }
    
    try {
        Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Elevated"
        exit
    }
    catch {
        Write-Styled "Falha ao obter privilégios de administrador" -Color $Theme.Error -Prefix "Erro"
        Write-Styled "Execute o PowerShell como administrador e tente novamente" -Color $Theme.Warning -Prefix "Aviso"
        Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor $Theme.Info
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        exit 1
    }
}

# Se a janela foi aberta com privilégios elevados, aguarda um momento
if ($Elevated) {
    Start-Sleep -Seconds 1
}

# Exibe o logo
Write-Host $Logo -ForegroundColor $Theme.Primary
Write-Host "Criado por Ramys`n" -ForegroundColor $Theme.Info

# Configura TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Cria diretório temporário
$TmpDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
New-Item -ItemType Directory -Path $TmpDir -Force | Out-Null

# Função de limpeza
function Cleanup {
    if (Test-Path $TmpDir) {
        Remove-Item -Recurse -Force $TmpDir -ErrorAction SilentlyContinue
    }
}

try {
    # URL de download
    $url = "https://github.com/yeongpin/cursor-free-vip/releases/download/ManualReset/reset_machine_manual.exe"
    $output = Join-Path $TmpDir "reset_machine_manual.exe"

    # Download do arquivo
    Write-Styled "Baixando ferramenta de reset..." -Color $Theme.Primary -Prefix "Download"
    Invoke-WebRequest -Uri $url -OutFile $output
    Write-Styled "Download concluído!" -Color $Theme.Success -Prefix "Concluído"

    # Executa a ferramenta de reset
    Write-Styled "Iniciando ferramenta de reset..." -Color $Theme.Primary -Prefix "Execução"
    Start-Process -FilePath $output -Wait
    Write-Styled "Reset concluído!" -Color $Theme.Success -Prefix "Concluído"
}
catch {
    Write-Styled "Falha na operação" -Color $Theme.Error -Prefix "Erro"
    Write-Styled $_.Exception.Message -Color $Theme.Error
}
finally {
    Cleanup
    Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor $Theme.Info
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
