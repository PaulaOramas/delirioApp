import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/screens/order_confirmation_screen.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_api.dart';
import 'package:delirio_app/screens/login_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartService();

  // Ajustes de cálculo
  static const double _ivaRate = 0.12; // 12% (EC)
  static const double _envio = 3.99;   // envío fijo de ejemplo

  bool _saving = false;

  double _subtotal(List<CartItem> items) =>
      items.fold(0.0, (sum, it) => sum + it.precio * it.qty);
  double _iva(List<CartItem> items) => _subtotal(items) * _ivaRate;
  double _total(List<CartItem> items) =>
      (items.isEmpty ? 0.0 : _subtotal(items) + _iva(items) + _envio);

  void _incQty(CartItem it) {
    // Actualiza la cantidad y notifica al ValueNotifier para que todos los
    // escuchadores (incluyendo otros widgets) se refresquen correctamente.
    setState(() => it.qty = (it.qty + 1).clamp(1, 99));
    cart.items.notifyListeners();
  }

  void _decQty(CartItem it) {
    setState(() => it.qty = (it.qty - 1).clamp(1, 99));
    cart.items.notifyListeners();
  }

  void _remove(CartItem it) => cart.removeItem(it.id);

  void _clearCart() => cart.clear();

  int? _extractUserId(Map<String, dynamic>? claims) {
    if (claims == null) return null;
    final candidates = ['id', 'Id', 'userId', 'UserId', 'nameid', 'nameId', 'sub'];
    for (final k in candidates) {
      final v = claims[k];
      if (v == null) continue;
      if (v is int) return v;
      final parsed = int.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return null;
  }

  Future<void> _checkout(List<CartItem> items) async {
    final auth = AuthService.instance;
    final claims = auth.claims;
    final userId = _extractUserId(claims);

    if (!auth.isLoggedIn() || userId == null) {
      final goLogin = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Inicia sesión'),
          content: const Text('Necesitas iniciar sesión para completar tu pedido.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Iniciar sesión')),
          ],
        ),
      );
      if (goLogin == true) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LoginScreen(replaceWithMainOnSuccess: false)),
        );
        setState(() {});
      }
      return;
    }

    setState(() => _saving = true);
    try {
      // Envía al backend
      await CartApi.agregarCarrito(userId: userId, items: items);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido enviado ✅')),
      );

      // Limpia el carrito local si tu backend persiste el pedido
      _clearCart();

      // Navega a confirmación
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OrderConfirmationScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo procesar el pedido: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          ValueListenableBuilder<List<CartItem>>(
            valueListenable: cart.items,
            builder: (context, items, _) {
              if (items.isEmpty) return const SizedBox.shrink();
              return IconButton(
                tooltip: 'Vaciar carrito',
                onPressed: _saving
                    ? null
                    : () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Vaciar carrito'),
                            content: const Text('Se eliminarán todos los productos.'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Vaciar')),
                            ],
                          ),
                        );
                        if (ok == true) _clearCart();
                      },
                icon: const Icon(Icons.delete_outline),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<CartItem>>(
          valueListenable: cart.items,
          builder: (context, items, _) {
            final isEmpty = items.isEmpty;
            return isEmpty
                ? _EmptyState(onExplore: () => Navigator.pop(context))
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final it = items[i];
                            return Dismissible(
                              key: ValueKey('${it.id}-${i}'),
                              direction: _saving ? DismissDirection.none : DismissDirection.endToStart,
                              onDismissed: (_) => _remove(it),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.delete, color: Theme.of(context).colorScheme.onErrorContainer),
                              ),
                              child: _CartTile(
                                item: it,
                                onDec: _saving ? null : () => _decQty(it),
                                onInc: _saving ? null : () => _incQty(it),
                                onRemove: _saving ? null : () => _remove(it),
                              ),
                            );
                          },
                        ),
                      ),
                      _SummaryCard(
                        subtotal: _subtotal(items),
                        iva: _iva(items),
                        envio: _envio,
                        total: _total(items),
                        isLoading: _saving,
                        onCheckout: _saving ? null : () => _checkout(items),
                      ),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback? onDec;
  final VoidCallback? onInc;
  final VoidCallback? onRemove;

  const _CartTile({
    required this.item,
    required this.onDec,
    required this.onInc,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen (si no hay URL válida, mostramos un placeholder local)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                // AspectRatio requiere constraints; envolvemos en SizedBox fijo para evitar 'unconstrained'
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Builder(builder: (context) {
                      final url = item.imagen?.trim();
                      if (url == null || url.isEmpty) {
                        return Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.local_florist, size: 28),
                        );
                      }

                      return Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceVariant,
                          child: const Icon(Icons.local_florist, size: 28),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(
                      item.categoria,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '\$${item.precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: kFucsia,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Controles de cantidad
                    Row(
                      children: [
                        _QtyButton(icon: Icons.remove, onTap: onDec),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.qty}', style: theme.textTheme.titleMedium),
                        ),
                        _QtyButton(icon: Icons.add, onTap: onInc),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: onRemove,
                          icon: const Icon(Icons.delete_outline),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e, st) {
      // Evitar que un error de renderización (null inesperado, etc.) bloquee
      // toda la pantalla del carrito. Logueamos y mostramos un placeholder.
      // En Flutter Web esto aparecerá en la consola JS (js_primitives).
      debugPrint('Cart tile build error: $e\n$st');
      return Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(child: Text('Error al mostrar este producto', style: TextStyle(color: Colors.red.shade700))),
              IconButton(onPressed: onRemove, icon: const Icon(Icons.delete_outline)),
            ],
          ),
        ),
      );
    }
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onTap == null;
    return Ink(
      decoration: BoxDecoration(
        color: disabled ? theme.disabledColor.withOpacity(.1) : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18, color: disabled ? theme.disabledColor : null),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double iva;
  final double envio;
  final double total;
  final bool isLoading;
  final VoidCallback? onCheckout;

  const _SummaryCard({
    required this.subtotal,
    required this.iva,
    required this.envio,
    required this.total,
    required this.isLoading,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = onCheckout == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            children: [
              _row('Subtotal', subtotal),
              const SizedBox(height: 6),
              _row('IVA (12%)', iva),
              const SizedBox(height: 6),
              _row('Envío', envio),
              const Divider(height: 22),
              _row('Total', total, isBold: true, isFucsia: true),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: disabled ? theme.disabledColor : kFucsia,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onCheckout,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.lock_outline),
                  label: Text(isLoading ? 'Procesando...' : 'Hacer pedido'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool isBold = false, bool isFucsia = false}) {
    final style = TextStyle(
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
      color: isFucsia ? kFucsia : null,
    );
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
        Text('\$${value.toStringAsFixed(2)}', style: style),
      ],
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
            Icon(Icons.shopping_bag_outlined, size: 72, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text('Tu carrito está vacío',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Explora nuestros ramos, plantas y regalos. ¡Hay algo para cada ocasión!',
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
