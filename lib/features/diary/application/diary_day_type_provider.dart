import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

part 'diary_day_type_provider.g.dart';

/// Day type of [day], or `null` while no calorie goal exists.
@riverpod
DiaryDayTypeStatus? diaryDayTypeStatus(Ref ref, DateTime day) {
  final settings = ref.watch(calorieGoalControllerProvider).value;
  if (settings == null || !settings.hasGoal) {
    return null;
  }
  return DiaryDayTypeStatus.fromSettings(settings, day);
}
