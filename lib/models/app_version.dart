class AppVersion {
  final String version;
  final int buildNumber;
  final String downloadUrl;
  final String releaseNotes;
  final DateTime releaseDate;
  final bool isForceUpdate;
  final String minRequiredVersion;

  const AppVersion({
    required this.version,
    required this.buildNumber,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.releaseDate,
    this.isForceUpdate = false,
    this.minRequiredVersion = '1.0.0',
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      version: json['version'] ?? '1.0.0',
      buildNumber: json['buildNumber'] ?? 1,
      downloadUrl: json['downloadUrl'] ?? '',
      releaseNotes: json['releaseNotes'] ?? '',
      releaseDate: DateTime.parse(json['releaseDate']),
      isForceUpdate: json['isForceUpdate'] ?? false,
      minRequiredVersion: json['minRequiredVersion'] ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'buildNumber': buildNumber,
      'downloadUrl': downloadUrl,
      'releaseNotes': releaseNotes,
      'releaseDate': releaseDate.toIso8601String(),
      'isForceUpdate': isForceUpdate,
      'minRequiredVersion': minRequiredVersion,
    };
  }

  /// Compara se esta versão é mais nova que a versão fornecida
  bool isNewerThan(String currentVersion) {
    final current = _parseVersion(currentVersion);
    final latest = _parseVersion(version);

    for (int i = 0; i < 3; i++) {
      if (latest[i] > current[i]) return true;
      if (latest[i] < current[i]) return false;
    }
    return false;
  }

  /// Verifica se a versão atual é compatível (não força atualização)
  bool isCompatibleWith(String currentVersion) {
    if (isForceUpdate) {
      return !isNewerThan(currentVersion);
    }
    return true;
  }

  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return [
      int.tryParse(parts[0]) ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }

  @override
  String toString() => 'AppVersion(v$version+$buildNumber)';
}

/// Informações sobre o app atual
class CurrentAppInfo {
  static const String version = '1.0.0';
  static const int buildNumber = 1;
  static const String appName = 'Corte Real';

  /// Obtém informações da versão atual do pubspec.yaml
  static String get fullVersion => '$version+$buildNumber';

  /// Verifica se precisa de atualização comparando com versão remota
  static bool needsUpdate(AppVersion remoteVersion) {
    return remoteVersion.isNewerThan(version);
  }

  /// Verifica se a atualização é obrigatória
  static bool isForceUpdate(AppVersion remoteVersion) {
    return remoteVersion.isForceUpdate && needsUpdate(remoteVersion);
  }
}
