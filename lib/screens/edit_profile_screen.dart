import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> profileData;
  final String currentAvatar;

  const EditProfileScreen({
    super.key,
    required this.profileData,
    required this.currentAvatar,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombre;
  late TextEditingController _apellido;
  late TextEditingController _correo;
  late TextEditingController _telefono;

  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();

  late String avatarSeleccionado;

  final avatares = [
    "assets/avatar/rosa_avatar.png",
    "assets/avatar/girasol_avatar.png",
    "assets/avatar/daysi_avatar.png",
    "assets/avatar/cactus_avatar.png",
    "assets/avatar/creativo_avatar.png",
    "assets/avatar/lavanda_avatar.png",
  ];

  @override
  void initState() {
    super.initState();
    _nombre = TextEditingController(text: widget.profileData['nombre']);
    _apellido = TextEditingController(text: widget.profileData['apellido']);
    _correo = TextEditingController(text: widget.profileData['correo']);
    _telefono = TextEditingController(text: widget.profileData['telefono']);

    avatarSeleccionado = widget.currentAvatar; // puede estar vacío
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar Perfil"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ------------------ AVATAR ------------------
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(.2),
                      backgroundImage: avatarSeleccionado.isNotEmpty
                          ? AssetImage(avatarSeleccionado)
                          : null,
                      child: avatarSeleccionado.isEmpty
                          ? const Icon(Icons.person, size: 50)
                          : null,
                    ),
                    const SizedBox(height: 12),

                    Text(
                      "Elige tu avatar",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: avatares.length + 1, // +1 para "sin avatar"
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (_, i) {
                          // 🆕 Opción 0 = círculo vacío ("Sin avatar")
                          if (i == 0) {
                            final isSelected = avatarSeleccionado.isEmpty;
                            return GestureDetector(
                              onTap: () => setState(() {
                                avatarSeleccionado = "";
                              }),
                              child: CircleAvatar(
                                radius: 36,
                                backgroundColor: isSelected
                                    ? theme.colorScheme.primary.withOpacity(.4)
                                    : theme.colorScheme.surfaceVariant,
                                child: const Icon(Icons.person_off,
                                    size: 32, color: Colors.grey),
                              ),
                            );
                          }

                          // Avatares reales
                          final img = avatares[i - 1];
                          final isSelected = avatarSeleccionado == img;

                          return GestureDetector(
                            onTap: () => setState(() {
                              avatarSeleccionado = img;
                            }),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: isSelected
                                  ? theme.colorScheme.primary.withOpacity(.4)
                                  : theme.colorScheme.surfaceVariant,
                              child: CircleAvatar(
                                radius: 32,
                                backgroundImage: AssetImage(img),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ------------------ CAMPOS ------------------
              _field(_nombre, "Nombre", Icons.badge),
              const SizedBox(height: 12),
              _field(_apellido, "Apellido", Icons.badge_outlined),
              const SizedBox(height: 12),
              _field(_correo, "Correo", Icons.email),
              const SizedBox(height: 12),
              _field(_telefono, "Teléfono", Icons.phone, numbers: true),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              Text(
                "Cambiar contraseña (opcional)",
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              _passwordField(_pass1, "Nueva contraseña"),
              const SizedBox(height: 12),
              _passwordField(_pass2, "Confirmar contraseña"),

              const SizedBox(height: 28),

              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  onPressed: _guardar,
                  label: const Text("Guardar cambios"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ HELPERS ------------------

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool numbers = false}) {
    return TextFormField(
      controller: c,
      keyboardType: numbers ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? "Campo obligatorio" : null,
    );
  }

  Widget _passwordField(TextEditingController c, String label) {
    return TextFormField(
      controller: c,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _guardar() {
    if (!_formKey.currentState!.validate()) return;

    if (_pass1.text.isNotEmpty && _pass1.text != _pass2.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    Navigator.pop(context, {
      "nombre": _nombre.text,
      "apellido": _apellido.text,
      "correo": _correo.text,
      "telefono": _telefono.text,
      "avatar": avatarSeleccionado,
      "password": _pass1.text.isNotEmpty ? _pass1.text : null
    });
  }
}
