import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthService.instance;
    final claims = auth.claims;
    
    // Obtener datos del usuario desde claims
    final displayName = claims?['nombre'] ?? 'Nombre de usuario';
    final email = claims?['email'] ?? 'user@example.com';
    final photoUrl = claims?['foto']; // puede ser null

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ProfileHeader(
                name: displayName,
                email: email,
                photoUrl: photoUrl,
                onEdit: () {
                  // TODO: Navegar a EditarPerfil
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Próximamente: Editar perfil')),
                  );
                },
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Cuenta',
                tiles: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Historial de pedidos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navegar a historial
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Direcciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navegar a direcciones
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Métodos de pago'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navegar a pagos
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Preferencias',
                tiles: [
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Notificaciones'),
                    value: true, // TODO: enlazar a tu estado
                    onChanged: (v) {
                      // TODO: guardar preferencia
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Tema'),
                    subtitle: const Text('Claro / Oscuro / Sistema'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final result = await showDialog<ThemeMode>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text('Selecciona el tema'),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, ThemeMode.system),
                              child: const Text('Sistema'),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, ThemeMode.light),
                              child: const Text('Claro'),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, ThemeMode.dark),
                              child: const Text('Oscuro'),
                            ),
                          ],
                        ),
                      );
                      if (result != null) {
                        themeController.setMode(result);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Privacidad y seguridad'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navegar a privacidad
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Ayuda',
                tiles: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Centro de ayuda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navegar a ayuda
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Términos y condiciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: abrir términos
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.error,
                  side: BorderSide(color: theme.colorScheme.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            top: 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 36),
              const SizedBox(height: 12),
              Text(
                '¿Cerrar sesión?',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tendrás que iniciar sesión nuevamente para continuar.',
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
                    child: FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.errorContainer,
                        foregroundColor: theme.colorScheme.onErrorContainer,
                      ),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Cerrar sesión'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result == true) {
      await AuthService.instance.logout();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? photoUrl;
  final VoidCallback onEdit;

  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Semantics(
              label: 'Foto de perfil',
              child: Hero(
                tag: 'profile_avatar',
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: kFucsia,
                  backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                      ? NetworkImage(photoUrl!)
                      : null,
                  child: (photoUrl == null || photoUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 40, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(email,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Editar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> tiles;

  const _SectionCard({required this.title, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Row(
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: .2,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._intersperse(const Divider(height: 1), tiles),
        ],
      ),
    );
  }

  List<Widget> _intersperse(Widget separator, List<Widget> children) {
    final list = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      list.add(children[i]);
      if (i != children.length - 1) list.add(separator);
    }
    return list;
  }
}
}
