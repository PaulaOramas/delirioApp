import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delirio_app/services/cliente_api.dart';
import 'package:delirio_app/services/auth_service.dart';

/// ====== MODELO LOCAL (mock) ======
class UserProfileMock {
  String nombre;
  String apellido;
  String cedula;
  String correo;
  String telefono; // sin +593 aquí, solo los dígitos de usuario
  String usuario;

  UserProfileMock({
    required this.nombre,
    required this.apellido,
    required this.cedula,
    required this.correo,
    required this.telefono,
    required this.usuario,
  });
}

/// ====== REPO FALSO (sin API) ======
class FakeProfileRepository {
  // Simula obtener el perfil desde “servidor”
  Future<UserProfileMock> getPerfil() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return UserProfileMock(
      nombre: 'María',
      apellido: 'Yánez',
      cedula: '1718137159',
      correo: 'maria@example.com',
      telefono: '0998765432', // 09 + 8 dígitos
      usuario: 'maria.yz',
    );
  }

  // Simula guardar cambios (90% éxito)
  Future<bool> updatePerfil(UserProfileMock p, {String? newPassword}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return DateTime.now().millisecond % 10 != 0; // a veces falla para probar errores
  }
}

/// ====== PANTALLA EDITAR PERFIL (Mock) ======
class EditProfileMockScreen extends StatefulWidget {
  const EditProfileMockScreen({super.key});

  @override
  State<EditProfileMockScreen> createState() => _EditProfileMockScreenState();
}

class _EditProfileMockScreenState extends State<EditProfileMockScreen> {
  final _repo = FakeProfileRepository();
  int? _userId;

  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _apellidoCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  final _correoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _usuarioCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _password2Ctrl = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _showPasswordSection = false;
  bool _obscure = true;
  bool _obscure2 = true;
  int _passwordScore = 0;

  String _countryCode = '+593'; // visible, pero sin impacto “servidor”
  late UserProfileMock _profile;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_onPasswordChanged);
    _initAndLoad();
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
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (_userId != null) {
        final pApi = await ClienteApi.getPerfilById(_userId!);
        _profile = UserProfileMock(
          nombre: pApi.nombre,
          apellido: pApi.apellido,
          cedula: pApi.cedula,
          correo: pApi.correo,
          telefono: pApi.telefono,
          usuario: pApi.usuario,
        );
      } else {
        final p = await _repo.getPerfil();
        _profile = p;
      }
    } catch (_) {
      // fallback al mock si falla la API
      final p = await _repo.getPerfil();
      _profile = p;
    }
    _nombreCtrl.text = _profile.nombre;
    _apellidoCtrl.text = _profile.apellido;
    _cedulaCtrl.text = _profile.cedula;
    _correoCtrl.text = _profile.correo;
    _telefonoCtrl.text = _profile.telefono;
    _usuarioCtrl.text = _profile.usuario;
    setState(() => _loading = false);
  }

  Future<void> _initAndLoad() async {
    final claims = AuthService.instance.claims;
    _userId = _extractUserId(claims);
    await _load();
  }

  // ===== VALIDACIONES =====
  String? _req(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? 'Ingresa $label' : null;

  String? _validateEmail(String? v) {
    final x = v?.trim() ?? '';
    if (x.isEmpty) return 'Ingresa tu correo';
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(x);
    return ok ? null : 'Correo inválido';
  }

  String? _validateUser(String? v) {
    final x = v?.trim() ?? '';
    if (x.isEmpty) return 'Ingresa un usuario';
    if (x.length < 4) return 'Debe tener al menos 4 caracteres';
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(x)) {
      return 'Solo letras, números y . _ -';
    }
    return null;
  }

  // Cédula Ecuador (10 dígitos, provincia 01–24/30, dígito verificador)
  String? _validateCedulaEc(String? v) {
    final input = v?.trim() ?? '';
    if (!RegExp(r'^\d{10}$').hasMatch(input)) return 'La cédula debe tener 10 dígitos';
    final prov = int.tryParse(input.substring(0, 2)) ?? -1;
    final provOk = (prov >= 1 && prov <= 24) || prov == 30;
    if (!provOk) return 'Código de provincia inválido';
    final digits = input.split('').map(int.parse).toList();
    final coeff = [2,1,2,1,2,1,2,1,2];
    int sum = 0;
    for (int i = 0; i < 9; i++) {
      var prod = digits[i] * coeff[i];
      if (prod >= 10) prod -= 9;
      sum += prod;
    }
    final dv = (10 - (sum % 10)) % 10;
    return dv == digits[9] ? null : 'Cédula inválida (dígito verificador)';
  }

  String? _validatePhone(String? v) {
    final d = (v ?? '').trim();
    if (d.isEmpty) return 'Ingresa tu teléfono';
    if (_countryCode == '+593') {
      return RegExp(r'^09\d{8}$').hasMatch(d)
          ? null
          : 'En Ecuador debe empezar con 09 y tener 10 dígitos';
    }
    return d.length >= 6 ? null : 'Teléfono inválido';
  }

  String? _validatePassword(String? v) {
    if (!_showPasswordSection) return null;
    final p = v ?? '';
    if (p.isEmpty) return 'Ingresa una nueva contraseña';
    if (p.length < 8) return 'Mínimo 8 caracteres';
    if (!RegExp(r'[A-Z]').hasMatch(p)) return 'Incluye al menos una mayúscula';
    if (!RegExp(r'[0-9]').hasMatch(p)) return 'Incluye al menos un número';
    if (!RegExp(r'[!@#\$%\^&\*(),.?":{}|<>_\-]').hasMatch(p)) {
      return 'Incluye al menos un símbolo';
    }
    return null;
  }

  String? _validatePassword2(String? v) {
    if (!_showPasswordSection) return null;
    if (v == null || v.isEmpty) return 'Repite tu contraseña';
    return v == _passwordCtrl.text ? null : 'Las contraseñas no coinciden';
  }

  // ===== PASSWORD METER =====
  void _onPasswordChanged() {
    final s = _passwordStrength(_passwordCtrl.text);
    if (s != _passwordScore) setState(() => _passwordScore = s);
  }

  int _passwordStrength(String p) {
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p)) score++;
    if (RegExp(r'[0-9]').hasMatch(p)) score++;
    if (RegExp(r'[!@#\$%\^&\*(),.?":{}|<>_\-]').hasMatch(p)) score++;
    return score;
  }

  String _passwordLabel(int s) => s <= 1 ? 'Débil' : (s == 2 ? 'Media' : 'Fuerte');
  Color _passwordColor(int s) =>
      s <= 1 ? Colors.redAccent : (s == 2 ? Colors.orange : Colors.green);

  // ===== UI helpers =====
  InputDecoration _dec(BuildContext context, String label, IconData icon,
      {String? helperText, String? hintText}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon),
      helperText: helperText,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary),
      ),
    );
  }

  // ===== GUARDAR (mock) =====
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final updated = UserProfileMock(
      nombre: _nombreCtrl.text.trim(),
      apellido: _apellidoCtrl.text.trim(),
      cedula: _cedulaCtrl.text.trim(),
      correo: _correoCtrl.text.trim(),
      telefono: _telefonoCtrl.text.trim(),
      usuario: _usuarioCtrl.text.trim(),
    );

    bool ok = false;
    if (_userId != null) {
      final payload = {
        'Nombre': updated.nombre,
        'Apellido': updated.apellido,
        'Cedula': updated.cedula,
        'Correo': updated.correo,
        'Telefono': updated.telefono,
        'Usuario': updated.usuario,
        if (_showPasswordSection) 'Password': _passwordCtrl.text,
      };
      ok = await ClienteApi.updatePerfil(_userId!, payload);
    } else {
      ok = await _repo.updatePerfil(
        updated,
        newPassword: _showPasswordSection ? _passwordCtrl.text : null,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cambios guardados ✅ (simulación)')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron guardar (simulación)')),
      );
    }
  }

  String _iniciales(String n, String a) {
    final s1 = n.trim().isNotEmpty ? n.trim()[0] : '';
    final s2 = a.trim().isNotEmpty ? a.trim()[0] : '';
    return (s1 + s2).toUpperCase();
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar perfil (demo)'),
        actions: [
          IconButton(
            tooltip: 'Guardar',
            onPressed: _saving || _loading ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
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
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: theme.colorScheme.primary.withOpacity(.12),
                                child: Text(
                                  _iniciales(_nombreCtrl.text, _apellidoCtrl.text),
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tu información',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        )),
                                    Text('Esta es una simulación sin API.',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: theme.hintColor,
                                        )),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nombreCtrl,
                                  textInputAction: TextInputAction.next,
                                  textCapitalization: TextCapitalization.words,
                                  autofillHints: const [AutofillHints.givenName],
                                  decoration: _dec(context, 'Nombre', Icons.badge_outlined),
                                  validator: (v) => _req(v, 'tu nombre'),
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
                                  validator: (v) => _req(v, 'tu apellido'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _cedulaCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            textInputAction: TextInputAction.next,
                            decoration: _dec(context, 'Cédula (Ecuador)', Icons.credit_card,
                                helperText: '10 dígitos • provincia válida • verificación automática'),
                            validator: _validateCedulaEc,
                          ),
                          const SizedBox(height: 12),

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

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButton<String>(
                                  value: _countryCode,
                                  underline: const SizedBox.shrink(),
                                  items: const [
                                    DropdownMenuItem(value: '+593', child: Text('🇪🇨 +593')),
                                    DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                                    DropdownMenuItem(value: '+52', child: Text('🇲🇽 +52')),
                                  ],
                                  onChanged: (v) => setState(() => _countryCode = v ?? '+593'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _telefonoCtrl,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    LengthLimitingTextInputFormatter(
                                        _countryCode == '+593' ? 10 : 15),
                                  ],
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.telephoneNumber],
                                  decoration: _dec(context, 'Teléfono', Icons.phone,
                                      helperText: _countryCode == '+593'
                                          ? 'Debe empezar con 09 (10 dígitos)'
                                          : null),
                                  validator: _validatePhone,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _usuarioCtrl,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.username],
                            decoration: _dec(context, 'Usuario', Icons.person_outline,
                                helperText: 'Mín. 4 caracteres. Usa letras y números.'),
                            validator: _validateUser,
                          ),

                          const SizedBox(height: 16),
                          Divider(color: theme.colorScheme.outlineVariant),
                          const SizedBox(height: 8),

                          // Sección cambio de contraseña (opcional)
                          InkWell(
                            onTap: () =>
                                setState(() => _showPasswordSection = !_showPasswordSection),
                            child: Row(
                              children: [
                                Icon(_showPasswordSection
                                    ? Icons.expand_less
                                    : Icons.expand_more),
                                const SizedBox(width: 6),
                                Text(
                                  'Cambiar contraseña (opcional)',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AnimatedCrossFade(
                            firstChild: const SizedBox.shrink(),
                            secondChild: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  textInputAction: TextInputAction.next,
                                  decoration: _dec(context, 'Nueva contraseña', Icons.lock_outline)
                                      .copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                  ),
                                  validator: _validatePassword,
                                ),
                                const SizedBox(height: 8),
                                if (_showPasswordSection)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: LinearProgressIndicator(
                                      value: (_passwordScore / 4).clamp(0, 1),
                                      minHeight: 6,
                                      color: _passwordColor(_passwordScore),
                                      backgroundColor: Colors.grey.shade200,
                                    ),
                                  ),
                                if (_showPasswordSection) ...[
                                  const SizedBox(height: 6),
                                  _PasswordChecklist(password: _passwordCtrl.text),
                                ],
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _password2Ctrl,
                                  obscureText: _obscure2,
                                  textInputAction: TextInputAction.done,
                                  decoration: _dec(
                                          context, 'Confirmar nueva contraseña', Icons.lock_reset)
                                      .copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscure2
                                          ? Icons.visibility_off
                                          : Icons.visibility),
                                      onPressed: () =>
                                          setState(() => _obscure2 = !_obscure2),
                                    ),
                                  ),
                                  validator: _validatePassword2,
                                ),
                              ],
                            ),
                            crossFadeState: _showPasswordSection
                                ? CrossFadeState.showSecond
                                : CrossFadeState.showFirst,
                            duration: const Duration(milliseconds: 200),
                          ),

                          const SizedBox(height: 20),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              onPressed: _saving ? null : _save,
                              icon: _saving
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.save_outlined),
                              label: Text(_saving ? 'Guardando...' : 'Guardar cambios'),
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

/// ===== Checklist de contraseña reutilizable =====
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
                  Icon(
                    r.ok ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: r.ok ? Colors.green : Colors.grey,
                  ),
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
