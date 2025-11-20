import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/services/product_service.dart';
import 'package:delirio_app/models/product.dart';
import 'package:delirio_app/screens/order_confirmation_screen.dart';

class AddOnsAndMessageScreen extends StatefulWidget {
  const AddOnsAndMessageScreen({super.key});

  @override
  State<AddOnsAndMessageScreen> createState() =>
      _AddOnsAndMessageScreenState();
}

class _AddOnsAndMessageScreenState extends State<AddOnsAndMessageScreen> {
  final cart = CartService();

  Product? product1;
  Product? product2;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestedProducts();
  }

  Future<void> _loadSuggestedProducts() async {
    try {
      product1 = await ProductService.getById(2);
      product2 = await ProductService.getById(3);
    } catch (e) {
      debugPrint("Error fetching suggested products: $e");
    }

    setState(() => loading = false);
  }

  void _addToCart(Product p) {
    cart.addItem(
      CartItem(
        id: p.id,
        nombre: p.nombre,
        categoria: p.categoria,
        precio: p.precio,
        imagen: p.imageUrl,
        qty: 1,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("${p.nombre} añadido al carrito")),
    );
  }

  void _continue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const OrderConfirmationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Añade algo especial 💕"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (product1 != null)
                    _AddOnCard(
                      product: product1!,
                      onAdd: () => _addToCart(product1!),
                    ),

                  const SizedBox(height: 12),

                  if (product2 != null)
                    _AddOnCard(
                      product: product2!,
                      onAdd: () => _addToCart(product2!),
                    ),

                  const SizedBox(height: 24),

                  // BOTÓN FINALIZAR
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _continue,
                      child: const Text("Finalizar pedido"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _AddOnCard extends StatelessWidget {
  final Product product;
  final VoidCallback onAdd;

  const _AddOnCard({
    super.key,
    required this.product,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl,
                width: 72,
                height: 72,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 72,
                  height: 72,
                  color: theme.colorScheme.surfaceVariant,
                  child: const Icon(Icons.local_florist, size: 28, color: kFucsia),
                ),
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nombre,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    product.categoria,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "\$${product.precio.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: kFucsia,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            FilledButton(
              onPressed: onAdd,
              child: const Text("Añadir"),
            ),
          ],
        ),
      ),
    );
  }
}
