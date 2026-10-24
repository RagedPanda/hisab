import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/currency/first_launch_currency_screen.dart';
import 'features/shell/router.dart';
import 'features/sms/sms_auto_add_snackbar.dart';
import 'features/sms/sms_auto_sync.dart';
import 'l10n/generated/app_localizations.dart';

class HisabApp extends ConsumerStatefulWidget {
  const HisabApp({super.key});

  @override
  ConsumerState<HisabApp> createState() => _HisabAppState();
}

class _HisabAppState extends ConsumerState<HisabApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _postDueRecurring);
    WidgetsBinding.instance.addPostFrameCallback((_) => _postDueRecurring());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// Posts recurring entries that fell due while the app was closed or in
  /// the background. Safe to run repeatedly: posting is idempotent.
  Future<void> _postDueRecurring() async {
    try {
      await ref.read(recurringRepositoryProvider).postDue(now: DateTime.now(), monthStartDay: ref.read(settingsProvider).monthStartDay);
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'recurring', context: ErrorDescription('posting due recurring entries')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      locale: settings.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [AppLocalizations.delegate, GlobalMaterialLocalizations.delegate, GlobalWidgetsLocalizations.delegate, GlobalCupertinoLocalizations.delegate],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: settings.themeMode,
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: Curves.easeOutCubic,
      routerConfig: appRouter,
      // A fresh install picks its currency before Home. The router keeps its
      // location (and any deep link) and shows it once the choice is saved.
      // Otherwise the SMS Undo snackbar sits above the navigator so it shows on
      // every route, including Bank SMS opened directly from a hisab://sms link.
      // SmsAutoSync drains queued SMS and catches up on the inbox on start and resume.
      builder: (context, child) => settings.currencyConfirmed ? SmsAutoSync(child: SmsAutoAddSnackbar(child: child ?? const SizedBox.shrink())) : const FirstLaunchCurrencyGate(),
    );
  }
}
