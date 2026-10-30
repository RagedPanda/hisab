import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../core/ids.dart';
import '../../domain/backup/seed_dedupe.dart';
import '../../domain/categories/category_catalog.dart';
import '../../domain/categories/category_packs.dart';
import '../../domain/quick_entries/starter_quick_entries.dart';
import '../../domain/sms/sms_outcome.dart';
import '../../domain/sms/sms_transaction_key.dart';

part 'database.g.dart';

// Table definitions below are read by drift's code generator and never run,
// so they are left out of line coverage.
// coverage:ignore-start

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

  /// Credit cards only: day of month the statement is generated (1-31; short
  /// months clamp to their last day) and the day the bill is due.
  IntColumn get statementDay => integer().nullable()();
  IntColumn get dueDay => integer().nullable()();
  IntColumn get creditLimitMinor => integer().nullable()();

  /// Amount billed on the most recent statement and that statement's date.
  IntColumn get lastStatementMinor => integer().nullable()();
  DateTimeColumn get lastStatementAt => dateTime().nullable()();

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
@TableIndex(name: 'entries_person_id', columns: {#personId})
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

  /// Person (People row) an udhaar entry was lent to, borrowed from or
  /// repaid by; null for every other entry (v22).
  TextColumn get personId => text().nullable()();

  /// lent | borrowed | repaid_to_me | repaid_by_me on an udhaar entry, which
  /// is stored as a one-sided transfer (see `domain/udhaar/udhaar.dart`) (v22).
  TextColumn get udhaarKind => text().nullable()();

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
@TableIndex(name: 'reminders_project_id', columns: {#projectId})
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

  // Due reminders (v11): bills, EMIs, card dues, subscriptions, insurance,
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

  // Document reminders (v14): PUC, passport, insurance and other renewals.

  /// Project the reminder belongs to (projects.id), e.g. the Vehicle project's PUC.
  TextColumn get projectId => text().nullable()();

  /// Policy, registration or document number, kept for reference.
  TextColumn get documentNumber => text().withDefault(const Constant(''))();

  /// Document preset the reminder was made from (lib/domain/reminders/document_presets.dart).
  TextColumn get presetKey => text().nullable()();

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

  /// Group a recurring group expense (rent, maid, wifi) is posted to.
  TextColumn get groupId => text().nullable()();

  /// How a group rule splits and who pays: `GroupExpenseTemplate` as JSON.
  TextColumn get groupSplit => text().nullable()();

  /// active | paused | ended
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(name: 'sms_log_transaction_key', columns: {#transactionKey})
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

  /// Reminder this message paid, when it matched one (R2 auto-done).
  TextColumn get matchedReminderId => text().nullable()();

  /// The bank transaction this message reports (see smsTransactionKey), so
  /// the same payment pasted again or read from the inbox is not added twice.
  TextColumn get transactionKey => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Set when the user clears the SMS history. The row stays (with its body
  /// wiped) so the message is still recognised and never processed twice.
  DateTimeColumn get clearedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The category the user chose for a bank SMS payee, so later messages from
/// the same payee get it ahead of the keyword rules. [id] is
/// `payeeMemoryRowId(kind, key)` from `domain/sms/payee_category_memory.dart`:
/// the entry kind plus the UPI ID, or the normalised name when there is none.
/// Deleting one in Settings soft-deletes it so a restore does not bring it back.
class PayeeCategories extends Table with SyncColumns {
  TextColumn get id => text()();

  /// Readable payee for the Settings list ("Rahul Sharma", "Swiggy").
  TextColumn get payee => text()();
  TextColumn get categoryId => text()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The user's own People list: everyone they added to a group with an email,
/// so a new group can suggest them (see `domain/people/people.dart`). [id] is
/// the lowercased email, so the same friend added on two devices is one row.
/// People added for udhaar without an email get a generated id and an empty
/// [email] (v22).
@DataClassName('Person')
class People extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();

  /// Phone for WhatsApp reminders about udhaar; null when not known (v22).
  TextColumn get phone => text().nullable()();

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

// coverage:ignore-end

/// A saved spend the user adds again and again (milk, auto fare, metro
/// recharge), shown as a one-tap chip on Home. [amountMinor] null means the
/// chip opens the editor prefilled instead of saving at once. [sortOrder]
/// is the user's order; the first few are shown, the rest sit behind "+N more".
class QuickEntries extends Table with SyncColumns {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get kind => text().withDefault(const Constant('expense'))();
  IntColumn get amountMinor => integer().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get accountId => text().nullable()();
  TextColumn get payee => text().nullable()();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get tags => text().withDefault(const Constant(''))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

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
  PayeeCategories,
  People,
  QuickEntries,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 22;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await seedDefaults();
          await seedQuickEntries();
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
          // v14: document reminders link to a project and keep a document number.
          if (from < 14) await _upgradeToDocumentReminders(m, from);
          // v15: recurring group expenses (groups parity) on recurring_rules.
          if (from < 15) await _upgradeToGroupRecurring(m);
          // v16: the reminder a bank SMS paid and the transaction each message
          // reports (R2, auto-done on an SMS match).
          if (from < 16) await _upgradeToSmsReminderMatch(m);
          // v17: credit card statement and due days, limit and last statement.
          if (from < 17) await _upgradeToCardDetails(m);
          // v18: categories remembered per SMS payee (daily-use, payee memory).
          if (from < 18) await _upgradeToPayeeCategories(m);
          // v19: the personal People list, seeded from members that have an email.
          if (from < 19) await _upgradeToPeople(m);
          // v20: one-tap quick entries on Home.
          if (from < 20) await m.createTable(quickEntries);
          // v21: starter quick entries, unless the user already made some.
          if (from < 21) await seedQuickEntries();
          // v22: udhaar (money lent to or borrowed from a person) on entries, and People phones.
          if (from < 22) {
            await m.addColumn(entries, entries.personId);
            await m.addColumn(entries, entries.udhaarKind);
            await m.createIndex(entriesPersonId);
            // Before v19 the People table is created above, phone included.
            if (from >= 19) await m.addColumn(people, people.phone);
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

  /// v14 step. A v5..v13 reminders table gains the project link, document
  /// number and preset key it lacks (a table created at v5 or later by this
  /// version already has them), plus the project index. Checking what exists
  /// keeps it idempotent, and it heals pre-release builds of this feature,
  /// which added these columns as schema 7 and so skipped main's v7 recurring
  /// step.
  Future<void> _upgradeToDocumentReminders(Migrator m, int from) async {
    if (from >= 5) {
      final existing = await _columnNames('reminders');
      for (final column in documentReminderColumns(reminders)) {
        if (!existing.contains(column.name)) await m.addColumn(reminders, column);
      }
    }
    if (!await _schemaObjectExists('index', 'reminders_project_id')) await m.createIndex(remindersProjectId);
    if (!await _schemaObjectExists('table', 'recurring_rules')) await m.createTable(recurringRules);
    if (!(await _columnNames('entries')).contains('recurring_id')) await m.addColumn(entries, entries.recurringId);
    if (!await _schemaObjectExists('index', 'entries_recurring_id')) await m.createIndex(entriesRecurringId);
  }

  /// v15 step. Lets recurring rules post into a group: recurring_rules gains
  /// the group columns it lacks (a table created at v7 or later by this version
  /// already has them). Checking what exists keeps it idempotent, and also
  /// heals pre-release builds of this feature, which stored these columns as
  /// schema 8/9 and so skipped main's v8 sms_log.cleared_at step.
  Future<void> _upgradeToGroupRecurring(Migrator m) async {
    final ruleColumns = await _columnNames('recurring_rules');
    for (final column in [recurringRules.groupId, recurringRules.groupSplit]) {
      if (!ruleColumns.contains(column.name)) await m.addColumn(recurringRules, column);
    }
    if (!(await _columnNames('sms_log')).contains(smsLog.clearedAt.name)) await m.addColumn(smsLog, smsLog.clearedAt);
  }

  /// v16 step. Adds the SMS-to-reminder link and the transaction key with its
  /// index, then backfills keys from stored parses. Checking what exists keeps
  /// it idempotent, and it heals pre-release builds of this feature, which
  /// added these columns as schema 7 and so skipped main's v7 recurring step.
  Future<void> _upgradeToSmsReminderMatch(Migrator m) async {
    final smsColumns = await _columnNames('sms_log');
    if (!smsColumns.contains('matched_reminder_id')) await m.addColumn(smsLog, smsLog.matchedReminderId);
    if (!smsColumns.contains('transaction_key')) await m.addColumn(smsLog, smsLog.transactionKey);
    if (!await _schemaObjectExists('index', 'sms_log_transaction_key')) await m.createIndex(smsLogTransactionKey);
    if (!await _schemaObjectExists('table', 'recurring_rules')) await m.createTable(recurringRules);
    if (!(await _columnNames('entries')).contains('recurring_id')) await m.addColumn(entries, entries.recurringId);
    if (!await _schemaObjectExists('index', 'entries_recurring_id')) await m.createIndex(entriesRecurringId);
    await _backfillSmsTransactionKeys();
  }

  /// Gives logged messages without one their transaction key from the stored
  /// parse, so pasting an old SMS again is still recognised.
  Future<void> _backfillSmsTransactionKeys() async {
    final rows = await customSelect('SELECT id, body, parsed_json FROM sms_log WHERE parsed_json IS NOT NULL AND transaction_key IS NULL').get();
    for (final row in rows) {
      final parsed = jsonDecode(row.read<String>('parsed_json')) as Map<String, dynamic>;
      final key = smsTransactionKeyForStored(row.read<String>('body'), parsed);
      if (key == null) continue;
      await customUpdate('UPDATE sms_log SET transaction_key = ? WHERE id = ?', variables: [Variable(key), Variable(row.read<String>('id'))]);
    }
  }

  /// v17 step. Adds the credit card columns a table lacks; pre-release
  /// builds of card dues stored them under schema 7.
  Future<void> _upgradeToCardDetails(Migrator m) async {
    final existing = await _columnNames('accounts');
    for (final column in cardDetailColumns(accounts)) {
      if (!existing.contains(column.name)) await m.addColumn(accounts, column);
    }
  }

  /// v18 step. Adds the payee category memory table unless a pre-release
  /// build of this feature already created it, so it is idempotent.
  Future<void> _upgradeToPayeeCategories(Migrator m) async {
    if (!await _schemaObjectExists('table', 'payee_categories')) await m.createTable(payeeCategories);
  }

  /// v19 step. Adds the People list and fills it from group members that
  /// already carry an email, the most recently edited name winning.
  Future<void> _upgradeToPeople(Migrator m) async {
    await m.createTable(people);
    await customStatement('''
      INSERT OR IGNORE INTO people (id, name, email, updated_at)
      SELECT LOWER(TRIM(email)), name, LOWER(TRIM(email)), updated_at FROM members
      WHERE deleted_at IS NULL AND email IS NOT NULL AND TRIM(email) LIKE '%_@_%._%'
      ORDER BY updated_at DESC
    ''');
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

  /// Deletes every row in every table, then seeds the defaults again, leaving
  /// the database as a fresh install has it. Foreign keys are checked at
  /// commit, so the delete order does not matter.
  Future<void> eraseAllData() => transaction(() async {
        await customStatement('PRAGMA defer_foreign_keys = ON');
        for (final table in allTables) {
          await delete(table).go();
        }
        await seedDefaults();
        await seedQuickEntries();
      });

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

  /// Inserts the starter quick entries when the install never had any
  /// (deleted ones count, so removing them sticks).
  Future<void> seedQuickEntries() async {
    final anyQuickEntry = await (select(quickEntries)..limit(1)).get();
    final seeded = await (select(categories)..where((t) => t.seedKey.isNotNull() & t.deletedAt.isNull())).get();
    final rows = starterQuickEntryRows(
      hasAnyQuickEntry: anyQuickEntry.isNotEmpty,
      categoryIdBySeedKey: {for (final category in seeded) category.seedKey!: category.id},
    );
    await batch((b) {
      for (final row in rows) {
        b.insert(quickEntries, QuickEntriesCompanion.insert(
          id: row.starter.id,
          label: row.starter.label,
          categoryId: Value(row.categoryId),
          sortOrder: Value(row.sortOrder),
        ));
      }
    });
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
          await (update(payeeCategories)..where((t) => t.categoryId.equals(droppedId)))
              .write(PayeeCategoriesCompanion(categoryId: Value(keptId), updatedAt: Value(now)));
          await (update(quickEntries)..where((t) => t.categoryId.equals(droppedId)))
              .write(QuickEntriesCompanion(categoryId: Value(keptId), updatedAt: Value(now)));
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
    final payeeRefs = await _countBy(payeeCategories, payeeCategories.categoryId);
    return [
      for (final category in live)
        SeedCandidate(
          id: category.id,
          key: category.seedKey!,
          references: (entryRefs[category.id] ?? 0) + (budgetRefs[category.id] ?? 0) + (ruleRefs[category.id] ?? 0) + (payeeRefs[category.id] ?? 0),
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

/// The credit card columns added to accounts at schema v12.
List<GeneratedColumn> cardDetailColumns($AccountsTable table) => [
      table.statementDay,
      table.dueDay,
      table.creditLimitMinor,
      table.lastStatementMinor,
      table.lastStatementAt,
    ];

/// Columns v11 added to [Reminders]; a v5..v10 database gains exactly these.
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

/// Columns v14 added to [Reminders]; a v13 database gains exactly these.
List<GeneratedColumn> documentReminderColumns($RemindersTable table) => [table.projectId, table.documentNumber, table.presetKey];
