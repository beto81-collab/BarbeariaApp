## 🔐 Credenciais de Administrador - CORTE REAL

### 📋 **Credenciais Atuais do Administrador**

Baseado na análise do código atual em `lib/services/firebase_service.dart` (linha 373-376):

- **📧 Email**: `admin@barbearia.com`
- **🔐 Senha**: `Cortereal2025` *(observe o "C" maiúsculo)*
- **👤 Nome**: `Gerente da Barbearia`
- **📞 Telefone**: `(51) 98061-7630`
- **🎭 Tipo**: `TipoUsuario.admin`

### 🔍 **Localização no Código**

```dart
// Arquivo: lib/services/firebase_service.dart (linha ~373)
await criarUsuarioAdmin(
  email: 'admin@barbearia.com',        // ← Email do admin
  senha: 'Cortereal2025',              // ← Senha do admin (C maiúsculo)
  nome: 'Gerente da Barbearia',        // ← Nome completo
  telefone: '(51) 98061-7630',         // ← Telefone
);
```

### ✅ **Detecção Automática de Admin**

O sistema detecta automaticamente usuários admin através de:

```dart
// Arquivo: lib/main.dart (linha ~75)
if (usuario?.isAdmin == true || usuario?.tipo == TipoUsuario.admin) {
  return const AdminDashboardScreen();  // Redireciona para dashboard admin
}
```

### 🚨 **Possíveis Problemas de Login**

1. **⚠️ Senha com Maiúscula**: A senha atual é `Cortereal2025` (C maiúsculo)
2. **🔄 Cache do Firebase**: Usuário admin pode não ter sido criado ainda
3. **📱 Conexão**: Problemas de rede com Firebase
4. **🗄️ Firestore**: Documento de usuário não criado no Firestore

### 🛠️ **Soluções Recomendadas**

#### **Opção 1: Testar Credenciais Atuais**
```
Email: admin@barbearia.com
Senha: Cortereal2025
```

#### **Opção 2: Simplificar a Senha**
Se quiser uma senha mais simples, posso alterar para:
```
Email: admin@barbearia.com
Senha: admin123
```

#### **Opção 3: Forçar Recriação do Admin**
Limpar cache do Firebase e recriar o usuário admin.

### 🔧 **Para Alterar as Credenciais**

Se quiser mudar as credenciais, altere as linhas 373-376 em `firebase_service.dart`:

```dart
await criarUsuarioAdmin(
  email: 'NOVO_EMAIL@dominio.com',
  senha: 'NOVA_SENHA',
  nome: 'Nome do Admin',
  telefone: 'Telefone',
);
```

### 🎯 **Status Atual**

- ✅ Código configurado para criar usuário admin
- ✅ Detecção automática de tipo admin funcionando
- ✅ Redirecionamento para AdminDashboardScreen configurado
- ⚠️ Possível problema: Senha com maiúscula pode confundir

---

**💡 Recomendação**: Teste primeiro com `Cortereal2025` (C maiúsculo). Se não funcionar, podemos simplificar para `admin123`.