import 'package:flutter/material.dart';
import 'package:delirio_app/models/cliente_perfil.dart';
import 'package:delirio_app/screens/edit_profile_screen.dart';

class ProfileViewScreen extends StatelessWidget {
  final ClientePerfil perfil;

  const ProfileViewScreen({
    super.key,
    required this.perfil,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Solo avatares desde assets
    final avatar = perfil.avatar ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tu Perfil"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Avatar circular
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primary.withOpacity(.2),
                  backgroundImage: avatar.isNotEmpty
                      ? AssetImage(avatar)
                      : null,
                  child: avatar.isEmpty
                      ? const Icon(Icons.person, size: 48)
                      : null,
                ),

                const SizedBox(height: 16),

                // Nombre completo
                Text(
                  perfil.nombreCompleto,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 6),

                // Correo
                Text(perfil.correo),

                const Divider(height: 32),

                // Info del usuario
                _info("Cédula", perfil.cedula),
                _info("Usuario", perfil.usuario),
                _info("Correo", perfil.correo),
                _info("Teléfono", perfil.telefono),

                const Spacer(),

                // Botón Editar Perfil
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            profileData: perfil.toJson(),
                            currentAvatar: avatar,
                          ),
                        ),
                      );
                    },
                    label: const Text("Editar perfil"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }
}
