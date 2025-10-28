import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/register_form_screen.dart';

class RegisterRoleScreen extends StatelessWidget {
  const RegisterRoleScreen({super.key});

  static const negocioUrl = 'https://tusitio-delirio.com/partners'; // <-- cámbialo

  Future<void> _confirmAndOpenNegocio(BuildContext context) async {
    final theme = Theme.of(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new, size: 36),
            const SizedBox(height: 10),
            Text('Abrir formulario externo',
                style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 6),
            const Text(
              'Te llevaremos al sitio para registrar tu negocio. Se abrirá fuera de la app.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.check),
                    onPressed: () => Navigator.pop(ctx, true),
                    label: const Text('Continuar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final uri = Uri.parse(negocioUrl);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el enlace')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tarjeta principal centrada
                      Card(
                        elevation: 0,
                        color: theme.colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: kFucsia,
                                    child: Icon(Icons.person_outline, color: Colors.white, size: 28),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      '¿Qué tipo de cuenta quieres crear?',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Acción 1: Usuario (único rol en-app)
                              _ActionTile(
                                icon: Icons.favorite_outline,
                                title: 'Cuenta de usuario',
                                subtitle: 'Compra ramos, plantas y regalos. Guarda direcciones y pedidos.',
                                cta: FilledButton.icon(
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text('Crear como usuario'),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterFormScreen(role: UserRole.usuario),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 12),

                              // Acción 2: Negocio (enlace externo)
                              _ActionTile(
                                icon: Icons.store_mall_directory_outlined,
                                title: 'Registrar mi negocio',
                                subtitle:
                                    '¿Vendes flores o regalos? Súmate como aliado y llega a más clientes.',
                                cta: OutlinedButton.icon(
                                  icon: const Icon(Icons.open_in_new, color: kFucsia),
                                  label: const Text('Ir al formulario'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: kFucsia,
                                    side: const BorderSide(color: kFucsia),
                                  ),
                                  onPressed: () => _confirmAndOpenNegocio(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Ayuda/seguridad (opcional)
                      Opacity(
                        opacity: .9,
                        child: Text(
                          'Al crear tu cuenta aceptas los Términos y la Política de privacidad.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // usar Expanded para empujar contenido hacia el centro si hay más espacio
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget cta;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cta,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(subtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerLeft, child: cta),
            ],
          ),
        ),
      ],
    );
  }
}
