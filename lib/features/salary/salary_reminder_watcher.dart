import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import 'salary_providers.dart';
import 'salary_reminder.dart';

/// Keeps the salary reminder in step with the data: on launch, on resume
/// (the day may have changed) and whenever an income is added, edited or
/// removed, including entries added from SMS. A language change re-posts the
/// alert so its text follows the app. Renders [child] unchanged.
class SalaryReminderWatcher extends ConsumerStatefulWidget {
  const SalaryReminderWatcher({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<SalaryReminderWatcher> createState() => _SalaryReminderWatcherState();
}

class _SalaryReminderWatcherState extends ConsumerState<SalaryReminderWatcher> {
  late final AppLifecycleListener lifecycle = AppLifecycleListener(onResume: sync);
  bool running = false;
  bool again = false;

  @override
  void initState() {
    super.initState();
    lifecycle;
    WidgetsBinding.instance.addPostFrameCallback((_) => sync());
  }

  @override
  void dispose() {
    lifecycle.dispose();
    super.dispose();
  }

  /// Runs one sync at a time; a request while one is running queues one more.
  Future<void> sync() async {
    if (!mounted) return;
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        await syncSalaryReminder(ref.read, now: DateTime.now());
      } while (again && mounted);
    } finally {
      running = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(salaryIncomesProvider, (_, next) {
      if (next.hasValue) sync();
    });
    ref.listen(salarySettingsProvider, (_, _) => sync());
    ref.listen(settingsProvider.select((settings) => settings.localeCode), (_, _) => sync());
    return widget.child;
  }
}
