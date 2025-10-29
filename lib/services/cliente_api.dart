// lib/services/cliente_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delirio_app/models/cliente_perfil.dart';
import 'package:delirio_app/services/auth_service.dart';

class ClienteApi {
  static const String _baseUrl = 'https://delirio.runasp.net';
  static const Duration _timeout = Duration(seconds: 12);

  /// GET /api/cliente/perfil/{id}
  static Future<ClientePerfil> getPerfilById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/cliente/perfil/$id');

    final token = AuthService.instance.token;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final res = await http.get(uri, headers: headers).timeout(_timeout);

    if (res.statusCode == 200) {
      final dynamic body = json.decode(res.body);
      final map = _extractFirstMap(body);
      if (map == null) {
        throw Exception('Formato inesperado de respuesta');
      }
      return ClientePerfil.fromJson(map);
    }

    if (res.statusCode == 401) {
      throw Exception('No autorizado (401). Inicia sesión nuevamente.');
    }

    String reason = res.reasonPhrase ?? 'Error de servidor';
    try {
      final err = json.decode(res.body);
      reason = (err is Map && err['message'] is String)
          ? '${res.statusCode}: ${err['message']}'
          : '${res.statusCode}: $reason';
    } catch (_) {
      reason = '${res.statusCode}: $reason';
    }
    throw Exception(reason);
  }

  /// Soporta objeto directo, {data}, {result} o lista con 1 item
  static Map<String, dynamic>? _extractFirstMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
      if (body['result'] is Map<String, dynamic>) return body['result'] as Map<String, dynamic>;
      return body;
    }
    if (body is List && body.isNotEmpty && body.first is Map<String, dynamic>) {
      return body.first as Map<String, dynamic>;
    }
    return null;
  }

  /// PUT /api/cliente/perfil/{id}
  /// Envía el JSON exactamente con las claves del backend:
  /// { Nombre, Apellido, Cedula, Correo, Password (opcional), Telefono, Usuario }
  // lib/services/cliente_api.dart
static Future<bool> updatePerfil(int id, Map<String, dynamic> payload) async {
  final uri = Uri.parse('$_baseUrl/api/cliente/perfil/$id');

  final token = AuthService.instance.token;
  final headers = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };

  try {
    final res = await http
        .put(uri, headers: headers, body: json.encode(payload))
        .timeout(_timeout);

    // ⬇️ DEBUG
    // ignore: avoid_print
    print('[PUT perfil] ${res.statusCode} ${res.reasonPhrase}');
    // ignore: avoid_print
    print('[PUT body] ${res.body}');

    return res.statusCode >= 200 && res.statusCode < 300;
  } catch (e) {
    // ignore: avoid_print
    print('[PUT ERROR] $e');
    return false;
  }
}

}
