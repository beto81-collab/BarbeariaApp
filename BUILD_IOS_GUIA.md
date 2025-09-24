## 📱 GUIA: Compilando para iOS - CORTE REAL

### 🚨 **REQUISITOS ESSENCIAIS:**

#### **Hardware:**
- 🍎 **Mac** (MacBook, iMac, Mac Mini, etc.)
- **RAM**: Mínimo 8GB (recomendado 16GB)
- **Storage**: 50GB+ livres

#### **Software:**
- 🔧 **Xcode** (versão mais recente da App Store)
- 🔥 **Flutter** instalado no Mac
- 📱 **Apple Developer Account** (para distribuição)

---

### 🔧 **PREPARAÇÃO NO WINDOWS (Já Feito):**

#### **✅ Configurações iOS Otimizadas:**
- **Nome do App**: "CORTE REAL"  
- **Bundle ID**: Configurado
- **Info.plist**: Otimizado
- **Firebase**: Configurado para iOS

---

### 🍎 **PASSOS NO MAC:**

#### **1. Instalar Flutter no Mac:**
```bash
# Instalar Flutter
git clone https://github.com/flutter/flutter.git
export PATH="$PATH:`pwd`/flutter/bin"

# Verificar instalação
flutter doctor
```

#### **2. Instalar Xcode:**
```bash
# Da App Store ou
xcode-select --install
```

#### **3. Transferir Projeto:**
```bash
# Copiar pasta do projeto para Mac
# Ou usar Git:
git clone [seu-repositorio]
cd BarbeariaApp
```

#### **4. Configurar Firebase iOS:**
```bash
# No Firebase Console:
# 1. Adicionar iOS app
# 2. Bundle ID: com.cortereal.app
# 3. Baixar GoogleService-Info.plist
# 4. Colocar em ios/Runner/
```

#### **5. Instalar Dependências:**
```bash
flutter pub get
cd ios
pod install
cd ..
```

#### **6. Compilar para iOS:**
```bash
# Para dispositivo/simulador (debug)
flutter run -d ios

# Para release (App Store)
flutter build ios --release

# Gerar IPA (arquivo final)
flutter build ipa --release
```

---

### ☁️ **ALTERNATIVA: BUILD NA NUVEM**

#### **🔥 Codemagic (Recomendado):**

1. **Conta**: https://codemagic.io/
2. **Conectar**: GitHub/GitLab repository  
3. **Configurar**: YAML build script
4. **Certificados**: Apple Developer certificates
5. **Build**: Automático na nuvem

**Exemplo codemagic.yaml:**
```yaml
workflows:
  ios-workflow:
    name: iOS Workflow
    instance_type: mac_mini_m1
    environment:
      flutter: 3.35.2
      ios_signing:
        distribution_type: app_store
    scripts:
      - name: Install dependencies
        script: flutter pub get
      - name: Build iOS
        script: flutter build ipa --release
    artifacts:
      - build/ios/ipa/*.ipa
```

---

### 📋 **CHECKLIST PRÉ-BUILD:**

#### **✅ Certificados Apple:**
- [ ] Apple Developer Account ($99/ano)
- [ ] iOS Distribution Certificate
- [ ] App Store Provisioning Profile
- [ ] Bundle ID registrado

#### **✅ Firebase iOS:**
- [ ] iOS app adicionado no Firebase Console
- [ ] GoogleService-Info.plist baixado
- [ ] Colocado em ios/Runner/

#### **✅ App Store Preparação:**
- [ ] Ícones do app (todos os tamanhos)
- [ ] Screenshots para App Store
- [ ] Descrição do app
- [ ] Política de privacidade

---

### 🎯 **ARQUIVOS FINAIS:**

#### **Após Build Bem-sucedido:**
```
📱 ARQUIVOS iOS:
├── 📦 CORTE_REAL.ipa (arquivo final)
├── 📊 Runner.app (para simulador)
└── 🔧 build/ (arquivos de build)
```

#### **Para Distribuição:**
- **TestFlight**: Upload do .ipa
- **App Store**: Submissão via App Store Connect
- **Ad-hoc**: Distribuição direta por link

---

### 💰 **CUSTOS ENVOLVIDOS:**

#### **Apple:**
- **Developer Account**: $99/ano
- **Certificados**: Inclusos na conta

#### **Build Services (Opcionais):**
- **Codemagic**: Grátis (500 min/mês) | Pago ($28+/mês)
- **Bitrise**: Grátis (200 builds/mês) | Pago
- **GitHub Actions**: Grátis (2000 min/mês)

---

### 🚀 **PRÓXIMOS PASSOS:**

#### **Opção 1: Mac Disponível**
1. Seguir passos do Mac acima
2. Configurar Xcode e certificados
3. Compilar diretamente

#### **Opção 2: Build na Nuvem**
1. Criar conta no Codemagic
2. Conectar repositório Git
3. Configurar certificados
4. Build automático

#### **Opção 3: Terceirizar**
1. Contratar desenvolvedor iOS
2. Enviar projeto Flutter
3. Receber IPA pronto

---

### 📞 **SUPORTE:**

Se precisar de ajuda com:
- 🍎 Configuração no Mac
- ☁️ Setup do build na nuvem  
- 📱 Certificados Apple
- 🏪 Publicação na App Store

**O projeto está preparado para iOS!** Só precisa do ambiente Mac para compilar.

**🎯 Recomendação**: Use Codemagic se não tiver Mac disponível!