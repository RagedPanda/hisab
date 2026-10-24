import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/ids.dart';
import '../../domain/backup/seed_dedupe.dart';
import '../../domain/categories/category_catalog.dart';
import '../../domain/categories/category_packs.dart';
import '../../domain/sms/sms_outcome.dart';

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
@TableIndex(name: 'entries_recurring_id', columns: {#recurringId})
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

  /// Recurring rule that produced (or started) this entry.
  TextColumn get recurringId => text().nullable()();
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

  /// A common line (tax, delivery, service charge) in a by-item group split:
  /// split equally among everyone holding a non-shared item.
  BoolColumn get isShared => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Who shares one line item of a by-item group split. The id is
/// `'<entryItemId>:<memberId>'`, so re-assigning a member revives the same row.
/// The materialised result still lands in Splits, so balances read only Splits.
@TableIndex(name: 'item_assignments_entry_item_id', columns: {#entryItemId})
class ItemAssignments extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get entryItemId => text()();
  TextColumn get memberId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {entryItemId, memberId},
      ];
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

  /// Trip, home, couple or other (see `GroupType`); sets the default icon and
  /// the empty-state wording (v7, group settings).
  TextColumn get type => text().withDefault(const Constant('other'))();

  /// Split method pre-selected for new expenses: equal, shares or percent (v7).
  TextColumn get defaultSplitMethod => text().withDefault(const Constant('equal'))();

  /// Free-text notes shown as a card on the Expenses tab (v7).
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Currency symbol shown for this group's amounts; null follows the app
  /// setting. A label only: amounts are never converted (v7).
  TextColumn get currencyLabel => text().nullable()();

  /// When the group was archived (or left); null while active (v7).
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Members extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get groupId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();

  /// UPI ID (VPA) for "Pay with UPI" links. Plain text, kept on this device.
  TextColumn get upiId => text().nullable()();
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

/// Who paid what when several members paid one group expense. Single-payer
/// entries have no rows here; `Entries.paidByMemberId` always holds the main
/// payer so older readers keep working.
@TableIndex(name: 'entry_payers_entry_id', columns: {#entryId})
class EntryPayers extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get entryId => text()();
  TextColumn get memberId => text()();
  IntColumn get amountMinor => integer()();

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

  /// cash | upi | bank | other
  TextColumn get method => text().withDefault(const Constant('cash'))();

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

/// A field a project records, copied from its template or added by the user.
/// Entry-scope fields are filled on each entry (into [EntryFieldValues]);
/// project-scope fields hold one value for the whole project right here.
@TableIndex(name: 'project_fields_project_id', columns: {#projectId})
class ProjectFields extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get projectId => text()();

  /// Stable key: a template field key (`odometer`) or a generated one for custom fields.
  TextColumn get key => text()();

  /// User-facing label for custom fields; template fields are labelled from the ARB files.
  TextColumn get label => text().withDefault(const Constant(''))();

  /// number | text | date | choice | unit
  TextColumn get type => text()();
  TextColumn get unit => text().nullable()();

  /// JSON array of option keys (choice) or unit options (unit).
  TextColumn get choices => text().withDefault(const Constant('[]'))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// project | entry
  TextColumn get scope => text().withDefault(const Constant('entry'))();

  /// The value of a project-scope field.
  RealColumn get numberValue => real().nullable()();
  TextColumn get textValue => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The value one entry recorded for a project field, keyed by the field's key
/// so it survives the field being re-created. A unit field keeps its number
/// in [numberValue] and its unit in [textValue].
@TableIndex(name: 'entry_field_values_entry_id', columns: {#entryId})
class EntryFieldValues extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get entryId => text()();
  TextColumn get fieldKey => text()();
  RealColumn get numberValue => real().nullable()();
  TextColumn get textValue => text().nullable()();
  DateTimeColumn get dateValue => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Anything Hisab nudged someone about, or will. One generic table so settle-up
/// reminders, recurring-expense prompts and the like share history and sync.
@TableIndex(name: 'reminders_group_id', columns: {#groupId})
@TableIndex(name: 'reminders_status_due', columns: {#status, #dueAt})
class Reminders extends Table with SyncColumns {
  TextColumn get id => text()();

  /// settle_up, or a due-reminder kind: bill | emi | card | subscription | insurance | document | custom
  TextColumn get kind => text()();
  TextColumn get groupId => text().nullable()();

  /// Who the reminder is about (the member asked to pay, for settle_up).
  TextColumn get memberId => text().nullable()();
  TextColumn get entryId => text().nullable()();

  /// When it should fire; null for reminders sent on the spot.
  DateTimeColumn get dueAt => dateTime().nullable()();
  DateTimeColumn get sentAt => dateTime().nullable()();
  DateTimeColumn get doneAt => dateTime().nullable()();

  /// share | copy | whatsapp | sms | notification
  TextColumn get channel => text().withDefault(const Constant('share'))();
  TextColumn get message => text().withDefault(const Constant(''))();

  // Due reminders (v9): bills, EMIs, card dues, subscriptions, insurance,
  // documents and custom nudges. Kinds and values live in
  // lib/domain/reminders/reminder_kind.dart.

  /// What the notification says ("Electricity bill"); empty for settle_up rows.
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// Expected amount, null for non-money reminders (documents, custom).
  IntColumn get amountMinor => integer().nullable()();

  /// Amount tolerance for SMS auto-match, in minor units.
  IntColumn get toleranceMinor => integer().withDefault(const Constant(0))();

  /// Lower-cased keywords matched against bank SMS: "tata power|tpddl".
  TextColumn get matchKeywords => text().withDefault(const Constant(''))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();

  /// Recurring rule that produced this reminder (recurring_rules.id).
  TextColumn get recurringId => text().nullable()();

  /// Insurance policy, document or asset the reminder is about.
  TextColumn get assetId => text().nullable()();

  /// once | weekly | monthly | quarterly | yearly
  TextColumn get repeat => text().withDefault(const Constant('once'))();

  /// Day of month a repeating reminder falls on, kept so 31 Jan -> 28 Feb -> 31 Mar.
  IntColumn get repeatDay => integer().nullable()();

  /// Days before dueAt to notify, comma separated ("3,0" = 3 days before and on the day).
  TextColumn get remindDaysBefore => text().withDefault(const Constant('0'))();

  /// Local time of day to notify, in minutes after midnight; null = no notification.
  IntColumn get notifyAtMinute => integer().nullable()();

  /// pending | done | skipped (snoozed = pending with [snoozedUntil] in the future)
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get snoozedUntil => dateTime().nullable()();

  /// The next occurrence spawned when this repeating reminder was paid or skipped,
  /// so undo can remove it again.
  TextColumn get nextId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A template entry plus a schedule. Due occurrences become entries with
/// [Entries.recurringId] set, either automatically ([autoPost]) or after the
/// user confirms them. Schedule maths lives in `lib/domain/recurring`.
class RecurringRules extends Table with SyncColumns {
  TextColumn get id => text()();

  /// Display name ("Rent", "Netflix"); empty falls back to payee or category.
  TextColumn get name => text().withDefault(const Constant(''))();

  /// expense | income | transfer
  TextColumn get kind => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text().withDefault(const Constant('INR'))();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get toAccountId => text().nullable()();
  TextColumn get payee => text().nullable()();
  TextColumn get projectId => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();

  /// daily | weekly | monthly | yearly; a custom schedule is one of these
  /// with [interval] above one.
  TextColumn get frequency => text()();
  IntColumn get interval => integer().withDefault(const Constant(1))();

  /// 1..31, -1 = last day of the month, 0 = the month start day setting.
  IntColumn get dayOfMonth => integer().nullable()();

  /// ISO weekday 1..7 for weekly rules.
  IntColumn get weekday => integer().nullable()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  IntColumn get maxCount => integer().nullable()();

  /// Occurrences already posted or skipped, counted against [maxCount].
  IntColumn get postedCount => integer().withDefault(const Constant(0))();

  /// How many of [postedCount] were skipped rather than added.
  IntColumn get skippedCount => integer().withDefault(const Constant(0))();

  /// Next occurrence not yet posted or skipped; null once the rule ended.
  DateTimeColumn get nextDue => dateTime().nullable()();

  /// Post due occurrences without asking; false lists them as Upcoming to confirm.
  BoolColumn get autoPost => boolean().withDefault(const Constant(true))();

  /// Comma separated days before the due date to notify ("3,0").
  TextColumn get remindDaysBefore => text().withDefault(const Constant(''))();
  BoolColumn get isSubscription => boolean().withDefault(const Constant(false))();

  /// active | paused | ended
  TextColumn get status => text().withDefault(const Constant('active'))();
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

  /// See SmsLogStatus: pending | added | ignored | skipped | not_bank | duplicate | undone
  TextColumn get status => text()();
  TextColumn get parsedJson => text().nullable()();
  TextColumn get entryId => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Set when the user clears the SMS history. The row stays (with its body
  /// wiped) so the message is still recognised and never processed twice.
  DateTimeColumn get clearedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Who added, edited, deleted or restored which group expense or payment,
/// and when, with the state before and after as JSON snapshots (see
/// `domain/split/group_activity.dart`).
@TableIndex(name: 'group_activities_group_id', columns: {#groupId})
class GroupActivities extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get groupId => text()();

  /// added | edited | deleted | restored
  TextColumn get action => text()();

  /// expense | payment
  TextColumn get subjectKind => text()();

  /// The entry or settlement id.
  TextColumn get subjectId => text()();

  /// The member who made the change; the device's own member until sync.
  TextColumn get actorMemberId => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  TextColumn get beforeJson => text().nullable()();
  TextColumn get afterJson => text().nullable()();

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
  ProjectFields,
  EntryFieldValues,
  Reminders,
  EntryPayers,
  RecurringRules,
  GroupActivities,
  ItemAssignments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 13;

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
          // v3: payment method on settlements (groups parity, record payment).
          if (from < 3) await m.addColumn(settlements, settlements.method);
          // v4: project fields and the values entries record for them.
          if (from < 4) {
            await m.createTable(projectFields);
            await m.createIndex(projectFieldsProjectId);
            await m.createTable(entryFieldValues);
            await m.createIndex(entryFieldValuesEntryId);
          }
          // v5: member UPI IDs and the generic reminders table (groups parity, reminders).
          if (from < 5) {
            await m.addColumn(members, members.upiId);
            await m.createTable(reminders);
            await m.createIndex(remindersGroupId);
          }
          // v6: several payers on one group expense (groups parity, multiple payers).
          if (from < 6) {
            await m.createTable(entryPayers);
            await m.createIndex(entryPayersEntryId);
          }
          // v7: recurring rules and the entries they post (R2, recurring entries).
          if (from < 7) {
            await m.createTable(recurringRules);
            await m.addColumn(entries, entries.recurringId);
            await m.createIndex(entriesRecurringId);
          }
          // v8: SMS history can be cleared without forgetting processed messages.
          if (from < 8) await m.addColumn(smsLog, smsLog.clearedAt);
          // v9 was never shipped (it held the due-reminder step, now v12, before v10 merged).
          // v10: group activity log (groups parity, undo and history).
          if (from < 10) {
            await m.createTable(groupActivities);
            await m.createIndex(groupActivitiesGroupId);
          }
          // v11: group type, default split, notes, currency label and archiving (groups parity, group settings).
          if (from < 11) {
            await m.addColumn(groups, groups.type);
            await m.addColumn(groups, groups.defaultSplitMethod);
            await m.addColumn(groups, groups.notes);
            await m.addColumn(groups, groups.currencyLabel);
            await m.addColumn(groups, groups.archivedAt);
          }
          // v12: due reminders (bills, EMIs, cards, documents) on the v5 reminders
          // table: new columns only, so existing rows are kept as they are.
          if (from < 12) await _upgradeToDueReminders(m, from);
          // v13: by-item group splits, shared lines and who shares each item.
          if (from < 13) {
            await m.addColumn(entryItems, entryItems.isShared);
            await m.createTable(itemAssignments);
            await m.createIndex(itemAssignmentsEntryItemId);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          await wipeUnkeptSmsText();
          // Heals installs where a restore doubled the seed (#63); writes nothing otherwise.
          if (!details.wasCreated) await mergeSeededDuplicates();
          if (!details.wasCreated) await recolourRetiredSeeds();
        },
      );

  /// v12 step. A v5..v11 table gains the due-reminder columns it lacks (a
  /// table created at v5 or later by this version already has them all).
  /// Checking what exists keeps it idempotent: it also upgrades pre-release
  /// builds of the reminders feature, which stored these columns and the index
  /// under schema 6 without main's v6 entry_payers table, and QA builds that
  /// added them as schema 9.
  Future<void> _upgradeToDueReminders(Migrator m, int from) async {
    if (from >= 5) {
      final existing = await _columnNames('reminders');
      for (final column in dueReminderColumns(reminders)) {
        if (!existing.contains(column.name)) await m.addColumn(reminders, column);
      }
    }
    if (!await _schemaObjectExists('index', 'reminders_status_due')) await m.createIndex(remindersStatusDue);
    if (!await _schemaObjectExists('table', 'entry_payers')) {
      await m.createTable(entryPayers);
      await m.createIndex(entryPayersEntryId);
    }
  }

  Future<Set<String>> _columnNames(String table) async {
    final rows = await customSelect('PRAGMA table_info($table)').get();
    return {for (final row in rows) row.read<String>('name')};
  }

  Future<bool> _schemaObjectExists(String type, String name) async {
    final rows = await customSelect('SELECT 1 FROM sqlite_master WHERE type = ? AND name = ?', variables: [Variable.withString(type), Variable.withString(name)]).get();
    return rows.isNotEmpty;
  }

  static QueryExecutor _openConnection() => driftDatabase(
        name: 'hisab',
        native: const DriftNativeOptions(shareAcrossIsolates: true),
      );

  /// Drops SMS text the log may not keep ([keepsSmsText]: not-bank messages,
  /// OTPs and promotions) that an earlier build or a restored backup stored.
  /// Idempotent, so it runs on every open.
  Future<void> wipeUnkeptSmsText() async {
    final rows = await (select(smsLog)..where((row) => row.body.equals('').not())).get();
    final wipeIds = [for (final row in rows) if (!keepsSmsText(row.status, row.body)) row.id];
    if (wipeIds.isEmpty) return;
    await (update(smsLog)..where((row) => row.id.isIn(wipeIds))).write(const SmsLogCompanion(body: Value('')));
  }

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

  /// Moves seeded categories still on a retired default colour to the
  /// current palette; colours the user picked are left alone. Writes nothing
  /// once every row is current.
  Future<int> recolourRetiredSeeds() async {
    final seedColors = {for (final seed in [...flattenCatalog(), ...packOnlySeeds()]) seed.key: seed.color};
    final seeded = await (select(categories)..where((t) => t.seedKey.isNotNull())).get();
    var recoloured = 0;
    for (final category in seeded) {
      final seedColor = seedColors[category.seedKey];
      final target = seedColor == null ? null : recolouredSeed(current: category.color, seedColor: seedColor);
      if (target == null) continue;
      await (update(categories)..where((t) => t.id.equals(category.id)))
          .write(CategoriesCompanion(color: Value(target), updatedAt: Value(DateTime.now())));
      recoloured++;
    }
    return recoloured;
  }

  /// Folds duplicate seeded rows into one: categories sharing a seedKey and
  /// extra untouched "Cash" accounts. References move to the kept row and the
  /// duplicate is soft-deleted, so restoring the same backup again keeps it
  /// gone. [preferIds] are kept over other copies (rows a restore just wrote).
  Future<int> mergeSeededDuplicates({Set<String> preferIds = const {}}) => transaction(() async {
        final categoryPlan = planSeedDedupe(await _seededCategoryCandidates(), preferIds: preferIds);
        final accountPlan = planSeedDedupe(await _cashAccountCandidates(), preferIds: preferIds);
        final now = DateTime.now();
        for (final MapEntry(key: droppedId, value: keptId) in categoryPlan.entries) {
          await (update(entries)..where((t) => t.categoryId.equals(droppedId)))
              .write(EntriesCompanion(categoryId: Value(keptId), updatedAt: Value(now)));
          await (update(budgets)..where((t) => t.categoryId.equals(droppedId)))
              .write(BudgetsCompanion(categoryId: Value(keptId), updatedAt: Value(now)));
          await (update(recurringRules)..where((t) => t.categoryId.equals(droppedId)))
              .write(RecurringRulesCompanion(categoryId: Value(keptId), updatedAt: Value(now)));
          await (update(categories)..where((t) => t.parentId.equals(droppedId)))
              .write(CategoriesCompanion(parentId: Value(keptId), updatedAt: Value(now)));
          await (update(categories)..where((t) => t.id.equals(droppedId)))
              .write(CategoriesCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        }
        for (final droppedId in accountPlan.keys) {
          await (update(accounts)..where((t) => t.id.equals(droppedId)))
              .write(AccountsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
        }
        return categoryPlan.length + accountPlan.length;
      });

  Future<List<SeedCandidate>> _seededCategoryCandidates() async {
    final live = await (select(categories)..where((t) => t.seedKey.isNotNull() & t.deletedAt.isNull())).get();
    final entryRefs = await _countBy(entries, entries.categoryId);
    final budgetRefs = await _countBy(budgets, budgets.categoryId);
    final ruleRefs = await _countBy(recurringRules, recurringRules.categoryId);
    return [
      for (final category in live)
        SeedCandidate(
          id: category.id,
          key: category.seedKey!,
          references: (entryRefs[category.id] ?? 0) + (budgetRefs[category.id] ?? 0) + (ruleRefs[category.id] ?? 0),
        ),
    ];
  }

  /// Only the seeded account's shape counts as a duplicate, and only an
  /// empty one (no entries, zero balance) may be dropped.
  Future<List<SeedCandidate>> _cashAccountCandidates() async {
    final live = await (select(accounts)
          ..where((t) => t.type.equals('cash') & t.name.equals('Cash') & t.deletedAt.isNull()))
        .get();
    final fromRefs = await _countBy(entries, entries.accountId);
    final toRefs = await _countBy(entries, entries.toAccountId);
    final ruleFromRefs = await _countBy(recurringRules, recurringRules.accountId);
    final ruleToRefs = await _countBy(recurringRules, recurringRules.toAccountId);
    return [
      for (final account in live)
        _cashCandidate(
          account,
          (fromRefs[account.id] ?? 0) + (toRefs[account.id] ?? 0) + (ruleFromRefs[account.id] ?? 0) + (ruleToRefs[account.id] ?? 0),
        ),
    ];
  }

  static SeedCandidate _cashCandidate(Account account, int references) => SeedCandidate(
        id: account.id,
        key: 'cash:Cash',
        references: references,
        removable: references == 0 && account.balanceMinor == 0,
      );

  /// Live-row count per value of [column] in [table].
  Future<Map<String, int>> _countBy(TableInfo<Table, dynamic> table, GeneratedColumn<String> column) async {
    final deletedAt = table.columnsByName['deleted_at']! as GeneratedColumn<DateTime>;
    final count = column.count();
    final rows = await (selectOnly(table)
          ..addColumns([column, count])
          ..where(column.isNotNull() & deletedAt.isNull())
          ..groupBy([column]))
        .get();
    return {for (final row in rows) row.read(column)!: row.read(count)!};
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

/// Columns v9 added to [Reminders]; a v5..v8 database gains exactly these.
List<GeneratedColumn> dueReminderColumns($RemindersTable table) => [
      table.title,
      table.notes,
      table.amountMinor,
      table.toleranceMinor,
      table.matchKeywords,
      table.categoryId,
      table.accountId,
      table.recurringId,
      table.assetId,
      table.repeat,
      table.repeatDay,
      table.remindDaysBefore,
      table.notifyAtMinute,
      table.status,
      table.snoozedUntil,
      table.nextId,
    ];
