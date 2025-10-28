import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/screens/order_confirmation_screen.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/login_screen.dart';
import 'package:delirio_app/services/product_service.dart'; // <- NUEVO

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartService();

  static const double _ivaRate = 0.12; // 12% (EC)
  static const double _envio = 3.99;   // ejemplo

  bool _saving = false;

  // cache de stock por productoId
  final Map<int, int> _stockById = {};
  bool _loadingStock = false;

  @override
  void initState() {
    super.initState();
    // cuando cambie el carrito, recargo stock
    cart.items.addListener(_refreshStocks);
    _refreshStocks();
  }

  @override
  void dispose() {
    cart.items.removeListener(_refreshStocks);
    super.dispose();
  }

  Future<void> _refreshStocks() async {
    final items = cart.items.value;
    if (items.isEmpty) {
      setState(() {
        _stockById.clear();
      });
      return;
    }

    setState(() => _loadingStock = true);
    try {
      // cargo stock para ids únicos
      final ids = items.map((e) => e.id).toSet().toList();
      for (final id in ids) {
        try {
          final p = await ProductService.getById(id);
          _stockById[id] = p.stock ?? 0; // ajusta si tu Product tiene "stock"
        } catch (_) {
          // si falla, deja stock 0 para ese producto (no dejar comprar)
          _stockById[id] = 0;
        }
      }
    } finally {
      setState(() => _loadingStock = false);
    }

    // si alguna qty > stock, la bajo
    bool changed = false;
    for (final it in items) {
      final max = _stockById[it.id] ?? 0;
      if (it.qty > max) {
        it.qty = max.clamp(0, 99);
        changed = true;
      }
    }
    if (changed) cart.items.notifyListeners();
  }

  double _subtotal(List<CartItem> items) =>
      items.fold(0.0, (sum, it) => sum + it.precio * it.qty);
  double _iva(List<CartItem> items) => _subtotal(items) * _ivaRate;
  double _total(List<CartItem> items) =>
      (items.isEmpty ? 0.0 : _subtotal(items) + _iva(items) + _envio);

  void _incQty(CartItem it) {
    final max = _stockById[it.id] ?? 0;
    if (max <= 0) {
      _toast('Sin stock disponible');
      return;
    }
    if (it.qty >= max) {
      _toast('Solo quedan $max unidades');
      return;
    }
    setState(() => it.qty = (it.qty + 1).clamp(1, max));
    cart.items.notifyListeners();
  }

  void _decQty(CartItem it) {
    setState(() => it.qty = (it.qty - 1).clamp(1, 99));
    cart.items.notifyListeners();
  }

  void _remove(CartItem it) => cart.removeItem(it.id);
  void _clearCart() => cart.clear();

  Future<bool> _ensureLoggedIn() async {
    if (AuthService.instance.isLoggedIn()) return true;
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
    return AuthService.instance.isLoggedIn();
  }

  // Valida que ninguna qty exceda stock. Si excede, la ajusta y notifica.
  bool _enforceMaxStock(List<CartItem> items) {
    bool adjusted = false;
    final msgs = <String>[];

    for (final it in items) {
      final max = _stockById[it.id] ?? 0;
      if (it.qty > max) {
        it.qty = max.clamp(0, 99);
        adjusted = true;
        msgs.add('${it.nombre}: máx $max');
      }
    }
    if (adjusted) {
      cart.items.notifyListeners();
      final text = 'Ajustamos por stock:\n• ' + msgs.join('\n• ');
      _snack(text);
    }
    return !adjusted; // true si todo ok; false si hubo ajustes
  }

  Future<void> _goToConfirmation(List<CartItem> items) async {
    if (items.isEmpty) {
      _snack('Tu carrito está vacío');
      return;
    }
    if (_loadingStock) {
      _snack('Cargando stock, intenta de nuevo…');
      return;
    }

    // fuerza cantidades contra stock
    final okStock = _enforceMaxStock(items);
    if (!okStock) return;

    // Requiere login antes de confirmar
    final ok = await _ensureLoggedIn();
    if (!ok) return;

    // Si aquí quisieras DESCONTAR stock en la API antes de ir a confirmar,
    // puedes hacerlo en este punto (transacción real sugerida en backend).
    // Ejemplo optimista (usa SOLO una de las variantes del ProductService):
    /*
    setState(() => _saving = true);
    try {
      for (final it in items) {
        final current = _stockById[it.id] ?? 0;
        final newStock = (current - it.qty).clamp(0, 1 << 31);
        await ProductService.updateStockOnly(it.id, newStock);
        // o: await ProductService.updateProductStockFull(it.id, newStock);
        _stockById[it.id] = newStock;
      }
    } catch (e) {
      _snack('No se pudo reservar stock. Intenta más tarde.');
      setState(() => _saving = false);
      return;
    } finally {
      setState(() => _saving = false);
    }
    */

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const OrderConfirmationScreen()),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _toast(String msg) => _snack(msg);

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
                      if (_loadingStock)
                        const LinearProgressIndicator(minHeight: 2),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final it = items[i];
                            final max = _stockById[it.id] ?? 0;
                            final reachedMax = it.qty >= max && max > 0;

                            return Dismissible(
                              key: ValueKey('${it.id}-$i'),
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
                                stock: max,                   // <- NUEVO
                                reachedMax: reachedMax,       // <- NUEVO
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
                        isLoading: _saving || _loadingStock,
                        onCheckout: (_saving || _loadingStock) ? null : () => _goToConfirmation(items),
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
  final int stock;            // <- NUEVO
  final bool reachedMax;      // <- NUEVO
  final VoidCallback? onDec;
  final VoidCallback? onInc;
  final VoidCallback? onRemove;

  const _CartTile({
    required this.item,
    required this.stock,
    required this.reachedMax,
    required this.onDec,
    required this.onInc,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final theme = Theme.of(context);
      final img = (item.imagen ?? '').trim();
      final noStock = stock <= 0;

      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen segura
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: img.isEmpty
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
                    const SizedBox(height: 6),
                    // Stock hint
                    Text(
                      noStock ? 'Sin stock' : 'Quedan $stock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: noStock ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
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
                        // Deshabilita el '+' si alcanzó stock o si no hay stock
                        AbsorbPointer(
                          absorbing: reachedMax || noStock,
                          child: Opacity(
                            opacity: (reachedMax || noStock) ? 0.4 : 1,
                            child: _QtyButton(icon: Icons.add, onTap: onInc),
                          ),
                        ),
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

// Widget que se muestra cuando el carrito está vacío
class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text('Tu carrito está vacío', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Explora productos y agrégalos al carrito.', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: onExplore,
            child: const Text('Explorar productos'),
          ),
        ],
      ),
    );
  }
}

// Resumen / tarjeta con total y botón de confirmar
class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double iva;
  final double envio;
  final double total;
  final bool isLoading;
  final VoidCallback? onCheckout;

  const _SummaryCard({
    this.subtotal = 0.0,
    this.iva = 0.0,
    this.envio = 0.0,
    this.total = 0.0,
    this.isLoading = false,
    this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: Text('Subtotal', style: theme.textTheme.bodyMedium)),
                Text('\$${subtotal.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('IVA', style: theme.textTheme.bodyMedium)),
                Text('\$${iva.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('Envío', style: theme.textTheme.bodyMedium)),
                Text('\$${envio.toStringAsFixed(2)}', style: theme.textTheme.bodyMedium),
              ],
            ),
            const Divider(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Total',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('\$${total.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (isLoading) ? null : onCheckout,
                child: isLoading ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Confirmar pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
