/// What the expense editor holds that a user would lose by leaving: compared
/// against the state the editor opened with to decide whether Back asks
/// "Discard this entry?" (#82). Pure.
library;

import 'dart:convert';

import '../../domain/entries/entry_filter.dart';
import '../../domain/projects/project_fields.dart';
import '../../domain/recurring/repeat_draft.dart';
import '../../domain/split/split_calculator.dart';
import 'item_row.dart';

/// A canonical, comparable form of the editor's input. Two fingerprints are
/// equal exactly when the user has nothing new to lose. Amounts compare by
/// value ("100" and "100.00" match), and empty project field readings count
/// as no reading.
String editorDraftFingerprint({
  required String kind,
  required int? amountMinor,
  required String note,
  required String payee,
  String tags = '',
  required DateTime occurredAt,
  required String? categoryId,
  required String? accountId,
  required String? toAccountId,
  required String? projectId,
  required String? paidByMemberId,
  required bool multiplePayers,
  required Map<String, int> payerAmounts,
  required SplitMethod splitMethod,
  required List<SplitInput> splitInputs,
  required List<ItemDraft> items,
  required Map<String, FieldReading> fieldValues,
  RepeatDraft? repeat,
}) => jsonEncode({
  'kind': kind,
  'amount': amountMinor ?? 0,
  'note': note.trim(),
  'payee': payee.trim(),
  'tags': [for (final tag in parseTags(tags)) tag.toLowerCase()],
  'date': occurredAt.toIso8601String(),
  'category': categoryId,
  'account': accountId,
  'toAccount': toAccountId,
  'project': projectId,
  'paidBy': paidByMemberId,
  'payers': multiplePayers
      ? (payerAmounts.entries.toList()..sort((a, b) => a.key.compareTo(b.key))).map((e) => '${e.key}=${e.value}').toList()
      : null,
  'split': splitMethod.name,
  'splitInputs': [for (final input in splitInputs) '${input.memberId}|${input.included}|${input.amountMinor}|${input.weight}'],
  'items': [for (final item in items) '${item.name.trim()}|${item.quantity}|${item.unit}|${item.unitPriceMinor}'],
  'fields': {
    for (final entry in (fieldValues.entries.where((entry) => !entry.value.isEmpty).toList()..sort((a, b) => a.key.compareTo(b.key))))
      entry.key: '${entry.value.number}|${entry.value.text?.trim()}|${entry.value.date?.toIso8601String()}',
  },
  'repeat': repeat == null
      ? null
      : '${repeat.frequency.name}|${repeat.interval}|${repeat.lastDayOfMonth}|${repeat.end.name}|'
            '${repeat.endDate?.toIso8601String()}|${repeat.maxCount}|${repeat.autoPost}',
});
