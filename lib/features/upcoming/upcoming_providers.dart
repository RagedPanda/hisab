/// Riverpod edge of the Upcoming card and due calendar: reads recurring
/// rules, reminders and card dues from the repositories, then hands plain
/// inputs to the pure aggregator in `lib/domain/upcoming`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dates.dart';
import '../../core/providers.dart';
import '../../domain/upcoming/upcoming_items.dart';
import '../dashboard/dashboard_providers.dart';
import 'upcoming_sources.dart';

/// Rows the dashboard card lists before "N more".
const int kUpcomingCardRows = 5;

const String kUpcomingWindowPrefKey = 'upcomingWindow';

/// Today at midnight; overridden in tests.
final upcomingTodayProvider = Provider<DateTime>((ref) => startOfDay(DateTime.now()));

/// The 7 or 30 day toggle on the card, remembered on this device.
class UpcomingWindowNotifier extends Notifier<UpcomingWindow> {
  @override
  UpcomingWindow build() => UpcomingWindow.parse(ref.watch(sharedPreferencesProvider).getString(kUpcomingWindowPrefKey));

  Future<void> select(UpcomingWindow window) async {
    state = window;
    await ref.read(sharedPreferencesProvider).setString(kUpcomingWindowPrefKey, window.name);
  }
}

final upcomingWindowProvider = NotifierProvider<UpcomingWindowNotifier, UpcomingWindow>(UpcomingWindowNotifier.new);

/// Everything the aggregator needs for one date range.
class UpcomingInputs {
  const UpcomingInputs({this.recurring = const [], this.reminders = const [], this.cardDues = const []});
  final List<RecurringOccurrenceInput> recurring;
  final List<ReminderInput> reminders;
  final List<CardDueInput> cardDues;
}

/// A closed-open date window, as a record so it can key a provider family.
typedef UpcomingRange = ({DateTime start, DateTime end});

/// Inputs due before the range end; recurring rules are expanded into their
/// occurrences inside the range, pending reminders come with any overdue ones.
///
/// Card dues are not wired yet: they arrive with the card statement cycle
/// (E1) and plug in here as [UpcomingInputs.cardDues].
final upcomingInputsProvider = Provider.family<AsyncValue<UpcomingInputs>, UpcomingRange>((ref, range) {
  final today = ref.watch(upcomingTodayProvider);
  final monthStartDay = ref.watch(settingsProvider).monthStartDay;
  // Paid and skipped reminders come along so a closed reminder still hides
  // its rule's occurrence for that day; the aggregator never lists them.
  final reminders = combineAsync(
    ref.watch(upcomingRemindersProvider),
    ref.watch(reminderHistoryProvider),
    (pending, closed) => [...pending, ...closed],
  );
  return combineAsync(
    ref.watch(recurringViewsProvider),
    reminders,
    (views, reminders) => UpcomingInputs(
      recurring: recurringOccurrenceInputs(views, today: today, start: range.start, end: range.end, monthStartDay: monthStartDay),
      reminders: reminderInputs(reminders, end: range.end),
    ),
  );
});

/// The range the dashboard card needs for its widest window.
UpcomingRange upcomingCardRange(DateTime today) => (start: today, end: DateTime(today.year, today.month, today.day + UpcomingWindow.month.days + 1));

/// The calendar month around [month].
UpcomingRange upcomingMonthRange(DateTime month) => (start: DateTime(month.year, month.month), end: DateTime(month.year, month.month + 1));

class UpcomingOverview {
  const UpcomingOverview({required this.window, required this.items, required this.summary});
  final UpcomingWindow window;
  final List<UpcomingItem> items;
  final UpcomingSummary summary;

  bool get isEmpty => items.isEmpty;
  List<UpcomingItem> get shown => items.take(kUpcomingCardRows).toList();
  int get more => items.length - shown.length;
}

final upcomingOverviewProvider = Provider<AsyncValue<UpcomingOverview>>((ref) {
  final today = ref.watch(upcomingTodayProvider);
  final window = ref.watch(upcomingWindowProvider);
  return mapAsync(ref.watch(upcomingInputsProvider(upcomingCardRange(today))), (inputs) {
    final items = upcomingWithin(today: today, window: window, recurring: inputs.recurring, reminders: inputs.reminders, cardDues: inputs.cardDues);
    return UpcomingOverview(window: window, items: items, summary: summariseUpcoming(items));
  });
});

/// Items due in one calendar month, for the due calendar. Pass the first of
/// the month so equal months share one provider.
final upcomingMonthProvider = Provider.family<AsyncValue<List<UpcomingItem>>, DateTime>((ref, month) {
  final today = ref.watch(upcomingTodayProvider);
  return mapAsync(
    ref.watch(upcomingInputsProvider(upcomingMonthRange(month))),
    (inputs) => upcomingInMonth(today: today, month: month, recurring: inputs.recurring, reminders: inputs.reminders, cardDues: inputs.cardDues),
  );
});
