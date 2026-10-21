import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hisab uses a deep teal with a warm amber accent: calm for daily use,
/// clearly different from the indigo/purple of most finance apps.
const Color kSeedColor = Color(0xFF0F6E6B);
const Color kAccentColor = Color(0xFFF2A33A);
const Color kExpenseColor = Color(0xFFD9534F);
const Color kIncomeColor = Color(0xFF2E9E6B);

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    secondary: kAccentColor,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: brightness == Brightness.light ? const Color(0xFFF6F8F7) : null,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: scheme.surfaceContainerLow,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
    ),
    navigationBarTheme: NavigationBarThemeData(
      indicatorColor: scheme.primaryContainer,
      labelTextStyle: WidgetStatePropertyAll(base.textTheme.labelMedium),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

/// Palette offered for categories, accounts and groups.
const List<int> kPaletteColors = [
  0xFF0F6E6B, 0xFF2E9E6B, 0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39, 0xFFF2A33A,
  0xFFFF7043, 0xFFD9534F, 0xFFE91E63, 0xFF9C27B0, 0xFF673AB7, 0xFF3F51B5,
  0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4, 0xFF795548, 0xFF607D8B, 0xFF9E9E9E,
];
