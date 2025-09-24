# CORTE REAL 💈

Um aplicativo Flutter moderno e elegante para a barbearia CORTE REAL, oferecendo uma experiência completa tanto para clientes quanto para barbeiros.

## ✨ Funcionalidades

### 🔐 Autenticação
- Sistema de login seguro
- Validação de formulários
- Interface intuitiva e profissional

### 📱 Dashboard Interativo
- **Início**: Visão geral com ações rápidas
- **Serviços**: Catálogo completo de serviços oferecidos
- **Barbeiros**: Perfis dos profissionais com avaliações
- **Agendamentos**: Gestão de horários e compromissos

### 🎨 Design Profissional
- Tema escuro elegante
- Cores inspiradas no ambiente de barbearia
- Interface responsiva e moderna
- Experiência do usuário otimizada

## 🚀 Como Executar

### Pré-requisitos
- Flutter SDK (versão 3.0 ou superior)
- Dart SDK
- Android Studio ou VS Code com extensões Flutter/Dart

### Instalação
1. Clone o repositório:
   ```bash
   git clone [url-do-repositorio]
   cd BarbeariaApp
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Execute o aplicativo:
   ```bash
   flutter run
   ```

## 🎨 Logo e Branding

O aplicativo apresenta o logo personalizado da **CORTE REAL**, implementado como widgets customizados Flutter:
- **Logo Circular**: Para telas de apresentação e login
- **Logo Horizontal**: Para AppBar e cabeçalhos
- **Cores da marca**: Dourado elegante com fundo escuro profissional

## 📁 Estrutura do Projeto

```
lib/
├── main.dart              # Ponto de entrada da aplicação
├── models/                # Modelos de dados
│   ├── agendamento.dart   # Modelo para agendamentos
│   ├── barbeiro.dart      # Modelo para barbeiros
│   ├── servico.dart       # Modelo para serviços
│   └── usuario.dart       # Modelo para usuários
├── screens/               # Telas do aplicativo
│   ├── dashboard_screen.dart  # Dashboard principal
│   └── login_screen.dart      # Tela de login
├── theme/                 # Configurações de tema
│   └── app_theme.dart     # Tema personalizado
├── widgets/               # Componentes reutilizáveis
│   └── logo_corte_real.dart   # Widgets do logo da marca
└── services/              # Serviços e APIs
```

## 🎯 Funcionalidades em Desenvolvimento

- [ ] Sistema de cadastro de usuários
- [ ] Recuperação de senha
- [ ] Agendamento de horários
- [ ] Sistema de notificações
- [ ] Perfil de usuário
- [ ] Avaliações e comentários
- [ ] Integração com pagamento
- [ ] Histórico de agendamentos

## 🛠️ Tecnologias Utilizadas

- **Flutter**: Framework principal
- **Dart**: Linguagem de programação
- **Material Design 3**: Sistema de design
- **Provider** (futuro): Gerenciamento de estado

## 🎨 Paleta de Cores

- **Primária**: #1A1A1A (Preto profissional)
- **Secundária**: #D4AF37 (Dourado elegante)
- **Accent**: #8B4513 (Marrom amadeirado)
- **Background**: #121212 (Preto suave)
- **Surface**: #1E1E1E (Cinza escuro)

## 📝 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

## 👥 Contribuições

Contribuições são bem-vindas! Por favor, leia as diretrizes de contribuição antes de enviar pull requests.

---

Desenvolvido com ❤️ para a comunidade de barbearias
