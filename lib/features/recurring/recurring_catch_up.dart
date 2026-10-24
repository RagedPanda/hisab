import 'dart:async';

import '../../domain/recurring/catch_up_schedule.dart';

/// Runs one catch-up at [now] and returns when the next one is due, or null
/// for the next local midnight.
typedef CatchUpRun = Future<DateTime?> Function(DateTime now);
typedef TimerFactory = Timer Function(Duration delay, void Function() callback);

/// Runs the recurring catch-up on launch, on resume, whenever rules change,
/// and while the app stays in the foreground, at the wake time each run
/// returns (the next due occurrence or local midnight, see nextWakeAt).
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

  Timer? _wakeTimer;
  Future<void>? _inFlight;
  bool _rerun = false;
  bool _disposed = false;

  /// Runs the catch-up now and re-arms the timer. Call on launch, on resume
  /// (timers can be late or lost while the app is suspended) and when rules
  /// change (a new or edited rule can move the next wake earlier).
  Future<void> trigger() {
    if (_disposed) return Future.value();
    if (_inFlight != null) {
      _rerun = true;
      return _inFlight!;
    }
    return _inFlight = _drain();
  }

  Future<void> _drain() async {
    DateTime? wake;
    try {
      do {
        _rerun = false;
        wake = await run(_clock());
      } while (_rerun && !_disposed);
    } finally {
      _inFlight = null;
      _arm(wake);
    }
  }

  void _arm(DateTime? wake) {
    _wakeTimer?.cancel();
    if (_disposed) return;
    final now = _clock();
    _wakeTimer = _timer(delayUntil(wake ?? nextLocalMidnight(now), now), trigger);
  }

  void dispose() {
    _disposed = true;
    _wakeTimer?.cancel();
    _wakeTimer = null;
  }
}
