// lib/screens/order_confirmation_screen.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/screens/login_screen.dart';
import 'package:delirio_app/services/pedido_api.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  // ====== Configuración de cálculo ======
  static const double _ivaRate = 0.12; // Ecuador

  // Ventana y horario de retiro (ajusta a tu negocio)
  static const int _pickupWindowDays = 7; // permitir escoger hasta 7 días adelante
  static const int _openHour = 9;  // 09:00
  static const int _closeHour = 21; // 21:00

  // Usamos la MISMA instancia de carrito para poder limpiar localStorage correctamente
  final CartService _cart = CartService();

  // Snapshot de ítems del carrito (tomado una sola vez al entrar)
  late final List<CartItem> _items;

  // Identificador local (solo referencia visual)
  late final String _orderId;

  int _pagoSeleccionado = 0; // 0 = 50%, 1 = 100%
  final ImagePicker _picker = ImagePicker();
  XFile? _voucherFile;
  Uint8List? _voucherBytes;

  bool _sending = false;

  // Fecha/hora de retiro seleccionada
  DateTime? _retirarEn;

  double get _subtotal => _items.fold(0.0, (s, it) => s + (it.precio * it.qty));
  double get _iva => _subtotal * _ivaRate;
  double get _total => _subtotal + _iva;
  double get _montoAPagar => _pagoSeleccionado == 0 ? (_total * 0.5) : _total;

  @override
  void initState() {
    super.initState();
    // Tomamos snapshot para que el resumen no cambie aunque modifiquen el carrito en otra vista
    _items = List.of(_cart.items.value);
    final now = DateTime.now();
    _orderId = 'EST-${now.year}${_pad2(now.month)}${_pad2(now.day)}-${now.millisecondsSinceEpoch % 100000}';
    // Valor por defecto: próxima media hora dentro del horario
    _retirarEn = _defaultPickup();
  }

  // ====== Pickers de fecha y hora ======
  DateTime _roundToNext30(DateTime dt) {
    final add = dt.minute % 30 == 0 ? 0 : (30 - dt.minute % 30);
    final rounded = DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute).add(Duration(minutes: add));
    return rounded;
  }

  DateTime _defaultPickup() {
    final now = DateTime.now();
    var candidate = _roundToNext30(now);
    final open = DateTime(now.year, now.month, now.day, _openHour);
    final close = DateTime(now.year, now.month, now.day, _closeHour);

    if (candidate.isBefore(open)) {
      candidate = open;
    } else if (candidate.isAfter(close)) {
      // siguiente día a primera hora
      final nextDay = now.add(const Duration(days: 1));
      candidate = DateTime(nextDay.year, nextDay.month, nextDay.day, _openHour);
    }
    return candidate;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _retirarEn ?? _defaultPickup();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day + _pickupWindowDays),
      helpText: 'Selecciona la fecha de retiro',
    );
    if (selectedDate == null) return;

    final current = _retirarEn ?? _defaultPickup();
    final candidate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      current.hour,
      current.minute,
    );

    setState(() {
      _retirarEn = _normalizeToBusinessHours(candidate);
    });
  }

  Future<void> _pickTime() async {
    final base = _retirarEn ?? _defaultPickup();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      helpText: 'Selecciona la hora de retiro',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child ?? const SizedBox.shrink(),
      ),
    );
    if (picked == null) return;

    final candidate = DateTime(base.year, base.month, base.day, picked.hour, picked.minute);
    final normalized = _normalizeToBusinessHours(_roundToNext30(candidate));

    if (!_isInBusinessWindow(normalized)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El horario de retiro es de ${_pad2(_openHour)}:00 a ${_pad2(_closeHour)}:00')),
      );
      return;
    }

    setState(() => _retirarEn = normalized);
  }

  DateTime _normalizeToBusinessHours(DateTime dt) {
    final open = DateTime(dt.year, dt.month, dt.day, _openHour);
    final close = DateTime(dt.year, dt.month, dt.day, _closeHour);
    if (dt.isBefore(open)) return open;
    if (dt.isAfter(close)) return close;
    return _roundToNext30(dt);
  }

  bool _isInBusinessWindow(DateTime dt) {
    final open = DateTime(dt.year, dt.month, dt.day, _openHour);
    final close = DateTime(dt.year, dt.month, dt.day, _closeHour);
    return (dt.isAtSameMomentAs(open) || dt.isAfter(open)) && (dt.isBefore(close) || dt.isAtSameMomentAs(close));
  }

  Future<void> _pickVoucher() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _voucherFile = file;
        _voucherBytes = bytes;
      });
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

  int? _extractUserId(Map<String, dynamic>? claims) {
    if (claims == null) return null;
    final keys = ['id', 'Id', 'userId', 'UserId', 'nameid', 'nameId', 'sub'];
    for (final k in keys) {
      final v = claims[k];
      if (v == null) continue;
      if (v is int) return v;
      final parsed = int.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  Future<void> _confirmarPedido() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tu carrito está vacío')),
      );
      return;
    }

    // Requerir login
    if (!AuthService.instance.isLoggedIn()) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const LoginScreen(replaceWithMainOnSuccess: false)),
      );
      if (!AuthService.instance.isLoggedIn()) return;
    }

    // Validación de fecha/hora de retiro
    if (_retirarEn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona la fecha y hora de retiro')),
      );
      return;
    }
    final now = DateTime.now();
    if (_retirarEn!.isBefore(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La fecha/hora de retiro debe ser posterior al momento actual')),
      );
      return;
    }
    if (!_isInBusinessWindow(_retirarEn!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El retiro debe estar entre ${_pad2(_openHour)}:00 y ${_pad2(_closeHour)}:00')),
      );
      return;
    }

    // Requerir comprobante
    if (_voucherBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adjunta el comprobante del pago para continuar')),
      );
      return;
    }

    final userId = _extractUserId(AuthService.instance.claims);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo identificar al usuario')),
      );
      return;
    }

    setState(() => _sending = true);
    try {
      // 1) Envía el pedido al backend (agregamos fechaRetiro)
      final resp = await PedidoApi.crearPedido(
        userId: userId,
        fecha: DateTime.now(),
        subtotal: _subtotal,
        iva: _iva,
        total: _total,
        items: _items,
        comprobanteBytes: _voucherBytes,
        estado: 'PEN', // PENDIENTE
      );

      if (!mounted) return;

      final serverId = (resp['id'] ?? resp['pedidoId'] ?? resp['orderId'] ?? '—').toString();

      // 2) Mostrar diálogo de éxito con CTA
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Pedido enviado!'),
          content: Text(
            'Tu pedido fue registrado con ID $serverId.\n'
            'Referencia local: $_orderId\n'
            'Retiro: ${_fmtDateTime(_retirarEn!)}\n\n'
            'Monto recibido: \$${_montoAPagar.toStringAsFixed(2)} '
            '(${_pagoSeleccionado == 0 ? '50%' : '100%'}). '
            'Quedará en estado PENDIENTE hasta la revisión.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx); // cierra el diálogo
                // 3) Limpiamos el carrito
                _cart.clear();
                // 4) Volver a Home (o pop a la raíz)
                Navigator.of(context).popUntil((route) => route.isFirst);
                // 5) Feedback final
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Carrito vacío. ¡Gracias por tu compra!')),
                );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo registrar el pedido: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
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
                      const SizedBox(height: 12),
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
              const _SectionTitle('Productos'),
              const SizedBox(height: 8),
              if (_items.isEmpty)
                const _EmptyItems()
              else
                ..._items.map((it) => _ItemTile(item: it, onTap: () {})).toList(),
              const SizedBox(height: 12),

              // ===== NUEVO: Selección de fecha y hora de retiro =====
              const _SectionTitle('Retiro en local'),
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
                        'Selecciona la fecha y hora en la que deseas retirar tu pedido.\n'
                        'Horario de atención: ${_pad2(_openHour)}:00 – ${_pad2(_closeHour)}:00. '
                        'Puedes agendar dentro de los próximos $_pickupWindowDays días.',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _sending ? null : _pickDate,
                              icon: const Icon(Icons.event_outlined),
                              label: Text(_retirarEn == null
                                  ? 'Elegir fecha'
                                  : 'Fecha: ${_fmtDate(_retirarEn!)}'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _sending ? null : _pickTime,
                              icon: const Icon(Icons.access_time),
                              label: Text(_retirarEn == null
                                  ? 'Elegir hora'
                                  : 'Hora: ${_fmtTime(_retirarEn!)}'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_retirarEn != null && !_isInBusinessWindow(_retirarEn!))
                        Text(
                          'La hora seleccionada está fuera del horario. Se ajustará al horario de atención.',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Resumen
              const _SectionTitle('Resumen'),
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
                      //const Divider(height: 22),
                      _row('Total', _total, bold: true, fucsia: true),
                      const SizedBox(height: 12),
                      // Mostrar selección de retiro en el resumen
                      Row(
                        children: [
                          const Icon(Icons.store_mall_directory_outlined, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _retirarEn == null
                                  ? 'Retiro: sin definir'
                                  : 'Retiro: ${_fmtDateTime(_retirarEn!)}',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pago
              const _SectionTitle('Pago'),
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
                      onChanged: _sending ? null : (v) => setState(() => _pagoSeleccionado = v ?? 0),
                      title: const Text('Pagar 50% ahora'),
                      subtitle: Text('Monto: \$${(_total * 0.5).toStringAsFixed(2)}'),
                    ),
                    const Divider(height: 1),
                    RadioListTile<int>(
                      value: 1,
                      groupValue: _pagoSeleccionado,
                      onChanged: _sending ? null : (v) => setState(() => _pagoSeleccionado = v ?? 1),
                      title: const Text('Pagar 100% ahora'),
                      subtitle: Text('Monto: \$${_total.toStringAsFixed(2)}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ===== NUEVO: Datos de transferencia =====
              const _SectionTitle('Datos de transferencia'),
              const SizedBox(height: 8),
              _AccountInfoCard(monto: _montoAPagar),
              const SizedBox(height: 12),


              // Comprobante
              const _SectionTitle('Comprobante de pago'),
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
                              onPressed: (_items.isEmpty || _sending) ? null : _pickVoucher,
                              icon: const Icon(Icons.upload),
                              label: const Text('Adjuntar imagen'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_voucherBytes != null)
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _sending
                                    ? null
                                    : () => setState(() {
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
                    backgroundColor: (_items.isEmpty || _sending) ? theme.disabledColor : kFucsia,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_items.isEmpty || _sending) ? null : _confirmarPedido,
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(_sending
                      ? 'Enviando...'
                      : 'Confirmar pedido — \$${_montoAPagar.toStringAsFixed(2)}'),
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

  String _fmtTime(DateTime d) {
    final h = _pad2(d.hour);
    final mi = _pad2(d.minute);
    return '$h:$mi';
  }

  String _fmtDateTime(DateTime d) => '${_fmtDate(d)} ${_fmtTime(d)}';

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
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
              const SizedBox(width: 12), // ← antes estaba height: 12
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.remove_shopping_cart_outlined),
            SizedBox(width: 10),
            Expanded(child: Text('No hay productos en este pedido.')),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final double monto;
  const _AccountInfoCard({required this.monto});

  static const _titular = 'Ana Rodiguez';
  static const _banco   = 'Banco Pichincha';
  static const _tipo    = 'Cuenta de ahorros';
  static const _numero  = '2210785643';

  Future<void> _copyAccount(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _numero));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Número de cuenta copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_wallet_outlined),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Datos para transferencia',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(_titular, style: theme.textTheme.bodyMedium),
            Text(_banco,   style: theme.textTheme.bodyMedium),
            Text(_tipo,    style: theme.textTheme.bodyMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    'No. $_numero',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kFucsia,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _copyAccount(context),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copiar'),
                  style: TextButton.styleFrom(
                    foregroundColor: kFucsia,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ],
            ),
            const Divider(height: 22),
            Row(
              children: [
                const Icon(Icons.payments_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Monto a transferir: \$${monto.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: kFucsia,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

