import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/theme.dart';

enum UserRole { usuario }

class RegisterFormScreen extends StatefulWidget {
  final UserRole role;
  const RegisterFormScreen({super.key, required this.role});

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  final _focusApellido = FocusNode();
  final _focusCedula = FocusNode();
  final _focusCorreo = FocusNode();
  final _focusTelefono = FocusNode();
  final _focusUsuario = FocusNode();
  final _focusPassword = FocusNode();
  final _focusPassword2 = FocusNode();

  bool _obscure = true;
  bool _obscure2 = true;
  bool _loading = false;
  bool _acceptTerms = false;

  // País por defecto
  String _countryCode = '+593';

  // Password score 0..4
  int _passwordScore = 0;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_onPasswordChanged);
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _cedulaCtrl.dispose();
    _correoCtrl.dispose();
    _telefonoCtrl.dispose();
    _usuarioCtrl.dispose();
    _passwordCtrl.dispose();
    _password2Ctrl.dispose();
    _focusApellido.dispose();
    _focusCedula.dispose();
    _focusCorreo.dispose();
    _focusTelefono.dispose();
    _focusUsuario.dispose();
    _focusPassword.dispose();
    _focusPassword2.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    final s = _passwordStrength(_passwordCtrl.text);
    if (s != _passwordScore) setState(() => _passwordScore = s);
  }

  // === Validaciones ===

  // Cédula de Ecuador: provincia 01–24 y 30, 10 dígitos, dígito verificador (módulo 10)
  String? _validateCedulaEc(String? v) {
    final input = v?.trim() ?? '';
    if (input.isEmpty) return 'Ingresa tu cédula';
    if (!RegExp(r'^\d{10}$').hasMatch(input)) return 'La cédula debe tener 10 dígitos';

    final prov = int.tryParse(input.substring(0, 2)) ?? -1;
    final provOk = (prov >= 1 && prov <= 24) || prov == 30;
    if (!provOk) return 'Código de provincia inválido';

    // Dígito verificador
    final digits = input.split('').map(int.parse).toList(); // 10
    final coefficients = [2,1,2,1,2,1,2,1,2]; // para los 9 primeros
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      int prod = digits[i] * coefficients[i];
      if (prod >= 10) prod -= 9;
      sum += prod;
    }
    final dv = (10 - (sum % 10)) % 10;
    if (dv != digits[9]) return 'Cédula inválida (dígito verificador no coincide)';

    return null;
  }

  String? _validatePhone(String? v) {
    final digits = (v ?? '').trim();
    if (digits.isEmpty) return 'Ingresa tu teléfono';
    if (_countryCode == '+593') {
      if (!RegExp(r'^09\d{8}$').hasMatch(digits)) {
        return 'En Ecuador debe empezar con 09 y tener 10 dígitos';
      }
    } else {
      if (digits.length < 6) return 'Teléfono inválido';
    }
    return null;
  }

  String? _validateEmail(String? v) {
    final x = v?.trim() ?? '';
    if (x.isEmpty) return 'Ingresa tu correo';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(x);
    if (!ok) return 'Correo inválido';
    return null;
  }

  String? _validateRequired(String? v, String label) {
    if (v == null || v.trim().isEmpty) return 'Ingresa $label';
    return null;
  }

  String? _validatePassword(String? v) {
    final p = v ?? '';
    if (p.isEmpty) return 'Ingresa una contraseña';
    if (p.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Debe incluir al menos una mayúscula';
    if (!RegExp(r'[0-9]').hasMatch(p)) return 'Debe incluir al menos un número';
    if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>_\-]').hasMatch(p)) {
      return 'Debe incluir al menos un símbolo';
    }
    return null;
  }

  String? _validatePassword2(String? v) {
    if (v == null || v.isEmpty) return 'Repite tu contraseña';
    if (v != _passwordCtrl.text) return 'Las contraseñas no coinciden';
    return null;
  }

  int _passwordStrength(String p) {
    var score = 0;
    if (p.length >= 8) score++; // length
    if (RegExp(r'[A-Z]').hasMatch(p)) score++; // uppercase
    if (RegExp(r'[0-9]').hasMatch(p)) score++; // digit
    if (RegExp(r'[!@#\$%\^&\*(),.?":{}|<>_\-]').hasMatch(p)) score++; // special
    return score; // 0..4
  }

  String _passwordLabel(int s) => s <= 1 ? 'Débil' : (s == 2 ? 'Media' : 'Fuerte');
  Color _passwordColor(BuildContext c, int s) =>
      s <= 1 ? Colors.redAccent : (s == 2 ? Colors.orange : Colors.green);

  // === UI helpers ===

 InputDecoration _dec(BuildContext context, String label, IconData icon,
    {String? helperText, String? hintText}) {
  final theme = Theme.of(context);
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: Icon(icon),
    helperText: helperText,
    helperMaxLines: 3, // 👈 permite saltos de línea en helper
    errorMaxLines: 3,  // 👈 permite saltos de línea en error
    filled: true,
    isDense: false, // 👈 deja espacio para mostrar texto multi-línea
    fillColor: theme.colorScheme.surface,
    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.primary),
    ),
  );
}


  bool get _canSubmit =>
      !_loading && _acceptTerms && (_formKey.currentState?.validate() ?? false);

  Future<void> _submit() async {
    // Validamos con autovalidate pero aseguramos una pasada completa
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes aceptar los Términos y la Política de privacidad')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final ok = await AuthService.instance.registerCliente(
        nombre: _nombreCtrl.text.trim(),
        apellido: _apellidoCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        correo: _correoCtrl.text.trim(),
        telefono: _telefonoCtrl.text.trim(),
        usuario: _usuarioCtrl.text.trim(),
        password: _passwordCtrl.text,
      );

      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada con éxito 🎉')),
        );
        Navigator.pop(context); // vuelve al Login
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo registrar. Intenta nuevamente')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo registrar: $e'),
          action: SnackBarAction(
            label: 'Reintentar',
            onPressed: _submit,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Regístrate para empezar',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Completa tus datos. Solo toma un minuto.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                    ),
                    const SizedBox(height: 16),

                    // Nombre / Apellido
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _nombreCtrl,
                            textInputAction: TextInputAction.next,
                            focusNode: _focusApellido, // el siguiente foco lo manejamos con onFieldSubmitted si necesitas
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.givenName],
                            decoration: _dec(context, 'Nombre', Icons.badge_outlined),
                            validator: (v) => _validateRequired(v, 'tu nombre'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _apellidoCtrl,
                            textInputAction: TextInputAction.next,
                            textCapitalization: TextCapitalization.words,
                            autofillHints: const [AutofillHints.familyName],
                            decoration: _dec(context, 'Apellido', Icons.badge),
                            validator: (v) => _validateRequired(v, 'tu apellido'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Cédula (EC)
                    TextFormField(
                      controller: _cedulaCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      decoration: _dec(context, 'Cédula (Ecuador)', Icons.credit_card,
                          helperText: '10 dígitos • provincia válida • verificación automática'),
                      validator: _validateCedulaEc,
                    ),
                    const SizedBox(height: 12),

                    // Correo
                    TextFormField(
                      controller: _correoCtrl,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: _dec(context, 'Correo', Icons.email_outlined,
                          hintText: 'tunombre@ejemplo.com'),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),

                    // Teléfono con prefijo fijo (+593) perfectamente alineado
                    TextFormField(
                      controller: _telefonoCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      decoration: InputDecoration(
                        labelText: 'Teléfono',
                        helperText: 'Debe empezar con 09 (10 dígitos)',
                        prefixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '🇪🇨 +593',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.phone, size: 20),
                            const SizedBox(width: 8),
                          ],
                        ),
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                        ),
                        helperMaxLines: 3,
                        errorMaxLines: 3,
                      ),
                      validator: _validatePhone,
                    ),

                    const SizedBox(height: 12),

                    // Usuario
                    TextFormField(
                      controller: _usuarioCtrl,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: _dec(context, 'Usuario', Icons.person_outline,
                          helperText: 'Mín. 4 caracteres. Usa letras y números.'),
                      validator: (v) {
                        final x = v?.trim() ?? '';
                        if (x.isEmpty) return 'Ingresa un usuario';
                        if (x.length < 4) return 'Debe tener al menos 4 caracteres';
                        if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(x)) {
                          return 'Solo letras, números y . _ -';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Password
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _dec(context, 'Contraseña', Icons.lock_outline).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                          tooltip: _obscure ? 'Mostrar' : 'Ocultar',
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 8),

                    // Barra de fortaleza
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: (_passwordScore / 4).clamp(0, 1),
                        minHeight: 6,
                        color: _passwordColor(context, _passwordScore),
                        backgroundColor: Colors.grey.shade200,
                        semanticsLabel: 'Fortaleza de contraseña',
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Checklist de reglas
                    _PasswordChecklist(password: _passwordCtrl.text),

                    const SizedBox(height: 12),

                    // Confirmar contraseña
                    TextFormField(
                      controller: _password2Ctrl,
                      obscureText: _obscure2,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: _dec(context, 'Confirmar contraseña', Icons.lock_reset).copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(_obscure2 ? Icons.visibility_off : Icons.visibility),
                          tooltip: _obscure2 ? 'Mostrar' : 'Ocultar',
                          onPressed: () => setState(() => _obscure2 = !_obscure2),
                        ),
                      ),
                      validator: _validatePassword2,
                    ),

                    const SizedBox(height: 8),
                    // Términos
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _acceptTerms,
                          onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                            child: Text.rich(
                              TextSpan(
                                text: 'Acepto los ',
                                children: [
                                  TextSpan(
                                    text: 'Términos y Condiciones',
                                    style: TextStyle(color: theme.colorScheme.primary),
                                  ),
                                  const TextSpan(text: ' y la '),
                                  TextSpan(
                                    text: 'Política de Privacidad',
                                    style: TextStyle(color: theme.colorScheme.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Botón enviar
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _canSubmit ? kFucsia : theme.disabledColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: _canSubmit ? _submit : null,
                        icon: _loading
                            ? const SizedBox(
                                width: 18, height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_alt_1),
                        label: Text(_loading ? 'Creando...' : 'Crear cuenta'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// === Widget de checklist de contraseña (UX deseable) ===
class _PasswordChecklist extends StatelessWidget {
  final String password;
  const _PasswordChecklist({required this.password});

  bool get hasLen => password.length >= 8;
  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(password);
  bool get hasNum => RegExp(r'[0-9]').hasMatch(password);
  bool get hasSym => RegExp(r'[!@#\$%\^&\*(),.?":{}|<>_\-]').hasMatch(password);

  @override
  Widget build(BuildContext context) {
    final items = [
      _Rule('8+ caracteres', hasLen),
      _Rule('Una mayúscula', hasUpper),
      _Rule('Un número', hasNum),
      _Rule('Un símbolo', hasSym),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((r) => Row(
                children: [
                  Icon(r.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18, color: r.ok ? Colors.green : Colors.grey),
                  const SizedBox(width: 6),
                  Text(r.text, style: Theme.of(context).textTheme.bodySmall),
                ],
              ))
          .toList(),
    );
  }
}

class _Rule {
  final String text;
  final bool ok;
  _Rule(this.text, this.ok);
}
