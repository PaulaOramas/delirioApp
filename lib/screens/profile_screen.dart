// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/login_screen.dart';

// API y modelo
import 'package:delirio_app/services/cliente_api.dart';
import 'package:delirio_app/models/cliente_perfil.dart';

// NOTA: themeController debe exportarse desde lib/theme.dart

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = AuthService.instance;
    final claims = auth.claims;

    // 1) ID robusto desde claims (evita nulos por claves distintas)
    final userId = _extractUserId(claims);

    // 2) Placeholders inmediatos desde claims
    final displayNameFromClaims = (claims?['nombre'] ?? claims?['Nombre'] ?? 'Nombre de usuario').toString();
    final emailFromClaims = (claims?['email'] ?? claims?['Correo'] ?? 'user@example.com').toString();
    final photoFromClaims = (claims?['foto'] ?? claims?['Foto'])?.toString();

    final loggedIn = auth.isLoggedIn();

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
              if (loggedIn && userId != null)
                FutureBuilder<ClientePerfil>(
                  future: ClienteApi.getPerfilById(userId),
                  builder: (context, snapshot) {
                    // Defaults (claims) mientras carga o si falla
                    var name = displayNameFromClaims;
                    var email = emailFromClaims;
                    var photo = photoFromClaims;

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Column(
                        children: [
                          _ProfileHeader(
                            name: name,
                            email: email,
                            photoUrl: photo,
                            onEdit: _onEditTap,
                          ),
                          const SizedBox(height: 8),
                          const LinearProgressIndicator(),
                        ],
                      );
                    }

                    if (snapshot.hasError) {
                      // aviso suave si falla
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('No se pudo cargar el perfil: ${snapshot.error}')),
                          );
                        }
                      });
                    }

                    if (snapshot.hasData) {
                      final p = snapshot.data!;
                      if (p.nombreCompleto.isNotEmpty) name = p.nombreCompleto;
                      if (p.correo.isNotEmpty) email = p.correo;
                      if ((p.foto ?? '').toString().isNotEmpty) photo = p.foto;
                    }

                    return _ProfileHeader(
                      name: name,
                      email: email,
                      photoUrl: photo,
                      onEdit: _onEditTap,
                    );
                  },
                )
              else ...[
                _ProfileHeader(
                  name: displayNameFromClaims,
                  email: emailFromClaims,
                  photoUrl: photoFromClaims,
                  onEdit: _onEditTap,
                ),
                const SizedBox(height: 12),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => const LoginScreen(replaceWithMainOnSuccess: false)))
                          .then((_) {
                        if (AuthService.instance.isLoggedIn() && mounted) setState(() {});
                      });
                    },
                    child: const Text('Iniciar sesión'),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              const SizedBox(height: 16),

              _SectionCard(
                title: 'Cuenta',
                tiles: [
                  ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: const Text('Historial de pedidos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: const Text('Direcciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Métodos de pago'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
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
                    onChanged: (v) {},
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
                        themeController.setMode(result); // provisto por tu app
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Privacidad y seguridad'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
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
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Términos y condiciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
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

  void _onEditTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente: Editar perfil')),
    );
  }

  int? _extractUserId(Map<String, dynamic>? claims) {
    if (claims == null) return null;
    final candidates = ['id', 'Id', 'userId', 'UserId', 'nameid', 'nameId', 'sub'];
    for (final k in candidates) {
      final v = claims[k];
      if (v == null) continue;
      if (v is int) return v;
      final parsed = int.tryParse(v.toString());
      if (parsed != null) return parsed;
    }
    return null;
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
              Text('¿Cerrar sesión?', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              const Text('Tendrás que iniciar sesión nuevamente para continuar.', textAlign: TextAlign.center),
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

// ====== UI helpers ======

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
                  Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
