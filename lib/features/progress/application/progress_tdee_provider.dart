import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/progress/domain/progress_tdee.dart';

part 'progress_tdee_provider.g.dart';

/// TDEE per confirmed weekly check-in of the current goal.
@riverpod
Future<ProgressTdee> progressTdee(Ref ref) async {
  final today = normalizeDiaryDay(ref.watch(clockProvider)());
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  return ProgressTdee.fromSettings(settings, today);
}
