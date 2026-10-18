import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/activity/domain/diary_activity_weight_models.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/weight_series_provider.dart';

part 'diary_activity_weight_data_provider.g.dart';

/// Provides weight data for the seven days that end on [day], from the
/// weights of all devices.
@riverpod
Future<DiaryActivityWeightData> diaryActivityWeightData(
  Ref ref,
  DateTime day,
) async {
  final keepAliveLink = ref.keepAlive();
  try {
    final selectedDay = normalizeDiaryDay(day);
    final goalState = ref.watch(calorieGoalControllerProvider);
    final weightByDay = (await ref.watch(weightSeriesProvider.future)).rawByDay;
    return DiaryActivityWeightData(
      profileWeightKg: goalState.value?.calculatorProfile?.weightKg,
      hasSelectedDayWeight: weightByDay.containsKey(diaryDayKey(selectedDay)),
      weightTrend: [
        for (var offset = -6; offset <= 0; offset++)
          weightByDay[diaryDayKey(addDiaryDays(selectedDay, offset))],
      ],
    );
  } finally {
    keepAliveLink.close();
  }
}
