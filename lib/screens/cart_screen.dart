import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/screens/order_confirmation_screen.dart';


class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final cart = CartService();

  // Ajustes de cálculo
  static const double _ivaRate = 0.12; // 12% (EC)
  static const double _envio = 3.99; // envío fijo de ejemplo

  double _subtotal(List<CartItem> items) => items.fold(0.0, (sum, it) => sum + it.precio * it.qty);
  double _iva(List<CartItem> items) => _subtotal(items) * _ivaRate;
  double _total(List<CartItem> items) => (items.isEmpty ? 0.0 : _subtotal(items) + _iva(items) + _envio);

  void _incQty(CartItem it) => setState(() => it.qty = (it.qty + 1).clamp(1, 99));
  void _decQty(CartItem it) => setState(() => it.qty = (it.qty - 1).clamp(1, 99));
  void _remove(CartItem it) => cart.removeItem(it.id);
  void _clearCart() => cart.clear();

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
                onPressed: () async {
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
                              key: ValueKey(it.id),
                              direction: DismissDirection.endToStart,
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
                                onDec: () => _decQty(it),
                                onInc: () => _incQty(it),
                                onRemove: () => _remove(it),
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
                        onCheckout: () {
                            Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const OrderConfirmationScreen(),
                                ),
                            );
                        },
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
  final VoidCallback onDec;
  final VoidCallback onInc;
  final VoidCallback onRemove;

  const _CartTile({
    required this.item,
    required this.onDec,
    required this.onInc,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Imagen
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                      item.imagen ?? '',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: theme.colorScheme.surfaceVariant,
                    child: const Icon(Icons.local_florist, size: 28),
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
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Ink(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, size: 18),
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
  final VoidCallback onCheckout;

  const _SummaryCard({
    required this.subtotal,
    required this.iva,
    required this.envio,
    required this.total,
    required this.onCheckout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                    backgroundColor: kFucsia,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: onCheckout,
                  icon: const Icon(Icons.lock_outline),
                  label: const Text('Hacer pedido'),
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

class _CartItem {
  final int id;
  final String nombre;
  final String categoria;
  final double precio;
  final String imagen;
  int qty;

  _CartItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.precio,
    required this.imagen,
    this.qty = 1,
  });
}
