import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/services/product_service.dart';
import 'package:delirio_app/models/product.dart';
import 'package:delirio_app/screens/cart_screen.dart';

class ProductScreen extends StatefulWidget {
  final int productId;

  const ProductScreen({Key? key, required this.productId}) : super(key: key);

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  Product? _producto;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      setState(() {
        _loading = true;
      });

      // Llamar API: obtén todos los productos y filtra por ID
      final productos = await ProductService.getAllProducts();
      final encontrado = productos.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () => throw Exception('Producto no encontrado'),
      );

      setState(() {
        _producto = encontrado;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ocurrió un error:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadProduct,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final p = _producto!;
    final disponible = p.stock > 0;
    final estadoTexto =
        disponible ? 'Disponible (${p.stock} unidades)' : 'Agotado';
    final colorEstado = disponible ? Colors.green : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.nombre),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 📸 Carrusel simple (una o dos imágenes)
              SizedBox(
                height: 280,
                child: PageView(
                  children: [
                    Image.network(
                      p.imagenes.isNotEmpty
                          ? p.imagenes.first
                          : 'https://via.placeholder.com/600x400',
                      fit: BoxFit.cover,
                    ),
                    if (p.imagenes.length > 1)
                      Image.network(
                        p.imagenes[1],
                        fit: BoxFit.cover,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 🏷️ Detalles del producto
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: kFucsia.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        p.categoria,
                        style: TextStyle(
                          color: kFucsia,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      p.nombre,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      p.descripcion,
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${p.precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: kFucsia,
                          ),
                        ),
                        Text(
                          estadoTexto,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorEstado,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // 🔘 Botón de acción
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              disponible ? kFucsia : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: disponible
                            ? () {
                                final cart = CartService();
                                cart.addItem(CartItem(
                                  id: p.id,
                                  nombre: p.nombre,
                                  categoria: p.categoria,
                                  precio: p.precio,
                                  imagen: p.imageUrl,
                                  qty: 1,
                                ));

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${p.nombre} agregado al carrito 🛒'),
                                  ),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(
                          disponible
                              ? 'Agregar al carrito'
                              : 'No disponible',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
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
