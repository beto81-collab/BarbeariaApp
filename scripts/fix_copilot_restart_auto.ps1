# Script: fix_copilot_restart_auto.ps1
# Objetivo: desativar extensões pesadas, reinstalar Copilot, reiniciar VS Code e coletar exthost.log

$workspace = Split-Path -Parent $MyInvocation.MyCommand.Definition
$outLog = Join-Path $workspace 'exthost_after_restart.log'

$exts = @(
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

Write-Output "Workspace script dir: $workspace"

foreach ($ext in $exts) {
    Write-Output "Disabling extension $ext"
    try {
        code --disable-extension ${ext} 2>&1 | ForEach-Object { Write-Output ${_} }
    } catch {
        Write-Output "Failed to disable ${ext}: ${_}"
    }
}

Write-Output "Reinstalling Copilot extensions (force)"
code --install-extension github.copilot --force 2>&1 | ForEach-Object { Write-Output $_ }
code --install-extension github.copilot-chat --force 2>&1 | ForEach-Object { Write-Output $_ }

Start-Sleep -Seconds 1

# Try to stop Code processes to force a clean restart
$codeProcs = Get-Process -Name Code -ErrorAction SilentlyContinue
if ($codeProcs) {
    Write-Output "Stopping Code processes (this will close VS Code)."
    foreach ($p in $codeProcs) {
        try { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue; Write-Output "Stopped process $($p.Id)" } catch { Write-Output "Could not stop $($p.Id): $_" }
    }
    Start-Sleep -Seconds 2
} else {
    Write-Output "No Code process found to stop."
}

# Start VS Code
Write-Output "Starting VS Code..."
Start-Process -FilePath "code"

# Wait for extension host logs to be created
Start-Sleep -Seconds 6

# Collect latest exthost.log
$latest = Get-ChildItem "$env:APPDATA\Code\logs" -Recurse -Filter exthost.log -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($latest) {
    Write-Output "Saving tail of $($latest.FullName) to $outLog"
    try {
        Get-Content $latest.FullName -Tail 500 | Out-File -FilePath $outLog -Encoding utf8
        Write-Output "Saved log to $outLog"
    } catch {
        Write-Output "Failed to save log: $_"
    }
} else {
    Write-Output "No exthost.log found under $env:APPDATA\Code\logs"
}

Write-Output "Script finished."