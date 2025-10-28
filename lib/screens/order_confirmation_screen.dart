import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/login_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  // 🔥 Datos quemados del pedido
  final _order = _DummyOrder(
    orderId: 'DLR-2025-00123',
    fecha: DateTime.now(),
    items: const [
      _DummyItem(
        nombre: 'Ramo Primavera',
        categoria: 'Ramos Florales',
        precio: 24.99,
        qty: 1,
        imagen: 'https://images.unsplash.com/photo-1501004318641-b39e6451bec6?w=800',
      ),
      _DummyItem(
        nombre: 'Orquídea Blanca',
        categoria: 'Plantas',
        precio: 29.50,
        qty: 1,
        imagen: 'https://images.unsplash.com/photo-1526045612212-70caf35c14df?w=800',
      ),
    ],
    envio: 3.99,
    ivaRate: 0.12, // Ecuador
  );

  // Pago: 0 = 50%, 1 = 100%
  int _pagoSeleccionado = 0;

  // Imagen del comprobante
  final ImagePicker _picker = ImagePicker();
  XFile? _voucherFile;
  Uint8List? _voucherBytes;

  double get _subtotal => _order.items.fold(0.0, (s, it) => s + it.precio * it.qty);
  double get _iva => _subtotal * _order.ivaRate;
  double get _total => _subtotal + _iva + _order.envio;
  double get _montoAPagar => _pagoSeleccionado == 0 ? (_total * 0.5) : _total;

  Future<void> _pickVoucher() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _voucherFile = file;
        _voucherBytes = bytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprobante adjuntado')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo adjuntar la imagen')),
      );
    }
  }

  void _confirmarPedido() {
    // Requerir inicio de sesión antes de confirmar el pedido
    if (!AuthService.instance.isLoggedIn()) {
      // Abrir LoginScreen y esperar resultado. Si el usuario no inicia sesión, abortamos.
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen(replaceWithMainOnSuccess: false)))
          .then((res) {
        if (AuthService.instance.isLoggedIn()) {
          // Si ahora está autenticado, intentamos confirmar de nuevo (el usuario sigue en la misma pantalla)
          _confirmarPedido();
        }
      });
      return;
    }

    if (_voucherBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunta el comprobante del pago para continuar')),
      );
      return;
    }

    // UI-only: feedback
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pedido confirmado'),
        content: Text(
          'Tu pedido ${_order.orderId} fue confirmado.\n\n'
          'Monto recibido: \$${_montoAPagar.toStringAsFixed(2)} '
          '(${_pagoSeleccionado == 0 ? '50%' : '100%'}).\n'
          'Nos pondremos en contacto para coordinar la entrega. 💐',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirmación de pedido')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encabezado
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        height: 44,
                        width: 44,
                        decoration: BoxDecoration(
                          color: kFucsia.withOpacity(.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.receipt_long, color: kFucsia),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Pedido #${_order.orderId}',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Fecha: ${_fmtDate(_order.fecha)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Items
              _SectionTitle('Productos'),
              const SizedBox(height: 8),
              ..._order.items
                  .map((it) => _ItemTile(
                        item: it,
                        onTap: () {},
                      ))
                  .toList(),
              const SizedBox(height: 12),

              // Resumen
              _SectionTitle('Resumen'),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Subtotal', _subtotal),
                      const SizedBox(height: 6),
                      _row('IVA (${(_order.ivaRate * 100).toStringAsFixed(0)}%)', _iva),
                      const SizedBox(height: 6),
                      _row('Envío', _order.envio),
                      const Divider(height: 22),
                      _row('Total', _total, bold: true, fucsia: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Método de pago
              _SectionTitle('Pago'),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    RadioListTile<int>(
                      value: 0,
                      groupValue: _pagoSeleccionado,
                      onChanged: (v) => setState(() => _pagoSeleccionado = v ?? 0),
                      title: const Text('Pagar 50% ahora'),
                      subtitle: Text('Monto: \$${(_total * 0.5).toStringAsFixed(2)}'),
                    ),
                    const Divider(height: 1),
                    RadioListTile<int>(
                      value: 1,
                      groupValue: _pagoSeleccionado,
                      onChanged: (v) => setState(() => _pagoSeleccionado = v ?? 1),
                      title: const Text('Pagar 100% ahora'),
                      subtitle: Text('Monto: \$${_total.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Comprobante
              _SectionTitle('Comprobante de pago'),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Adjunta una foto del comprobante correspondiente '
                        '(${_pagoSeleccionado == 0 ? '50%' : '100%'} del total).',
                      ),
                      const SizedBox(height: 12),
                      if (_voucherBytes != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _voucherBytes!,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        Container(
                          height: 160,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.image_outlined, size: 48),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickVoucher,
                              icon: const Icon(Icons.upload),
                              label: const Text('Adjuntar imagen'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_voucherBytes != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => setState(() {
                                  _voucherFile = null;
                                  _voucherBytes = null;
                                }),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Quitar'),
                              ),
                            ),
                        ],
                      ),
                      if (_voucherFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          kIsWeb ? 'Archivo seleccionado' : (_voucherFile!.name),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botón confirmar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kFucsia,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _confirmarPedido,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text('Confirmar pedido — \$${_montoAPagar.toStringAsFixed(2)}'),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Al confirmar aceptas los Términos y la Política de privacidad.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false, bool fucsia = false}) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: fucsia ? kFucsia : null,
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$day/$m/$y';
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: .2,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final _DummyItem item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Image.network(
                    item.imagen,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.colorScheme.surfaceVariant,
                      child: const Icon(Icons.local_florist, size: 28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nombre,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item.categoria,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        )),
                    const SizedBox(height: 6),
                    Text(
                      '\$${item.precio.toStringAsFixed(2)}  ×  ${item.qty}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: kFucsia),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --------- Modelos de demo (quemados) ----------
class _DummyOrder {
  final String orderId;
  final DateTime fecha;
  final List<_DummyItem> items;
  final double envio;
  final double ivaRate;

  const _DummyOrder({
    required this.orderId,
    required this.fecha,
    required this.items,
    required this.envio,
    required this.ivaRate,
  });
}

class _DummyItem {
  final String nombre;
  final String categoria;
  final double precio;
  final int qty;
  final String imagen;

  const _DummyItem({
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.qty,
    required this.imagen,
  });
}
