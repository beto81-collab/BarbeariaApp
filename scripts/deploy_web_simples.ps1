# Deploy automatico para Firebase Hosting
Write-Host "=== Deploy Automatico para Firebase Hosting ===" -ForegroundColor Green

# Verificar se esta no diretorio correto
if (-not (Test-Path "pubspec.yaml")) {
    Write-Host "ERRO: Execute o script na raiz do projeto Flutter." -ForegroundColor Red
    exit 1
}

# Limpar build anterior
Write-Host "`nLimpando build anterior..." -ForegroundColor Cyan
if (Test-Path "build/web") {
    Remove-Item -Recurse -Force "build/web"
}

# Flutter clean e pub get
Write-Host "`nPreparando dependencias..." -ForegroundColor Cyan
flutter clean
flutter pub get

# Build para web
Write-Host "`nFazendo build para web..." -ForegroundColor Cyan
flutter build web --release

# Verificar se build foi bem-sucedido
if (-not (Test-Path "build/web/index.html")) {
    Write-Host "ERRO: Build web falhou!" -ForegroundColor Red
    exit 1
}

Write-Host "Build web concluido com sucesso!" -ForegroundColor Green

# Deploy apenas hosting (sem functions)
Write-Host "`nFazendo deploy para Firebase..." -ForegroundColor Cyan
firebase deploy --only hosting

Write-Host "`n=== DEPLOY CONCLUIDO ===" -ForegroundColor Green
Write-Host "Seu app foi atualizado no Firebase Hosting!" -ForegroundColor Yellow