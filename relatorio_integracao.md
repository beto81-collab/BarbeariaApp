# Relatório de Integração Flutter Web + Firebase (CORTE REAL)

## 1. Problema Inicial
- **Erro:** `api-key-not-valid` ao tentar autenticar no Firebase Auth pelo Flutter Web.
- **Sintoma:** Login/admin não funcionava, erro retornado antes mesmo de tentar autenticar.

---

## 2. Diagnóstico e Ações Realizadas

### A. Conferência de Configuração
- Verificação do arquivo `firebase_options.dart`:
  - Checagem da chave `apiKey` e `projectId` para web.
  - Confirmação de que o projeto correto era `corte-real-6b077`.
- Conferência do método de login (e-mail/senha) ativado no Firebase Console.
- Remoção de configurações antigas e duplicadas:
  - Descontinuação do `firebase_config.dart`.
  - Remoção/comentário do script manual do Firebase em `web/index.html`.
- Garantia de uso apenas de `DefaultFirebaseOptions.currentPlatform` no `main.dart`.

### B. Limpeza e Testes
- Limpeza de cache e service workers do navegador.
- Execução dos comandos:
  ```
  flutter clean
  flutter pub get
  flutter run -d chrome
  ```
- Testes em aba anônima e outros navegadores.

### C. Troca de API Key
- Geração de uma nova API Key no Google Cloud Console.
- Atualização do campo `apiKey` do web em `firebase_options.dart`.
- Espera de alguns minutos para propagação.

### D. Resolução do Erro de API Key
- Após troca e propagação, o erro sumiu e o app passou a exibir a tela de login normalmente.

---

## 3. Upload de Imagem no Storage (Flutter Web)

### A. Sintoma
- Seleção de imagem funcionava, mas o botão "Enviar" ficava inoperante.

### B. Diagnóstico
- O botão só habilitava se `_imagensParaUpload.isNotEmpty`, mas no web as imagens vão para `_imagensBytesWeb`.

### C. Solução
- Alteração da condição do botão para:
  ```dart
  onPressed: (_imagensParaUpload.isEmpty && _imagensBytesWeb.isEmpty)
      ? null
      : _uploadImagens,
  ```
- Agora o botão habilita corretamente no web e mobile.

---

## 4. Erro de CORS no Firebase Storage

### A. Sintoma
- Erro no console:  
  `Access to XMLHttpRequest at ... has been blocked by CORS policy`

### B. Solução
- Criação do arquivo `cors.json`:
  ```json
  [
    {
      "origin": ["http://localhost:62047", "http://localhost:5000", "*"],
      "method": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      "maxAgeSeconds": 3600,
      "responseHeader": ["Content-Type", "Authorization"]
    }
  ]
  ```
- Aplicação do CORS no bucket correto:
  ```
  gsutil cors set cors.json gs://corte-real-6b077.firebasestorage.app
  ```
  (Atenção: O nome do bucket deve ser exatamente igual ao do console do Firebase Storage.)

- **Dicas de permissão:**  
  - Rodar o comando como administrador se necessário.
  - Corrigir erros de permissão e de bucket inexistente.

---

## 5. Comandos Utilizados

- Limpeza e build:
  ```
  flutter clean
  flutter pub get
  flutter run -d chrome
  ```
- Troca de API Key:
  - Atualização manual do campo `apiKey` em `firebase_options.dart`.
- Configuração de CORS:
  ```
  gsutil cors set cors.json gs://<nome-do-bucket>
  ```
- (Opcional) Instalação do Google Cloud SDK:
  ```
  npm install -g firebase-tools
  gcloud init
  ```

---

## 6. Resumo dos Problemas e Soluções

| Problema                        | Solução                                                                                   |
|----------------------------------|------------------------------------------------------------------------------------------|
| api-key-not-valid               | Conferir chave, trocar API Key, aguardar propagação, limpar cache/service worker          |
| Botão "Enviar" inoperante (web) | Corrigir condição para considerar também `_imagensBytesWeb`                              |
| Erro de CORS no Storage         | Criar e aplicar `cors.json` no bucket correto usando `gsutil`                            |
| Permissão negada no gsutil      | Rodar terminal como administrador                                                        |
| Bucket não encontrado           | Usar nome exato do bucket conforme console do Firebase Storage                           |

---

## 7. Boas Práticas para Produção
- Restringir a API Key para apenas as APIs necessárias.
- Restringir o CORS para apenas os domínios do seu app.
- Ativar apenas as APIs realmente usadas pelo app no Google Cloud.

---

**Relatório gerado automaticamente por GitHub Copilot**
Acesse: https://code.visualstudio.com/insiders/
