import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color _cream = Color(0xFFE9E9E9);
  static const Color _sand = Color(0xFFD3D3D3);
  static const Color _steel = Color(0xFF818284);
  static const Color _navy = Colors.black;
  static const Color _ink = Color(0xFF1B1B1B);

  static final ColorScheme _lightScheme = const ColorScheme(
    brightness: Brightness.light,
    primary: _navy,
    onPrimary: Color(0xFFEAE6E0),
    secondary: _steel,
    onSecondary: Colors.white,
    tertiary: _sand,
    onTertiary: _ink,
    error: Colors.red,
    onError: Colors.white,
    surface: Color(0xFFEAE6E0),
    onSurface: _ink,
  );

  static final ColorScheme _darkScheme = const ColorScheme(
    brightness: Brightness.dark,
    primary: _steel,
    onPrimary: Color(0xFFEAE6E0),
    secondary: _navy,
    onSecondary: Colors.white,
    tertiary: _sand,
    onTertiary: _ink,
    error: Colors.redAccent,
    onError: Colors.black,
    surface: Color(0xFF111214),
    onSurface: Colors.white,
  );

  static final lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _lightScheme,
    scaffoldBackgroundColor: Color(0xFFEAE6E0),
    textTheme: GoogleFonts.fustatTextTheme().apply(
      bodyColor: _ink,
      displayColor: _ink,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _steel.withOpacity(.3))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: _steel.withOpacity(.3))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _navy, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: _steel),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.fustat(fontWeight: FontWeight.w600),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: _darkScheme,
    scaffoldBackgroundColor: const Color(0xFF0F1011),
    textTheme: GoogleFonts.fustatTextTheme(ThemeData.dark().textTheme),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1B1D),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(.10))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.white.withOpacity(.10))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _steel, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Colors.white70),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _steel,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: GoogleFonts.fustat(fontWeight: FontWeight.w600),
      ),
    ),
  );
}
