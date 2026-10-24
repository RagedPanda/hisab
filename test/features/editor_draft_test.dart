import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/projects/project_fields.dart';
import 'package:hisab/domain/recurring/recurrence.dart';
import 'package:hisab/domain/recurring/repeat_draft.dart';
import 'package:hisab/domain/split/split_calculator.dart';
import 'package:hisab/features/expense_editor/editor_draft.dart';
import 'package:hisab/features/expense_editor/item_row.dart';

String fingerprintOf({
  int? amountMinor,
  String note = '',
  String? categoryId,
  Map<String, FieldReading> fieldValues = const {},
  List<ItemDraft> items = const [],
  RepeatDraft? repeat,
}) =>
    editorDraftFingerprint(
      kind: 'expense',
      amountMinor: amountMinor,
      note: note,
      payee: '',
      occurredAt: DateTime(2026, 10, 23),
      categoryId: categoryId,
      accountId: 'cash',
      toAccountId: null,
      projectId: null,
      paidByMemberId: null,
      multiplePayers: false,
      payerAmounts: const {},
      splitMethod: SplitMethod.equal,
      splitInputs: const [],
      items: items,
      fieldValues: fieldValues,
      repeat: repeat,
    );

void main() {
  test('an empty amount and a zero amount are the same draft', () {
    expect(fingerprintOf(amountMinor: null), fingerprintOf(amountMinor: 0));
  });

  test('surrounding spaces in the note are not a change', () {
    expect(fingerprintOf(note: ' chai '), fingerprintOf(note: 'chai'));
  });

  test('an emptied project field reading is not a change', () {
    expect(fingerprintOf(fieldValues: {'km': const FieldReading(text: ' ')}), fingerprintOf());
  });

  test('amount, note, category and items each count as a change', () {
    final blank = fingerprintOf();
    expect(fingerprintOf(amountMinor: 100), isNot(blank));
    expect(fingerprintOf(note: 'chai'), isNot(blank));
    expect(fingerprintOf(categoryId: 'milk'), isNot(blank));
    expect(fingerprintOf(items: [ItemDraft(name: 'Milk', unitPriceMinor: 6000)]), isNot(blank));
  });

  test('choosing or changing Repeat counts as a change', () {
    const monthly = RepeatDraft();
    expect(fingerprintOf(repeat: monthly), isNot(fingerprintOf()));
    expect(fingerprintOf(repeat: const RepeatDraft(frequency: RecurrenceFrequency.weekly)), isNot(fingerprintOf(repeat: monthly)));
    expect(fingerprintOf(repeat: const RepeatDraft()), fingerprintOf(repeat: monthly));
  });
}
