// lib/screens/order_history_screen.dart
import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';

/// ===== Modelo y utilidades (solo para UI quemada) =====

enum OrderStatus { pendiente, aceptado, rechazado }

class OrderSummary {
  final DateTime createdAt;
  final OrderStatus status;
  final double total;

  OrderSummary({
    required this.createdAt,
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
      case OrderStatus.pendiente: return 'Pendiente';
      case OrderStatus.aceptado:  return 'Aceptado';
      case OrderStatus.rechazado: return 'Rechazado';
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pendiente: return Icons.schedule_outlined;
      case OrderStatus.aceptado:  return Icons.check_circle_outline;
      case OrderStatus.rechazado: return Icons.cancel_outlined;
    }
  }

  Color bg(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (this) {
      case OrderStatus.pendiente: return cs.surfaceVariant;
      case OrderStatus.aceptado:  return cs.primary.withOpacity(.12);
      case OrderStatus.rechazado: return cs.errorContainer;
    }
  }

  Color fg(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;
    switch (this) {
      case OrderStatus.pendiente: return cs.onSurfaceVariant;
      case OrderStatus.aceptado:  return cs.primary;
      case OrderStatus.rechazado: return cs.onErrorContainer;
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

  @override
  void initState() {
    super.initState();
    _future = _loadMock();
  }

  Future<List<OrderSummary>> _loadMock() async {
    await Future.delayed(const Duration(milliseconds: 600)); // shimmer simple
    final now = DateTime.now();

    // Datos QUEMADOS (ajusta a gusto)
    return [
      OrderSummary(
        createdAt: now.subtract(const Duration(minutes: 35)),
        status: OrderStatus.pendiente,
        total: 26.98,
      ),
      OrderSummary(
        createdAt: now.subtract(const Duration(days: 2, hours: 3)),
        status: OrderStatus.aceptado,
        total: 42.15,
      ),
      OrderSummary(
        createdAt: now.subtract(const Duration(days: 4, hours: 5)),
        status: OrderStatus.rechazado,
        total: 18.50,
      ),
      OrderSummary(
        createdAt: now.subtract(const Duration(days: 8, hours: 2)),
        status: OrderStatus.aceptado,
        total: 55.40,
      ),
    ];
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadMock();
    });
    await _future;
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
          if (snap.connectionState == ConnectionState.waiting) {
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
              itemBuilder: (ctx, i) {
                final it = items[i];
                return _OrderCard(item: it);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _refresh(),
        icon: const Icon(Icons.refresh),
        label: const Text('Actualizar'),
        backgroundColor: kFucsia,
        foregroundColor: Colors.white,
      ),
    );
  }
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
          // Aquí podrías navegar a detalle si luego lo implementas
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
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Fecha y total
                    Row(
                      children: [
                        Text(
                          '$date • $time',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${item.total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
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
            Text('Aún no tienes pedidos',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
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

String _formatDate(DateTime dt) =>
    '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';

String _formatTime(DateTime dt) =>
    '${_two(dt.hour)}:${_two(dt.minute)}';
