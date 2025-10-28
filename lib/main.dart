import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/navigation.dart';
// Estas pantallas sí se usan
import 'package:delirio_app/screens/dashboard_screen.dart';
import 'package:delirio_app/screens/search_screen.dart';
import 'package:delirio_app/screens/profile_screen.dart';


// Si no usas login ni auth aquí, coméntalos o elimínalos de este archivo:
// import 'package:delirio_app/screens/login_screen.dart';
// import 'package:delirio_app/services/auth_service.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:delirio_app/services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar servicio de autenticación para carga de token persistente
  await AuthService.instance.init();
  runApp(const DeLirioApp());
}

class DeLirioApp extends StatelessWidget {
  const DeLirioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'DeLirio',
          debugShowCheckedModeBanner: false,
          theme: buildDeLirioTheme(),
          darkTheme: buildDeLirioDarkTheme(),
          themeMode: themeController.mode,
          // Abrir directamente el scaffold principal (que inicia en Dashboard)
          home: const MainScaffold(),
        );
      },
    );
  }
}

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  static final List<Widget> _pages = <Widget>[
    const DashboardScreen(),
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: bottomNavIndex,
      builder: (context, currentIndex, _) {
        final idx = (currentIndex >= 0 && currentIndex < _pages.length) ? currentIndex : 0;
        return Scaffold(
          body: _pages[idx],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: idx,
            onTap: (i) => bottomNavIndex.value = i,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
            ],
          ),
        );
      },
    );
  }
}

/*import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';

// Pantallas principales
import 'package:delirio_app/screens/login_screen.dart';
import 'package:delirio_app/screens/dashboard_screen.dart';
import 'package:delirio_app/screens/search_screen.dart';
import 'package:delirio_app/screens/profile_screen.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
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
      home: const LoginScreen(), // 👈 Inicia directamente en el Login
    );
  }
}

// Este widget puedes dejarlo para cuando el usuario inicie sesión.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const List<Widget> _pages = <Widget>[
    DashboardScreen(),
    SearchScreen(),
    ProfileScreen(),
  ];

  void _onTap(int idx) {
    setState(() => _currentIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTap,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Buscar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}*/

