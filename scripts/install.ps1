# Definir tema de cores
$Theme = @{
    Primary   = 'Cyan'
    Success   = 'Green'
    Warning   = 'Yellow'
    Error     = 'Red'
    Info      = 'White'
}

# Logo em ASCII
$Logo = @"
   ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗      ██████╗ ██████╗  ██████╗   
  ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗     ██╔══██╗██╔══██╗██╔═══██╗  
  ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝     ██████╔╝██████╔╝██║   ██║  
  ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗     ██╔═══╝ ██╔══██╗██║   ██║  
  ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║     ██║     ██║  ██║╚██████╔╝  
   ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝     ╚═╝     ╚═╝  ╚═╝ ╚═════╝  
"@

# Função para saída estilizada
function Write-Styled {
    param (
        [string]$Mensagem,
        [string]$Cor = $Theme.Info,
        [string]$Prefixo = "",
        [switch]$SemNovaLinha
    )
    $simbolo = switch ($Cor) {
        $Theme.Success { "[OK]" }
        $Theme.Error   { "[X]" }
        $Theme.Warning { "[!]" }
        default        { "[*]" }
    }
    
    $saida = if ($Prefixo) { "$simbolo $Prefixo :: $Mensagem" } else { "$simbolo $Mensagem" }
    if ($SemNovaLinha) {
        Write-Host $saida -ForegroundColor $Cor -NoNewline
    } else {
        Write-Host $saida -ForegroundColor $Cor
    }
}

# Função para obter a versão mais recente
function Get-VersaoMaisRecente {
    try {
        $ultimoRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/yeongpin/cursor-free-vip/releases/latest"
        return @{
            Versao = $ultimoRelease.tag_name.TrimStart('v')
            Arquivos = $ultimoRelease.assets
        }
    } catch {
        Write-Styled $_.Exception.Message -Cor $Theme.Error -Prefixo "Erro"
        throw "Não foi possível obter a versão mais recente"
    }
}

# Exibir logo
Write-Host $Logo -ForegroundColor $Theme.Primary
$infoRelease = Get-VersaoMaisRecente
$versao = $infoRelease.Versao
Write-Host "Versão $versao" -ForegroundColor $Theme.Info
Write-Host "Criado por yeongpin`n" -ForegroundColor $Theme.Info

# Configurar TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Função principal de instalação
function Install-CursorFreeVIP {
    Write-Styled "Iniciando download do Cursor Free VIP" -Cor $Theme.Primary -Prefixo "Download"
    
    try {
        # Obter versão mais recente
        Write-Styled "Verificando versão mais recente..." -Cor $Theme.Primary -Prefixo "Atualização"
        $infoRelease = Get-VersaoMaisRecente
        $versao = $infoRelease.Versao
        Write-Styled "Versão mais recente encontrada: $versao" -Cor $Theme.Success -Prefixo "Versão"
        
        # Localizar arquivo correspondente
        $arquivo = $infoRelease.Arquivos | Where-Object { $_.name -eq "CursorFreeVIP_${versao}_windows.exe" }
        if (!$arquivo) {
            Write-Styled "Arquivo não encontrado: CursorFreeVIP_${versao}_windows.exe" -Cor $Theme.Error -Prefixo "Erro"
            Write-Styled "Arquivos disponíveis:" -Cor $Theme.Warning -Prefixo "Info"
            $infoRelease.Arquivos | ForEach-Object {
                Write-Styled "- $($_.name)" -Cor $Theme.Info
            }
            throw "Não foi possível encontrar o arquivo alvo"
        }
        
        # Verificar se o arquivo já existe na pasta de Downloads
        $caminhoDownloads = [Environment]::GetFolderPath("UserProfile") + "\Downloads"
        $caminhoDownload = Join-Path $caminhoDownloads "CursorFreeVIP_${versao}_windows.exe"
        
        if (Test-Path $caminhoDownload) {
            Write-Styled "Arquivo de instalação já existente encontrado" -Cor $Theme.Success -Prefixo "Encontrado"
            Write-Styled "Localização: $caminhoDownload" -Cor $Theme.Info -Prefixo "Local"
            
            # Verificar privilégios de administrador
            $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            if (-not $isAdmin) {
                Write-Styled "Solicitando privilégios de administrador..." -Cor $Theme.Warning -Prefixo "Admin"
                
                # Criar processo com privilégios elevados
                $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                $startInfo.FileName = $caminhoDownload
                $startInfo.UseShellExecute = $true
                $startInfo.Verb = "runas"
                
                try {
                    [System.Diagnostics.Process]::Start($startInfo)
                    Write-Styled "Programa iniciado com privilégios de administrador" -Cor $Theme.Success -Prefixo "Início"
                    return
                }
                catch {
                    Write-Styled "Falha ao iniciar com privilégios de administrador. Iniciando normalmente..." -Cor $Theme.Warning -Prefixo "Aviso"
                    Start-Process $caminhoDownload
                    return
                }
            }
            
            # Se já tiver privilégios, iniciar diretamente
            Start-Process $caminhoDownload
            return
        }
        
        Write-Styled "Nenhum arquivo de instalação encontrado, iniciando download..." -Cor $Theme.Primary -Prefixo "Download"

        # Usar HttpWebRequest para download em partes com barra de progresso
        $url = $arquivo.browser_download_url
        $arquivoSaida = $caminhoDownload
        Write-Styled "Download de: $url" -Cor $Theme.Info -Prefixo "URL"
        Write-Styled "Salvando em: $arquivoSaida" -Cor $Theme.Info -Prefixo "Caminho"

        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.UserAgent = "PowerShell Script"
        $response = $request.GetResponse()
        $tamanhoTotal = $response.ContentLength
        $responseStream = $response.GetResponseStream()
        $fileStream = [System.IO.File]::OpenWrite($arquivoSaida)
        $buffer = New-Object byte[] 8192
        $bytesLidos = 0
        $totalLido = 0
        $ultimoProgresso = -1
        $inicio = Get-Date
        try {
            do {
                $bytesLidos = $responseStream.Read($buffer, 0, $buffer.Length)
                if ($bytesLidos -gt 0) {
                    $fileStream.Write($buffer, 0, $bytesLidos)
                    $totalLido += $bytesLidos
                    $progresso = [math]::Round(($totalLido / $tamanhoTotal) * 100, 1)
                    if ($progresso -ne $ultimoProgresso) {
                        $decorrido = (Get-Date) - $inicio
                        $velocidade = if ($decorrido.TotalSeconds -gt 0) { $totalLido / $decorrido.TotalSeconds } else { 0 }
                        $velocidadeExibida = if ($velocidade -gt 1MB) {
                            "{0:N2} MB/s" -f ($velocidade / 1MB)
                        } elseif ($velocidade -gt 1KB) {
                            "{0:N2} KB/s" -f ($velocidade / 1KB)
                        } else {
                            "{0:N2} B/s" -f $velocidade
                        }
                        $baixadoMB = [math]::Round($totalLido / 1MB, 2)
                        $totalMB = [math]::Round($tamanhoTotal / 1MB, 2)
                        Write-Progress -Activity "Baixando CursorFreeVIP" -Status "$baixadoMB MB / $totalMB MB ($progresso%) - $velocidadeExibida" -PercentComplete $progresso
                        $ultimoProgresso = $progresso
                    }
                }
            } while ($bytesLidos -gt 0)
        } finally {
            $fileStream.Close()
            $responseStream.Close()
            $response.Close()
        }
        Write-Progress -Activity "Baixando CursorFreeVIP" -Completed
        # Verificar se o arquivo existe e não está vazio
        if (!(Test-Path $arquivoSaida) -or ((Get-Item $arquivoSaida).Length -eq 0)) {
            throw "Download falhou ou arquivo está vazio."
        }
        Write-Styled "Download concluído!" -Cor $Theme.Success -Prefixo "Concluído"
        Write-Styled "Local do arquivo: $arquivoSaida" -Cor $Theme.Info -Prefixo "Local"
        Write-Styled "Iniciando programa..." -Cor $Theme.Primary -Prefixo "Início"
        Start-Process $arquivoSaida
    }
    catch {
        Write-Styled $_.Exception.Message -Cor $Theme.Error -Prefixo "Erro"
        throw
    }
}

# Executar instalação
try {
    Install-CursorFreeVIP
}
catch {
    Write-Styled "Falha no download" -Cor $Theme.Error -Prefixo "Erro"
    Write-Styled $_.Exception.Message -Cor $Theme.Error
}
finally {
    Write-Host "`nPressione qualquer tecla para sair..." -ForegroundColor $Theme.Info
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
}
