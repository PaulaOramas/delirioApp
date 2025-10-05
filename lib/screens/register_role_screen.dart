import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/register_form_screen.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  static const negocioUrl = 'https://tusitio-delirio.com/partners'; // <-- cámbialo

  Future<void> _openNegocio() async {
    final uri = Uri.parse(negocioUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'No se pudo abrir $negocioUrl';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.person_outline, size: 48, color: kFucsia),
                    const SizedBox(height: 8),
                    const Text('¿Qué tipo de cuenta quieres crear?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.favorite_outline),
                            label: const Text('Usuario'),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const RegisterFormScreen(role: UserRole.usuario),
                              ));
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.delivery_dining, color: kFucsia),
                            label: const Text('Repartidor'),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const RegisterFormScreen(role: UserRole.repartidor),
                              ));

                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: kFucsia),
                              foregroundColor: kFucsia,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _openNegocio,
                      icon: const Icon(Icons.store_mall_directory_outlined),
                      label: const Text('¿Tienes un negocio? Regístralo aquí'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
