// lib/services/cart_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_service.dart';

class CartApi {
  static const String _baseUrl = 'https://delirio.runasp.net';
  static const Duration _timeout = Duration(seconds: 15);

  /// Envía el carrito al backend:
  /// POST /api/carrito/agregar
  ///
  /// body esperado (ejemplo):
  /// {
  ///   "userId": 1,
  ///   "fecha": "2025-10-28T01:39:01.012Z",
  ///   "detalles": [
  ///     { "prdId": 1, "carId": 0, "cantidad": 3 },
  ///     ...
  ///   ]
  /// }
  ///
  /// Nota: si tu API requiere `carId`, puedes mandar 0 o null y que el backend lo asigne.
  static Future<void> agregarCarrito({
    required int userId,
    required List<CartItem> items,
  }) async {
    // Compacta items por producto (si el usuario agregó repetidos)
    final Map<int, int> qtyPorProducto = {};
    for (final it in items) {
      qtyPorProducto.update(it.id, (q) => q + it.qty, ifAbsent: () => it.qty);
    }

    final detalles = qtyPorProducto.entries.map((e) {
      return {
        'prdId': e.key,
        'carId': 0,          // Ajusta si tu API exige un ID específico
        'cantidad': e.value,
      };
    }).toList();

    final payload = {
      'userId': userId,
      'fecha': DateTime.now().toIso8601String(),
      'detalles': detalles,
    };

    final uri = Uri.parse('$_baseUrl/api/carrito/agregar');
    final token = AuthService.instance.token;

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };

    final res = await http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(_timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      return;
    }

    // Construir mensaje de error legible
    String reason = 'Error ${res.statusCode}';
    try {
      final body = json.decode(res.body);
      if (body is Map && body['message'] is String) {
        reason = '${res.statusCode}: ${body['message']}';
      } else {
        reason = '${res.statusCode}: ${res.reasonPhrase ?? 'Error de servidor'}';
      }
    } catch (_) {
      reason = '${res.statusCode}: ${res.reasonPhrase ?? 'Error de servidor'}';
    }
    throw Exception(reason);
  }
}
