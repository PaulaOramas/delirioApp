import 'package:flutter/material.dart';

const kRosaPalo   = Color(0xFFF7C7D9);
const kFucsia     = Color(0xFFE35A83);
const kVerdeHoja  = Color(0xFF8CBF88);
const kCrema      = Color(0xFFFFF6F2);
const kGrisCarbon = Color(0xFF2E2E2E);

// ===== LIGHT THEME =====
ThemeData buildDeLirioTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kFucsia,
    primary: kFucsia,
    onPrimary: Colors.white,
    secondary: kVerdeHoja,
    onSecondary: Colors.white,
    surface: kCrema,
    onSurface: kGrisCarbon,
    background: kCrema,
    onBackground: kGrisCarbon,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kCrema,
    appBarTheme: const AppBarTheme(
      backgroundColor: kFucsia,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kFucsia, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kFucsia,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kFucsia,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}

// ===== DARK THEME =====
ThemeData buildDeLirioDarkTheme() {
  final darkScheme = ColorScheme.fromSeed(
    seedColor: kFucsia,
    brightness: Brightness.dark,
    // Ajustes clave para tu marca
    primary: kFucsia,
    onPrimary: Colors.white,
    secondary: kVerdeHoja,
    onSecondary: Colors.black,
    surface: const Color(0xFF1D1D1D),   // superficie/cards
    onSurface: Colors.white,            // texto sobre superficie
    background: const Color(0xFF121212),
    onBackground: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: darkScheme,
    scaffoldBackgroundColor: darkScheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: kGrisCarbon,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // en oscuro evitamos blanco puro; usamos una capa sobre surface
      fillColor: darkScheme.surface.withOpacity(0.9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kFucsia, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kFucsia,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kFucsia,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,        // contraste alto en dark
      contentTextStyle: const TextStyle(color: Colors.black),
    ),
    iconTheme: const IconThemeData(color: Colors.white),
    dividerColor: Colors.white.withOpacity(0.08),
  );
}

// ===== Control simple de tema (opcional, sin paquetes) =====
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  void setMode(ThemeMode m) {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
  }

  void toggleLightDark() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

// Instancia global simple para controlar el tema desde cualquier pantalla.
// Puedes reemplazar esto por Provider o Riverpod si prefieres.
final themeController = ThemeController();
