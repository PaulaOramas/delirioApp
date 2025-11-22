import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/models/pedido.dart';

class PedidoApi {
  static const String _baseUrl = 'https://delirio.runasp.net/';

  /// ==================================================
  /// 1) CREAR PEDIDO – POST api/pedido
  /// ==================================================
  static Future<Map<String, dynamic>> crearPedido({
    required int userId,
    required DateTime fecha,
    required double subtotal,
    required double iva,
    required double total,
    required bool abonado,
    required double montoAbonado,
    required bool credito,
    required double montoCredito,
    required List<CartItem> items,
    required String estado,
  }) async {
    final payload = {
      "userId": userId,
      "fecha": fecha.toIso8601String(),
      "subtotal": subtotal,
      "iva": iva,
      "total": total,
      "comprobante": "",
      "estado": estado,
      "abonado": abonado,
      "montoAbonado": montoAbonado,
      "credito": credito,
      "montoCredito": montoCredito,
      "detalles": items.map((it) => {
            "prdId": it.id,
            "precio": it.precio,
            "cantidad": it.qty,
            "mensaje": it.dedicatoria ?? ""
          }).toList(),
    };

    final uri = Uri.parse("${_baseUrl}api/pedido");
    final headers = AuthService.instance.authHeaders();

    final res = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(payload),
    );

    final body = res.body.trim();
    print("RESPUESTA API PEDIDO => $body");

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // Caso: la API devuelve sólo un número
      final parsed = int.tryParse(body);
      if (parsed != null) return {"pedidoId": parsed};

      // Caso: regresa un JSON
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}

      return {"raw": body};
    }

    throw Exception("Error ${res.statusCode}: $body");
  }

  /// ==================================================
  /// 2) SUBIR COMPROBANTE – POST api/subir-comprobante
  /// ==================================================
  static Future<bool> subirComprobante({
    required int pedidoId,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    final uri = Uri.parse("${_baseUrl}api/subir-comprobante?pedidoId=$pedidoId");

    final request = http.MultipartRequest("POST", uri);
    request.headers.addAll(AuthService.instance.authHeaders());

    request.fields["pedidoId"] = pedidoId.toString();

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType("image", "jpeg"),
      ),
    );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    print("RESPUESTA API COMPROBANTE => ${response.body}");

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }

    throw Exception(
        "Error al subir comprobante: ${response.statusCode} - ${response.body}");
  }

  /// ==================================================
  /// 3) OBTENER PEDIDOS POR USUARIO – GET api/pedido/usuario/{id}
  /// ==================================================
  static Future<List<Pedido>> obtenerPedidosPorUsuario(int usuarioId) async {
    final uri =
        Uri.parse("${_baseUrl}api/pedido/usuario/$usuarioId");

    final headers = AuthService.instance.authHeaders();
    final res = await http.get(uri, headers: headers);

    print("RESPUESTA API HISTORIAL => ${res.body}");

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final List<dynamic> data = jsonDecode(res.body);
      return data.map((e) => Pedido.fromJson(e)).toList();
    }

    throw Exception(
        "Error al obtener pedidos del usuario: ${res.statusCode}");
  }

  //cancelar pedido
  static Future<bool> cancelarPedido(int pedidoId, String token) async {
    final url = Uri.parse('https://delirio.runasp.net/api/pedido/cancelar/$pedidoId');

    final res = await http.post(
      url,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode == 200) {
      return true;
    }

    throw Exception("No se pudo cancelar el pedido: ${res.body}");
  }

}


