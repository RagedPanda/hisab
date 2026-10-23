import 'dart:async';

import '../../domain/recurring/catch_up_schedule.dart';

typedef CatchUpRun = Future<void> Function(DateTime now);
typedef TimerFactory = Timer Function(Duration delay, void Function() callback);

/// Runs the recurring catch-up on launch, on resume and at each local
/// midnight while the app stays in the foreground.
///
/// Runs never overlap: a trigger that arrives while a run is in flight is
/// folded into one follow-up run. Together with the idempotent posting in the
/// repository, an occurrence is never posted twice.
class RecurringCatchUp {
  RecurringCatchUp({required this.run, DateTime Function()? clock, TimerFactory? timer})
      : _clock = clock ?? DateTime.now,
        _timer = timer ?? Timer.new;

  final CatchUpRun run;
  final DateTime Function() _clock;
  final TimerFactory _timer;

  Timer? _midnight;
  Future<void>? _inFlight;
  bool _rerun = false;
  bool _disposed = false;

  /// Runs the catch-up now and re-arms the midnight timer. Call on launch and
  /// on resume (timers can be late or lost while the app is suspended).
  Future<void> trigger() {
    if (_disposed) return Future.value();
    if (_inFlight != null) {
      _rerun = true;
      return _inFlight!;
    }
    return _inFlight = _drain();
  }

  Future<void> _drain() async {
    try {
      do {
        _rerun = false;
        await run(_clock());
      } while (_rerun && !_disposed);
    } finally {
      _inFlight = null;
      _arm();
    }
  }

  void _arm() {
    _midnight?.cancel();
    if (_disposed) return;
    _midnight = _timer(delayUntilNextDay(_clock()), trigger);
  }

  void dispose() {
    _disposed = true;
    _midnight?.cancel();
    _midnight = null;
  }
}
