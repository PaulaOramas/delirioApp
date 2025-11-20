import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/screens/order_confirmation_screen.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/login_screen.dart';
import 'package:delirio_app/services/product_service.dart';
import 'package:delirio_app/navigation.dart';
import 'package:delirio_app/screens/add_ons_message_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartService();

  static const double _ivaRate = 0.15; // 15% (EC)
  bool _saving = false;
  final Map<int, int> _stockById = {};
  bool _loadingStock = false;

  @override
  void initState() {
    super.initState();
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
      final ids = items.map((e) => e.id).toSet().toList();
      for (final id in ids) {
        try {
          final p = await ProductService.getById(id);
          _stockById[id] = p.stock ?? 0;
        } catch (_) {
          _stockById[id] = 0;
        }
      }
    } finally {
      setState(() => _loadingStock = false);
    }

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
      (items.isEmpty ? 0.0 : _subtotal(items) + _iva(items));

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
    if (it.qty == 1) {
      _remove(it);
    } else {
      setState(() => it.qty = (it.qty - 1).clamp(1, 99));
      cart.items.notifyListeners();
    }
  }

  void _remove(CartItem it) => cart.removeItem(it.id);
  void _clearCart() => cart.clear();

  Future<bool> _ensureLoggedIn() async {
    if (AuthService.instance.isLoggedIn()) return true;
    final goLogin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Inicia sesión'),
        content:
            const Text('Necesitas iniciar sesión para completar tu pedido.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Iniciar sesión')),
        ],
      ),
    );
    if (goLogin == true) {
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) =>
                const LoginScreen(replaceWithMainOnSuccess: false)),
      );
      setState(() {});
    }
    return AuthService.instance.isLoggedIn();
  }

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
    return !adjusted;
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

    final okStock = _enforceMaxStock(items);
    if (!okStock) return;

    final ok = await _ensureLoggedIn();
    if (!ok) return;

    setState(() => _saving = true);
    try {
      for (final it in items) {
        final current = _stockById[it.id] ?? 0;
        final newStock = (current - it.qty).clamp(0, 1 << 31);
        await ProductService.updateStockOnly(it.id, newStock);
        _stockById[it.id] = newStock;
      }
    } catch (e) {
      _snack('No se pudo reservar stock. Intenta más tarde.');
      setState(() => _saving = false);
      return;
    } finally {
      setState(() => _saving = false);
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddOnsAndMessageScreen()),
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
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Vaciar carrito'),
                              content: const Text(
                                  'Se eliminarán todos los productos.'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text('Cancelar')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Vaciar')),
                              ],
                            ),
                          );
                          if (ok == true) _clearCart();
                        },
                  child: Text(
                    'Vaciar carrito',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) {
                            final it = items[i];
                            final max = _stockById[it.id] ?? 0;
                            final reachedMax = it.qty >= max && max > 0;

                            return Dismissible(
                              key: ValueKey('${it.id}-$i'),
                              direction: _saving
                                  ? DismissDirection.none
                                  : DismissDirection.endToStart,
                              onDismissed: (_) => _remove(it),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(Icons.delete,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer),
                              ),
                              child: _CartTile(
                                item: it,
                                stock: max,
                                reachedMax: reachedMax,
                                onDec: _saving ? null : () => _decQty(it),
                                onInc: _saving ? null : () => _incQty(it),
                                onRemove:
                                    _saving ? null : () => _remove(it),
                              ),
                            );
                          },
                        ),
                      ),
                      _SummaryCard(
                        subtotal: _subtotal(items),
                        iva: _iva(items),
                        total: _total(items),
                        isLoading: _saving || _loadingStock,
                        onCheckout: (_saving || _loadingStock)
                            ? null
                            : () => _goToConfirmation(items),
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
  final int stock;
  final bool reachedMax;
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

      // ⭐ Nueva validación: deshabilitar el botón de "menos" cuando qty = 1
      final disableMinus = item.qty <= 1;

      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // IMAGE
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 72,
                  height: 72,
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

              const SizedBox(width: 12),

              // INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),

                    const SizedBox(height: 2),

                    Text(
                      item.categoria,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      noStock ? 'Sin stock' : 'Quedan $stock',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: noStock
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurfaceVariant,
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

                    const SizedBox(height: 12),

                    // CANTIDAD + ELIMINAR
                    Row(
                      children: [
                        // -----------------------------------------
                        //  BOTÓN MENOS (deshabilitado si qty == 1)
                        // -----------------------------------------
                        AbsorbPointer(
                          absorbing: disableMinus,
                          child: Opacity(
                            opacity: disableMinus ? 0.35 : 1,
                            child: _QtyButton(icon: Icons.remove, onTap: onDec),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text('${item.qty}',
                              style: theme.textTheme.titleMedium),
                        ),

                        AbsorbPointer(
                          absorbing: reachedMax || noStock,
                          child: Opacity(
                            opacity: (reachedMax || noStock) ? 0.35 : 1,
                            child:
                                _QtyButton(icon: Icons.add, onTap: onInc),
                          ),
                        ),

                        const Spacer(),

                        // -----------------------------------------
                        //  BASURERO + CONFIRMACIÓN
                        // -----------------------------------------
                        IconButton(
                          tooltip: 'Eliminar',
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text("Eliminar producto"),
                                content: Text(
                                    "¿Deseas eliminar '${item.nombre}' del carrito?"),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, false),
                                    child: const Text("Cancelar"),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx, true),
                                    child: const Text("Eliminar"),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && onRemove != null) {
                              onRemove!();
                            }
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
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
        color: disabled
            ? theme.disabledColor.withOpacity(.1)
            : theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 18, color: disabled ? theme.disabledColor : null),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyState({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Center(
        key: const ValueKey('empty-cart'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 0,
              color: theme.colorScheme.surfaceContainerHighest,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withOpacity(.12),
                            theme.colorScheme.primary.withOpacity(.06),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.shopping_bag_outlined, size: 44, color: kFucsia),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Tu carrito está vacío',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explora ramos, plantas y detallitos. ¡Tenemos algo para cada ocasión! 🌸',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 10,
                      runSpacing: 8,
                      children: const [
                        _BenefitPill(icon: Icons.local_florist, label: 'Arreglos frescos'),
                        _BenefitPill(icon: Icons.favorite_border, label: 'Regalos únicos'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Ir al inicio'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // Cambiar a la pantalla del Dashboard (index 0)
                          bottomNavIndex.value = 0;
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BenefitPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BenefitPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: .2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double iva;
  final double total;
  final bool isLoading;
  final VoidCallback? onCheckout;

  const _SummaryCard({
    this.subtotal = 0.0,
    this.iva = 0.0,
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
                child: isLoading
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Confirmar pedido'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
