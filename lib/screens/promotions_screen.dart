import 'package:flutter/material.dart';
import 'package:delirio_app/services/cart_service.dart';
import 'package:delirio_app/services/cart_animation.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final _cart = CartService();
  final PageController _pageController = PageController(viewportFraction: 0.88);

  final promos = [
    {
      "titulo": "✨ Promo San Valentín",
      "descripcion": "Ramo Premium + Bombones Ferrero",
      "precio": 29.99,
      "antes": 39.99,
      "descuento": 25,
      "imagen": "assets/images/promos/promo1.jpg",
    },
    {
      "titulo": "🌸 Combo Primavera",
      "descripcion": "Ramo Mixto + Mensaje personalizado",
      "precio": 19.99,
      "antes": 27.99,
      "descuento": 29,
      "imagen": "assets/images/promos/promo2.jpg",
    },
    {
      "titulo": "🎁 Caja Floral Deluxe",
      "descripcion": "Caja sorpresa + Mini suculenta",
      "precio": 24.99,
      "antes": 34.99,
      "descuento": 27,
      "imagen": "assets/images/promos/promo3.jpg",
    }
  ];

  void _addToCart(Map<String, dynamic> promo, BuildContext ctx) {
    try {
      final item = CartItem(
        id: DateTime.now().millisecondsSinceEpoch,
        nombre: promo["titulo"],
        categoria: "Promoción",
        precio: promo["precio"],
        imagen: promo["imagen"],
        qty: 1,
      );

      _cart.addItem(item);

      // Animación
      try {
        final box = ctx.findRenderObject() as RenderBox?;
        if (box != null) {
          final center = box.localToGlobal(
            Offset(box.size.width / 2, box.size.height / 2),
          );
          final rect = Rect.fromCenter(
            center: center,
            width: box.size.width,
            height: box.size.height,
          );
          CartAnimation.animateAddToCart(
            context,
            startRect: rect,
            imageUrl: promo["imagen"],
          );
        }
      } catch (_) {}
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al agregar al carrito.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promociones'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== BANNER =====
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Promos del día 💐',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Aprovecha precios especiales por tiempo limitado.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(12)),
                        child: Image.asset(
                          'assets/images/estatusLogoOff.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ===== TÍTULO =====
          const Text(
            "Destacados",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          // ===== CARRUSEL =====
          SizedBox(
            height: 220,
            child: PageView.builder(
              controller: _pageController,
              itemCount: promos.length,
              itemBuilder: (_, index) {
                final p = promos[index];

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Image.asset(
                          p["imagen"] as String,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "-${p['descuento']}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // ===== LISTA DE PROMOS =====
          const Text(
            "Promociones disponibles",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: promos.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final p = promos[index];

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).cardColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // IMAGEN + DESCUENTO
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          AspectRatio(
                            aspectRatio: 1.5,
                            child: Image.asset(
                              p["imagen"] as String,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade600,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "-${p['descuento']}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    // INFORMACIÓN
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p["imagen"] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p["descripcion"] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // PRECIOS
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "\$${(p['precio'] as double).toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    "\$${(p['antes'] as double).toStringAsFixed(2)} antes",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.red,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ),

                              // AGREGAR AL CARRITO
                              Builder(
                                builder: (ctx) => ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 10),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () => _addToCart(p, ctx),
                                  child: const Text("Agregar"),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
