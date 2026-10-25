import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/progress/domain/progress_period.dart';
import 'package:yamt/features/progress/domain/progress_tdee.dart';

part 'progress_tdee_provider.g.dart';

/// Daily TDEE of the period of [scope] with its check-ins.
@riverpod
Future<ProgressTdee> progressTdee(Ref ref, ProgressScope scope) async {
  final today = normalizeLocalDay(ref.watch(clockProvider)());
  final settings = await ref.watch(calorieGoalControllerProvider.future);
  final period = ProgressPeriod.of(
    settings: settings,
    scope: scope,
    today: today,
  );
  final points = period.goalStarts.isEmpty
      ? const <TdeeAnalyticsPoint>[]
      : (await ref.watch(
          tdeeAnalyticsProvider(const TdeeAnalyticsQuery(cycleIds: {'all'}))
              .future,
        )).points;
  return ProgressTdee.fromPoints(
    settings: settings,
    period: period,
    points: points,
    today: today,
  );
}
