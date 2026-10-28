import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hisab uses a vivid teal with a warm amber accent: calm for daily use,
/// clearly different from the indigo/purple of most finance apps. Each kind
/// of money has its own colour so a screen says at a glance what it shows.
const Color kSeedColor = Color(0xFF0D9488);
const Color kSeedColorLight = Color(0xFF14B8A6);
const Color kAccentColor = Color(0xFFF59E0B);
const Color kExpenseColor = Color(0xFFF43F5E);
const Color kIncomeColor = Color(0xFF10B981);
const Color kTransferColor = Color(0xFF3B82F6);

/// The brand gradient behind hero surfaces (dashboard balance, entry header).
const LinearGradient kBrandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [kSeedColor, kSeedColorLight],
);

/// Scaffold / splash backgrounds, mirrored in android res (splash_background).
const Color kLightBackground = Color(0xFFF8FAFC);
const Color kDarkBackground = Color(0xFF0B1416);

/// The colour of a kind of money ('expense', 'income', 'transfer');
/// [fallback] for anything else.
Color kindColor(String kind, {required Color fallback}) => switch (kind) {
      'expense' => kExpenseColor,
      'income' => kIncomeColor,
      'transfer' => kTransferColor,
      _ => fallback,
    };

/// Fixed-width digits so amounts line up in rows and legends (P3-14).
const List<FontFeature> kTabularFigures = [FontFeature.tabularFigures()];

extension MoneyText on TextStyle {
  TextStyle get tabular => copyWith(fontFeatures: kTabularFigures);
}

ThemeData buildTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: kSeedColor,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    // Pin the primary to the vivid brand teal; the tonal scheme alone mutes it.
    primary: brightness == Brightness.dark ? kSeedColorLight : kSeedColor,
    onPrimary: Colors.white,
    secondary: kAccentColor,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final isDark = brightness == Brightness.dark;
  final scaffoldColor = isDark ? kDarkBackground : kLightBackground;
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
      // A soft tint keeps the selected icon readable on the vivid primary.
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? scheme.primary : scheme.onSurfaceVariant),
      ),
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
  0xFF0D9488, 0xFF10B981, 0xFF4CAF50, 0xFF8BC34A, 0xFFCDDC39, 0xFFF59E0B,
  0xFFFF7043, 0xFFF43F5E, 0xFFE91E63, 0xFF9C27B0, 0xFF673AB7, 0xFF3F51B5,
  0xFF2196F3, 0xFF03A9F4, 0xFF00BCD4, 0xFF795548, 0xFF607D8B, 0xFF9E9E9E,
];
