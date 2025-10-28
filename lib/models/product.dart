// lib/models/product.dart
class Product {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final int stock;
  final String categoria;
  final List<String> imagenes;
  final String estado;

  Product({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.stock,
    required this.categoria,
    required this.imagenes,
    required this.estado,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] is int)
          ? (json['precio'] as int).toDouble()
          : (json['precio'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      categoria: json['categoria'] ?? '',
      imagenes: (json['imagenes'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      estado: json['estado'] ?? '',
    );
  }

  /// Para conveniencia: usar la primera imagen o una de respaldo
  String get imageUrl =>
      imagenes.isNotEmpty ? imagenes.first : 'https://via.placeholder.com/200';
}
