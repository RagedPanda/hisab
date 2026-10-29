import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/data/db/database.dart';
import 'package:hisab/data/db/watch_tables.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  tearDown(() => db.close());

  test('a failing recompute reaches listeners as an error, not a crash', () async {
    final stream = db.watchTables<int>([db.entries], () async => throw StateError('query failed'));

    await expectLater(stream.first, throwsA(isA<StateError>()));
  });
}
