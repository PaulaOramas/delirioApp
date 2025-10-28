// lib/services/cliente_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delirio_app/models/cliente_perfil.dart';
import 'package:delirio_app/services/auth_service.dart';

class ClienteApi {
  static const String _baseUrl = 'https://delirio.runasp.net';
  static const Duration _timeout = Duration(seconds: 12);

  /// GET /api/cliente/perfil/{id}
  /// Usa token Bearer si existe. Lanza excepción si falla (sin fallback silencioso).
  static Future<ClientePerfil> getPerfilById(int id) async {
    final uri = Uri.parse('$_baseUrl/api/cliente/perfil/$id');

    try {
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

      // Intenta incluir mensaje del servidor si existe
      String reason = res.reasonPhrase ?? 'Error de servidor';
      try {
        final err = json.decode(res.body);
        if (err is Map && err['message'] is String) {
          reason = '${res.statusCode}: ${err['message']}';
        } else {
          reason = '${res.statusCode}: $reason';
        }
      } catch (_) {
        reason = '${res.statusCode}: $reason';
      }
      throw Exception(reason);
    } catch (e) {
      // No devolvemos perfil dummy para no ocultar el problema.
      rethrow;
    }
  }

  /// Soporta varios formatos: objeto directo, envueltos ("data"/"result") o lista con un item.
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

  /// Actualiza el perfil del cliente por ID. Devuelve true si la operación fue exitosa.
  /// Endpoint: PUT /api/clientes/{id}
  static Future<bool> updatePerfil(int id, Map<String, dynamic> payload) async {
    final uri = Uri.parse('$_baseUrl/api/clientes/$id');
    try {
      final res = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode(payload),
          )
          .timeout(_timeout);

      return res.statusCode >= 200 && res.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

}
