import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/screens/login_screen.dart';
import 'package:delirio_app/services/pedido_api.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  static const double _ivaRate = 0.15;
  static const int _pickupWindowDays = 7;
  static const int _openHour = 9;
  static const int _closeHour = 21;

  final CartService _cart = CartService();
  late final List<CartItem> _items;
  late final String _orderId;

  int _pagoSeleccionado = 0;
  final ImagePicker _picker = ImagePicker();
  XFile? _voucherFile;
  Uint8List? _voucherBytes;

  bool _sending = false;
  DateTime? _retirarEn;

  double get _subtotal =>
      _items.fold(0, (s, it) => s + (it.precio * it.qty));
  double get _iva => _subtotal * _ivaRate;
  double get _total => _subtotal + _iva;
  double get _montoAPagar =>
      _pagoSeleccionado == 0 ? _total * 0.5 : _total;

  @override
  void initState() {
    super.initState();

    _items = List.of(_cart.items.value);

    final now = DateTime.now();
    _orderId =
        "EST-${now.year}${_pad2(now.month)}${_pad2(now.day)}-${now.millisecondsSinceEpoch % 100000}";

    _retirarEn = _defaultPickup();
  }

  DateTime _roundToNext30(DateTime dt) {
    final add = dt.minute % 30 == 0 ? 0 : (30 - dt.minute % 30);
    final rounded = dt.add(Duration(minutes: add));
    return rounded;
  }

  DateTime _defaultPickup() {
    final now = DateTime.now();
    var candidate = _roundToNext30(now);
    final open = DateTime(now.year, now.month, now.day, _openHour);
    final close = DateTime(now.year, now.month, now.day, _closeHour);

    if (candidate.isBefore(open)) return open;
    if (candidate.isAfter(close)) {
      final next = now.add(const Duration(days: 1));
      return DateTime(next.year, next.month, next.day, _openHour);
    }
    return candidate;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _retirarEn ?? _defaultPickup();

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year, now.month, now.day + _pickupWindowDays),
    );
    if (date == null) return;

    final current = _retirarEn ?? _defaultPickup();

    setState(() {
      _retirarEn = _normalize(DateTime(
        date.year,
        date.month,
        date.day,
        current.hour,
        current.minute,
      ));
    });
  }

  Future<void> _pickTime() async {
    final base = _retirarEn ?? _defaultPickup();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: base.hour, minute: base.minute),
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;

    setState(() {
      _retirarEn = _normalize(DateTime(
        base.year,
        base.month,
        base.day,
        picked.hour,
        picked.minute,
      ));
    });
  }

  DateTime _normalize(DateTime dt) {
    final open = DateTime(dt.year, dt.month, dt.day, _openHour);
    final close = DateTime(dt.year, dt.month, dt.day, _closeHour);

    if (dt.isBefore(open)) return open;
    if (dt.isAfter(close)) return close;
    return _roundToNext30(dt);
  }

  bool _isInBusinessWindow(DateTime dt) {
    final open = DateTime(dt.year, dt.month, dt.day, _openHour);
    final close = DateTime(dt.year, dt.month, dt.day, _closeHour);
    return dt.isAfter(open) && dt.isBefore(close);
  }

  Future<void> _pickVoucher() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        _voucherFile = file;
        _voucherBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo adjuntar la imagen")),
      );
    }
  }

int? _extractUserId(Map<String, dynamic>? claims) {
  if (claims == null) return null;

  final keys = ["Id", "id", "ID", "userId", "UserId", "sub", "nameid"];

  for (final k in keys) {
    final v = claims[k];
    if (v == null) continue;

    return int.tryParse(v.toString());
  }

  return null;
}


  Future<void> _confirmarPedido() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tu carrito está vacío")),
      );
      return;
    }

    if (!AuthService.instance.isLoggedIn()) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const LoginScreen(replaceWithMainOnSuccess: false),
        ),
      );
      if (!AuthService.instance.isLoggedIn()) return;
    }

    if (_retirarEn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecciona fecha y hora de retiro")),
      );
      return;
    }

    if (_voucherBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Adjunta el comprobante de pago")),
      );
      return;
    }

    final userId = _extractUserId(AuthService.instance.claims);
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario no identificado")),
      );
      return;
    }

    setState(() => _sending = true);

    try {
      final resp = await PedidoApi.crearPedido(
        userId: userId,
        fecha: DateTime.now(),
        subtotal: _subtotal,
        iva: _iva,
        total: _total,
        estado: "CRE",
        abonado: _pagoSeleccionado == 1,
        montoAbonado:
            _pagoSeleccionado == 1 ? _total : _total * 0.5,
        credito: false,
        montoCredito: 0,
        items: _items,
      );

      final int pedidoId = resp["pedidoId"] ?? resp["id"] ?? -1;
      if (pedidoId == -1) throw Exception("ID no válido");

      await PedidoApi.subirComprobante(
        pedidoId: pedidoId,
        fileBytes: _voucherBytes!,
        fileName: _voucherFile?.name ?? "comprobante.jpg",
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text("¡Pedido enviado!"),
          content: Text(
            "Tu pedido fue registrado con ID #$pedidoId.\n"
            "Retiro: ${_fmtDateTime(_retirarEn!)}\n"
            "Monto: \$${_montoAPagar.toStringAsFixed(2)}",
          ),
          actions: [
            TextButton(
              onPressed: () {
                _cart.clear();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
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
              _headerCard(theme),
              const SizedBox(height: 12),

              const _SectionTitle('Productos'),
              const SizedBox(height: 8),
              _items.isEmpty
                  ? const _EmptyItems()
                  : Column(
                      children: _items
                          .map((it) =>
                              _ItemTile(item: it, onTap: () {}))
                          .toList(),
                    ),

              const SizedBox(height: 16),
              const _SectionTitle('Retiro en local'),
              const SizedBox(height: 8),
              _pickupCard(theme),
              const SizedBox(height: 16),

              const _SectionTitle('Resumen'),
              const SizedBox(height: 8),
              _summaryCard(theme),
              const SizedBox(height: 16),

              const _SectionTitle('Pago'),
              const SizedBox(height: 8),
              _paymentCard(),
              const SizedBox(height: 16),

              const _SectionTitle('Datos de transferencia'),
              const SizedBox(height: 8),
              _AccountInfoCard(monto: _montoAPagar),
              const SizedBox(height: 16),

              const _SectionTitle('Comprobante de pago'),
              const SizedBox(height: 8),
              _voucherCard(theme),
              const SizedBox(height: 20),

              _confirmButton(theme),
              const SizedBox(height: 12),
              _cancelButton(),
              const SizedBox(height: 8),

              Text(
                'Al confirmar aceptas los Términos y la Política de privacidad.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ====== WIDGETS DE SECCIÓN ======

  Widget _headerCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
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
                  Text(
                    'Pedido #$_orderId',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Fecha: ${_fmtDate(DateTime.now())}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickupCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Selecciona fecha y hora de retiro.\n'
              'Horario: ${_pad2(_openHour)}:00 – ${_pad2(_closeHour)}:00. '
              'Puedes agendar hasta $_pickupWindowDays días adelante.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : _pickDate,
                    icon: const Icon(Icons.event_outlined),
                    label: Text(
                      _retirarEn == null
                          ? 'Elegir fecha'
                          : 'Fecha: ${_fmtDate(_retirarEn!)}',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sending ? null : _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      _retirarEn == null
                          ? 'Elegir hora'
                          : 'Hora: ${_fmtTime(_retirarEn!)}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_retirarEn != null && !_isInBusinessWindow(_retirarEn!))
              Text(
                'La hora seleccionada está fuera del horario.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(ThemeData theme) {
    return Card(
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
            _row('Total', _total, bold: true, fucsia: true),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.store, size: 18),
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
    );
  }

  Widget _paymentCard() {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          RadioListTile(
            value: 0,
            groupValue: _pagoSeleccionado,
            onChanged: _sending
                ? null
                : (v) => setState(() => _pagoSeleccionado = (v as int?) ?? 0),
            title: const Text("Pagar 50% ahora"),
            subtitle: Text("Monto: \$${(_total * 0.5).toStringAsFixed(2)}"),
          ),
          const Divider(height: 1),
          RadioListTile(
            value: 1,
            groupValue: _pagoSeleccionado,
            onChanged: _sending
                ? null
                : (v) => setState(() => _pagoSeleccionado = (v as int?) ?? 1),
            title: const Text("Pagar 100% ahora"),
            subtitle: Text("Monto: \$${_total.toStringAsFixed(2)}"),
          ),
        ],
      ),
    );
  }

  Widget _voucherCard(ThemeData theme) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              "Adjunta el comprobante "
              "(${_pagoSeleccionado == 0 ? "50%" : "100%"} del total).",
            ),
            const SizedBox(height: 12),
            _voucherBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _voucherBytes!,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
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
                    onPressed:
                        (_items.isEmpty || _sending) ? null : _pickVoucher,
                    icon: const Icon(Icons.upload),
                    label: const Text("Adjuntar imagen"),
                  ),
                ),
                const SizedBox(width: 12),
                if (_voucherBytes != null)
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text("Quitar"),
                      onPressed: _sending
                          ? null
                          : () {
                              setState(() {
                                _voucherFile = null;
                                _voucherBytes = null;
                              });
                            },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _confirmButton(ThemeData theme) {
    final isDisabled = _items.isEmpty || _sending;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDisabled ? theme.disabledColor : kFucsia,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isDisabled ? null : _confirmarPedido,
        icon: _sending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check_circle_outline),
        label: Text(
          _sending
              ? "Enviando..."
              : "Confirmar pedido — \$${_montoAPagar.toStringAsFixed(2)}",
        ),
      ),
    );
  }

  Widget _cancelButton() {
    final errorColor = Theme.of(context).colorScheme.error;
    return OutlinedButton.icon(
      icon: Icon(Icons.cancel_outlined, color: errorColor),
      label: Text(
        'Cancelar pedido',
        style: TextStyle(
          color: errorColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: errorColor, width: 1.4),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("¿Cancelar pedido?"),
            content: const Text(
              "Esto eliminará todos los productos del carrito.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("No"),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Sí, cancelar"),
              ),
            ],
          ),
        );

        if (confirm == true) {
          _cart.clear();
          if (mounted) {
            Navigator.of(context).popUntil((r) => r.isFirst);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pedido cancelado")),
            );
          }
        }
      },
    );
  }

  // ===== HELPER VISUAL =====

  Widget _row(String label, double value,
      {bool bold = false, bool fucsia = false}) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          "\$${value.toStringAsFixed(2)}",
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: fucsia ? kFucsia : null,
          ),
        ),
      ],
    );
  }

  String _fmtDate(DateTime d) =>
      "${_pad2(d.day)}/${_pad2(d.month)}/${d.year}";
  String _fmtTime(DateTime d) =>
      "${_pad2(d.hour)}:${_pad2(d.minute)}";
  String _fmtDateTime(DateTime d) => "${_fmtDate(d)} ${_fmtTime(d)}";
  String _pad2(int n) => n.toString().padLeft(2, "0");
}

// ===== TITULITOS =====

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

// ===== WIDGETS AUXILIARES =====

class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'No hay productos en tu pedido.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onTap;

  const _ItemTile({required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: item.imagen != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imagen!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.local_florist_outlined),
                ),
              )
            : const Icon(Icons.local_florist_outlined),
        title: Text(item.nombre),
        subtitle: Text(
          "x${item.qty} • \$${item.precio.toStringAsFixed(2)}",
          style: theme.textTheme.bodySmall,
        ),
        trailing: Text(
          "\$${(item.precio * item.qty).toStringAsFixed(2)}",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  final double monto;
  const _AccountInfoCard({required this.monto});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cuenta para transferencia",
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text("Banco: Banco de Ejemplo S.A."),
            Text("Titular: DeLirio Florería"),
            Text("Cuenta: 1234567890"),
            Text("Tipo: Cuenta de ahorros"),
            const SizedBox(height: 12),
            Text(
              "Monto a pagar ahora: \$${monto.toStringAsFixed(2)}",
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: kFucsia,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
