import 'package:flutter/material.dart';
import 'package:delirio_app/models/pedido.dart';
import 'package:delirio_app/models/detalle_pedido.dart';
import 'package:delirio_app/models/order_status.dart';
import 'package:delirio_app/services/product_service.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/pedido_api.dart';

class OrderDetailScreen extends StatefulWidget {
  final Pedido pedido;


  const OrderDetailScreen({super.key, required this.pedido});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
    late Pedido _pedido;   // 👈 AQUÍ SÍ VA
  @override
  void initState() {
    super.initState();
    _pedido = widget.pedido;
    _loadProductNames();
  }

  Future<void> _loadProductNames() async {
    for (var d in _pedido.detalles) {
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
    final status = mapEstado(_pedido.estado);

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
                    "Pedido #${_pedido.pedidoId}",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "${_formatDate(_pedido.fecha)} • ${_formatTime(_pedido.fecha)}",
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

            ..._pedido.detalles.map((d) => _ProductTile(detalle: d)),

            const SizedBox(height: 20),

            _SectionCard(
              child: Column(
                children: [
                  _priceRow("Subtotal", _pedido.subtotal, theme),
                  _priceRow("IVA", _pedido.iva, theme),
                  const Divider(),
                  _priceRow("Total", _pedido.total, theme, bold: true),
                ],
              ),
            ),

            if (status == OrderStatus.pendiente || status == OrderStatus.aceptado) ...[
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                    ),
                    onPressed: _cancelarPedido,
                    child: const Text("Cancelar pedido", style: TextStyle(color: Colors.white)),
                    ),
                ),
                ],


            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelarPedido() async {
  final token = AuthService.instance.token; // si tienes token aquí
  final pedidoId = _pedido.pedidoId;

  if (token == null || token.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Debes iniciar sesión para cancelar")),
    );
    return;
  }

  try {
    final ok = await PedidoApi.cancelarPedido(pedidoId, token);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pedido cancelado correctamente")),
      );

      setState(() {
        _pedido = Pedido(
            pedidoId: _pedido.pedidoId,
            userId: _pedido.userId,
            fecha: _pedido.fecha,
            subtotal: _pedido.subtotal,
            iva: _pedido.iva,
            total: _pedido.total,
            comprobante: _pedido.comprobante,
            abonado: _pedido.abonado,
            montoAbonado: _pedido.montoAbonado,
            credito: _pedido.credito,
            montoCredito:_pedido.montoCredito,
            estado: "RCZ",
            detalles: _pedido.detalles,
        );
    });

    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error al cancelar: $e")),
    );
  }
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
