import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/recurring/recurring_catch_up.dart';
import 'features/recurring/recurring_list_model.dart';
import 'features/shell/router.dart';
import 'l10n/generated/app_localizations.dart';

class HisabApp extends ConsumerStatefulWidget {
  const HisabApp({super.key});

  @override
  ConsumerState<HisabApp> createState() => _HisabAppState();
}

class _HisabAppState extends ConsumerState<HisabApp> {
  late final AppLifecycleListener _lifecycle;
  late final RecurringCatchUp _catchUp = RecurringCatchUp(run: _postDueRecurring);

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _catchUp.trigger);
    WidgetsBinding.instance.addPostFrameCallback((_) => _catchUp.trigger());
    // A new, edited, paused or resumed rule can move the next wake earlier.
    ref.listenManual(recurringViewsProvider, (_, _) => _catchUp.trigger());
  }

  @override
  void dispose() {
    _catchUp.dispose();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Posts recurring entries that fell due while the app was closed, in the
  /// background, or since the last wake in the foreground, then refreshes the
  /// Recurring list. Safe to run repeatedly: posting is idempotent.
  /// Returns when the next occurrence falls due, so the open app wakes then.
  Future<DateTime?> _postDueRecurring(DateTime now) async {
    if (!mounted) return null;
    try {
      final wake = await ref.read(recurringRepositoryProvider).catchUp(now: now, monthStartDay: ref.read(settingsProvider).monthStartDay);
      if (mounted) ref.read(recurringLastCatchUpProvider.notifier).set(now);
      return wake;
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'recurring', context: ErrorDescription('posting due recurring entries')));
      return null;
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
    );
  }
}
