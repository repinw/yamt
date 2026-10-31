import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/application/calorie_budget_settings_provider.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';

part 'diary_day_tdee_provider.g.dart';

/// The daily TDEE of a diary day and the base goal of that day, each `null`
/// when there is none.
typedef DiaryDayTdee = ({double? tdeeKcal, double? goalKcal});

/// The daily TDEE estimate in effect on the diary [day] and the day's base
/// goal.
///
/// A day after the newest estimate keeps it, as today keeps yesterday's.
@riverpod
Future<DiaryDayTdee> diaryDayTdee(Ref ref, DateTime day) async {
  final normalizedDay = normalizeLocalDay(day);
  final settings = await ref.watch(calorieBudgetSettingsProvider.future);
  if (!settings.hasGoal) {
    return (tdeeKcal: null, goalKcal: null);
  }
  final analytics = await ref.watch(
    tdeeAnalyticsProvider(const TdeeAnalyticsQuery(cycleIds: {'all'})).future,
  );
  final point = analytics.points.lastWhereOrNull(
    (point) => !point.day.isAfter(normalizedDay),
  );
  return (
    tdeeKcal: point?.learnedBaseTdeeKcal,
    goalKcal: settings.baseGoalEntryForDay(normalizedDay) == null
        ? null
        : settings.baseGoalKcalForDay(normalizedDay),
  );
}
