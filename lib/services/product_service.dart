// lib/services/product_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delirio_app/models/product.dart';

class ProductService {
  static const String _baseUrl = 'https://delirio.runasp.net';
  static const Duration _timeout = Duration(seconds: 12);

  /// Obtener todos los productos
  static Future<List<Product>> getAllProducts() async {
    final uri = Uri.parse('$_baseUrl/api/productos');
    final res = await http
        .get(uri, headers: {'Accept': 'application/json'})
        .timeout(_timeout);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data is List) {
        return data.map<Product>((p) => Product.fromJson(p)).toList();
      } else {
        throw Exception('Formato de respuesta no esperado');
      }
    } else {
      throw Exception(
          'Error ${res.statusCode} al obtener productos: ${res.body}');
    }
  }

  //Obtener producto por ID
  /// Obtener un producto por su ID
static Future<Product> getById(int id) async {
  final uri = Uri.parse('https://delirio.runasp.net/api/productos/$id');
  final res = await http
      .get(uri, headers: {'Accept': 'application/json'})
      .timeout(_timeout);

  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    return Product.fromJson(data);
  } else {
    throw Exception('Error ${res.statusCode} al obtener producto: ${res.body}');
  }
}


  /// Crear un nuevo producto (si usas POST)
  static Future<Product> createProduct(Product p) async {
    final uri = Uri.parse('$_baseUrl/api/producto');
    final res = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'nombre': p.nombre,
            'descripcion': p.descripcion,
            'precio': p.precio,
            'stock': p.stock,
            'categoria': p.categoria,
            'imagenes': p.imagenes,
            'estado': p.estado,
          }),
        )
        .timeout(_timeout);

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Product.fromJson(json.decode(res.body));
    } else {
      throw Exception(
          'Error ${res.statusCode} al crear producto: ${res.body}');
    }
  }
}
