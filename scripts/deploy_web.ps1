# ============================================================================
# SCRIPT: Deploy Automático para Firebase Hosting
# ============================================================================
# 
# FUNCIONALIDADES:
# - Faz build otimizado da versão web do Flutter
# - Incrementa a versão automaticamente no pubspec.yaml
# - Faz deploy para Firebase Hosting
# - Mostra a URL do app publicado
#
# USO: Execute este script sempre que quiser atualizar a versão web
# ============================================================================

$ErrorActionPreference = "Stop"

Write-Host "=== Deploy Automático para Firebase Hosting ===" -ForegroundColor Green

# ETAPA 1: Verificar se está no diretório correto
$pubspecPath = "pubspec.yaml"
if (-not (Test-Path $pubspecPath)) {
    Write-Host "ERRO: pubspec.yaml não encontrado. Execute o script na raiz do projeto Flutter." -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Verificando dependências ===" -ForegroundColor Cyan

# Verificar se Flutter está instalado
try {
    $flutterVersion = flutter --version 2>&1 | Select-Object -First 1
    Write-Host "✓ Flutter encontrado: $flutterVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ ERRO: Flutter não encontrado no PATH" -ForegroundColor Red
    exit 1
}

# Verificar se Firebase CLI está instalado
try {
    $firebaseVersion = firebase --version 2>&1
    Write-Host "✓ Firebase CLI encontrado: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ ERRO: Firebase CLI não encontrado. Instale com: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

# ETAPA 2: Limpar builds anteriores
Write-Host "`n=== Limpando builds anteriores ===" -ForegroundColor Cyan
if (Test-Path "build/web") {
    Remove-Item -Recurse -Force "build/web"
    Write-Host "✓ Build anterior removido" -ForegroundColor Green
}

# ETAPA 3: Incrementar versão (opcional)
Write-Host "`n=== Incrementando versão ===" -ForegroundColor Cyan
$pubspecContent = Get-Content $pubspecPath
$versionLine = $pubspecContent | Where-Object { $_ -match "^version:\s*(.+)$" }
if ($versionLine) {
    $currentVersion = $matches[1]
    Write-Host "Versão atual: $currentVersion" -ForegroundColor Yellow
    
    # Incrementar patch version (ex: 1.0.0+1 -> 1.0.0+2)
    if ($currentVersion -match "^(\d+\.\d+\.\d+)\+(\d+)$") {
        $baseVersion = $matches[1]
        $buildNumber = [int]$matches[2] + 1
        $newVersion = "$baseVersion+$buildNumber"
        
        $pubspecContent = $pubspecContent -replace "^version:\s*.+$", "version: $newVersion"
        Set-Content -Path $pubspecPath -Value $pubspecContent -Encoding UTF8
        
        Write-Host "✓ Nova versão: $newVersion" -ForegroundColor Green
    } else {
        Write-Host "✓ Formato de versão não reconhecido, mantendo: $currentVersion" -ForegroundColor Yellow
    }
}

# ETAPA 4: Flutter clean e pub get
Write-Host "`n=== Preparando dependências ===" -ForegroundColor Cyan
Write-Host "Executando flutter clean..." -ForegroundColor Yellow
flutter clean

Write-Host "Executando flutter pub get..." -ForegroundColor Yellow
flutter pub get

# ETAPA 5: Build para web
Write-Host "`n=== Fazendo build para web ===" -ForegroundColor Cyan
Write-Host "Executando flutter build web --release..." -ForegroundColor Yellow

try {
    flutter build web --release --web-renderer html
    Write-Host "✓ Build web concluído com sucesso!" -ForegroundColor Green
} catch {
    Write-Host "✗ ERRO no build web: $_" -ForegroundColor Red
    exit 1
}

# ETAPA 6: Verificar arquivos gerados
if (-not (Test-Path "build/web/index.html")) {
    Write-Host "✗ ERRO: Arquivos web não foram gerados corretamente" -ForegroundColor Red
    exit 1
}

$webFiles = Get-ChildItem "build/web" -Recurse | Measure-Object
Write-Host "✓ $($webFiles.Count) arquivos gerados em build/web/" -ForegroundColor Green

# ETAPA 7: Deploy para Firebase
Write-Host "`n=== Fazendo deploy para Firebase ===" -ForegroundColor Cyan
Write-Host "Executando firebase deploy..." -ForegroundColor Yellow

try {
    $deployOutput = firebase deploy --only hosting 2>&1
    Write-Host $deployOutput -ForegroundColor White
    
    # Extrair URL do projeto
    $urlMatch = $deployOutput | Select-String "Hosting URL: (https://[^\s]+)"
    if ($urlMatch) {
        $hostingUrl = $urlMatch.Matches[0].Groups[1].Value
        Write-Host "`n🎉 DEPLOY CONCLUÍDO COM SUCESSO! 🎉" -ForegroundColor Green
        Write-Host "`n📱 Seu app está disponível em:" -ForegroundColor Cyan
        Write-Host "$hostingUrl" -ForegroundColor White -BackgroundColor Blue
    } else {
        Write-Host "✓ Deploy concluído!" -ForegroundColor Green
    }
    
} catch {
    Write-Host "✗ ERRO no deploy: $_" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== RESUMO ===" -ForegroundColor Green
Write-Host "✓ Build web gerado" -ForegroundColor Green
Write-Host "✓ Versão incrementada" -ForegroundColor Green  
Write-Host "✓ Deploy para Firebase concluído" -ForegroundColor Green
Write-Host "`nPara fazer novo deploy, execute novamente este script!" -ForegroundColor Yellow