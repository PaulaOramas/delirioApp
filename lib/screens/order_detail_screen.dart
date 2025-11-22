import 'package:flutter/material.dart';
import 'package:delirio_app/models/pedido.dart';
import 'package:delirio_app/models/detalle_pedido.dart';
import 'package:delirio_app/models/order_status.dart';
import 'package:delirio_app/services/product_service.dart';

class OrderDetailScreen extends StatefulWidget {
  final Pedido pedido;

  const OrderDetailScreen({super.key, required this.pedido});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    _loadProductNames();
  }

  Future<void> _loadProductNames() async {
    for (var d in widget.pedido.detalles) {
      if (d.nombreProducto == null) {
        try {
          final prod = await ProductService.getById(d.prdId);
          d.nombreProducto = prod.nombre ?? "Producto";
        } catch (e) {
          d.nombreProducto = "Producto";
        }
      }
    }

    setState(() {}); // refresca la pantalla
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = mapEstado(widget.pedido.estado);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Detalle del pedido"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Pedido #${widget.pedido.pedidoId}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${_formatDate(widget.pedido.fecha)} • ${_formatTime(widget.pedido.fecha)}",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 16),

                  _OrderStatusChip(status: status),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              "Productos",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: 8),

            ...widget.pedido.detalles.map((d) => _ProductTile(detalle: d)),

            const SizedBox(height: 20),

            _SectionCard(
              child: Column(
                children: [
                  _priceRow("Subtotal", widget.pedido.subtotal, theme),
                  _priceRow("IVA", widget.pedido.iva, theme),
                  const Divider(),
                  _priceRow("Total", widget.pedido.total, theme, bold: true),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

Widget _priceRow(String label, double value, ThemeData theme,
    {bool bold = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: bold
                ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
                : theme.textTheme.bodyLarge,
          ),
        ),
        Text(
          "\$${value.toStringAsFixed(2)}",
          style: bold
              ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)
              : theme.textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class _OrderStatusChip extends StatelessWidget {
  final OrderStatus status;
  const _OrderStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.bg(context),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 18, color: status.fg(context)),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.fg(context),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final DetallePedido detalle;

  const _ProductTile({required this.detalle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_florist_outlined),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detalle.nombreProducto ?? "Producto",
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    "Cantidad: ${detalle.cantidad}",
                    style: theme.textTheme.bodyMedium,
                  ),

                  if (detalle.mensaje.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      "Mensaje: ${detalle.mensaje}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            Text(
              "\$${detalle.precio.toStringAsFixed(2)}",
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String _formatDate(DateTime dt) => '${_two(dt.day)}/${_two(dt.month)}/${dt.year}';
String _formatTime(DateTime dt) => '${_two(dt.hour)}:${_two(dt.minute)}';
