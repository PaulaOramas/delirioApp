import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const _kTokenKey = 'auth_token';

  static Future<bool> login(String email, String password) async {
    // Simulación: reemplaza por tu llamada a API real
    await Future.delayed(const Duration(milliseconds: 600));
    final ok = email.isNotEmpty && password.length >= 6;
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kTokenKey, 'token_simulado_123');
    }
    return ok;
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kTokenKey) != null;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokenKey);
  }
}
