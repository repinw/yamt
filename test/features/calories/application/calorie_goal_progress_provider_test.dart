import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_goal_progress_provider.dart';
import 'package:yamt/features/calories/application/tdee_analytics_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_history.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_models.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_time_range.dart';

class _FakeCalorieGoalController extends CalorieGoalController {
  new(this.settings);

  final CalorieGoalSettings settings;

  @override
  FutureOr<CalorieGoalSettings> build() => settings;
}

void main() {
  test('takes the goal of the end date, not a newer one', () async {
    final settings =
        CalorieGoalSettings.single(
          dailyKcalGoal: 2000,
          calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
            goalMode: CalorieGoalMode.lose,
            weightKg: 85,
            targetWeightKg: 75,
          ),
          effectiveDate: DateTime(2025),
        ).applyGoalChange(
          changedAt: DateTime(2025, 2),
          dailyKcalGoal: 2500,
          calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
            goalMode: CalorieGoalMode.maintain,
            weightKg: 75,
          ),
        );
    final queries = <TdeeAnalyticsQuery>[];
    final container = ProviderContainer(
      overrides: [
        calorieGoalControllerProvider.overrideWith(
          () => _FakeCalorieGoalController(settings),
        ),
        tdeeAnalyticsProvider.overrideWith((ref, query) async {
          queries.add(query);
          return TdeeAnalyticsState(
            selectedCycles: const [],
            availableCycles: const [],
            timeRange: TdeeAnalyticsTimeRange.all,
            points: [
              TdeeAnalyticsPoint(
                day: DateTime(2025, 1, 10),
                scaleWeightKg: 84,
                trendWeightKg: 84.2,
              ),
              TdeeAnalyticsPoint(day: DateTime(2025, 1, 25), trendWeightKg: 83),
            ],
            summary: const TdeeAnalyticsSummary(
              averageTdeeKcal: 0,
              tdeeDifferenceKcal: 0,
              threeDayDeltaKcal: 0,
              sevenDayDeltaKcal: 0,
              fourteenDayDeltaKcal: 0,
              currentWeightKg: 83,
              weightChangeKg: 0,
              weeklyRateKg: 0,
            ),
          );
        }),
      ],
    );
    addTearDown(container.dispose);
    final provider = calorieGoalProgressProvider(DateTime(2025, 1, 20));
    final subscription = container.listen(provider, (_, _) {});
    addTearDown(subscription.close);

    final progress = (await container.read(provider.future))!;

    expect(progress.startDate, DateTime(2025));
    expect(progress.startWeightKg, 85);
    expect(progress.targetWeightKg, 75);
    expect(progress.weights.map((weight) => weight.day), [
      DateTime(2025, 1, 10),
    ]);
    expect(queries.single.cycleIds.single, isNot('all'));
  });
}
