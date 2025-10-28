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

  // ===== Navegación de imágenes =====
  late final PageController _pageController;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadProduct();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        _currentImage = 0;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _goPrev(List<String> imgs) {
    if (imgs.length <= 1) return;
    final prev = (_currentImage - 1 + imgs.length) % imgs.length;
    _animateTo(prev);
  }

  void _goNext(List<String> imgs) {
    if (imgs.length <= 1) return;
    final next = (_currentImage + 1) % imgs.length;
    _animateTo(next);
  }

  void _animateTo(int index) {
    setState(() => _currentImage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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

    final p = _producto;
    if (p == null) {
      // Si por alguna razón no hay producto pero no estamos en loading/error,
      // mostramos un mensaje seguro en lugar de usar el operador `!`.
      return Scaffold(
        appBar: AppBar(title: const Text('Producto')),
        body: Center(child: Text('Producto no disponible', style: theme.textTheme.titleMedium)),
      );
    }

    final disponible = p.stock > 0;
    final estadoTexto = disponible ? 'Disponible (${p.stock} unidades)' : 'Agotado';
    final colorEstado = disponible ? Colors.green : Colors.red;

    // Lista de imágenes segura
  final List<String> imgs = (p.imagenes.isNotEmpty)
    ? p.imagenes
    : (p.imageUrl.isNotEmpty ? [p.imageUrl] : ['https://via.placeholder.com/1200x800']);

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
              // ===============================
              //        HEADER DE IMAGEN
              // ===============================
              SizedBox(
                height: 320,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Carrusel
                    PageView.builder(
                      controller: _pageController,
                      itemCount: imgs.length,
                      onPageChanged: (i) => setState(() => _currentImage = i),
                      itemBuilder: (_, i) {
                        return Hero(
                          tag: 'product_${p.id}_img_$i',
                          child: Image.network(
                            imgs[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined, size: 48),
                            ),
                          ),
                        );
                      },
                    ),

                    // Degradado superior para contraste de botones
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    // Botón cerrar (X)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _RoundIconButton(
                        icon: Icons.close_rounded,
                        tooltip: 'Cerrar',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),

                    // Flecha izquierda
                    if (imgs.length > 1)
                      Positioned(
                        left: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _RoundIconButton(
                            icon: Icons.chevron_left_rounded,
                            tooltip: 'Anterior',
                            onPressed: () => _goPrev(imgs),
                          ),
                        ),
                      ),

                    // Flecha derecha
                    if (imgs.length > 1)
                      Positioned(
                        right: 8,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: _RoundIconButton(
                            icon: Icons.chevron_right_rounded,
                            tooltip: 'Siguiente',
                            onPressed: () => _goNext(imgs),
                          ),
                        ),
                      ),

                    // Indicadores (dots) abajo a la derecha
                    if (imgs.length > 1)
                      Positioned(
                        right: 12,
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              imgs.length,
                              (i) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: i == _currentImage ? 9 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: i == _currentImage ? Colors.white : Colors.white70,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ===============================
              //     DETALLES DEL PRODUCTO
              // ===============================
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Categoría badge
                    if (p.categoria.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: kFucsia.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          p.categoria,
                          style: const TextStyle(
                            color: kFucsia,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (p.categoria.isNotEmpty) const SizedBox(height: 8),

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

                    // Botón agregar al carrito
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: disponible ? kFucsia : Colors.grey.shade400,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: disponible
                            ? () {
                                final cart = CartService();
                                cart.addItem(
                                  CartItem(
                                    id: p.id,
                                    nombre: p.nombre,
                                    categoria: p.categoria,
                                    precio: p.precio,
                                    // Usa la imagen actual en el carrusel si existe,
                                    // caso contrario intenta la principal o placeholder.
                                    imagen: (imgs.isNotEmpty ? imgs[_currentImage] : p.imageUrl) ??
                                        'https://via.placeholder.com/600x400',
                                    qty: 1,
                                  ),
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${p.nombre} agregado al carrito 🛒')),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.shopping_cart_outlined),
                        label: Text(
                          disponible ? 'Agregar al carrito' : 'No disponible',
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

// ===============================
//       WIDGETS AUXILIARES
// ===============================

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final String? tooltip;
  final VoidCallback onPressed;

  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}
