// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delirio_app/models/product.dart';

class ProductService {
  static const String _baseUrl = 'https://delirio.runasp.net';
  static const Duration _timeout = Duration(seconds: 12);

  // ========== Helpers ==========
  static Map<String, String> _headers({String? bearerToken, bool jsonBody = false}) {
    final h = <String, String>{
      'Accept': 'application/json',
      if (jsonBody) 'Content-Type': 'application/json',
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $bearerToken';
    }
    return h;
  }

  static dynamic _decode(String body) {
    try {
      return json.decode(body);
    } catch (_) {
      return body; // devuelve texto plano si no es JSON
    }
  }

  static Exception _httpError(String where, http.Response res) {
    final payload = _decode(res.body);
    return Exception('Error ${res.statusCode} en $where: $payload');
  }

  // ========== Read ==========
  /// Obtener todos los productos
  static Future<List<Product>> getAllProducts({String? bearerToken}) async {
    final uri = Uri.parse('$_baseUrl/api/productos');
    final res = await http
        .get(uri, headers: _headers(bearerToken: bearerToken))
        .timeout(_timeout);

    if (res.statusCode == 200) {
      final data = _decode(res.body);
      if (data is List) {
        return data.map<Product>((p) {
          if (p is Map) {
            return Product.fromJson(Map<String, dynamic>.from(p));
          }
          throw Exception('Formato de producto inválido en la lista: $p');
        }).toList();
      }
      throw Exception('Formato de respuesta no esperado (no es lista).');
    }
    throw _httpError('GET /api/productos', res);
  }

  /// Obtener un producto por su ID
  static Future<Product> getById(int id, {String? bearerToken}) async {
    final uri = Uri.parse('$_baseUrl/api/productos/$id');
    final res = await http
        .get(uri, headers: _headers(bearerToken: bearerToken))
        .timeout(_timeout);

    if (res.statusCode == 200) {
      final data = _decode(res.body);
      if (data is Map) {
        // asegurar Map<String, dynamic>
        return Product.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Formato de respuesta no esperado (no es objeto).');
    }
    throw _httpError('GET /api/productos/$id', res);
  }

  // ========== Create ==========
  /// Crear un nuevo producto (POST)
  static Future<Product> createProduct(Product p, {String? bearerToken}) async {
    final uri = Uri.parse('$_baseUrl/api/producto');
    final body = json.encode({
      'nombre':     p.nombre,
      'descripcion':p.descripcion,
      'precio':     p.precio,
      'stock':      p.stock,
      'categoria':  p.categoria,
      'imagenes':   p.imagenes,
      'estado':     p.estado,
    });

    final res = await http
        .post(uri, headers: _headers(bearerToken: bearerToken, jsonBody: true), body: body)
        .timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = _decode(res.body);
      if (data is Map) {
        return Product.fromJson(Map<String, dynamic>.from(data));
      }
      throw Exception('Formato de respuesta no esperado (esperaba objeto JSON).');
    }
    throw _httpError('POST /api/producto', res);
  }

  // ========== Update (PUT) ==========
  /// Actualizar un producto COMPLETO por ID (PUT /api/producto/{id})
  /// Úsalo si tu API requiere el objeto completo.
  static Future<Product> updateProductFull(Product p, {String? bearerToken}) async {
    if (p.id == null) {
      throw Exception('updateProductFull: el producto debe tener id.');
    }
    final id = p.id!;
    final uri = Uri.parse('$_baseUrl/api/producto/$id');

    final body = json.encode({
      'id':         id,
      'nombre':     p.nombre,
      'descripcion':p.descripcion,
      'precio':     p.precio,
      'stock':      p.stock,
      'categoria':  p.categoria,
      'imagenes':   p.imagenes,
      'estado':     p.estado,
    });

    final res = await http
        .put(uri, headers: _headers(bearerToken: bearerToken, jsonBody: true), body: body)
        .timeout(_timeout);

    if (res.statusCode >= 200 && res.statusCode < 300) {
      // algunas APIs devuelven el objeto actualizado; otras, vacío
      if (res.body.isEmpty) return p;
      final data = _decode(res.body);
      if (data is Map) return Product.fromJson(Map<String, dynamic>.from(data));
      return p;
    }
    throw _httpError('PUT /api/producto/$id', res);
  }

  /// Actualizar SOLO el stock (PUT /api/producto/{id})
  /// Úsalo si tu API acepta payload parcial con solo { "stock": n }.
  static Future<void> updateStockOnly(int id, int newStock, {String? bearerToken}) async {
    final uri = Uri.parse('$_baseUrl/api/producto/$id');
    final body = json.encode({'stock': newStock});

    final res = await http
        .put(uri, headers: _headers(bearerToken: bearerToken, jsonBody: true), body: body)
        .timeout(_timeout);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _httpError('PUT /api/producto/$id (solo stock)', res);
    }
  }

  /// Helper: disminuye el stock actual leyendo el producto y aplicando PUT.
  /// Si tu API no permite PUT parcial, esta función usa updateProductFull.
  static Future<int> decreaseStock(int id, int amount, {String? bearerToken}) async {
    if (amount <= 0) return (await getById(id, bearerToken: bearerToken)).stock ?? 0;

    final current = await getById(id, bearerToken: bearerToken);
    final curStock = (current.stock ?? 0);
    final newStock = (curStock - amount).clamp(0, 1 << 31);
    // Intenta primero payload parcial; si tu API no lo soporta, comenta esta línea y usa la de abajo.
    await updateStockOnly(id, newStock, bearerToken: bearerToken);
    // Alternativa (objeto completo):
    // final updated = current.copyWith(stock: newStock);  // si tienes copyWith
    // await updateProductFull(updated, bearerToken: bearerToken);

    return newStock;
  }

  /// Opcional: descontar en lote (secuencial). Ideal post-confirmación de pedido.
  /// items: lista de pares (idProducto, cantidad)
  static Future<void> batchDecreaseStock(List<dynamic> items, {String? bearerToken}) async {
    for (final it in items) {
      int id;
      int qty;
      if (it is Map) {
        // soporta Map con keys 'id' y 'qty' (string o int)
        final rawId = it['id'];
        final rawQty = it['qty'];
        id = (rawId is int) ? rawId : int.tryParse('$rawId') ?? (throw Exception('id inválido'));
        qty = (rawQty is int) ? rawQty : int.tryParse('$rawQty') ?? (throw Exception('qty inválido'));
      } else if (it is List && it.length >= 2) {
        id = (it[0] is int) ? it[0] as int : int.tryParse('${it[0]}') ?? (throw Exception('id inválido'));
        qty = (it[1] is int) ? it[1] as int : int.tryParse('${it[1]}') ?? (throw Exception('qty inválido'));
      } else {
        throw Exception('batchDecreaseStock: formato de item no soportado: $it');
      }
      await decreaseStock(id, qty, bearerToken: bearerToken);
    }
  }
}
