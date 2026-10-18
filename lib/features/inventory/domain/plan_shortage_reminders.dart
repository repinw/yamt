import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

/// Notification ids of the day-before reminders: this base plus the plan day
/// as yyyymmdd, so every plan day has one stable id.
const planShortageNotificationIdBase = 100000000;

const _payloadPrefix = 'plan-shortage:';

/// A reminder the day before the plan day that ingredients are missing,
/// with their count.
typedef PlanShortageReminder = ({DateTime day, DateTime at, int count});

/// The notification id of the reminder for [day].
int planShortageNotificationId(DateTime day) =>
    planShortageNotificationIdBase +
    day.year * 10000 +
    day.month * 100 +
    day.day;

/// Whether [id] belongs to a day-before reminder.
bool isPlanShortageNotificationId(int id) =>
    id >= planShortageNotificationIdBase &&
    id < 2 * planShortageNotificationIdBase;

/// The reminders for the plan days in [missingByDay] (missing ingredient
/// count per local day): each fires the day before at [minuteOfDay]. Days
/// in [quietDays], days without missing ingredients, and reminders whose
/// time passed more than an hour before [now] get none. A reminder that
/// passed within the hour stays, because Android may still be holding it
/// back to save battery.
List<PlanShortageReminder> planShortageReminders(
  Map<DateTime, int> missingByDay, {
  required DateTime now,
  required int minuteOfDay,
  required Set<DateTime> quietDays,
}) {
  final reminders = <PlanShortageReminder>[];
  for (final MapEntry(key: day, value: count) in missingByDay.entries) {
    final planDay = normalizeLocalDay(day);
    if (count <= 0 || quietDays.contains(planDay)) {
      continue;
    }
    final dayBefore = previousLocalDay(planDay);
    final at = DateTime(
      dayBefore.year,
      dayBefore.month,
      dayBefore.day,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );
    if (at.isAfter(now.subtract(const Duration(hours: 1)))) {
      reminders.add((day: planDay, at: at, count: count));
    }
  }
  reminders.sort((a, b) => a.day.compareTo(b.day));
  return reminders;
}

/// The missing ingredient count per plan day.
Map<DateTime, int> missingByDay(List<ShoppingPlanNeedGroup> groups) {
  final counts = <DateTime, int>{};
  for (final group in groups) {
    final day = normalizeLocalDay(group.day);
    counts[day] = (counts[day] ?? 0) + group.needs.length;
  }
  return counts;
}

/// The tap payload of the reminder for the plan [day].
String planShortageReminderPayload(DateTime day) =>
    '$_payloadPrefix${localDayKey(day)}';

/// The plan day a tap [payload] names; null for other notifications.
DateTime? planShortageReminderDay(String payload) {
  if (!payload.startsWith(_payloadPrefix)) {
    return null;
  }
  return parseLocalDayKey(payload.substring(_payloadPrefix.length));
}
