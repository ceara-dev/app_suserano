import 'package:flutter/material.dart';

const appBackgroundColor = Color(0xFFF3F6FC);
const appPrimaryColor = Color(0xFF2F6FED);
const appPrimaryDarkColor = Color(0xFF1B4FC4);

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(seedColor: appPrimaryColor);
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: appBackgroundColor,
    colorScheme: colorScheme,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 0,
      indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
      surfaceTintColor: Colors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: appBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.black87,
    ),
  );
}
