import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/dashboard_screen.dart';

enum UserRole { usuario, repartidor }

class RegisterFormScreen extends StatefulWidget {
  final UserRole role;
  const RegisterFormScreen({super.key, required this.role});

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // comunes
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  // usuario
  final _addressCtrl = TextEditingController();

  // repartidor
  final _vehicleTypeCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _idCtrl = TextEditingController();

  bool _obscure = true;
  bool _loading = false;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _vehicleTypeCtrl.dispose();
    _plateCtrl.dispose();
    _idCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los términos y condiciones')),
      );
      return;
    }

    setState(() => _loading = true);

    // TODO: Llamar a tu API real de registro aquí.
    await Future.delayed(const Duration(milliseconds: 900));

    // Simula auto-login tras registro
    await AuthService.login(_usernameCtrl.text.trim(), _passwordCtrl.text);

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRepartidor = widget.role == UserRole.repartidor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isRepartidor ? 'Registro Repartidor' : 'Registro Usuario'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 6,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Comunes
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: _dec('Nombre completo', Icons.badge_outlined),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Ingresa tu nombre' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _usernameCtrl,
                    decoration: _dec('Nombre de usuario', Icons.person_outline),
                    validator: (v) => (v == null || v.trim().length < 3) ? 'Mínimo 3 caracteres' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _dec('Teléfono', Icons.phone_outlined),
                    validator: (v) {
                      final t = (v ?? '').replaceAll(RegExp(r'\s'), '');
                      if (t.length < 9) return 'Teléfono no válido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    decoration: _dec('Contraseña', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                  ),
                  const SizedBox(height: 16),

                  // Campos específicos por rol
                  if (!isRepartidor) ...[
                    // USUARIO
                    TextFormField(
                      controller: _addressCtrl,
                      decoration: _dec('Dirección', Icons.home_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa tu dirección' : null,
                    ),
                  ] else ...[
                    // REPARTIDOR
                    TextFormField(
                      controller: _vehicleTypeCtrl,
                      decoration: _dec('Tipo de vehículo (moto/bici/auto)', Icons.two_wheeler_outlined),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el tipo de vehículo' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _plateCtrl,
                      decoration: _dec('Placa', Icons.confirmation_number_outlined),
                      validator: (v) => (v == null || v.trim().length < 5) ? 'Placa no válida' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _idCtrl,
                      decoration: _dec('Identificación (cédula)', Icons.badge_outlined),
                      validator: (v) => (v == null || v.trim().length < 8) ? 'Documento no válido' : null,
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Términos
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        activeColor: kFucsia,
                        onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                      ),
                      const Expanded(
                        child: Text('Acepto los términos y condiciones'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Botón
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Crear cuenta'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
