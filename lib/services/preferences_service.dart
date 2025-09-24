import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';

  /// Salvar credenciais do usuário
  static Future<void> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_keyRememberMe, rememberMe);

    if (rememberMe) {
      await prefs.setString(_keyEmail, email);
      await prefs.setString(_keyPassword, password);
    } else {
      // Se não quer lembrar, limpar dados salvos
      await prefs.remove(_keyEmail);
      await prefs.remove(_keyPassword);
    }
  }

  /// Obter credenciais salvas
  static Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    final email = prefs.getString(_keyEmail) ?? '';
    final password = prefs.getString(_keyPassword) ?? '';

    return {'rememberMe': rememberMe, 'email': email, 'password': password};
  }

  /// Limpar todas as credenciais salvas
  static Future<void> clearSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
  }

  /// Verificar se o usuário quer lembrar credenciais
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  /// Salvar apenas o email (para casos onde senha não deve ser salva)
  static Future<void> saveEmailOnly(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
  }

  /// Obter apenas o email salvo
  static Future<String> getSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEmail) ?? '';
  }
}
