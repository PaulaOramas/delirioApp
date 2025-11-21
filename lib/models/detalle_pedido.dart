class DetallePedido {
  final int prdId;
  final double precio;
  final int cantidad;
  final String mensaje;

  DetallePedido({
    required this.prdId,
    required this.precio,
    required this.cantidad,
    required this.mensaje,
  });

  factory DetallePedido.fromJson(Map<String, dynamic> json) {
    return DetallePedido(
      prdId: json['prdId'] ?? json['productoId'] ?? 0,
      precio: (json['precio'] ?? 0).toDouble(),
      cantidad: json['cantidad'] ?? 0,
      mensaje: json['mensaje'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        'prdId': prdId,
        'precio': precio,
        'cantidad': cantidad,
        'mensaje': mensaje,
      };
}
