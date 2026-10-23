import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/currency/first_launch_currency_screen.dart';
import 'features/shell/router.dart';
import 'l10n/generated/app_localizations.dart';

class HisabApp extends ConsumerWidget {
  const HisabApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: appRouter,
      // A fresh install picks its currency before Home. The router keeps its
      // location (and any deep link) and shows it once the choice is saved.
      builder: (context, child) => settings.currencyConfirmed
          ? child ?? const SizedBox.shrink()
          : FirstLaunchCurrencyGate(deviceRegion: WidgetsBinding.instance.platformDispatcher.locale.countryCode),
    );
  }
}
