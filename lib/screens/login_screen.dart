import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/widgets/custom_navbar.dart';
import 'package:delirio_app/screens/register_form_screen.dart';
import 'package:delirio_app/screens/profile_screen.dart';
import 'package:delirio_app/navigation.dart' as nav;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.replaceWithMainOnSuccess = true});
  final bool replaceWithMainOnSuccess;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _userFocus = FocusNode();
  final _passFocus = FocusNode();

  bool _obscure = true;
  bool _loading = false;

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey[700]),
      filled: true,
      fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.white.withOpacity(0.9),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final ok = await AuthService.instance.login(
        _userCtrl.text.trim(),
        _passCtrl.text,
      );

      if (!mounted) return;

      if (ok) {
        if (widget.replaceWithMainOnSuccess) {
          // Podrías elegir a qué tab ir tras login. Por defecto dejamos el que ya esté seleccionado.
          Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const CustomNavBar()),
            (route) => false,
          );
        } else {
          Navigator.of(context).pop(true);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credenciales inválidas')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo iniciar sesión: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Navega al Dashboard Screen
void _goBackToDashboard() {
  // Cambiar el tab global al Perfil (índice 3)
  nav.bottomNavIndex.value = 0;

  // Navegar al CustomNavBar con ese tab activo
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const CustomNavBar()),
    (route) => false,
  );
}


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: _goBackToDashboard,
              tooltip: 'Volver al perfil',
              splashRadius: 20,
            ),
          ),
        ),
        leadingWidth: 56,
      ),
      body: Stack(
        children: [
          // Fondo con degradado horizontal
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.surface,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
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
                      // Logo
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
                        'Estatus',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 24),

                      // Card con formulario
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
                                Text(
                                  'Iniciar sesión',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                const SizedBox(height: 12),

                                // Usuario
                                TextFormField(
                                  controller: _userCtrl,
                                  focusNode: _userFocus,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => _passFocus.requestFocus(),
                                  decoration: _inputDecoration(hint: 'Nombre de usuario', icon: Icons.person),
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty) ? 'Ingresa tu usuario' : null,
                                ),
                                const SizedBox(height: 12),

                                // Contraseña
                                TextFormField(
                                  controller: _passCtrl,
                                  focusNode: _passFocus,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.done,
                                  onFieldSubmitted: (_) => _onLogin(),
                                  decoration: _inputDecoration(hint: 'Contraseña', icon: Icons.lock).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                      ),
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
                                    onPressed: _loading
                                        ? null
                                        : () => ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Recuperar contraseña (próximamente)')),
                                            ),
                                    child: const Text('¿Olvidaste tu contraseña?'),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Botón ingresar
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

                                // CTA crear cuenta
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text('¿No tienes cuenta?'),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => RegisterFormScreen(role: UserRole.usuario),
                                                ),
                                              );
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
