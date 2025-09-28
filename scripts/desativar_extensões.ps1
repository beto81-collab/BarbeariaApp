# ============================================================================
# SCRIPT: Desativar Extensões Pesadas para Acelerar o GitHub Copilot Chat
# ============================================================================
# 
# PROBLEMA RESOLVIDO: 
# - Chat do Copilot estava lento para responder (demora para iniciar + travamentos)
# - Extension Host com erros "Canceled" ao ativar múltiplas extensões
# - Extensões pesadas causando conflitos e consumo excessivo de recursos
#
# SOLUÇÃO:
# - Desativa extensões que não são essenciais para desenvolvimento Flutter/Dart
# - Força reinstalação das extensões do GitHub Copilot 
# - Melhora significativamente a velocidade de resposta do chat
#
# USO: Execute este script sempre que o Copilot ficar lento novamente
# ============================================================================

$workspace = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outLog = Join-Path $workspace 'exthost_after_restart.log'

# Lista de extensões pesadas que causam lentidão no Copilot
# Estas extensões podem ser reativadas individualmente se necessário usando:
# code --enable-extension nome-da-extensao
$exts = @(
    'ms-azuretools.azure-dev',                    # Azure Development Tools
    'ms-azuretools.vscode-azure-github-copilot',  # Azure GitHub Copilot Integration
    'ms-azuretools.vscode-azureappservice',       # Azure App Service
    'ms-azuretools.vscode-azurecontainerapps',    # Azure Container Apps
    'ms-azuretools.vscode-azureresourcegroups',    # Azure Resource Groups
    'ms-azuretools.vscode-azurestorage',          # Azure Storage
    'ms-vscode-remote.remote-containers',         # Remote Containers (Docker)
    'redhat.java',                                # Java Language Support
    'vscjava.vscode-gradle',                      # Gradle for Java
    'ritwickdey.liveserver',                      # Live Server (HTML)
    'esbenp.prettier-vscode',                     # Prettier Code Formatter
    'dbaeumer.vscode-eslint'                      # ESLint JavaScript Linter
)

# ETAPA 1: Desativar extensões pesadas que causam conflitos
Write-Host "=== Desativando extensões pesadas ===" -ForegroundColor Cyan
Write-Output "Workspace script dir: $workspace"

foreach ($ext in $exts) {
    Write-Host "  Desativando: $ext" -ForegroundColor Yellow
    try {
        code --disable-extension ${ext} 2>&1 | ForEach-Object { Write-Output ${_} }
    } catch {
        Write-Output "Failed to disable ${ext}: ${_}"
    }
}

# ETAPA 2: Reinstalar extensões do GitHub Copilot (força atualização)
Write-Host "`n=== Reinstalando GitHub Copilot ===" -ForegroundColor Green
Write-Output "Reinstalling Copilot extensions (force)"
Write-Host "  Reinstalando github.copilot..." -ForegroundColor Yellow
code --install-extension github.copilot --force 2>&1 | ForEach-Object { Write-Output $_ }
Write-Host "  Reinstalando github.copilot-chat..." -ForegroundColor Yellow
code --install-extension github.copilot-chat --force 2>&1 | ForEach-Object { Write-Output $_ }

Start-Sleep -Seconds 1

# ETAPA 3: Reiniciar VS Code para aplicar as mudanças
Write-Host "`n=== Reiniciando VS Code ===" -ForegroundColor Magenta
# Tenta fechar todos os processos do VS Code para forçar um restart limpo
$codeProcs = Get-Process -Name Code -ErrorAction SilentlyContinue
if ($codeProcs) {
    Write-Host "  Fechando VS Code para aplicar as mudanças..." -ForegroundColor Yellow
    foreach ($p in $codeProcs) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; Write-Output "Stopped process $($p.Id)" } catch { Write-Output "Could not stop $($p.Id): $_" }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Output "No Code process found to stop."
}

# ETAPA 4: Reabrir VS Code
Write-Host "  Reabrindo VS Code..." -ForegroundColor Yellow
Start-Process -FilePath "code"

# Aguardar criação de novos logs do extension host
Start-Sleep -Seconds 6

# ETAPA 5: Coletar logs para verificação (opcional)
Write-Host "`n=== Coletando logs de verificação ===" -ForegroundColor Cyan
$latest = Get-ChildItem "$env:APPDATA\Code\logs" -Recurse -Filter exthost.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latest) {
    Write-Host "  Salvando últimas 500 linhas do exthost.log..." -ForegroundColor Yellow
    try {
        Get-Content $latest.FullName -Tail 500 | Out-File -FilePath $outLog -Encoding utf8
        Write-Host "  Log salvo em: $outLog" -ForegroundColor Green
    } catch {
        Write-Output "Failed to save log: $_"
    }
} else {
    Write-Output "No exthost.log found under $env:APPDATA\Code\logs"
}

# RESULTADO
Write-Host "`n=== CONCLUÍDO ===" -ForegroundColor Green
Write-Host "Extensões pesadas desativadas ✓" -ForegroundColor Green
Write-Host "GitHub Copilot reinstalado ✓" -ForegroundColor Green
Write-Host "VS Code reiniciado ✓" -ForegroundColor Green
Write-Host "`nO chat do Copilot deve estar mais rápido agora!" -ForegroundColor Yellow
Write-Host "`nPara reativar uma extensão específica, use:" -ForegroundColor Cyan
Write-Host "code --enable-extension nome-da-extensao" -ForegroundColor White

Write-Output "Script finished."