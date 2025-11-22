// lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';

import 'package:delirio_app/services/pedido_api.dart';
import 'package:delirio_app/models/pedido.dart';  // donde guardaste el modelo
import 'package:delirio_app/services/auth_service.dart';

/// ===== Modelo y utilidades (solo para UI quemada) =====

enum OrderStatus { pendiente, aceptado, rechazado }

class OrderSummary {
  final DateTime createdAt;
  final DateTime? pickupAt; // opcional: fecha/hora de retiro si la tuvieses en backend
  final OrderStatus status;
  final double total;

  OrderSummary({
    required this.createdAt,
    this.pickupAt,
    required this.status,
    required this.total,
  });

  /// Formato: EST-YYYYMMDD-xxxxx (xxxxx = millis % 100000)
  String get orderCode => _formatOrderCode(createdAt);
}

String _formatOrderCode(DateTime now) {
  String _pad2(int n) => n.toString().padLeft(2, '0');
  final suffix = (now.millisecondsSinceEpoch % 100000).toString().padLeft(5, '0');
  return 'EST-${now.year}${_pad2(now.month)}${_pad2(now.day)}-$suffix';
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

  // Colores del chip por estado
  Color bg(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (this) {
      case OrderStatus.pendiente:
        return Colors.amber.withOpacity(.25); // amarillo suave
      case OrderStatus.aceptado:
        return kVerdeHoja.withOpacity(.18); // verde suave de tu paleta
      case OrderStatus.rechazado:
        return cs.errorContainer; // rojo claro del tema
    }
  }

  Color fg(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (this) {
      case OrderStatus.pendiente:
        return Colors.amber[900] ?? Colors.brown; // texto amarillo oscuro
      case OrderStatus.aceptado:
        return kVerdeHoja; // texto verde
      case OrderStatus.rechazado:
        return cs.onErrorContainer; // texto para fondo de error
    }
  }
}

/// ===== Pantalla =====

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late Future<List<OrderSummary>> _future;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _future = _loadOrders();

  }

Future<List<OrderSummary>> _loadOrders() async {
  await Future.delayed(const Duration(milliseconds: 300)); // pequeño shimmer

  // Obtener claims del token
  final claims = AuthService.instance.claims;

  // Ajuste importante → tu token usa "Id"
  final userId = int.tryParse(claims?["Id"]?.toString() ?? "") ?? 0;

  if (userId == 0) {
    throw Exception("Usuario no autenticado");
  }

  // Llamar a la API real
  final pedidos = await PedidoApi.obtenerPedidosPorUsuario(userId);

  // Convertir pedidos reales → UI actual (OrderSummary)
  return pedidos.map((p) {
    return OrderSummary(
      createdAt: p.fecha,
      pickupAt: null, // si quieres añadir luego
      status: _mapEstado(p.estado),
      total: p.total,
    );
  }).toList();
}



  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() {
      _refreshing = true;
      _future = _loadOrders();
    });
    await _future;
    if (!mounted) return;
    setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de pedidos'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<OrderSummary>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !_hasData(snap)) {
            return const _LoadingList();
          }
          if (snap.hasError) {
            return _ErrorState(
              message: 'No se pudo cargar el historial',
              onRetry: _refresh,
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return _EmptyState(onExplore: () => Navigator.pop(context));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) => _OrderCard(item: items[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _refreshing ? null : _refresh,
        icon: _refreshing
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : const Icon(Icons.refresh),
        label: Text(_refreshing ? 'Actualizando...' : 'Actualizar'),
        backgroundColor: kFucsia,
        foregroundColor: Colors.white,
      ),
    );
  }

  bool _hasData(AsyncSnapshot<List<OrderSummary>> snap) =>
      snap.hasData && (snap.data?.isNotEmpty ?? false);
}

/// ===== Widgets =====

class _OrderCard extends StatelessWidget {
  final OrderSummary item;
  const _OrderCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = item.orderCode;
    final date = _formatDate(item.createdAt);
    final time = _formatTime(item.createdAt);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Pedido $code')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Ícono
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long_outlined),
              ),
              const SizedBox(width: 12),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order code
                    Text(
                      code,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Fecha, retiro y total
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$date • $time'
                            '${item.pickupAt != null ? ' • Retiro: ${_formatDate(item.pickupAt!)} ${_formatTime(item.pickupAt!)}' : ''}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: kFucsia,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Estado (chip)
              _StatusChip(status: item.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final bg = status.bg(context);
    final fg = status.fg(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withOpacity(.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 18, color: fg),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget skeleton() => Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: const SizedBox(height: 78),
        );

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => skeleton(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined, size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Aún no tienes pedidos',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Cuando realices tu primer pedido, aparecerá aquí.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onExplore,
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Explorar productos'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text('Ups…', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===== Helpers de fecha/hora (visual) =====

String _two(int n) => n.toString().padLeft(2, '0');

String _formatDate(DateTime dt) => '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';

String _formatTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';

DateTime _withTime(DateTime base, {required int hour, required int minute}) =>
    DateTime(base.year, base.month, base.day, hour, minute);

OrderStatus _mapEstado(String estado) {
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
