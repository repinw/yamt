import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:yamt/core/preferences/app_preferences.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/application/calorie_goal_progress_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_plan_provider.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_provider.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

import '../../../helpers/memory_app_preferences.dart';

class _FakeCalorieGoalController extends CalorieGoalController {
  new(this.settings);

  final CalorieGoalSettings settings;

  @override
  FutureOr<CalorieGoalSettings> build() => settings;
}

// 2026-09-01 is a Tuesday; the runs start on it and every seven days after.
final _goalStart = DateTime(2026, 9);
final _today = DateTime(2026, 9, 15, 9);

CalorieGoalSettings _settings() {
  return CalorieGoalSettings.single(
    dailyKcalGoal: 2000,
    calculatorProfile: const CalorieCalculatorProfile.defaults().copyWith(
      trainingWeekdays: [DateTime.monday, DateTime.thursday],
      trainingDayKcalOffset: 300,
    ),
    effectiveDate: _goalStart,
  );
}

ProviderContainer _container(CalorieWeeklyCheckInData data) {
  final container = ProviderContainer(
    overrides: [
      appPreferencesProvider.overrideWithValue(MemoryAppPreferences()),
      clockProvider.overrideWithValue(() => _today),
      calorieGoalControllerProvider.overrideWith(
        () => _FakeCalorieGoalController(_settings()),
      ),
      calorieWeeklyCheckInDataProvider.overrideWith((ref) async => data),
      calorieGoalProgressProvider.overrideWith((ref, endDate) async => null),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test(
    'plans the run of today with the weekdays of the reviewed run',
    () async {
      final data = calorieWeeklyCheckInDemoData(today: DateTime(2026, 9, 15));
      final container = _container(data);
      final subscription = container.listen(
        calorieWeeklyCheckInPlanProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);

      final plan = await container.read(
        calorieWeeklyCheckInPlanProvider.future,
      );

      expect(plan, isNotNull);
      expect(plan!.reviewedRunNumber, 2);
      expect(plan.nextRunDays.first, DateTime(2026, 9, 15));
      expect(plan.suggestedTrainingDays, {
        DateTime(2026, 9, 17),
        DateTime(2026, 9, 21),
      });
      expect(plan.sessionKcal, 300);
      expect(plan.previousGoalKcal, 2000);
      expect(plan.measurement!.goalKcal, data.calculation!.newGoalKcal);
    },
  );

  test('has no plan without a pending check-in', () async {
    final data = calorieWeeklyCheckInDemoData(today: DateTime(2026, 9, 15));
    final container = _container(
      CalorieWeeklyCheckInData(
        pendingWeeklyCheckIn: null,
        shouldAutoOpen: false,
        days: data.days,
        calculation: null,
        blockedReason: null,
        missingIntakeDays: const [],
        missingWeightDays: const [],
        freshness: CalorieLearnedTdeeFreshness.fresh,
        latestLearnedTdeeAt: null,
        lowConfidence: false,
      ),
    );
    final subscription = container.listen(
      calorieWeeklyCheckInPlanProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);

    expect(
      await container.read(calorieWeeklyCheckInPlanProvider.future),
      isNull,
    );
  });
}
