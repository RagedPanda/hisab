import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../data/db/database.dart';
import '../../data/repositories/groups_repository.dart';
import '../../domain/split/debt_simplifier.dart';
import '../../domain/split/group_export.dart';
import '../../l10n/category_names.dart';
import '../../l10n/generated/app_localizations.dart';
import 'member_display.dart';

/// Byte-order mark so spreadsheet apps (Excel in particular) read the file
/// as UTF-8 and show Hindi or emoji names correctly.
const _utf8Bom = '﻿';

/// Writes a CSV to a temporary file and opens the system share sheet with
/// it. Returns true unless the person dismissed the sheet.
final csvFileSharerProvider = Provider<Future<bool> Function({required String fileName, required String csv, required String subject})>(
  (ref) => ({required fileName, required csv, required subject}) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString('$_utf8Bom$csv', flush: true);
    final result = await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: 'text/csv')], subject: subject));
    return result.status != ShareResultStatus.dismissed;
  },
);

/// The CSV header words in the current language.
GroupCsvLabels groupCsvLabels(AppLocalizations l10n) => GroupCsvLabels(
      date: l10n.groupCsvDate,
      description: l10n.groupCsvDescription,
      category: l10n.category,
      cost: l10n.groupCsvCost,
      paidBy: l10n.groupCsvPaidBy,
      paidColumn: l10n.groupCsvPaidColumn,
      shareColumn: l10n.groupCsvShareColumn,
      balanceColumn: l10n.groupCsvBalanceColumn,
    );

/// Every member the export needs a column for: current members (me first),
/// then removed members who still appear in an expense or payment.
List<ExportMember> exportMembers(AppLocalizations l10n, GroupDetail detail, List<ExportRow> rows) {
  final referenced = {
    for (final row in rows) ...[...row.paidMinor.keys, ...row.shareMinor.keys],
  };
  final currentIds = {for (final member in detail.members) member.id};
  return [
    for (final member in detail.members) (id: member.id, name: memberDisplayName(l10n, member)),
    for (final member in detail.allMembers)
      if (!currentIds.contains(member.id) && referenced.contains(member.id)) (id: member.id, name: member.name),
  ];
}

/// The group's expenses and payments as CSV rows, in the current language.
List<ExportRow> exportRows(
  AppLocalizations l10n,
  GroupDetail detail, {
  required Map<String, Category> categoryById,
  required Locale locale,
}) {
  final nameById = {for (final member in detail.allMembers) member.id: memberShortName(l10n, member)};
  String nameOf(String id) => nameById[id] ?? l10n.unknown;
  return [
    for (final (entry, _, _) in detail.entries)
      if (detail.timelineByEntryId[entry.id] case final timeline?)
        () {
          final category = entry.categoryId == null ? null : categoryById[entry.categoryId];
          final categoryName = category == null ? '' : categoryDisplayName(category, locale);
          final description = entry.note.isNotEmpty ? entry.note : (entry.payee ?? (categoryName.isEmpty ? l10n.kindExpense : categoryName));
          return ExportRow(
            occurredAt: entry.occurredAt,
            description: description,
            category: categoryName,
            costMinor: entry.amountMinor,
            paidMinor: timeline.paidMinor,
            shareMinor: timeline.shareMinor,
          );
        }(),
    for (final settlement in detail.settlements)
      ExportRow(
        occurredAt: settlement.occurredAt,
        description: [
          l10n.settlementLine(nameOf(settlement.fromMemberId), nameOf(settlement.toMemberId)),
          if (settlement.note.isNotEmpty) settlement.note,
        ].join(' · '),
        category: l10n.groupCsvPayment,
        costMinor: settlement.amountMinor,
        paidMinor: {settlement.fromMemberId: settlement.amountMinor},
        shareMinor: {settlement.toMemberId: settlement.amountMinor},
      ),
  ];
}

/// The whole group as CSV text, ready to write to a file.
String groupCsv(AppLocalizations l10n, GroupDetail detail, {required Map<String, Category> categoryById, required Locale locale}) {
  final rows = exportRows(l10n, detail, categoryById: categoryById, locale: locale);
  return buildGroupCsv(members: exportMembers(l10n, detail, rows), rows: rows, labels: groupCsvLabels(l10n));
}

/// A plain-text summary of who owes whom that pastes cleanly into WhatsApp:
/// a bold title, one line per suggested payment, then where each member
/// stands overall. [nameOf] resolves member ids; [myMemberId] switches the
/// wording to "You owe" / "owes you".
String groupSummaryText(
  AppLocalizations l10n, {
  required String groupName,
  required List<Transfer> transfers,
  required Map<String, int> net,
  required List<String> memberOrder,
  required String? myMemberId,
  required String Function(String memberId) nameOf,
  required String symbol,
}) {
  String money(int amountMinor) => formatMinor(amountMinor, symbol: symbol);
  String transferLine(Transfer transfer) {
    if (transfer.from == myMemberId) return l10n.groupSummaryYouOwe(nameOf(transfer.to), money(transfer.amountMinor));
    if (transfer.to == myMemberId) return l10n.groupSummaryOwesYou(nameOf(transfer.from), money(transfer.amountMinor));
    return l10n.owesLine(nameOf(transfer.from), nameOf(transfer.to), money(transfer.amountMinor));
  }

  String standingLine(String memberId, int balance) {
    final isMe = memberId == myMemberId;
    if (balance > 0) return isMe ? l10n.groupSummaryYouGetBack(money(balance)) : l10n.groupSummaryGetsBack(nameOf(memberId), money(balance));
    return isMe ? l10n.groupSummaryYouOweInTotal(money(-balance)) : l10n.groupSummaryOwesInTotal(nameOf(memberId), money(-balance));
  }

  final title = '*${l10n.shareHeader(groupName)}*';
  final footer = l10n.sharedFromHisab;
  if (transfers.isEmpty) return '$title\n${l10n.allSettledUp}\n\n$footer';
  final standings = [
    for (final memberId in memberOrder)
      if ((net[memberId] ?? 0) != 0) '• ${standingLine(memberId, net[memberId]!)}',
  ];
  return [
    title,
    '',
    '*${l10n.groupSummaryWhoPaysWhom}*',
    for (final transfer in transfers) '• ${transferLine(transfer)}',
    '',
    '*${l10n.groupSummaryStandings}*',
    ...standings,
    '',
    footer,
  ].join('\n');
}

/// [groupSummaryText] for the group on screen.
String groupSummaryFor(AppLocalizations l10n, GroupDetail detail, {required String symbol}) {
  final nameById = {for (final member in detail.allMembers) member.id: memberShortName(l10n, member)};
  return groupSummaryText(
    l10n,
    groupName: detail.group.name,
    transfers: detail.balances.suggested,
    net: detail.balances.net,
    memberOrder: [
      for (final member in detail.members) member.id,
      for (final member in detail.allMembers)
        if (!detail.members.contains(member)) member.id,
    ],
    myMemberId: detail.me?.id,
    nameOf: (id) => nameById[id] ?? l10n.unknown,
    symbol: symbol,
  );
}
