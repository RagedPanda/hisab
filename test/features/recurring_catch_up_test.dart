import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/repositories/recurring_repository.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/features/recurring/recurring_catch_up.dart';

/// A clock the test moves by hand.
class FakeClock {
  FakeClock(this.now);
  DateTime now;
  DateTime call() => now;
}

/// Records timers instead of starting them; [fire] runs the pending one.
class FakeTimers {
  final pending = <({Duration delay, void Function() callback, _FakeTimer timer})>[];

  Timer start(Duration delay, void Function() callback) {
    final timer = _FakeTimer();
    pending.add((delay: delay, callback: callback, timer: timer));
    return timer;
  }

  List<Duration> get armed => [for (final entry in pending) if (entry.timer.isActive) entry.delay];

  void fire() {
    final entry = pending.lastWhere((entry) => entry.timer.isActive);
    entry.timer.cancel();
    entry.callback();
  }
}

class _FakeTimer implements Timer {
  bool _active = true;
  @override
  void cancel() => _active = false;
  @override
  bool get isActive => _active;
  @override
  int get tick => 0;
}

/// A run that records each time it was called and asks for [wake] next.
CatchUpRun recordingRun(List<DateTime> runs, {DateTime? wake}) => (now) async {
      runs.add(now);
      return wake;
    };

void main() {
  late FakeClock clock;
  late FakeTimers timers;

  setUp(() {
    clock = FakeClock(DateTime(2026, 10, 23, 22));
    timers = FakeTimers();
  });

  test('runs now and arms a timer for just past the next local midnight', () async {
    final runs = <DateTime>[];
    final catchUp = RecurringCatchUp(run: recordingRun(runs), clock: clock.call, timer: timers.start);
    await catchUp.trigger();
    expect(runs, [DateTime(2026, 10, 23, 22)]);
    expect(timers.armed, [const Duration(hours: 2, seconds: 1)]);
  });

  test('the midnight timer runs the catch-up and re-arms itself for the next day', () async {
    final runs = <DateTime>[];
    final catchUp = RecurringCatchUp(run: recordingRun(runs), clock: clock.call, timer: timers.start);
    await catchUp.trigger();
    clock.now = DateTime(2026, 10, 24, 0, 0, 1);
    timers.fire();
    await pumpEventQueue();
    expect(runs.last, DateTime(2026, 10, 24, 0, 0, 1));
    expect(timers.armed, [const Duration(hours: 24)], reason: 'one live timer, for the following midnight');
  });

  test('resume runs again and replaces the timer, since timers can be late after a suspend', () async {
    final runs = <DateTime>[];
    final catchUp = RecurringCatchUp(run: recordingRun(runs), clock: clock.call, timer: timers.start);
    await catchUp.trigger();
    clock.now = DateTime(2026, 10, 25, 9);
    await catchUp.trigger();
    expect(runs, hasLength(2));
    expect(timers.armed, [const Duration(hours: 15, seconds: 1)]);
  });

  test('triggers during a run fold into one follow-up run, never overlapping', () async {
    var active = 0;
    var maxActive = 0;
    var runs = 0;
    final gate = Completer<void>();
    final catchUp = RecurringCatchUp(
      run: (now) async {
        active++;
        maxActive = active > maxActive ? active : maxActive;
        runs++;
        if (runs == 1) await gate.future;
        active--;
        return null;
      },
      clock: clock.call,
      timer: timers.start,
    );
    final first = catchUp.trigger();
    unawaited(catchUp.trigger());
    unawaited(catchUp.trigger());
    gate.complete();
    await first;
    expect(maxActive, 1);
    expect(runs, 2, reason: 'the queued triggers collapse into a single rerun');
  });

  test('arms for the wake time the run returns when it comes before midnight', () async {
    clock.now = DateTime(2026, 10, 23, 8, 58);
    final catchUp = RecurringCatchUp(run: recordingRun([], wake: DateTime(2026, 10, 23, 9)), clock: clock.call, timer: timers.start);
    await catchUp.trigger();
    expect(timers.armed, [const Duration(minutes: 2, seconds: 1)]);
  });

  test('dispose cancels the timer and later triggers do nothing', () async {
    final runs = <DateTime>[];
    final catchUp = RecurringCatchUp(run: recordingRun(runs), clock: clock.call, timer: timers.start);
    await catchUp.trigger();
    catchUp.dispose();
    expect(timers.armed, isEmpty);
    await catchUp.trigger();
    expect(runs, hasLength(1));
  });

  group('with the real repository', () {
    late AppDatabase db;
    late RecurringRepository recurring;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      recurring = RecurringRepository(db);
    });
    tearDown(() => db.close());

    Future<int> recurringEntryCount() async => (await (db.select(db.entries)..where((t) => t.source.equals('recurring'))).get()).length;

    test('a daily rule posts the new day at midnight without a restart, and only once', () async {
      await recurring.saveRule(RecurringRepository.newRule(
        name: 'Milk',
        kind: 'expense',
        amountMinor: 7000,
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 10, 23),
        autoPost: true,
      ));
      final catchUp = RecurringCatchUp(run: (now) => recurring.catchUp(now: now), clock: clock.call, timer: timers.start);
      await catchUp.trigger();
      expect(await recurringEntryCount(), 1, reason: 'the launch catch-up posts today');

      clock.now = DateTime(2026, 10, 24, 0, 0, 1);
      timers.fire();
      // A resume landing at the same moment as the midnight timer.
      await catchUp.trigger();
      await pumpEventQueue();
      expect(await recurringEntryCount(), 2, reason: 'the 24th is posted once, not once per trigger');

      await catchUp.trigger();
      expect(await recurringEntryCount(), 2);
      catchUp.dispose();
    });

    RecurringRulesCompanion formRule({required DateTime firstAt, bool autoPost = true}) => RecurringRepository.newRule(
          name: 'Rent',
          kind: 'expense',
          amountMinor: 1500000,
          frequency: RecurrenceFrequency.monthly,
          dayOfMonth: firstAt.day,
          startDate: firstAt,
          autoPost: autoPost,
        );

    test('an open app posts a 09:00 occurrence as it falls due, not at the next resume (#100)', () async {
      clock.now = DateTime(2026, 10, 23, 8, 58);
      await recurring.saveRule(formRule(firstAt: DateTime(2026, 10, 23, 9)));
      final catchUp = RecurringCatchUp(run: (now) => recurring.catchUp(now: now), clock: clock.call, timer: timers.start);
      await catchUp.trigger();
      expect(await recurringEntryCount(), 0);
      expect(timers.armed, [const Duration(minutes: 2, seconds: 1)], reason: 'wakes at 09:00, before midnight');

      clock.now = DateTime(2026, 10, 23, 9, 0, 1);
      timers.fire();
      await pumpEventQueue();
      expect(await recurringEntryCount(), 1);
      expect(timers.armed, [const Duration(hours: 15)], reason: 'next month is after midnight, so midnight wins');
      catchUp.dispose();
    });

    test('a confirm-first rule wakes the app at its due time without posting', () async {
      clock.now = DateTime(2026, 10, 23, 8, 58);
      await recurring.saveRule(formRule(firstAt: DateTime(2026, 10, 23, 9), autoPost: false));
      expect(await recurring.catchUp(now: clock.now), DateTime(2026, 10, 23, 9));
      expect(await recurring.catchUp(now: DateTime(2026, 10, 23, 9, 0, 1)), DateTime(2026, 10, 24), reason: 'an already waiting occurrence does not keep waking the app');
      expect(await recurringEntryCount(), 0);
    });

    test('8 rapid background and resume cycles around the due time post once', () async {
      clock.now = DateTime(2026, 10, 23, 8, 59, 58);
      await recurring.saveRule(formRule(firstAt: DateTime(2026, 10, 23, 9)));
      final catchUp = RecurringCatchUp(run: (now) => recurring.catchUp(now: now), clock: clock.call, timer: timers.start);
      final triggers = <Future<void>>[];
      for (var cycle = 0; cycle < 8; cycle++) {
        clock.now = clock.now.add(const Duration(milliseconds: 500));
        triggers.add(catchUp.trigger());
        if (cycle == 4) {
          // The wake timer also fires in the middle of the burst.
          await Future.wait(triggers);
          timers.fire();
        }
      }
      await Future.wait(triggers);
      await pumpEventQueue();
      expect(await recurringEntryCount(), 1);
      expect(timers.armed, hasLength(1));
      catchUp.dispose();
    });

    test('concurrent postDue calls for the same moment never double-post', () async {
      await recurring.saveRule(RecurringRepository.newRule(
        name: 'Milk',
        kind: 'expense',
        amountMinor: 7000,
        frequency: RecurrenceFrequency.daily,
        startDate: DateTime(2026, 10, 20),
        autoPost: true,
      ));
      final now = DateTime(2026, 10, 24, 0, 0, 1);
      await Future.wait([recurring.postDue(now: now), recurring.postDue(now: now), recurring.postDue(now: now)]);
      expect(await recurringEntryCount(), 5);
      final rule = await db.select(db.recurringRules).getSingle();
      expect(rule.postedCount, 5);
      expect(rule.nextDue, DateTime(2026, 10, 25));
    });
  });
}
