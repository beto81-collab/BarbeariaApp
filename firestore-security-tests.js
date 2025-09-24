// ==================== TESTES DAS REGRAS DE SEGURANÇA ====================

/* 
Para testar as regras no Firebase Console:
1. Vá em Firestore Database → Regras → Simulador de Regras
2. Use os exemplos abaixo para validar
*/

// TESTE 1: Usuário tentando acessar seus próprios dados ✅ PERMITIDO
// Configuração do simulador:
// - Documento: /usuarios/USER_123
// - Usuário autenticado: USER_123
// - Operação: get
// Resultado esperado: ✅ Permitido

// TESTE 2: Usuário tentando acessar dados de outro usuário ❌ NEGADO
// Configuração do simulador:
// - Documento: /usuarios/USER_456
// - Usuário autenticado: USER_123
// - Operação: get
// Resultado esperado: ❌ Negado

// TESTE 3: Cliente criando agendamento válido ✅ PERMITIDO
// Configuração do simulador:
// - Documento: /agendamentos/AGEND_123
// - Usuário autenticado: USER_123
// - Operação: create
// - Dados do documento:
{
  "clienteId": "USER_123",
  "barbeiroId": "BARBER_456", 
  "servicoId": "SERVICE_789",
  "dataHora": "2025-09-25T10:00:00Z", // Data futura
  "status": "agendado",
  "valor": 25.0,
  "observacoes": ""
}
// Resultado esperado: ✅ Permitido

// TESTE 4: Cliente tentando agendar no passado ❌ NEGADO
// Configuração do simulador:
// - Documento: /agendamentos/AGEND_456
// - Usuário autenticado: USER_123
// - Operação: create
// - Dados do documento:
{
  "clienteId": "USER_123",
  "barbeiroId": "BARBER_456",
  "servicoId": "SERVICE_789", 
  "dataHora": "2025-09-10T10:00:00Z", // Data no passado
  "status": "agendado",
  "valor": 25.0
}
// Resultado esperado: ❌ Negado

// TESTE 5: Usuário não autenticado tentando ler serviços ❌ NEGADO
// Configuração do simulador:
// - Documento: /servicos/SERVICE_123
// - Usuário autenticado: (deixar vazio)
// - Operação: get
// Resultado esperado: ❌ Negado

// TESTE 6: Cliente autenticado lendo produtos ✅ PERMITIDO
// Configuração do simulador:
// - Documento: /produtos/PROD_123
// - Usuário autenticado: USER_123
// - Operação: get
// Resultado esperado: ✅ Permitido

// TESTE 7: Cliente tentando editar produto ❌ NEGADO
// Configuração do simulador:
// - Documento: /produtos/PROD_123
// - Usuário autenticado: USER_123 (tipo: cliente)
// - Operação: update
// Resultado esperado: ❌ Negado

/* 
COMO CRIAR UM USUÁRIO ADMIN PARA TESTES:

1. Cadastre um usuário normalmente pelo app
2. No Firestore Database, vá na coleção 'usuarios'
3. Encontre o documento do usuário
4. Edite o campo 'tipo' de 'cliente' para 'admin'
5. Agora esse usuário pode editar produtos e serviços
*/

// ==================== LOGS DE SEGURANÇA ====================

/*
Para monitorar tentativas de acesso negado:

1. Vá em Firestore Database → Uso
2. Monitore as métricas de "Leituras negadas" e "Escritas negadas"
3. Configure alertas para detectar ataques

Em caso de muitas tentativas negadas:
- Analise os logs
- Considere implementar rate limiting
- Reforce regras se necessário
*/