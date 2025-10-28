import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  // ==== Ajusta si cambias de host ====
  static const String _baseUrl = 'https://delirio.runasp.net/';

  // ==== Claves de storage ====
  static const String _kTokenKey = 'auth_token';

  // ==== Estado en memoria ====
  String? _token;
  Map<String, dynamic>? _claims;

  /// Carga el token guardado (llámalo al inicio de la app si quieres sesión persistente).
  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    _token = sp.getString(_kTokenKey);
    if (_token != null) {
      try {
        _claims = Jwt.parseJwt(_token!);
      } catch (_) {
        _claims = null;
      }
    }
  }

  /// Login: envía {Username, Password}. Devuelve true si ok.
  Future<bool> login(String username, String password) async {
    final uri = Uri.parse('${_baseUrl}api/auth/login');

    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'Username': username,
            'Password': password,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // El backend puede devolver { token: '...' } o el JWT en texto plano.
      String? token;
      try {
        final body = jsonDecode(res.body);
        if (body is Map) {
          token = (body['token'] ??
              body['Token'] ??
              body['accessToken'] ??
              body['AccessToken'])?.toString();
        }
      } catch (_) {
        // puede ser texto plano
      }
      token ??= res.body.trim();
      if (token.isEmpty || !token.startsWith('eyJ')) {
        throw Exception('La respuesta no contiene un token JWT válido');
      }

      // Guardar en memoria y en disco
      _token = token;
      try {
        _claims = Jwt.parseJwt(token);
      } catch (_) {
        _claims = null; // no es crítico si falla el parse
      }

      final sp = await SharedPreferences.getInstance();
      await sp.setString(_kTokenKey, token);

      return true;
    } else {
      // intenta extraer mensaje de error
      try {
        final data = jsonDecode(res.body);
        final msg = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : res.body;
        throw Exception('HTTP ${res.statusCode}: $msg');
      } catch (_) {
        throw Exception('HTTP ${res.statusCode}');
      }
    }
  }

  /// Registro de cliente: envía el JSON requerido y devuelve true si ok.
  Future<bool> registerCliente({
    required String nombre,
    required String apellido,
    required String cedula,
    required String correo,
    required String telefono,
    required String usuario,
    required String password,
  }) async {
    final uri = Uri.parse('${_baseUrl}api/register/cliente');

    final payload = {
      "Nombre": nombre,
      "Apellido": apellido,
      "Cedula": cedula,
      "Correo": correo,
      "Telefono": telefono,
      "Usuario": usuario,
      "Password": password,
    };

    final res = await http
        .post(
          uri,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return true;
    } else {
      try {
        final body = jsonDecode(res.body);
        final msg = (body is Map && body['message'] != null)
            ? body['message'].toString()
            : res.body.toString();
        throw Exception('Error ${res.statusCode}: $msg');
      } catch (_) {
        throw Exception('Error HTTP ${res.statusCode}');
      }
    }
  }

  /// Cierra sesión: borra token en memoria y disco.
  Future<void> logout() async {
    _token = null;
    _claims = null;
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_kTokenKey);
  }

  /// Retorna si hay token y no está expirado.
  bool isLoggedIn() {
    if (_token == null) return false;
    return !isTokenExpired();
  }

  /// Verifica expiración del JWT (exp en segundos desde epoch).
  bool isTokenExpired() {
    if (_token == null) return true;
    try {
      return Jwt.isExpired(_token!);
    } catch (_) {
      return true;
    }
  }

  /// Encabezados para llamadas autenticadas.
  Map<String, String> authHeaders({Map<String, String>? extra}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    if (extra != null) headers.addAll(extra);
    return headers;
  }

  /// Accesores útiles
  String? get token => _token;
  Map<String, dynamic>? get claims => _claims;

  /// Ejemplo de GET autenticado (puedes copiar este patrón)
  Future<http.Response> getAuthed(String path) {
    final uri = Uri.parse('$_baseUrl$path');
    return http.get(uri, headers: authHeaders()).timeout(const Duration(seconds: 20));
  }
}
