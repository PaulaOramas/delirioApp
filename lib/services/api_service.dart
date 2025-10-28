// lib/services/api_service.dart
/*import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Excepción clara para errores HTTP/API
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Respuesta de login típica { token, user }
class AuthPayload {
  final String token;
  final Map<String, dynamic>? user;

  AuthPayload({required this.token, this.user});

  factory AuthPayload.fromJson(Map<String, dynamic> json) {
    // Ajusta las llaves según responda tu API
    final token = (json['token'] ?? json['accessToken'] ?? '').toString();
    if (token.isEmpty) {
      throw ApiException('La respuesta de login no contiene token.');
    }
    return AuthPayload(
      token: token,
      user: (json['user'] is Map) ? (json['user'] as Map).cast<String, dynamic>() : null,
    );
  }
}

class ApiService {
  /// Cárgala desde .env. Ej: API_BASE_URL=https://tu-api.azurewebsites.net
  final String baseUrl = dotenv.env['API_BASE_URL']!.replaceAll(RegExp(r'/$'), '');

  /// Timeout razonable por request
  final Duration _timeout = const Duration(seconds: 15);

  Uri _u(String path) => Uri.parse('$baseUrl/${path.replaceFirst(RegExp(r"^/"), "")}');

  Map<String, String> _jsonHeaders({String? token}) => {
        HttpHeaders.contentTypeHeader: 'application/json',
        if (token != null && token.isNotEmpty) HttpHeaders.authorizationHeader: 'Bearer $token',
      };

  /// Helper: procesa respuesta, lanza ApiException en error
  T _parseJsonOrThrow<T>(http.Response res) {
    final code = res.statusCode;

    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : null;
    } catch (_) {
      // No es JSON; mantenemos el texto crudo para el mensaje
      body = res.body;
    }

    if (code >= 200 && code < 300) {
      return body as T;
    }

    // Intenta extraer mensaje significativo
    String msg = 'Error HTTP $code';
    if (body is Map<String, dynamic>) {
      msg = (body['message'] ?? body['error'] ?? body['detail'] ?? msg).toString();
    } else if (body is String && body.trim().isNotEmpty) {
      msg = body;
    }
    throw ApiException(msg, statusCode: code);
  }

  // ======================
  // AUTH
  // ======================

  /// POST api/auth/login
  /// Body esperado (ajusta las claves a tu contrato real):
  /// { "email": "...", "password": "..." }
  Future<AuthPayload> login({
    required String email,
    required String password,
  }) async {
    final res = await http
        .post(
          _u('api/auth/login'),
          headers: _jsonHeaders(),
          body: jsonEncode({
            // ⚠️ cambia a "correo"/"clave" si tu API lo requiere
            'email': email,
            'password': password,
          }),
        )
        .timeout(_timeout);

    final json = _parseJsonOrThrow<Map<String, dynamic>>(res);
    return AuthPayload.fromJson(json);
  }

  // ======================
  // REGISTER
  // ======================

  /// POST api/register/cliente
  /// data debe contener los campos que tu API espera (ejemplo):
  /// {
  ///   "nombres": "...",
  ///   "apellidos": "...",
  ///   "email": "...",
  ///   "password": "...",
  ///   "telefono": "...",
  ///   "direccion": "..."
  /// }
  Future<Map<String, dynamic>> registerCliente(Map<String, dynamic> data) async {
    final res = await http
        .post(
          _u('api/register/cliente'),
          headers: _jsonHeaders(),
          body: jsonEncode(data),
        )
        .timeout(_timeout);

    return _parseJsonOrThrow<Map<String, dynamic>>(res);
  }

  /// POST api/register/repartidor
  /// Ejemplo de body (ajústalo):
  /// {
  ///   "nombres": "...",
  ///   "apellidos": "...",
  ///   "email": "...",
  ///   "password": "...",
  ///   "telefono": "...",
  ///   "placaVehiculo": "...",
  ///   "tipoVehiculo": "moto|auto|bicicleta"
  /// }
  Future<Map<String, dynamic>> registerRepartidor(Map<String, dynamic> data) async {
    final res = await http
        .post(
          _u('api/register/repartidor'),
          headers: _jsonHeaders(),
          body: jsonEncode(data),
        )
        .timeout(_timeout);

    return _parseJsonOrThrow<Map<String, dynamic>>(res);
  }

  /// POST api/register/tienda
  /// Ejemplo de body (ajústalo):
  /// {
  ///   "nombreComercial": "...",
  ///   "ruc": "...",
  ///   "email": "...",
  ///   "password": "...",
  ///   "telefono": "...",
  ///   "direccion": "...",
  ///   "lat": -0.20,
  ///   "lng": -78.49
  /// }
  Future<Map<String, dynamic>> registerTienda(Map<String, dynamic> data) async {
    final res = await http
        .post(
          _u('api/register/tienda'),
          headers: _jsonHeaders(),
          body: jsonEncode(data),
        )
        .timeout(_timeout);

    return _parseJsonOrThrow<Map<String, dynamic>>(res);
  }

  // ======================
  // (Plantillas para futuros GET/PUT/DELETE con token)
  // ======================

  Future<Map<String, dynamic>> getJson(String path, {String? token}) async {
    final res = await http.get(_u(path), headers: _jsonHeaders(token: token)).timeout(_timeout);
    return _parseJsonOrThrow<Map<String, dynamic>>(res);
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body, {String? token}) async {
    final res = await http
        .put(_u(path), headers: _jsonHeaders(token: token), body: jsonEncode(body))
        .timeout(_timeout);
    return _parseJsonOrThrow<Map<String, dynamic>>(res);
  }

  Future<void> delete(String path, {String? token}) async {
    final res = await http.delete(_u(path), headers: _jsonHeaders(token: token)).timeout(_timeout);
    _parseJsonOrThrow(res); // dispara error si no es 2xx
  }
}*/
