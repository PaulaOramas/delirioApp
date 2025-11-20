import 'package:flutter/material.dart';
import 'package:delirio_app/theme.dart';
import 'package:delirio_app/navigation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:delirio_app/services/auth_service.dart';
import 'package:delirio_app/services/cart_service.dart';

// 🧭 Importa el menú personalizado
import 'package:delirio_app/widgets/custom_navbar.dart';

// Pantallas (ya las usa el menú)
import 'package:delirio_app/screens/dashboard_screen.dart';
import 'package:delirio_app/screens/search_screen.dart';
import 'package:delirio_app/screens/cart_screen.dart';
import 'package:delirio_app/screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.init(); // 🔐 Inicializar autenticación persistente
  final cart = CartService();
  await cart.loadFromLocal();
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
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.mode,
          // ✅ ahora el menú principal es el widget CustomNavBar
          home: const CustomNavBar(),
        );
      },
    );
  }
}
