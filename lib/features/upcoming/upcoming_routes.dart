import '../../domain/upcoming/upcoming_items.dart';

/// Route of the due calendar screen.
const String kUpcomingCalendarRoute = '/upcoming/calendar';

/// Where tapping an upcoming item goes: the screen that owns its source.
String upcomingItemRoute(UpcomingItem item) => switch (item.source) {
  UpcomingSource.recurring => '/recurring/${item.sourceId}',
  UpcomingSource.reminder => '/reminders/${item.sourceId}',
  UpcomingSource.cardDue => '/accounts',
};
