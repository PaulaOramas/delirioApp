import 'package:flutter/material.dart';

const kRosaPalo   = Color(0xFFF7C7D9);
const kFucsia     = Color(0xFFE35A83);
const kVerdeHoja  = Color(0xFF8CBF88);
const kCrema      = Color(0xFFFFF6F2);
const kGrisCarbon = Color(0xFF2E2E2E);

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
  );
}
