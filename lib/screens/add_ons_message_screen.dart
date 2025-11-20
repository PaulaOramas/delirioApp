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

  bool addProduct1 = false;
  bool addProduct2 = false;

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
      product1 = await ProductService.getById(1);
      product2 = await ProductService.getById(2);
    } catch (e) {
      debugPrint("Error fetching suggested products: $e");
    }

    setState(() => loading = false);
  }

  void _addSelectedProducts() {
    if (addProduct1 && product1 != null) {
      cart.addItem(
        CartItem(
          id: product1!.id,
          nombre: product1!.nombre,
          categoria: product1!.categoria,
          precio: product1!.precio,
          imagen: product1!.imageUrl, // <--- USAR EL GETTER CORRECTO
          qty: 1,
        ),
      );
    }

    if (addProduct2 && product2 != null) {
      cart.addItem(
        CartItem(
          id: product2!.id,
          nombre: product2!.nombre,
          categoria: product2!.categoria,
          precio: product2!.precio,
          imagen: product2!.imageUrl,
          qty: 1,
        ),
      );
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => OrderConfirmationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Productos sugeridos"),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (product1 != null)
                    _SuggestedProduct(
                      product: product1!,
                      value: addProduct1,
                      onChanged: (v) => setState(() => addProduct1 = v),
                    ),

                  const SizedBox(height: 12),

                  if (product2 != null)
                    _SuggestedProduct(
                      product: product2!,
                      value: addProduct2,
                      onChanged: (v) => setState(() => addProduct2 = v),
                    ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _addSelectedProducts,
                      child: const Text("Añadir al carrito"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SuggestedProduct extends StatelessWidget {
  final Product product;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SuggestedProduct({
    required this.product,
    required this.value,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                product.imageUrl, // <--- CORRECTO
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                product.nombre, // <--- CORRECTO
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Column(
              children: [
                Text(
                  "\$${product.precio}", // <--- CORRECTO
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: kFucsia,
                  ),
                ),
                const SizedBox(height: 6),
                Switch(
                  value: value,
                  onChanged: onChanged,
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
