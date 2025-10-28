import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/screens/login_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  // ====== Configuración de cálculo ======
  static const double _ivaRate = 0.12; // 12% (EC)
  static const double _envio = 3.99;

  // Snapshot de ítems del carrito (tomado una sola vez al entrar)
  late final List<CartItem> _items;

  // Identificador local del pedido (visual)
  late final String _orderId;

  // Pago: 0 = 50%, 1 = 100%
  int _pagoSeleccionado = 0;

  // Imagen del comprobante
  final ImagePicker _picker = ImagePicker();
  XFile? _voucherFile;
  Uint8List? _voucherBytes;

  // ====== Cálculos ======
  double get _subtotal => _items.fold(0.0, (s, it) => s + (it.precio * it.qty));
  double get _iva => _subtotal * _ivaRate;
  double get _total => _subtotal + _iva + _envio;
  double get _montoAPagar => _pagoSeleccionado == 0 ? (_total * 0.5) : _total;

  @override
  void initState() {
    super.initState();
    _items = List.of(CartService().items.value); // snapshot inmutable
    final now = DateTime.now();
    _orderId = 'EST-${now.year}${_pad2(now.month)}${_pad2(now.day)}-${now.millisecondsSinceEpoch % 100000}';
  }

  Future<void> _pickVoucher() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() {
        _voucherFile = file;
        _voucherBytes = bytes;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comprobante adjuntado')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo adjuntar la imagen')),
      );
    }
  }

  void _confirmarPedido() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu carrito está vacío')),
      );
      return;
    }

    // Requerir inicio de sesión antes de confirmar
    if (!AuthService.instance.isLoggedIn()) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const LoginScreen(replaceWithMainOnSuccess: false)))
          .then((_) {
        if (AuthService.instance.isLoggedIn()) {
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

    // UI local (si luego conectas API, este es el sitio)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pedido confirmado'),
        content: Text(
          'Tu pedido $_orderId fue confirmado.\n\n'
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
                            Text('Pedido #$_orderId',
                                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text('Fecha: ${_fmtDate(DateTime.now())}',
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
              if (_items.isEmpty)
                const _EmptyItems()
              else
                ..._items.map((it) => _ItemTile(item: it, onTap: () {})).toList(),
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
                      _row('IVA (${(_ivaRate * 100).toStringAsFixed(0)}%)', _iva),
                      const SizedBox(height: 6),
                      _row('Envío', _envio),
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
                              onPressed: _items.isEmpty ? null : _pickVoucher,
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
              const SizedBox(height: 12),

              // Datos para transferencia
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Datos para transferencia',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: Text('Banco', style: theme.textTheme.bodyMedium)),
                          Text('Pichincha', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: Text('Tipo de cuenta', style: theme.textTheme.bodyMedium)),
                          Text('Ahorros', style: theme.textTheme.bodyMedium),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Número de cuenta', style: theme.textTheme.bodyMedium),
                                const SizedBox(height: 4),
                                SelectableText(
                                  '221045678',
                                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Titular: Ana Rodriguez',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copiar número',
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(const ClipboardData(text: '221045678'));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Número de cuenta copiado')),
                              );
                            },
                          ),
                        ],
                      ),
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
                    backgroundColor: _items.isEmpty ? theme.disabledColor : kFucsia,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _items.isEmpty ? null : _confirmarPedido,
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

  // ===== Helpers =====
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

  String _pad2(int n) => n.toString().padLeft(2, '0');
}

// ======= Widgets auxiliares =======

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
  final CartItem item;
  final VoidCallback onTap;

  const _ItemTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final img = (item.imagen ?? '').trim();

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
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: (img.isEmpty)
                        ? Container(
                            color: theme.colorScheme.surfaceVariant,
                            child: const Icon(Icons.local_florist, size: 28),
                          )
                        : Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: theme.colorScheme.surfaceVariant,
                              child: const Icon(Icons.local_florist, size: 28),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.nombre,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.categoria,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.shopping_cart_outlined, size: 56),
            const SizedBox(height: 12),
            Text(
              'Tu carrito está vacío',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega algunos productos para continuar con tu pedido.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: kFucsia,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.shop),
              label: const Text('Seguir comprando'),
            ),
          ],
        ),
      ),
    );
  }
}
