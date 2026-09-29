import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/daily_nutrition_target_resolver_service.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_queries.dart';
import 'package:yamt/features/health/application/recent_weight_trend_provider.dart';
import 'package:yamt/features/progress/domain/progress_goal.dart';

part 'progress_goal_provider.g.dart';

/// The current goal with the weight that counts now and today's targets.
@riverpod
Future<ProgressGoal> progressGoal(Ref ref) async {
  final now = ref.watch(clockProvider)();
  final resolver = ref.watch(dailyNutritionTargetResolverProvider);
  final trendFuture = ref.watch(recentWeightTrendProvider().future);
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final trend = await trendFuture;
  final goalKcal = settings.hasGoal ? settings.baseGoalKcalForDay(now) : null;
  return ProgressGoal(
    profile: settings.calculatorProfile,
    currentWeightKg: trend.trendWeightKg ?? trend.latestWeighInKg,
    dailyKcalGoal: goalKcal,
    macroTarget: goalKcal == null
        ? null
        : resolver.resolveBaseTarget(day: now, goalKcal: goalKcal),
  );
}
