# Script: fix_copilot_restart.ps1
# Propósito: desativar extensões pesadas, forçar reinstalação do GitHub Copilot/Copilot Chat,
# reiniciar o VS Code e coletar o exthost.log após o restart para análise.

$ErrorActionPreference = 'Stop'

Write-Output "[1/6] Disabling heavy extensions..."
$extToDisable = @(
    'ms-azuretools.azure-dev',
    'ms-azuretools.vscode-azure-github-copilot',
    'ms-azuretools.vscode-azureappservice',
    'ms-azuretools.vscode-azurecontainerapps',
    'ms-azuretools.vscode-azureresourcegroups',
    'ms-azuretools.vscode-azurestorage',
    'ms-vscode-remote.remote-containers',
    'redhat.java',
    'vscjava.vscode-gradle',
    'ritwickdey.liveserver',
    'esbenp.prettier-vscode',
    'dbaeumer.vscode-eslint'
)
foreach ($ext in $extToDisable) {
    try {
        Write-Output " Disabling $ext"
        code --disable-extension $ext 2>&1 | Write-Output
    } catch {
        Write-Output "  (warning) falha ao desativar ${ext}: $_"
    }
}

Write-Output "[2/6] Forçando reinstalação do GitHub Copilot e Copilot Chat..."
code --install-extension github.copilot --force 2>&1 | Write-Output
code --install-extension github.copilot-chat --force 2>&1 | Write-Output

Write-Output "[3/6] Capturando status do VS Code antes do restart..."
code --status 2>&1 | Out-File -FilePath "$PSScriptRoot\code_status_before.txt" -Encoding utf8

Write-Output "[4/6] Fechando o VS Code (Code.exe) para forçar restart..."
# Fecha instâncias do VS Code
try {
    Stop-Process -Name Code -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 800
} catch {
    Write-Output "  (info) Não foi possível parar o processo Code (talvez já fechado)."
}

Write-Output "[5/6] Abrindo o VS Code novamente... (pode demorar alguns segundos)"
Start-Process -FilePath "code" -ArgumentList "." -WorkingDirectory "$PSScriptRoot\.." -WindowStyle Normal
Start-Sleep -Seconds 12

Write-Output "[6/6] Coletando exthost.log mais recente e salvando em exthost_after_restart.log"
$latest = Get-ChildItem "$env:APPDATA\Code\logs" -Recurse -Filter exthost.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latest) {
    $outFile = "$PSScriptRoot\exthost_after_restart.log"
    Write-Output " Latest exthost.log: $($latest.FullName)"
    Get-Content $latest.FullName -Tail 1000 | Out-File -FilePath $outFile -Encoding utf8
    Write-Output " Saved to $outFile"
    Write-Output " --- Últimas 200 linhas: ---"
    Get-Content $outFile -Tail 200 | Write-Output
} else {
    Write-Output "Nenhum exthost.log encontrado em $env:APPDATA\Code\logs"
}

Write-Output "Script finalizado. Verifique 'exthost_after_restart.log' no diretório 'scripts' do projeto."