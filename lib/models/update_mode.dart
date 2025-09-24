/// Modos de verificação de atualização
enum UpdateCheckMode {
  production, // Produção: verifica a cada 6 horas
  development, // Desenvolvimento: verifica a cada 15 minutos
  testing, // Testes: verifica a cada 1 minuto
  always, // Sempre verifica (ignora cache)
  disabled, // Desabilitado
}
