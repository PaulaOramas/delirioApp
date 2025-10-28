import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/cart_screen.dart';
import 'package:delirio_app/screens/product_screen.dart'; // Asegúrate que exista ProductScreen(productId: ...)
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/services/product_service.dart';
import 'package:delirio_app/models/product.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _searchCtrl = TextEditingController();
  final _cart = CartService();

  List<Product> _all = [];
  List<Product> _filtered = [];
  bool _loading = true;
  String? _error;

  final _categories = const [
    {'name': 'Ramos', 'icon': Icons.local_florist},
    {'name': 'Suculentas', 'icon': Icons.grass},
    {'name': 'Plantas', 'icon': Icons.spa},
    {'name': 'Regalos', 'icon': Icons.card_giftcard},
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(() => _applyFilter(_searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final list = await ProductService.getAllProducts();
      setState(() {
        _all = list;
        _filtered = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _applyFilter(String q) {
    if (q.trim().isEmpty) {
      setState(() => _filtered = _all);
      return;
    }
    final query = q.toLowerCase();
    setState(() {
      _filtered = _all.where((p) {
        return p.nombre.toLowerCase().contains(query) ||
            p.categoria.toLowerCase().contains(query) ||
            p.descripcion.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _openDetails(Product p) {
    // ✅ Navega al detalle que consume GET /api/productos/{id}
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductScreen(productId: p.id),
      ),
    );
  }

  void _addToCart(Product p) {
    try {
      final item = CartItem(
        id: p.id,
        nombre: p.nombre,
        categoria: p.categoria,
        precio: p.precio,
        imagen: p.imagenes.isNotEmpty ? p.imagenes.first : null,
        qty: 1,
      );
      _cart.addItem(item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Añadido "${p.nombre}" al carrito')),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo agregar. Revisa CartService.')),
      );
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
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('Ocurrió un error:\n$_error', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loadProducts,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Estatus')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CartScreen()));
        },
        icon: const Icon(Icons.shopping_cart),
        label: ValueListenableBuilder<List<CartItem>>(
          valueListenable: CartService().items,
          builder: (context, items, _) {
            final total = items.fold<int>(0, (s, it) => s + it.qty);
            return Text('Carrito ($total)');
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== Banner =====
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient:
                  LinearGradient(colors: [kFucsia, Colors.pinkAccent.shade100]),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Flores para cada momento',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '¡Pide tu arreglo ya!',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: Icon(Icons.local_florist, size: 48, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ===== Buscador =====
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Buscar ramos, plantas o regalos',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: _applyFilter,
          ),
          const SizedBox(height: 16),

          // ===== Categorías (demo) =====
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = _categories[index];
                return GestureDetector(
                  onTap: () {
                    final name = c['name'] as String;
                    _searchCtrl.text = name;
                    _applyFilter(name);
                  },
                  child: Container(
                    width: 120,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(c['icon'] as IconData, size: 28, color: kFucsia),
                        const SizedBox(height: 8),
                        Text(
                          c['name'] as String,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // ===== Encabezado =====
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Productos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: () {
                  _searchCtrl.clear();
                  _applyFilter('');
                },
                child: const Text('Ver todo'),
              ),
            ],
          ),

          // ===== Grid de productos =====
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              // 🔧 un poco más alto para evitar overflow
              childAspectRatio: 0.70,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final p = _filtered[index];
              final disponible = p.stock > 0;
              final estadoTexto =
                  disponible ? 'Disp. (${p.stock})' : 'Agotado';

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () => _openDetails(p),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Imagen
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: AspectRatio(
                          aspectRatio: 1.4,
                          child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.image, size: 48, color: Colors.grey),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey[200],
                                child: const Center(child: CircularProgressIndicator()),
                              );
                            },
                          ),
                        ),
                      ),
                      // Info
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                p.categoria,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontWeight: FontWeight.w500),
                              ),
                              Text(
                                p.nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '\$${p.precio.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: kFucsia),
                                      ),
                                      Text(
                                        estadoTexto,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: disponible ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_shopping_cart_outlined),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
                                    onPressed: disponible ? () => _addToCart(p) : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
