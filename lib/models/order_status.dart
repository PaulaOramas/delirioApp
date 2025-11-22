import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';

enum OrderStatus { pendiente, aceptado, rechazado }

OrderStatus mapEstado(String estado) {
  switch (estado.toUpperCase()) {
    case "ACP":
    case "ACEPTADO":
      return OrderStatus.aceptado;

    case "RCZ":
    case "RECHAZADO":
      return OrderStatus.rechazado;

    default:
      return OrderStatus.pendiente;
  }
}

extension OrderStatusX on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pendiente:
        return 'Pendiente';
      case OrderStatus.aceptado:
        return 'Aceptado';
      case OrderStatus.rechazado:
        return 'Rechazado';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pendiente:
        return Icons.schedule_outlined;
      case OrderStatus.aceptado:
        return Icons.check_circle_outline;
      case OrderStatus.rechazado:
        return Icons.cancel_outlined;
    }
  }

  Color bg(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (this) {
      case OrderStatus.pendiente:
        return Colors.amber.withOpacity(.25);
      case OrderStatus.aceptado:
        return kVerdeHoja.withOpacity(.18);
      case OrderStatus.rechazado:
        return cs.errorContainer;
    }
  }

  Color fg(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (this) {
      case OrderStatus.pendiente:
        return Colors.amber[900] ?? Colors.brown;
      case OrderStatus.aceptado:
        return kVerdeHoja;
      case OrderStatus.rechazado:
        return cs.onErrorContainer;
    }
  }
}
