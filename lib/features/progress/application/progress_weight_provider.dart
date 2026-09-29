import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/health/application/recent_weight_trend_provider.dart';
import 'package:yamt/features/progress/domain/progress_weight.dart';

part 'progress_weight_provider.g.dart';

/// Weight trend of the last four weeks with the goal weight and its forecast.
@riverpod
Future<ProgressWeight> progressWeight(Ref ref) async {
  final today = normalizeDiaryDay(ref.watch(clockProvider)());
  final trendFuture = ref.watch(
    recentWeightTrendProvider(dayCount: progressWeightDayCount).future,
  );
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final trend = await trendFuture;
  return ProgressWeight.fromTrend(
    trend: trend,
    profile: settings.calculatorProfile,
    today: today,
  );
}
