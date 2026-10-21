import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hisab uses a deep teal with a warm amber accent: calm for daily use,
/// clearly different from the indigo/purple of most finance apps.
const Color kSeedColor = Color(0xFF0F6E6B);
const Color kAccentColor = Color(0xFFF2A33A);
const Color kExpenseColor = Color(0xFFD9534F);
const Color kIncomeColor = Color(0xFF2E9E6B);

/// Light scaffold / splash background, mirrored in android res (splash_background).
const Color kLightBackground = Color(0xFFF6F8F7);

/// Fixed-width digits so amounts line up in rows and legends (P3-14).
const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];

extension MoneyText on TextStyle {
  TextStyle get tabular => copyWith(fontFeatures: kTabularFigures);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    secondary: kAccentColor,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final isDark = brightness == Brightness.dark;
  final scaffoldColor = isDark ? scheme.surface : kLightBackground;
  return base.copyWith(
    scaffoldBackgroundColor: scaffoldColor,
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // One step above the scaffold in dark mode so cards keep their edges (P2-21).
      color: isDark ? scheme.surfaceContainer : scheme.surfaceContainerLow,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scaffoldColor,
      surfaceTintColor: scheme.surfaceTint,
      scrolledUnderElevation: 2,
      shadowColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      systemOverlayStyle: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      titleTextStyle: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: scheme.surface, surfaceTintColor: Colors.transparent),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      // Unselected chips get an outline so they read as controls; the fill alone marks selection (P2-9).
      side: WidgetStateBorderSide.resolveWith(
        (states) => states.contains(WidgetState.selected) ? BorderSide.none : BorderSide(color: scheme.outlineVariant),
      ),
      backgroundColor: scheme.surface,
      selectedColor: scheme.secondaryContainer,
      labelStyle: base.textTheme.labelLarge?.copyWith(color: scheme.onSurface),
      showCheckmark: false,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
      TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
    }),
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
