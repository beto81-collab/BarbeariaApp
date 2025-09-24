import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.dart';
import '../services/firebase_service.dart';

class AniversarioService {
  static const String _keyUltimaVerificacao = 'ultima_verificacao_aniversario';
  static const String _keyAniversariosNotificados = 'aniversarios_notificados_';

  /// Buscar clientes que fazem aniversário hoje
  static Future<List<Usuario>> buscarAniversariantesHoje() async {
    try {
      // Buscar todos os clientes
      final clientes = await FirebaseService.buscarClientes();

      // Filtrar apenas os que fazem aniversário hoje
      final aniversariantes = clientes
          .where((cliente) => cliente.isAniversarioHoje)
          .toList();

      return aniversariantes;
    } catch (e) {
      debugPrint('Erro ao buscar aniversariantes: $e');
      return [];
    }
  }

  /// Verificar se já foi notificado hoje para um cliente específico
  static Future<bool> jaFoiNotificadoHoje(String clienteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoje = DateTime.now();
      final chaveHoje = '${hoje.day}-${hoje.month}-${hoje.year}';
      final chaveCompleta = '$_keyAniversariosNotificados$clienteId';

      final ultimaNotificacao = prefs.getString(chaveCompleta);
      return ultimaNotificacao == chaveHoje;
    } catch (e) {
      debugPrint('Erro ao verificar notificação: $e');
      return false;
    }
  }

  /// Marcar cliente como notificado hoje
  static Future<void> marcarComoNotificado(String clienteId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoje = DateTime.now();
      final chaveHoje = '${hoje.day}-${hoje.month}-${hoje.year}';
      final chaveCompleta = '$_keyAniversariosNotificados$clienteId';

      await prefs.setString(chaveCompleta, chaveHoje);
    } catch (e) {
      debugPrint('Erro ao marcar notificação: $e');
    }
  }

  /// Buscar aniversariantes que ainda não foram notificados hoje
  static Future<List<Usuario>> buscarAniversariantesNaoNotificados() async {
    try {
      final aniversariantes = await buscarAniversariantesHoje();
      final naoNotificados = <Usuario>[];

      for (final cliente in aniversariantes) {
        final jaNotificado = await jaFoiNotificadoHoje(cliente.id);
        if (!jaNotificado) {
          naoNotificados.add(cliente);
        }
      }

      return naoNotificados;
    } catch (e) {
      debugPrint('Erro ao buscar não notificados: $e');
      return [];
    }
  }

  /// Verificar se é uma nova data (evita múltiplas verificações no mesmo dia)
  static Future<bool> isNovaData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hoje = DateTime.now();
      final chaveHoje = '${hoje.day}-${hoje.month}-${hoje.year}';

      final ultimaVerificacao = prefs.getString(_keyUltimaVerificacao);

      if (ultimaVerificacao != chaveHoje) {
        await prefs.setString(_keyUltimaVerificacao, chaveHoje);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Erro ao verificar nova data: $e');
      return false;
    }
  }

  /// Calcular idade atual
  static int calcularIdade(DateTime dataNascimento) {
    final agora = DateTime.now();
    int idade = agora.year - dataNascimento.year;

    if (agora.month < dataNascimento.month ||
        (agora.month == dataNascimento.month &&
            agora.day < dataNascimento.day)) {
      idade--;
    }

    return idade;
  }

  /// Gerar mensagem de aniversário personalizada
  static String gerarMensagemAniversario(Usuario cliente) {
    final idade = cliente.idade;
    if (idade != null) {
      return '🎉 ${cliente.nome} está fazendo $idade anos hoje! '
          'Que tal oferecer um desconto especial? 🎂';
    } else {
      return '🎉 ${cliente.nome} está de aniversário hoje! '
          'Que tal oferecer um desconto especial? 🎂';
    }
  }

  /// Limpar dados antigos de notificações (manutenção)
  static Future<void> limparDadosAntigos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final hoje = DateTime.now();
      final limiteData = hoje.subtract(const Duration(days: 30));

      for (final key in keys) {
        if (key.startsWith(_keyAniversariosNotificados)) {
          final valor = prefs.getString(key);
          if (valor != null) {
            try {
              final partes = valor.split('-');
              if (partes.length == 3) {
                final data = DateTime(
                  int.parse(partes[2]), // ano
                  int.parse(partes[1]), // mês
                  int.parse(partes[0]), // dia
                );

                if (data.isBefore(limiteData)) {
                  await prefs.remove(key);
                }
              }
            } catch (e) {
              // Remove dados corrompidos
              await prefs.remove(key);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Erro ao limpar dados antigos: $e');
    }
  }
}
