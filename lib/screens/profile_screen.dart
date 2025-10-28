// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/login_screen.dart';

// Añadir esta import para navegar al historial de pedidos
import 'package:delirio_app/screens/order_history_screen.dart';

// API y modelo
import 'package:delirio_app/services/cliente_api.dart';
import 'package:delirio_app/models/cliente_perfil.dart';
// Navigation helper (global bottomNavIndex)
import 'package:delirio_app/navigation.dart';
import 'package:delirio_app/screens/edit_profile_screen.dart';

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
    final displayNameFromClaims =
        (claims?['nombre'] ?? claims?['Nombre'] ?? 'Nombre de usuario').toString();
    final emailFromClaims =
        (claims?['email'] ?? claims?['Correo'] ?? 'user@example.com').toString();
    final photoFromClaims = (claims?['foto'] ?? claims?['Foto'])?.toString();

    final loggedIn = auth.isLoggedIn();
    final bool isGuest = !loggedIn || userId == null;

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
              // ===== Header =====
              if (!isGuest)
                FutureBuilder<ClientePerfil>(
                  future: ClienteApi.getPerfilById(userId!),
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('No se pudo cargar el perfil: ${snapshot.error}'),
                            ),
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
              else
                // ===== Empty state para invitados =====
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      const Icon(Icons.account_circle_outlined, size: 100, color: Colors.grey),
                      const SizedBox(height: 20),
                      Text(
                        'Inicia sesión para personalizar tu experiencia 🌸',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Guarda tus pedidos y preferencias fácilmente.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Botón principal: iniciar sesión
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.login),
                          label: const Text('Iniciar sesión'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => const LoginScreen(
                                      replaceWithMainOnSuccess: false,
                                    ),
                                  ),
                                )
                                .then((_) {
                              if (AuthService.instance.isLoggedIn() && mounted) setState(() {});
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Botón secundario: crear cuenta
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1_outlined),
                          label: const Text('Crear cuenta'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: theme.colorScheme.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            // TODO: navegar a RegisterScreen
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // ===== Sección Cuenta (solo si está logueado) =====
              if (!isGuest)
                _SectionCard(
                  title: 'Cuenta',
                  tiles: [
                    ListTile(
                      leading: const Icon(Icons.receipt_long),
                      title: const Text('Historial de pedidos'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        // Navegar a la pantalla de historial de pedidos
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const OrderHistoryScreen()),
                        );
                      },
                    ),
                  ],
                ),

              if (!isGuest) const SizedBox(height: 16),

              // ===== Preferencias (siempre visible) =====
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
                      final picked = await showThemeModePicker(context);
                      if (picked != null) {
                        themeController.setMode(picked); // provisto por tu app
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                picked == ThemeMode.system
                                    ? 'Tema: Sistema'
                                    : picked == ThemeMode.light
                                        ? 'Tema: Claro'
                                        : 'Tema: Oscuro',
                              ),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Privacidad y seguridad'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO
                    },
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ===== Ayuda (siempre visible) =====
              _SectionCard(
                title: 'Ayuda',
                tiles: [
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Centro de ayuda'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.description_outlined),
                    title: const Text('Términos y condiciones'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===== Botón Cerrar sesión (solo si está logueado) =====
              if (!isGuest)
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
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const EditProfileMockScreen()))
        .then((updated) {
      // Si el editor devolvió true, refrescamos la pantalla para recargar datos
      if (updated == true && mounted) setState(() {});
    });
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
      // Cambiar a pestaña Inicio (dashboard) en lugar de redirigir al Login
      try {
        bottomNavIndex.value = 0;
      } catch (_) {}

      if (!context.mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      setState(() {}); // forzar reconstrucción si estamos dentro de MainScaffold
    }
  }
}

// ===== Picker de Tema (Bottom Sheet) =====

Future<ThemeMode?> showThemeModePicker(BuildContext context) {
  final theme = Theme.of(context);
  final current = themeController.mode ??
      (theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light);

  return showModalBottomSheet<ThemeMode>(
    context: context,
    isScrollControlled: true, // <- importante para permitir mayor alto + scroll
    showDragHandle: true,
    backgroundColor: theme.colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final mq = MediaQuery.of(ctx);
      final sheetMaxHeight = mq.size.height * 0.6; // ~60% de la pantalla

      return SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: sheetMaxHeight),
          child: ListView( // <- scrollable, evita overflow
            padding: EdgeInsets.fromLTRB(16, 8, 16, mq.viewPadding.bottom + 16),
            children: [
              Center(
                child: Text(
                  'Apariencia',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),

              const _ThemePreviewRow(),

              const SizedBox(height: 12),
              const Divider(height: 1),

              _ThemeOptionTile(
                title: 'Sistema',
                subtitle: 'Se ajusta al tema del dispositivo',
                icon: Icons.phone_android,
                selected: current == ThemeMode.system,
                onTap: () => Navigator.pop(ctx, ThemeMode.system),
              ),
              const Divider(height: 1),

              _ThemeOptionTile(
                title: 'Claro',
                subtitle: 'Fondo claro, textos oscuros',
                icon: Icons.wb_sunny_outlined,
                selected: current == ThemeMode.light,
                onTap: () => Navigator.pop(ctx, ThemeMode.light),
              ),
              const Divider(height: 1),

              _ThemeOptionTile(
                title: 'Oscuro',
                subtitle: 'Fondo oscuro, descanso visual',
                icon: Icons.nightlight_round,
                selected: current == ThemeMode.dark,
                onTap: () => Navigator.pop(ctx, ThemeMode.dark),
              ),
            ],
          ),
        ),
      );
    },
  );
}


class _ThemeOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tileColor = selected
        ? theme.colorScheme.primary.withOpacity(0.08)
        : theme.colorScheme.surface;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selected
                  ? Icon(
                      Icons.check_circle,
                      key: const ValueKey('sel'),
                      color: theme.colorScheme.primary,
                    )
                  : const SizedBox.shrink(key: ValueKey('nosel')),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemePreviewRow extends StatelessWidget {
  const _ThemePreviewRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget _previewCard({
      required String title,
      required bool dark,
    }) {
      final bg = dark ? const Color(0xFF1E1E1E) : Colors.white;
      final onBg = dark ? Colors.white : Colors.black87;
      final chipBg = dark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F3F3);

      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ejemplo', style: TextStyle(color: onBg, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Chip', style: TextStyle(color: onBg)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: chipBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('UI', style: TextStyle(color: onBg)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(title,
                  style: TextStyle(
                    color: onBg.withOpacity(.8),
                    fontSize: 12,
                  )),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        _previewCard(title: 'Claro', dark: false),
        _previewCard(title: 'Oscuro', dark: true),
      ],
    );
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
