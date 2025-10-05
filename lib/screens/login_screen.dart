import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/screens/dashboard_screen.dart';
import 'package:delirio_app/screens/register_role_screen.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  InputDecoration _inputDecoration({required String hint, required IconData icon}) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      );

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await AuthService.login(_userCtrl.text.trim(), _passCtrl.text);
    setState(() => _loading = false);

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Credenciales inválidas')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo con degradado usando tu esquema de color
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo y título
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_florist, size: 64, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'DeLirio',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Tarjeta con campos
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text('Iniciar sesión', style: Theme.of(context).textTheme.titleLarge),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _userCtrl,
                                  //keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(hint: 'Nombre de usuario', icon: Icons.person),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) return 'Ingresa tu usuario';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passCtrl,
                                  obscureText: _obscure,
                                  decoration: _inputDecoration(hint: 'Contraseña', icon: Icons.lock).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                                      onPressed: () => setState(() => _obscure = !_obscure),
                                      tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                                    if (v.length < 4) return 'La contraseña es muy corta';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Función no implementada')),
                                      );
                                    },
                                    child: const Text('¿Olvidaste tu contraseña?'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  height: 48,
                                  child: ElevatedButton(
                                    onPressed: _loading ? null : _onLogin,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Text('Ingresar'),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('¿No tienes cuenta?'),
                                    TextButton(
                                        onPressed: () {
                                            Navigator.of(context).push(MaterialPageRoute(
                                                builder: (_) => const RegisterRoleScreen(),
                                            ));
                                        },
                                        child: const Text('Crear cuenta'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Al ingresar aceptas los términos y condiciones',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: size.height * 0.05),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
