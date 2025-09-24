import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_version.dart';
import '../models/update_mode.dart';

class UpdateService {
  static const String _lastUpdateCheckKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version_';
  static const String _updateModeKey = 'update_check_mode';

  // Diferentes intervalos baseados no modo
  static const Duration _productionInterval = Duration(hours: 6);
  static const Duration _developmentInterval = Duration(minutes: 15);
  static const Duration _testingInterval = Duration(minutes: 1);

  /// Define o modo de verificação de atualizações
  static Future<void> setUpdateCheckMode(UpdateCheckMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_updateModeKey, mode.name);
    debugPrint('UpdateService: Modo alterado para ${mode.name}');
  }

  /// Obtém o modo atual de verificação
  static Future<UpdateCheckMode> getUpdateCheckMode() async {
    final prefs = await SharedPreferences.getInstance();
    final modeString = prefs.getString(_updateModeKey);

    if (modeString != null) {
      return UpdateCheckMode.values.firstWhere(
        (mode) => mode.name == modeString,
        orElse: () => _getDefaultMode(),
      );
    }

    return _getDefaultMode();
  }

  /// Determina o modo padrão baseado no ambiente
  static UpdateCheckMode _getDefaultMode() {
    if (kDebugMode) {
      return UpdateCheckMode.development;
    }
    return UpdateCheckMode.production;
  }

  /// Obtém o intervalo baseado no modo
  static Duration _getIntervalForMode(UpdateCheckMode mode) {
    switch (mode) {
      case UpdateCheckMode.production:
        return _productionInterval;
      case UpdateCheckMode.development:
        return _developmentInterval;
      case UpdateCheckMode.testing:
        return _testingInterval;
      case UpdateCheckMode.always:
        return Duration.zero; // Sempre verifica
      case UpdateCheckMode.disabled:
        return Duration(days: 365); // Nunca verifica
    }
  }

  /// Verifica se há atualizações disponíveis (com controle de modo)
  static Future<AppVersion?> checkForUpdate({bool forceCheck = false}) async {
    try {
      final mode = await getUpdateCheckMode();

      // Se está desabilitado, não verifica
      if (mode == UpdateCheckMode.disabled && !forceCheck) {
        debugPrint('UpdateService: Verificação desabilitada');
        return null;
      }

      // Verificar se já verificou recentemente (a menos que seja forçado)
      if (!forceCheck && mode != UpdateCheckMode.always) {
        final lastCheck = await _getLastUpdateCheck();
        final interval = _getIntervalForMode(mode);

        if (lastCheck != null &&
            DateTime.now().difference(lastCheck) < interval) {
          debugPrint(
            'UpdateService: Verificação recente (modo: ${mode.name}), pulando...',
          );
          return null;
        }
      }

      debugPrint(
        'UpdateService: Verificando atualizações (modo: ${mode.name})...',
      );

      // Buscar informações da versão mais recente no Firebase
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_info')
          .get();

      if (!doc.exists) {
        debugPrint('UpdateService: Documento de versão não encontrado');
        return null;
      }

      final versionData = doc.data()!;
      final latestVersion = AppVersion.fromJson(versionData);

      // Salvar timestamp da verificação
      await _saveLastUpdateCheck();

      // Obter versão atual do app
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Verificar se há atualização disponível
      if (latestVersion.isNewerThan(currentVersion)) {
        debugPrint(
          'UpdateService: Nova versão disponível: ${latestVersion.version}',
        );
        return latestVersion;
      }

      debugPrint('UpdateService: App está atualizado (v$currentVersion)');
      return null;
    } catch (e) {
      debugPrint('UpdateService: Erro ao verificar atualizações: $e');
      return null;
    }
  }

  /// Verifica se o usuário optou por pular esta versão
  static Future<bool> isVersionSkipped(String version) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_skipVersionKey$version') ?? false;
  }

  /// Marca uma versão como "pulada" pelo usuário
  static Future<void> skipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_skipVersionKey$version', true);
  }

  /// Remove o flag de versão pulada (quando usuário decide atualizar)
  static Future<void> unSkipVersion(String version) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_skipVersionKey$version');
  }

  /// Inicia o download/instalação da atualização
  static Future<bool> startUpdate(AppVersion version) async {
    try {
      if (!kIsWeb && Platform.isAndroid) {
        // Para Android, abrir URL de download do APK
        final Uri url = Uri.parse(version.downloadUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          return true;
        }
      } else if (!kIsWeb && Platform.isIOS) {
        // Para iOS, redirecionar para App Store
        final Uri appStoreUrl = Uri.parse(version.downloadUrl);
        if (await canLaunchUrl(appStoreUrl)) {
          await launchUrl(appStoreUrl, mode: LaunchMode.externalApplication);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('UpdateService: Erro ao iniciar atualização: $e');
      return false;
    }
  }

  // MÉTODOS DE CONVENIÊNCIA PARA DIFERENTES SITUAÇÕES

  /// Força verificação imediata (ignora cache)
  static Future<AppVersion?> forceCheckNow() async {
    debugPrint('UpdateService: Verificação forçada pelo usuário');
    return await checkForUpdate(forceCheck: true);
  }

  /// Ativa modo de desenvolvimento (15 minutos)
  static Future<void> enableDevelopmentMode() async {
    await setUpdateCheckMode(UpdateCheckMode.development);
    debugPrint('UpdateService: Modo desenvolvimento ativado (15 min)');
  }

  /// Ativa modo de teste (1 minuto)
  static Future<void> enableTestingMode() async {
    await setUpdateCheckMode(UpdateCheckMode.testing);
    debugPrint('UpdateService: Modo teste ativado (1 min)');
  }

  /// Ativa verificação contínua (sempre verifica)
  static Future<void> enableAlwaysCheck() async {
    await setUpdateCheckMode(UpdateCheckMode.always);
    debugPrint('UpdateService: Verificação contínua ativada');
  }

  /// Volta ao modo produção (6 horas)
  static Future<void> enableProductionMode() async {
    await setUpdateCheckMode(UpdateCheckMode.production);
    debugPrint('UpdateService: Modo produção ativado (6 horas)');
  }

  /// Desabilita completamente as verificações
  static Future<void> disableUpdateCheck() async {
    await setUpdateCheckMode(UpdateCheckMode.disabled);
    debugPrint('UpdateService: Verificações desabilitadas');
  }

  /// Obtém status atual das verificações
  static Future<String> getUpdateStatus() async {
    final mode = await getUpdateCheckMode();
    final interval = _getIntervalForMode(mode);
    final lastCheck = await _getLastUpdateCheck();

    String status = 'Modo: ${mode.name}\n';
    status += 'Intervalo: ${_formatDuration(interval)}\n';

    if (lastCheck != null) {
      final timeSince = DateTime.now().difference(lastCheck);
      status += 'Última verificação: ${_formatDuration(timeSince)} atrás\n';

      if (mode != UpdateCheckMode.always && mode != UpdateCheckMode.disabled) {
        final timeUntilNext = interval - timeSince;
        if (timeUntilNext.isNegative) {
          status += 'Próxima verificação: Agora';
        } else {
          status += 'Próxima verificação: ${_formatDuration(timeUntilNext)}';
        }
      }
    } else {
      status += 'Nunca verificou';
    }

    return status;
  }

  /// Formata duração para exibição amigável
  static String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays} dia(s)';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hora(s)';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} minuto(s)';
    } else {
      return '${duration.inSeconds} segundo(s)';
    }
  }

  /// Verifica atualizações em background (chamado no startup do app)
  static Future<AppVersion?> checkForUpdateSilently() async {
    try {
      final update = await checkForUpdate();
      if (update != null) {
        // Verificar se não foi pulada pelo usuário
        final isSkipped = await isVersionSkipped(update.version);
        if (isSkipped && !update.isForceUpdate) {
          return null;
        }
        return update;
      }
      return null;
    } catch (e) {
      debugPrint('UpdateService: Erro na verificação silenciosa: $e');
      return null;
    }
  }

  /// Cria/atualiza informações de versão no Firebase (para admins)
  static Future<void> createVersionInfo({
    required String version,
    required int buildNumber,
    required String downloadUrl,
    required String releaseNotes,
    bool isForceUpdate = false,
    String minRequiredVersion = '1.0.0',
  }) async {
    try {
      final versionInfo = AppVersion(
        version: version,
        buildNumber: buildNumber,
        downloadUrl: downloadUrl,
        releaseNotes: releaseNotes,
        releaseDate: DateTime.now(),
        isForceUpdate: isForceUpdate,
        minRequiredVersion: minRequiredVersion,
      );

      await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_info')
          .set(versionInfo.toJson());

      debugPrint(
        'UpdateService: Informações de versão atualizadas no Firebase',
      );
    } catch (e) {
      debugPrint('UpdateService: Erro ao salvar informações de versão: $e');
      rethrow;
    }
  }

  /// Obtém histórico de versões (para tela de configurações)
  static Future<List<AppVersion>> getVersionHistory() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('version_history')
          .collection('versions')
          .orderBy('releaseDate', descending: true)
          .limit(10)
          .get();

      return query.docs.map((doc) => AppVersion.fromJson(doc.data())).toList();
    } catch (e) {
      debugPrint('UpdateService: Erro ao obter histórico: $e');
      return [];
    }
  }

  // Métodos privados para gerenciar timestamps
  static Future<DateTime?> _getLastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(_lastUpdateCheckKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  static Future<void> _saveLastUpdateCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastUpdateCheckKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Limpa cache de verificações (para forçar nova verificação)
  static Future<void> clearUpdateCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastUpdateCheckKey);
    debugPrint('UpdateService: Cache de atualizações limpo');
  }

  /// Obtém informações detalhadas da versão atual
  static Future<Map<String, dynamic>> getCurrentAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return {
      'appName': packageInfo.appName,
      'packageName': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'buildSignature': packageInfo.buildSignature,
    };
  }
}
