import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';

part 'diary_plan_start_day_provider.g.dart';

/// First day of the user's plan, or `null` while no plan exists.
@riverpod
DateTime? diaryPlanStartDay(Ref ref) {
  return ref.watch(calorieGoalControllerProvider).value?.firstGoalStartDay;
}
