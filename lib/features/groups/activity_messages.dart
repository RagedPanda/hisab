import '../../domain/split/group_activity.dart';
import '../../l10n/generated/app_localizations.dart';
import 'member_display.dart';
import 'record_payment_sheet.dart' show paymentMethodLabel;

/// One feed row as text: a headline ("You edited “Dinner”") and the detail
/// lines under it (what it cost, or what changed).
typedef ActivityWords = ({String headline, List<String> details});

/// How the feed turns ids, amounts and dates into words; supplied by the
/// screen so these functions stay pure.
class ActivityFormatters {
  const ActivityFormatters({required this.nameOf, required this.categoryNameOf, required this.money, required this.date, required this.myMemberId});

  /// Short member name, "You" for me.
  final String Function(String memberId) nameOf;

  /// Category name, or a generic word when there is none.
  final String Function(String? categoryId) categoryNameOf;
  final String Function(int amountMinor) money;
  final String Function(DateTime day) date;
  final String? myMemberId;
}

/// The headline and detail lines for one activity row.
ActivityWords activityWords(AppLocalizations l10n, ActivityRecord activity, ActivityFormatters format) {
  final actor = activity.actorMemberId == null ? l10n.you : format.nameOf(activity.actorMemberId!);
  return switch (activity.latest) {
    final PaymentSnapshot payment => (headline: _paymentHeadline(l10n, activity.action, actor), details: _paymentDetails(l10n, activity, payment, format)),
    final ExpenseSnapshot expense => (headline: _expenseHeadline(l10n, activity.action, actor, expenseTitle(expense, format)), details: _expenseDetails(l10n, activity, expense, format)),
    null => activity.subject == ActivitySubject.payment
        ? (headline: _paymentHeadline(l10n, activity.action, actor), details: const <String>[])
        : (headline: _expenseHeadline(l10n, activity.action, actor, l10n.kindExpense), details: const <String>[]),
  };
}

/// What an expense is called in the feed: its description, else its category.
String expenseTitle(ExpenseSnapshot expense, ActivityFormatters format) {
  final description = expenseDescription(expense);
  return description.isNotEmpty ? description : format.categoryNameOf(expense.categoryId);
}

String _expenseHeadline(AppLocalizations l10n, ActivityAction action, String actor, String title) => switch (action) {
      ActivityAction.added => l10n.activityExpenseAdded(actor, title),
      ActivityAction.edited => l10n.activityExpenseEdited(actor, title),
      ActivityAction.deleted => l10n.activityExpenseDeleted(actor, title),
      ActivityAction.restored => l10n.activityExpenseRestored(actor, title),
    };

String _paymentHeadline(AppLocalizations l10n, ActivityAction action, String actor) => switch (action) {
      ActivityAction.added => l10n.activityPaymentAdded(actor),
      ActivityAction.edited => l10n.activityPaymentEdited(actor),
      ActivityAction.deleted => l10n.activityPaymentDeleted(actor),
      ActivityAction.restored => l10n.activityPaymentRestored(actor),
    };

List<String> _expenseDetails(AppLocalizations l10n, ActivityRecord activity, ExpenseSnapshot expense, ActivityFormatters format) =>
    activity.action == ActivityAction.edited
        ? [for (final change in activity.changes) changeLine(l10n, change, format)]
        : [l10n.activityExpenseLine(format.money(expense.amountMinor), _payers(l10n, [for (final payer in expense.payers) payer.memberId], format))];

/// An edited payment names the payment as it is now, then what changed.
List<String> _paymentDetails(AppLocalizations l10n, ActivityRecord activity, PaymentSnapshot payment, ActivityFormatters format) => [
      l10n.activityPaymentLine(format.nameOf(payment.fromMemberId), _objectName(l10n, payment.toMemberId, format), format.money(payment.amountMinor)),
      if (activity.action == ActivityAction.edited)
        for (final change in activity.changes) changeLine(l10n, change, format),
    ];

/// One "Field: before → after" line.
String changeLine(AppLocalizations l10n, ActivityChange change, ActivityFormatters format) => switch (change) {
      AmountChange(:final fromMinor, :final toMinor) => l10n.activityChangeAmount(format.money(fromMinor), format.money(toMinor)),
      DateChange(:final from, :final to) => l10n.activityChangeDate(format.date(from), format.date(to)),
      DescriptionChange(:final from, :final to) => l10n.activityChangeDescription(_orNone(l10n, from), _orNone(l10n, to)),
      CategoryChange(:final fromId, :final toId) => l10n.activityChangeCategory(format.categoryNameOf(fromId), format.categoryNameOf(toId)),
      PayersChange(:final fromMemberIds, :final toMemberIds) => l10n.activityChangePayers(_payers(l10n, fromMemberIds, format), _payers(l10n, toMemberIds, format)),
      ShareChange(:final memberId, :final fromMinor, :final toMinor) => memberId == format.myMemberId
          ? l10n.activityChangeMyShare(format.money(fromMinor), format.money(toMinor))
          : l10n.activityChangeShare(format.nameOf(memberId), format.money(fromMinor), format.money(toMinor)),
      PartiesChange() => l10n.activityChangeParties(
          l10n.activityPartiesPair(format.nameOf(change.fromBefore), _objectName(l10n, change.toBefore, format)),
          l10n.activityPartiesPair(format.nameOf(change.fromAfter), _objectName(l10n, change.toAfter, format)),
        ),
      MethodChange(:final from, :final to) => l10n.activityChangeMethod(paymentMethodLabel(from, l10n), paymentMethodLabel(to, l10n)),
      NoteChange(:final from, :final to) => l10n.activityChangeNote(_orNone(l10n, from), _orNone(l10n, to)),
    };

String _payers(AppLocalizations l10n, List<String> memberIds, ActivityFormatters format) =>
    memberIds.isEmpty ? l10n.activityNone : payerNamesLine(l10n, memberIds, myMemberId: format.myMemberId, nameOf: format.nameOf);

String _orNone(AppLocalizations l10n, String text) => text.isEmpty ? l10n.activityNone : text;

/// A member mid-sentence: "you" in lower case for me, else the name.
String _objectName(AppLocalizations l10n, String memberId, ActivityFormatters format) => memberId == format.myMemberId ? l10n.youInList : format.nameOf(memberId);
