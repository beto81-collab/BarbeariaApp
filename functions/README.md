# Cloud Functions - Barbearia CORTE REAL

## Função automática de presente de aniversário

Esta função agenda diariamente o envio da oferta de aniversário para todos os usuários aniversariantes do dia, sem necessidade de ação manual do admin.

### Como funciona
- Roda todos os dias às 00:10 (horário de Brasília).
- Busca todos os usuários com aniversário no dia.
- Busca a oferta de aniversário ativa (coleção `ofertas_aniversario`).
- Atualiza o campo `presenteAniversario` no documento do usuário, se ainda não tiver presente pendente.
- Permite que a oferta não tenha produto ou serviço ("Nenhum").

### Estrutura esperada no Firestore
- Coleção `usuarios`:
  - Campos: `dataNascimentoDia` (string, ex: '23'), `dataNascimentoMes` (string, ex: '09'), `presenteAniversario` (mapa)
- Coleção `ofertas_aniversario`:
  - Campos: `ativa` (bool), `produtoEspecial` (opcional), `servicoEspecial` (opcional), outros campos customizados

### Deploy
1. Instale dependências:
   ```bash
   cd functions
   npm install
   ```
2. Faça login no Firebase CLI e configure o projeto:
   ```bash
   firebase login
   firebase use --add
   ```
3. Faça o deploy:
   ```bash
   npm run deploy
   ```

### Observações
- A função só envia o presente se o usuário não tiver um presente pendente ou já resgatado.
- O admin pode cadastrar ofertas com ou sem produto/serviço ("Nenhum").
- Para testes locais, use o emulador do Firebase Functions.

---

Dúvidas? Consulte o código em `functions/index.js` ou peça suporte ao desenvolvedor.

---

### Verificações de Ambiente

Antes de iniciar, verifique se as versões do Node.js e npm estão atualizadas:

```bash
node -v
npm -v
```
