/// A group's ledger as CSV: one row per expense or payment, in date order,
/// with who paid, each member's share and everyone's running balance.
/// Pure functions; the caller supplies names, labels and wording.
library;

/// A member as a CSV column: their id and the name shown in the header.
typedef ExportMember = ({String id, String name});

/// One expense or payment, already in the words the CSV should show.
///
/// A payment from A to B is a row where A paid the amount and B's share is
/// the amount: it moves both balances exactly as the settlement does.
class ExportRow {
  const ExportRow({
    required this.occurredAt,
    required this.description,
    required this.category,
    required this.costMinor,
    required this.paidMinor,
    required this.shareMinor,
    this.isPayment = false,
  });
  final DateTime occurredAt;
  final String description;
  final String category;
  final int costMinor;

  /// Amount each payer put in, by member id.
  final Map<String, int> paidMinor;

  /// Amount each member owes for this row, by member id.
  final Map<String, int> shareMinor;

  /// A payment between members: it moves balances but is not spending, so
  /// it stays out of the totals.
  final bool isPayment;
}

/// What the group spent overall, and what each member paid and owed of it.
/// Payments between members are left out: they settle debt, they are not
/// spending.
typedef ExpenseTotals = ({int totalMinor, Map<String, int> paidByMember, Map<String, int> shareByMember});

ExpenseTotals expenseTotals(Iterable<ExportRow> rows) {
  var total = 0;
  final paid = <String, int>{};
  final share = <String, int>{};
  for (final row in rows.where((row) => !row.isPayment)) {
    total += row.costMinor;
    row.paidMinor.forEach((id, amount) => paid.update(id, (value) => value + amount, ifAbsent: () => amount));
    row.shareMinor.forEach((id, amount) => share.update(id, (value) => value + amount, ifAbsent: () => amount));
  }
  return (totalMinor: total, paidByMember: paid, shareByMember: share);
}

/// Header words, localised by the caller.
class GroupCsvLabels {
  const GroupCsvLabels({
    required this.date,
    required this.description,
    required this.category,
    required this.cost,
    required this.paidBy,
    required this.paidColumn,
    required this.shareColumn,
    required this.balanceColumn,
    required this.total,
  });
  final String date;
  final String description;
  final String category;
  final String cost;

  /// Header of the readable "Rahul 600.00; Asha 300.00" column.
  final String paidBy;
  final String Function(String memberName) paidColumn;
  final String Function(String memberName) shareColumn;
  final String Function(String memberName) balanceColumn;

  /// Description of the closing total row.
  final String total;
}

/// A row with every member's balance after it (positive = the group owes
/// them), by member id.
typedef RowWithBalances = ({ExportRow row, Map<String, int> balances});

/// [rows] in date order (ties keep their given order), each with the running
/// balance of every member in [memberIds] once that row is applied.
List<RowWithBalances> withRunningBalances(List<ExportRow> rows, Iterable<String> memberIds) {
  final ordered = [for (var index = 0; index < rows.length; index++) (index: index, row: rows[index])]
    ..sort((first, second) {
      final byDate = first.row.occurredAt.compareTo(second.row.occurredAt);
      return byDate != 0 ? byDate : first.index.compareTo(second.index);
    });
  var running = {for (final id in memberIds) id: 0};
  final result = <RowWithBalances>[];
  for (final (index: _, :row) in ordered) {
    running = applyRow(running, row);
    result.add((row: row, balances: running));
  }
  return result;
}

/// [balances] after [row]: payers go up by what they put in, sharers down by
/// their share. Returns a new map.
Map<String, int> applyRow(Map<String, int> balances, ExportRow row) {
  final next = Map<String, int>.of(balances);
  row.paidMinor.forEach((id, amount) => next.update(id, (value) => value + amount, ifAbsent: () => amount));
  row.shareMinor.forEach((id, amount) => next.update(id, (value) => value - amount, ifAbsent: () => -amount));
  return next;
}

/// The whole CSV: a header line, one line per row in date order, then a
/// total line: the group's spend, what each member paid and owed in all,
/// and everyone's final balance.
/// Lines end in CRLF (RFC 4180). Amounts are plain decimals ("-12.50") so
/// spreadsheets read them as numbers.
String buildGroupCsv({required List<ExportMember> members, required List<ExportRow> rows, required GroupCsvLabels labels}) {
  final header = [
    labels.date,
    labels.description,
    labels.category,
    labels.cost,
    labels.paidBy,
    for (final member in members) labels.paidColumn(member.name),
    for (final member in members) labels.shareColumn(member.name),
    for (final member in members) labels.balanceColumn(member.name),
  ].map(csvTextCell);
  final nameById = {for (final member in members) member.id: member.name};
  final ordered = withRunningBalances(rows, members.map((member) => member.id));
  final totals = expenseTotals(rows);
  final finalBalances = ordered.isEmpty ? const <String, int>{} : ordered.last.balances;
  final lines = [
    header.join(','),
    for (final (:row, :balances) in ordered)
      [
        isoDate(row.occurredAt),
        csvTextCell(row.description),
        csvTextCell(row.category),
        decimalAmount(row.costMinor),
        csvTextCell(paidBySummary(row.paidMinor, nameById)),
        for (final member in members) decimalAmount(row.paidMinor[member.id] ?? 0),
        for (final member in members) decimalAmount(row.shareMinor[member.id] ?? 0),
        for (final member in members) decimalAmount(balances[member.id] ?? 0),
      ].join(','),
    [
      '',
      csvTextCell(labels.total),
      '',
      decimalAmount(totals.totalMinor),
      '',
      for (final member in members) decimalAmount(totals.paidByMember[member.id] ?? 0),
      for (final member in members) decimalAmount(totals.shareByMember[member.id] ?? 0),
      for (final member in members) decimalAmount(finalBalances[member.id] ?? 0),
    ].join(','),
  ];
  return '${lines.join('\r\n')}\r\n';
}

/// "Rahul 600.00; Asha 300.00": every payer with what they put in, in the
/// order given. Ids missing from [nameById] are skipped.
String paidBySummary(Map<String, int> paidMinor, Map<String, String> nameById) => [
      for (final MapEntry(key: id, value: amount) in paidMinor.entries)
        if (amount != 0 && nameById[id] != null) '${nameById[id]} ${decimalAmount(amount)}',
    ].join('; ');

/// Minor units as a plain decimal with two places: 123450 -> "1234.50",
/// -5 -> "-0.05".
String decimalAmount(int amountMinor) {
  final sign = amountMinor < 0 ? '-' : '';
  final absolute = amountMinor.abs();
  return '$sign${absolute ~/ 100}.${(absolute % 100).toString().padLeft(2, '0')}';
}

/// yyyy-MM-dd, which every spreadsheet reads as a date.
String isoDate(DateTime when) =>
    '${when.year.toString().padLeft(4, '0')}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';

const _formulaStarts = {'=', '+', '-', '@', '\t', '\r'};

/// A free-text cell, safe to open in a spreadsheet: text a spreadsheet would
/// run as a formula gets a leading apostrophe, and the cell is quoted (with
/// inner quotes doubled) when it holds a comma, quote or line break.
String csvTextCell(String text) {
  final defused = text.isNotEmpty && _formulaStarts.contains(text[0]) ? "'$text" : text;
  return csvEscape(defused);
}

/// RFC 4180 quoting: wrap in double quotes when the value holds a comma,
/// double quote, CR or LF, doubling any inner double quotes.
String csvEscape(String value) {
  final needsQuotes = value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r');
  return needsQuotes ? '"${value.replaceAll('"', '""')}"' : value;
}

/// A filesystem-safe file name for the export, e.g. "goa-trip-2026-10-22.csv".
/// Letters in any script are kept; anything else becomes a dash.
String exportFileName(String groupName, DateTime when) {
  final slug = groupName
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return '${slug.isEmpty ? 'group' : slug}-${isoDate(when)}.csv';
}
