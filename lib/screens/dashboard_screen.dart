import 'package:flutter/material.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo (placeholders)
    final categories = [
      {'name': 'Ramos', 'icon': Icons.local_florist},
      {'name': 'Suculentas', 'icon': Icons.grass},
      {'name': 'Plantas', 'icon': Icons.spa},
      {'name': 'Regalos', 'icon': Icons.card_giftcard},
    ];

    final featured = List.generate(6, (i) => {
          'title': 'Ramo ${i + 1}',
          'price': 20 + i * 5,
          'color': Colors.primaries[i % Colors.primaries.length],
        });

    return Scaffold(
      appBar: AppBar(
        title: const Text('DeLirio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ir al carrito (pendiente)')));
        },
        icon: const Icon(Icons.shopping_cart),
        label: const Text('Carrito'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero banner
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(colors: [kFucsia, Colors.pinkAccent.shade100]),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Flores para cada momento', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Entrega rápida y arreglos personalizados', style: TextStyle(color: Colors.white70)),
                        SizedBox(height: 12),
                        // CTA
                        // ElevatedButton can be added here if desired
                      ],
                    ),
                  ),
                  // Placeholder para una ilustración
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_florist, size: 48, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Buscador
          TextField(
            decoration: InputDecoration(
              hintText: 'Buscar ramos, plantas o regalos',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onSubmitted: (q) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Buscar: $q')));
            },
          ),
          const SizedBox(height: 16),

          // Categorías
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final c = categories[index];
                return GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ver ${c['name']}')));
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
                        Text(c['name'] as String, textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Encabezado sección
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Ramos destacados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              TextButton(onPressed: () {}, child: const Text('Ver todo')),
            ],
          ),

          // Grid de productos
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: featured.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.78, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemBuilder: (context, index) {
              final item = featured[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Abrir ${item['title']}')));
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // imagen placeholder
                      Container(
                        height: 110,
                        decoration: BoxDecoration(
                          color: (item['color'] as MaterialColor).shade200,
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
                        ),
                        child: const Icon(Icons.image, size: 48, color: Colors.white70),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('\$${item['price']}', style: const TextStyle(fontWeight: FontWeight.bold, color: kFucsia)),
                                IconButton(
                                  icon: const Icon(Icons.add_shopping_cart_outlined),
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Añadido ${item['title']} al carrito')));
                                  },
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
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
