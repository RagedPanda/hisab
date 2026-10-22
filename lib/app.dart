import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/shell/router.dart';
import 'features/sms/sms_auto_sync.dart';
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
      builder: (context, child) => SmsAutoSync(child: child ?? const SizedBox.shrink()),
    );
  }
}
