import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/backup/seed_dedupe.dart';

void main() {
  test('single copies are left alone', () {
    expect(planSeedDedupe(const [SeedCandidate(id: 'a', key: 'food'), SeedCandidate(id: 'b', key: 'fuel')]), isEmpty);
  });

  test('restored rows win over the fresh seed', () {
    final plan = planSeedDedupe(
      const [SeedCandidate(id: 'fresh', key: 'food', references: 3), SeedCandidate(id: 'backup', key: 'food')],
      preferIds: {'backup'},
    );
    expect(plan, {'fresh': 'backup'});
  });

  test('without a preference the most referenced copy wins, then the smallest id', () {
    expect(planSeedDedupe(const [SeedCandidate(id: 'a', key: 'food'), SeedCandidate(id: 'b', key: 'food', references: 2)]), {'a': 'b'});
    expect(
      planSeedDedupe(const [SeedCandidate(id: 'b', key: 'food'), SeedCandidate(id: 'a', key: 'food'), SeedCandidate(id: 'c', key: 'food')]),
      {'b': 'a', 'c': 'a'},
    );
  });

  test('a copy that cannot be removed is kept, and is preferred as keeper on a tie', () {
    expect(planSeedDedupe(const [SeedCandidate(id: 'a', key: 'cash:Cash'), SeedCandidate(id: 'b', key: 'cash:Cash', removable: false)]), {
      'a': 'b',
    });
    expect(
      planSeedDedupe(
        const [SeedCandidate(id: 'a', key: 'cash:Cash', removable: false), SeedCandidate(id: 'b', key: 'cash:Cash', removable: false)],
        preferIds: {'b'},
      ),
      isEmpty,
    );
  });
}
