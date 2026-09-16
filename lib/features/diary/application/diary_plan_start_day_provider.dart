import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/diary/application/diary_weekly_checkin_provider.dart';

part 'diary_plan_start_day_provider.g.dart';

/// First day of the user's plan, or `null` while no plan exists.
@Riverpod(keepAlive: true)
DateTime? diaryPlanStartDay(Ref ref) {
  return ref.watch(diaryCalorieGoalSettingsProvider).value?.firstGoalStartDay;
}
