import 'package:flutter/material.dart';

// ===== PALETA ROSA (Original) =====
const kRosaPalo   = Color(0xFFF7C7D9);
const kFucsia     = Color(0xFFE35A83);
const kVerdeHoja  = Color(0xFF8CBF88);
const kCrema      = Color(0xFFFFF6F2);
const kGrisCarbon = Color(0xFF2E2E2E);

// ===== PALETA LAVANDA =====
const kLavandaClaro    = Color(0xFFE1BEE7);
const kLavandaPrimario = Color(0xFF9C27B0);
const kLavandaSecund   = Color(0xFFBA68C8);
const kLavandaFondo    = Color(0xFFF3E5F5);

// ===== PALETA DURAZNO =====
const kDuraznoClaro    = Color(0xFFFFE0B2);
const kDuraznoPrimario = Color(0xFFFF9800);
const kDuraznoSecund   = Color(0xFFFFB74D);
const kDuraznoFondo    = Color(0xFFFFF8E1);

// ===== PALETA AZUL =====
const kAzulClaro    = Color(0xFFBBDEFB);
const kAzulPrimario = Color(0xFF2196F3);
const kAzulSecund   = Color(0xFF64B5F6);
const kAzulFondo    = Color(0xFFE3F2FD);

// ===== ENUM PARA PALETAS =====
enum ColorPalette { rosa, lavanda, durazno, azul }

// ===== CONFIGURACIÓN DE COLORES POR PALETA =====
Map<String, Color> _getColorsForPalette(ColorPalette palette) {
  switch (palette) {
    case ColorPalette.rosa:
      return {
        'primary': kFucsia,
        'secondary': kVerdeHoja,
        'surface': kCrema,
        'background': kCrema,
        'accent': kRosaPalo,
      };
    case ColorPalette.lavanda:
      return {
        'primary': kLavandaPrimario,
        'secondary': kLavandaSecund,
        'surface': Colors.white,
        'background': kLavandaFondo,
        'accent': kLavandaClaro,
      };
    case ColorPalette.durazno:
      return {
        'primary': kDuraznoPrimario,
        'secondary': kDuraznoSecund,
        'surface': Colors.white,
        'background': kDuraznoFondo,
        'accent': kDuraznoClaro,
      };
    case ColorPalette.azul:
      return {
        'primary': kAzulPrimario,
        'secondary': kAzulSecund,
        'surface': Colors.white,
        'background': kAzulFondo,
        'accent': kAzulClaro,
      };
  }
}

// ===== LIGHT THEME =====
ThemeData buildDeLirioTheme({ColorPalette palette = ColorPalette.rosa}) {
  final colors = _getColorsForPalette(palette);
  
  final scheme = ColorScheme.fromSeed(
    seedColor: colors['primary']!,
    primary: colors['primary']!,
    onPrimary: Colors.white,
    secondary: colors['secondary']!,
    onSecondary: Colors.white,
    surface: colors['surface']!,
    onSurface: kGrisCarbon,
    background: colors['background']!,
    onBackground: kGrisCarbon,
    brightness: Brightness.light,
  );

  return _buildThemeData(scheme, colors, false);
}

// ===== DARK THEME =====
ThemeData buildDeLirioDarkTheme({ColorPalette palette = ColorPalette.rosa}) {
  final colors = _getColorsForPalette(palette);
  
  final darkScheme = ColorScheme.fromSeed(
    seedColor: colors['primary']!,
    brightness: Brightness.dark,
    primary: colors['primary']!,
    onPrimary: Colors.white,
    secondary: colors['secondary']!,
    onSecondary: Colors.white,
    surface: const Color(0xFF1D1D1D),
    onSurface: Colors.white,
    background: const Color(0xFF121212),
    onBackground: Colors.white,
  );

  return _buildThemeData(darkScheme, colors, true);
}

// ===== FUNCIÓN HELPER PARA CONSTRUIR TEMAS =====
ThemeData _buildThemeData(ColorScheme scheme, Map<String, Color> colors, bool isDark) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.background,
    appBarTheme: AppBarTheme(
      backgroundColor: isDark ? kGrisCarbon : colors['primary']!,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark 
          ? scheme.surface.withOpacity(0.9)
          : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark 
              ? Colors.white.withOpacity(0.08)
              : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: colors['primary']!, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colors['primary']!,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors['primary']!,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: isDark ? Colors.white : colors['surface']!,
      contentTextStyle: TextStyle(
        color: isDark ? Colors.black : kGrisCarbon,
      ),
    ),
    iconTheme: IconThemeData(
      color: isDark ? Colors.white : kGrisCarbon,
    ),
    dividerColor: isDark 
        ? Colors.white.withOpacity(0.08)
        : kGrisCarbon.withOpacity(0.12),
  );
}

// ===== Control de tema mejorado =====
class ThemeController extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.system;
  ColorPalette _palette = ColorPalette.rosa;

  ThemeMode get mode => _mode;
  ColorPalette get palette => _palette;

  // Getters para obtener los temas actuales
  ThemeData get lightTheme => buildDeLirioTheme(palette: _palette);
  ThemeData get darkTheme => buildDeLirioDarkTheme(palette: _palette);

  void setMode(ThemeMode m) {
    if (m == _mode) return;
    _mode = m;
    notifyListeners();
  }

  void setPalette(ColorPalette p) {
    if (p == _palette) return;
    _palette = p;
    notifyListeners();
  }

  void toggleLightDark() {
    _mode = _mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  String get paletteDisplayName {
    switch (_palette) {
      case ColorPalette.rosa:
        return 'Rosa';
      case ColorPalette.lavanda:
        return 'Lavanda';
      case ColorPalette.durazno:
        return 'Durazno';
      case ColorPalette.azul:
        return 'Azul';
    }
  }
}

// Instancia global para controlar el tema desde cualquier pantalla.
final themeController = ThemeController();
