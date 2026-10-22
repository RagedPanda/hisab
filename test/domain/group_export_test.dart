import 'package:flutter_test/flutter_test.dart';
import 'package:hisab/domain/split/group_export.dart';

GroupCsvLabels get labels => GroupCsvLabels(
      date: 'Date',
      description: 'Description',
      category: 'Category',
      cost: 'Cost',
      paidBy: 'Paid by',
      paidColumn: (name) => '$name paid',
      shareColumn: (name) => '$name share',
      balanceColumn: (name) => '$name balance',
    );

ExportRow row(DateTime when, String description, int cost, Map<String, int> paid, Map<String, int> share, {String category = 'Food'}) =>
    ExportRow(occurredAt: when, description: description, category: category, costMinor: cost, paidMinor: paid, shareMinor: share);

List<String> linesOf(String csv) => csv.split('\r\n')..removeLast();

void main() {
  group('csvEscape', () {
    test('leaves plain text alone', () => expect(csvEscape('Dinner'), 'Dinner'));
    test('quotes commas', () => expect(csvEscape('Dinner, drinks'), '"Dinner, drinks"'));
    test('doubles inner quotes', () => expect(csvEscape('The "best" dosa'), '"The ""best"" dosa"'));
    test('quotes line breaks', () {
      expect(csvEscape('line one\nline two'), '"line one\nline two"');
      expect(csvEscape('a\r\nb'), '"a\r\nb"');
    });
  });

  group('csvTextCell', () {
    test('defuses text a spreadsheet would run as a formula', () {
      expect(csvTextCell('=SUM(A1:A3)'), "'=SUM(A1:A3)");
      expect(csvTextCell('+91 98765'), "'+91 98765");
      expect(csvTextCell('-refund'), "'-refund");
      expect(csvTextCell('@home'), "'@home");
    });
    test('defuses then quotes', () => expect(csvTextCell('=1,2'), '"\'=1,2"'));
    test('empty stays empty', () => expect(csvTextCell(''), ''));
  });

  group('decimalAmount', () {
    test('whole and fractional', () {
      expect(decimalAmount(0), '0.00');
      expect(decimalAmount(5), '0.05');
      expect(decimalAmount(123450), '1234.50');
    });
    test('negative', () {
      expect(decimalAmount(-5), '-0.05');
      expect(decimalAmount(-90000), '-900.00');
    });
  });

  test('isoDate pads month and day', () => expect(isoDate(DateTime(2026, 3, 7, 22, 15)), '2026-03-07'));

  group('withRunningBalances', () {
    test('orders by date, keeps the given order on ties, and accumulates', () {
      final rows = [
        row(DateTime(2026, 10, 3), 'Taxi', 600, {'b': 600}, {'a': 300, 'b': 300}),
        row(DateTime(2026, 10, 1), 'Dinner', 900, {'a': 900}, {'a': 300, 'b': 300, 'c': 300}),
        row(DateTime(2026, 10, 3), 'Payment', 300, {'c': 300}, {'a': 300}),
      ];
      final result = withRunningBalances(rows, ['a', 'b', 'c']);
      expect(result.map((entry) => entry.row.description), ['Dinner', 'Taxi', 'Payment']);
      expect(result[0].balances, {'a': 600, 'b': -300, 'c': -300});
      expect(result[1].balances, {'a': 300, 'b': 0, 'c': -300});
      expect(result[2].balances, {'a': 0, 'b': 0, 'c': 0});
    });

    test('does not change earlier snapshots', () {
      final result = withRunningBalances([
        row(DateTime(2026, 1, 1), 'One', 200, {'a': 200}, {'a': 100, 'b': 100}),
        row(DateTime(2026, 1, 2), 'Two', 200, {'a': 200}, {'a': 100, 'b': 100}),
      ], ['a', 'b']);
      expect(result.first.balances, {'a': 100, 'b': -100});
      expect(result.last.balances, {'a': 200, 'b': -200});
    });

    test('empty ledger', () => expect(withRunningBalances(const [], ['a']), isEmpty));
  });

  group('buildGroupCsv', () {
    const members = [(id: 'a', name: 'You'), (id: 'b', name: 'Rahul')];

    test('header lists paid, share and balance columns per member', () {
      final csv = buildGroupCsv(members: members, rows: const [], labels: labels);
      expect(linesOf(csv), ['Date,Description,Category,Cost,Paid by,You paid,Rahul paid,You share,Rahul share,You balance,Rahul balance']);
      expect(csv.endsWith('\r\n'), isTrue);
    });

    test('one payer', () {
      final csv = buildGroupCsv(members: members, rows: [row(DateTime(2026, 10, 1), 'Dinner', 90000, {'a': 90000}, {'a': 45000, 'b': 45000})], labels: labels);
      expect(linesOf(csv)[1], '2026-10-01,Dinner,Food,900.00,You 900.00,900.00,0.00,450.00,450.00,450.00,-450.00');
    });

    test('several payers are listed in the paid-by column and each paid column', () {
      final three = [...members, (id: 'c', name: 'Asha')];
      final csv = buildGroupCsv(
        members: three,
        rows: [row(DateTime(2026, 10, 2), 'Hotel', 90000, {'b': 60000, 'c': 30000}, {'a': 30000, 'b': 30000, 'c': 30000}, category: 'Stay')],
        labels: labels,
      );
      expect(linesOf(csv)[1], '2026-10-02,Hotel,Stay,900.00,Rahul 600.00; Asha 300.00,0.00,600.00,300.00,300.00,300.00,300.00,-300.00,300.00,0.00');
    });

    test('unicode names and descriptions pass through, escaped where needed', () {
      const hindi = [(id: 'a', name: 'आप'), (id: 'b', name: 'राहुल, "R"')];
      final csv = buildGroupCsv(
        members: hindi,
        rows: [row(DateTime(2026, 10, 4), 'चाय 🍵, समोसा', 4000, {'b': 4000}, {'a': 2000, 'b': 2000}, category: 'खाना')],
        labels: labels,
      );
      final lines = linesOf(csv);
      expect(lines[0], 'Date,Description,Category,Cost,Paid by,आप paid,"राहुल, ""R"" paid",आप share,"राहुल, ""R"" share",आप balance,"राहुल, ""R"" balance"');
      expect(lines[1], '2026-10-04,"चाय 🍵, समोसा",खाना,40.00,"राहुल, ""R"" 40.00",0.00,40.00,20.00,20.00,-20.00,20.00');
    });

    test('a description with a line break stays one CSV record', () {
      final csv = buildGroupCsv(members: members, rows: [row(DateTime(2026, 10, 5), 'Groceries\nand milk', 100, {'a': 100}, {'b': 100})], labels: labels);
      expect(csv, contains('"Groceries\nand milk"'));
      expect(linesOf(csv), hasLength(2));
    });

    test('a payment row settles the running balance to zero', () {
      final csv = buildGroupCsv(
        members: members,
        rows: [
          row(DateTime(2026, 10, 1), 'Dinner', 1000, {'a': 1000}, {'a': 500, 'b': 500}),
          row(DateTime(2026, 10, 2), 'Rahul paid You', 500, {'b': 500}, {'a': 500}, category: 'Payment'),
        ],
        labels: labels,
      );
      expect(linesOf(csv)[2], endsWith(',0.00,0.00'));
    });
  });

  test('paidBySummary skips unknown and zero payers', () {
    expect(paidBySummary({'a': 100, 'x': 50, 'b': 0}, {'a': 'You', 'b': 'Rahul'}), 'You 1.00');
  });

  group('exportFileName', () {
    test('slugs the group name', () => expect(exportFileName('Goa Trip 2026!', DateTime(2026, 10, 22)), 'goa-trip-2026-2026-10-22.csv'));
    test('keeps Devanagari', () => expect(exportFileName('गोवा यात्रा', DateTime(2026, 10, 22)), 'गोवा-यात्रा-2026-10-22.csv'));
    test('falls back when nothing is left', () => expect(exportFileName('***', DateTime(2026, 1, 2)), 'group-2026-01-02.csv'));
  });
}
