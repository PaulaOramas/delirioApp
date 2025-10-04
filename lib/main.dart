import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/screens/login_screen.dart';
import 'package:delirio_app/screens/dashboard_screen.dart';
import 'package:delirio_app/services/auth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DeLirioApp());
}

class DeLirioApp extends StatelessWidget {
  const DeLirioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DeLirio',
      debugShowCheckedModeBanner: false,
      theme: buildDeLirioTheme(),
      home: const _RootDecider(), // decide si muestra Login o Dashboard
    );
  }
}

class _RootDecider extends StatelessWidget {
  const _RootDecider();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AuthService.isLoggedIn(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final logged = snap.data ?? false;
        return logged ? const DashboardScreen() : const LoginScreen();
      },
    );
  }
}
