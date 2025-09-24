## 📧 CONFIGURAÇÃO GMAIL - CORTE REAL

### 🎯 **PRÓXIMOS PASSOS APÓS CRIAR GMAIL:**

#### **1. 📧 Criar Conta Gmail** ✅
```
Sugestões de nomes:
- cortereal.barbearia@gmail.com
- barbearia.cortereal@gmail.com
- admin.cortereal@gmail.com
- contato.cortereal@gmail.com
```

---

### 🔥 **2. CONFIGURAR FIREBASE**

#### **A. Criar Projeto Firebase:**
1. **Acessar**: https://console.firebase.google.com/
2. **Fazer login** com a nova conta Gmail
3. **Criar projeto**: "corte-real-app" (ou nome preferido)
4. **Ativar Google Analytics**: Recomendado
5. **Aguardar** criação do projeto

#### **B. Ativar Serviços Necessários:**

**🔐 Authentication:**
- Ir em **Authentication** → **Sign-in method**
- Ativar **Email/Password**
- Configurar domínios autorizados

**📊 Firestore Database:**
- Ir em **Firestore Database**
- **Criar banco** em modo produção
- Escolher região (us-central1 ou southamerica-east1)

**🔔 Cloud Messaging:**
- Ir em **Cloud Messaging**
- Já vem ativo por padrão

**📱 Storage:**
- Ir em **Storage**
- Criar bucket para imagens/arquivos

---

### 📱 **3. CONFIGURAR ANDROID**

#### **A. Adicionar App Android:**
1. **Project Overview** → **Add app** → **Android**
2. **Package name**: `com.cortereal.barbearia_app`
3. **Nickname**: "CORTE REAL Android"
4. **SHA-1**: (opcional por enquanto)

#### **B. Baixar Configuração:**
1. **Download** `google-services.json`
2. **Substituir** arquivo em: `android/app/google-services.json`

---

### 🍎 **4. CONFIGURAR IOS (Se necessário)**

#### **A. Adicionar App iOS:**
1. **Add app** → **iOS**
2. **Bundle ID**: `com.cortereal.barbeariaApp`
3. **Nickname**: "CORTE REAL iOS"

#### **B. Baixar Configuração:**
1. **Download** `GoogleService-Info.plist`
2. **Adicionar** em: `ios/Runner/GoogleService-Info.plist`

---

### 🔧 **5. ATUALIZAR CÓDIGO DO APP**

#### **A. Verificar Firebase Config:**
Arquivo: `lib/services/firebase_config.dart`
```dart
// Os dados serão atualizados automaticamente quando 
// substituir o google-services.json
```

#### **B. Aplicar Regras Firestore:**
1. **Firestore** → **Rules**
2. **Copiar** conteúdo do arquivo `firestore.rules`
3. **Publicar** as regras

---

### 🧪 **6. TESTAR CONFIGURAÇÃO**

#### **A. Compilar e Testar:**
```powershell
# Limpar build anterior
flutter clean
flutter pub get

# Testar no Chrome
flutter run -d chrome

# Compilar APK final
flutter build apk --release
```

#### **B. Verificar Conexões:**
- ✅ **Login/Cadastro** funcionando
- ✅ **Agendamentos** salvando no Firestore
- ✅ **Notificações** funcionando
- ✅ **Admin** acessando dados

---

### 💰 **7. CONFIGURAR BILLING (IMPORTANTE)**

#### **A. Plano Spark (Gratuito):**
- **Firestore**: 50k leituras/20k escritas por dia
- **Authentication**: Ilimitado gratuito
- **Storage**: 1GB gratuito

#### **B. Se Precisar de Mais:**
- **Plano Blaze**: Pay-as-you-go
- **Custos típicos**: $5-20/mês para app pequeno/médio

---

### 📋 **CHECKLIST PÓS-CONFIGURAÇÃO:**

#### **✅ Firebase Console:**
- [ ] Projeto criado
- [ ] Authentication ativado
- [ ] Firestore criado
- [ ] Regras aplicadas
- [ ] Apps Android/iOS adicionados

#### **✅ Arquivos Baixados:**
- [ ] `google-services.json` (Android)
- [ ] `GoogleService-Info.plist` (iOS)

#### **✅ Testes:**
- [ ] App compila sem erro
- [ ] Login funcionando
- [ ] Dados salvando no Firestore
- [ ] Notificações ativas

---

### 🎯 **RESULTADO ESPERADO:**

**🔥 Firebase 100% Funcional:**
- ☁️ **Dados na nuvem** (Firestore)
- 🔐 **Login seguro** (Authentication)
- 🔔 **Notificações** (Cloud Messaging)
- 📱 **App totalmente online**

---

### 📞 **SE PRECISAR DE AJUDA:**

1. **Compartilhe** os dados do projeto Firebase
2. **Mostre** eventuais erros na configuração
3. **Teste** cada etapa e me informe resultados

**🚀 Pronto para começar? Crie a conta e vamos configurar tudo!**