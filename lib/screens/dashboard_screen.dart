import 'package:flutter/material.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DeLirio – Inicio'),
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('¡Bienvenida a DeLirio!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  SizedBox(height: 8),
                  Text('Empieza ordenando flores para tus momentos especiales 💐'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.local_florist),
            label: const Text('Explorar ramos'),
            onPressed: () {
              // TODO: Navegar al catálogo real
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ir al catálogo (pendiente)')),
              );
            },
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.shopping_cart_outlined, color: kFucsia),
            label: const Text('Ver carrito'),
            onPressed: () {
              // TODO: Navegar al carrito
            },
          ),
        ],
      ),
    );
  }
}
