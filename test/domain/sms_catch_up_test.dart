import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/sms/sms_catch_up.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);

  group('catchUpSince', () {
    test('starts at the cursor, less the overlap', () {
      final cursor = DateTime(2026, 10, 22, 9);
      expect(catchUpSince(now: now, cursor: cursor), cursor.subtract(const Duration(minutes: 1)));
    });

    test('prefers the cursor over the newest logged SMS', () {
      final cursor = DateTime(2026, 10, 22, 9);
      expect(catchUpSince(now: now, cursor: cursor, lastLogged: DateTime(2026, 10, 1), overlap: Duration.zero), cursor);
    });

    test('falls back to the newest logged SMS when there is no cursor yet', () {
      final logged = DateTime(2026, 10, 20, 8);
      expect(catchUpSince(now: now, lastLogged: logged, overlap: Duration.zero), logged);
    });

    test('a first scan reaches back the lookback window', () {
      expect(catchUpSince(now: now, lookback: const Duration(days: 30), overlap: Duration.zero), now.subtract(const Duration(days: 30)));
    });

    test('an old cursor is capped at the lookback window', () {
      expect(catchUpSince(now: now, cursor: DateTime(2025, 1, 1), lookback: const Duration(days: 90), overlap: Duration.zero), now.subtract(const Duration(days: 90)));
    });
  });

  group('advanceCursor', () {
    test('moves to the newest message seen', () {
      expect(advanceCursor(null, [DateTime(2026, 10, 1), DateTime(2026, 10, 3), DateTime(2026, 10, 2)]), DateTime(2026, 10, 3));
    });

    test('never moves backwards', () {
      final cursor = DateTime(2026, 10, 5);
      expect(advanceCursor(cursor, [DateTime(2026, 10, 1)]), cursor);
    });

    test('keeps the cursor when nothing was seen', () {
      expect(advanceCursor(null, const []), isNull);
      expect(advanceCursor(now, const []), now);
    });
  });
}
