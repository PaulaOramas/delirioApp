// lib/services/pedido_api.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_service.dart';

class PedidoApi {
  static const String _baseUrl = 'https://delirio.runasp.net/';

  /// Envía el pedido al endpoint POST api/pedido
  static Future<Map<String, dynamic>> crearPedido({
    required int userId,
    required DateTime fecha,
    required double subtotal,
    required double iva,
    required double total,
    required List<CartItem> items,
    required Uint8List? comprobanteBytes,
    required String estado, // "PEN", "ACP", "RCZ"
  }) async {
    // Convertir comprobante a Base64 (string)
    final String? b64 = comprobanteBytes != null ? base64Encode(comprobanteBytes) : null;

    // Construir JSON según tu DTO exacto
    final Map<String, dynamic> payload = {
      "userId": userId, // int
      "fecha": fecha.toIso8601String(), // DateTime ISO
      "subtotal": double.parse(subtotal.toStringAsFixed(2)), // decimal
      "iva": double.parse(iva.toStringAsFixed(2)), // decimal
      "total": double.parse(total.toStringAsFixed(2)), // decimal
      "comprobante": b64 ?? "", // string base64
      "estado": estado, // PEN, ACP o RCZ
      "detalles": items
          .map((it) => {
                "pedId": 0, // lo genera SQL Server
                "prdId": it.id,
                "precio": double.parse(it.precio.toStringAsFixed(2)),
                "cantidad": it.qty,
              })
          .toList(),
    };

    final uri = Uri.parse('${_baseUrl}api/pedido');

    final headers = AuthService.instance.authHeaders();

    final res = await http
        .post(uri, headers: headers, body: jsonEncode(payload))
        .timeout(const Duration(seconds: 25));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      try {
        return jsonDecode(res.body) as Map<String, dynamic>;
      } catch (_) {
        return {"raw": res.body};
      }
    } else {
      throw Exception('Error ${res.statusCode}: ${res.body}');
    }
  }
}
