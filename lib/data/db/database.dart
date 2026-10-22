import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/ids.dart';
import '../../domain/categories/category_catalog.dart';

part 'database.g.dart';

/// Every table carries [updatedAt] and a soft [deletedAt] so rows can be
/// merged last-writer-wins across devices during sync.
mixin SyncColumns on Table {
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Accounts extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();

  /// bank | cash | card | wallet
  TextColumn get type => text()();
  TextColumn get bankName => text().nullable()();
  TextColumn get last4 => text().nullable()();

  /// Key produced by the SMS parser ("HDFC Bank:ac:1234") so later messages
  /// map to this account automatically.
  TextColumn get smsKey => text().nullable()();
  IntColumn get balanceMinor => integer().withDefault(const Constant(0))();
  DateTimeColumn get balanceAsOf => dateTime().nullable()();
  BoolColumn get includeInTotal => boolean().withDefault(const Constant(true))();
  IntColumn get color => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table with SyncColumns {
  TextColumn get id => text()();

  /// Catalog key for seeded categories; null for user-created ones.
  TextColumn get seedKey => text().nullable()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  IntColumn get color => integer()();

  /// expense | income | transfer
  TextColumn get kind => text()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  /// Comma separated suggested units for item entry ("L,ml,kg").
  TextColumn get units => text().withDefault(const Constant(''))();

  /// Category pack this row came from (Settings > Categories > Add a pack);
  /// null for catalog and user-created categories.
  TextColumn get packKey => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'entries_project_id', columns: {#projectId})
class Entries extends Table with SyncColumns {
  TextColumn get id => text()();

  /// expense | income | transfer
  TextColumn get kind => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get payee => text().nullable()();

  /// manual | sms | import | recurring
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get smsId => text().nullable()();
  TextColumn get groupId => text().nullable()();
  TextColumn get paidByMemberId => text().nullable()();
  TextColumn get splitMethod => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant(''))();

  /// Project (vehicle, trip, construction...) this entry is tracked under.
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class EntryItems extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get entryId => text()();
  TextColumn get name => text()();
  RealColumn get quantity => real().withDefault(const Constant(1))();
  TextColumn get unit => text().nullable()();
  IntColumn get unitPriceMinor => integer()();
  IntColumn get amountMinor => integer()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Groups extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('group'))();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  BoolColumn get simplifyDebts => boolean().withDefault(const Constant(true))();

  /// Short code shared with friends so other devices can join (sync plan).
  TextColumn get inviteCode => text().nullable()();

  /// Project this group's expenses roll up into (no UI yet; see roadmap R1).
  TextColumn get projectId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Members extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  BoolColumn get isMe => boolean().withDefault(const Constant(false))();

  /// Default weight for equal splits (2 = counts as two people).
  RealColumn get weight => real().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

class Splits extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get entryId => text()();
  TextColumn get memberId => text()();
  IntColumn get amountMinor => integer()();

  /// Raw input that produced the amount (percent, shares, exact...).
  RealColumn get shareValue => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Settlements extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get fromMemberId => text()();
  TextColumn get toMemberId => text()();
  IntColumn get amountMinor => integer()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get note => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table with SyncColumns {
  TextColumn get id => text()();

  /// null = overall budget across all expense categories.
  TextColumn get categoryId => text().nullable()();

  /// weekly | monthly | yearly
  TextColumn get period => text().withDefault(const Constant('monthly'))();
  IntColumn get amountMinor => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A long-running thing money is spent on: a vehicle, a trip, a house build.
/// Entries link to it through [Entries.projectId]; totals are derived.
class Projects extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().withDefault(const Constant('folder'))();
  IntColumn get color => integer()();

  /// Key of the template the project was created from; null for blank.
  TextColumn get templateKey => text().nullable()();

  /// active | completed | archived
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// null = no budget set for this project.
  IntColumn get budgetMinor => integer().nullable()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SmsLog extends Table {
  /// Hash of sender+body+timestamp so a message is only processed once.
  TextColumn get id => text()();
  TextColumn get sender => text()();
  TextColumn get body => text()();
  DateTimeColumn get receivedAt => dateTime()();

  /// pending | added | ignored | skipped
  TextColumn get status => text()();
  TextColumn get parsedJson => text().nullable()();
  TextColumn get entryId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [
  Accounts,
  Categories,
  Entries,
  EntryItems,
  Groups,
  Members,
  Splits,
  Settlements,
  Budgets,
  SmsLog,
  Projects,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDefaults();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(projects);
            await m.addColumn(entries, entries.projectId);
            await m.createIndex(entriesProjectId);
            await m.addColumn(groups, groups.projectId);
            await m.addColumn(categories, categories.packKey);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'hisab',
        native: const DriftNativeOptions(shareAcrossIsolates: true),
      );

  /// Inserts the category catalog and a Cash account. Idempotent by seedKey.
  Future<void> seedDefaults() async {
    final existing = (await select(categories).get()).map((c) => c.seedKey).toSet();
    await batch((b) {
      var order = 0;
      for (final parent in categoryCatalog) {
        final parentId = newId();
        if (!existing.contains(parent.key)) {
          b.insert(categories, seedCategoryRow(parent, id: parentId, order: order++));
        }
        for (final child in parent.children) {
          if (!existing.contains(child.key)) {
            b.insert(categories, seedCategoryRow(child, id: newId(), parentId: parentId, order: order++));
          }
        }
      }
    });
    final accountCount = await (select(accounts)..limit(1)).get();
    if (accountCount.isEmpty) {
      await into(accounts).insert(AccountsCompanion.insert(
        id: newId(),
        name: 'Cash',
        type: 'cash',
        color: 0xFF43A047,
      ));
    }
  }
}

/// Insert row for a catalog or pack seed. [packKey] marks categories a pack created.
CategoriesCompanion seedCategoryRow(CategorySeed seed, {required String id, String? parentId, required int order, String? packKey}) =>
    CategoriesCompanion.insert(
      id: id,
      seedKey: Value(seed.key),
      packKey: Value(packKey),
      name: seed.name,
      icon: seed.icon,
      color: seed.color,
      kind: seed.kind.name,
      parentId: Value(parentId),
      sortOrder: Value(order),
      units: Value(seed.units.join(',')),
    );
