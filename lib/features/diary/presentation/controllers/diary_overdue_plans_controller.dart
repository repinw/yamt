import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/features/diary/application/diary_plan_days_provider.dart';
import 'package:yamt/features/diary/application/diary_plan_start_day_provider.dart';
import 'package:yamt/features/diary/domain/diary_calendar_bounds.dart';

part 'diary_overdue_plans_controller.g.dart';

const _dismissedKey = 'diary_overdue_plans_dismissed_v1';

/// How many days back the diary looks for plans that were never eaten.
const diaryOverduePlanLookbackDays = 7;

/// The days of the last week before [today] that the calendar can open
/// and whose plans were never eaten or removed, or null when there are none
/// or the user closed the hint for them. Closing hides the hint until a
/// later day has overdue plans; the choice is saved on the device.
@riverpod
class DiaryOverduePlansController extends _$DiaryOverduePlansController {
  @override
  List<DateTime>? build(DateTime today) {
    final day = normalizeLocalDay(today);
    final lookback = addLocalDays(day, -diaryOverduePlanLookbackDays);
    // Only days the calendar can open; it starts at the first goal.
    final selectable = DiaryCalendarBounds.resolve(
      today: day,
      planStartDay: ref.watch(diaryPlanStartDayProvider),
    ).earliestDay;
    final earliest = selectable.isAfter(lookback) ? selectable : lookback;
    final latest = addLocalDays(day, -1);
    if (earliest.isAfter(latest)) {
      return null;
    }
    final planned =
        ref
            .watch(
              diaryPlanDaysProvider(
                DiaryCalendarBounds(earliestDay: earliest, latestDay: latest),
              ),
            )
            .value ??
        const <DateTime>{};
    final days = planned.sorted((a, b) => a.compareTo(b));
    final dismissed = DateTime.tryParse(
      ref.watch(appPreferencesProvider).getStringSync(_dismissedKey) ?? '',
    );
    if (days.isEmpty || (dismissed != null && !days.last.isAfter(dismissed))) {
      return null;
    }
    return days;
  }

  /// Hides the hint until a later day has overdue plans.
  Future<void> dismiss() async {
    final last = state?.last;
    if (last == null) {
      return;
    }
    state = null;
    await ref
        .read(appPreferencesProvider)
        .setString(_dismissedKey, last.toIso8601String());
  }
}
