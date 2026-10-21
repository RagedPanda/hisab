import 'dart:async';

import 'package:drift/drift.dart';

import 'database.dart';

/// Builds a stream that recomputes [compute] now and again whenever any of
/// [tables] changes. Use it for derived values that join several tables;
/// nesting `.watch()` streams with `asyncExpand` never completes the inner
/// streams, so the outer value goes stale after the first inner change.
///
/// Updates that arrive while a recompute is running are coalesced into one
/// further recompute, so a transaction touching several tables emits once.
extension WatchTables on AppDatabase {
  Stream<T> watchTables<T>(Iterable<TableInfo> tables, Future<T> Function() compute) {
    late final StreamController<T> controller;
    StreamSubscription<void>? updates;
    var running = false;
    var dirty = false;

    Future<void> recompute() async {
      if (running) {
        dirty = true;
        return;
      }
      running = true;
      try {
        do {
          dirty = false;
          final value = await compute();
          if (!controller.isClosed) controller.add(value);
        } while (dirty && !controller.isClosed);
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
      } finally {
        running = false;
      }
    }

    controller = StreamController<T>(
      onListen: () {
        recompute();
        updates = tableUpdates(TableUpdateQuery.onAllTables(tables)).listen((_) => recompute());
      },
      onCancel: () {
        updates?.cancel();
        updates = null;
        controller.close();
      },
    );
    return controller.stream;
  }
}
