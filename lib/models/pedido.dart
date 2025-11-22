import 'detalle_pedido.dart';

class Pedido {
  final int pedidoId;
  final int userId;
  final DateTime fecha;
  final double subtotal;
  final double iva;
  final double total;
  final String comprobante;
  final String estado;

  final bool abonado;
  final double montoAbonado;
  final bool credito;
  final double montoCredito;

  final List<DetallePedido> detalles;

  Pedido({
    required this.pedidoId,
    required this.userId,
    required this.fecha,
    required this.subtotal,
    required this.iva,
    required this.total,
    required this.comprobante,
    required this.estado,
    required this.abonado,
    required this.montoAbonado,
    required this.credito,
    required this.montoCredito,
    required this.detalles,
  });

  factory Pedido.fromJson(Map<String, dynamic> json) {
    return Pedido(
      pedidoId: json["pedidoId"]
        ?? json["id"]
        ?? ((json["detalles"] != null && json["detalles"].isNotEmpty)
            ? (json["detalles"][0]["pedId"] ?? 0)
            : 0),
      userId: json["userId"] ?? 0,
      fecha: DateTime.parse(json["fecha"]),
      subtotal: (json["subtotal"] ?? 0).toDouble(),
      iva: (json["iva"] ?? 0).toDouble(),
      total: (json["total"] ?? 0).toDouble(),
      comprobante: json["comprobante"] ?? "",
      estado: json["estado"] ?? "",

      abonado: json["abonado"] ?? false,
      montoAbonado: (json["montoAbonado"] ?? 0).toDouble(),
      credito: json["credito"] ?? false,
      montoCredito: (json["montoCredito"] ?? 0).toDouble(),

      detalles: (json["detalles"] as List<dynamic>? ?? [])
          .map((d) => DetallePedido.fromJson(d))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "pedidoId": pedidoId,
      "userId": userId,
      "fecha": fecha.toIso8601String(),
      "subtotal": subtotal,
      "iva": iva,
      "total": total,
      "comprobante": comprobante,
      "estado": estado,

      "abonado": abonado,
      "montoAbonado": montoAbonado,
      "credito": credito,
      "montoCredito": montoCredito,

      "detalles": detalles.map((d) => d.toJson()).toList(),
    };
  }
}
