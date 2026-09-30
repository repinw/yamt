import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_demo_data.dart';
import 'package:yamt/features/calories/application/calorie_weekly_checkin_models.dart';
import 'package:yamt/features/calories/domain/macro_goal_settings.dart';

final _today = DateTime(2026, 9, 30, 10);

void main() {
  test('the demo check-in is ready and ended yesterday', () {
    final data = calorieWeeklyCheckInDemoData(today: _today);

    expect(data.isReady, isTrue);
    expect(data.pendingWeeklyCheckIn!.windowEndDate, DateTime(2026, 9, 29));
    expect(data.days, hasLength(calorieDemoWindowDays));
  });

  test('the blocked demo lacks the end weight', () {
    final data = calorieWeeklyCheckInDemoData(today: _today, blocked: true);

    expect(data.isReady, isFalse);
    expect(
      data.blockedReason,
      CalorieWeeklyCheckInBlockedReason.missingWindowEndWeight,
    );
    expect(data.missingWeightDays, [DateTime(2026, 9, 29)]);
    expect(data.days.last.weightKg, isNull);
  });

  test('the demo plan reviews the demo window and plans from today', () {
    final data = calorieWeeklyCheckInDemoData(today: _today);
    final plan = calorieWeeklyCheckInDemoPlan(
      today: _today,
      macroSettings: const MacroGoalSettings(),
      profile: null,
    );

    expect(plan.reviewedDays.start, data.pendingWeeklyCheckIn!.windowStartDate);
    expect(plan.nextRunDays.first, DateTime(2026, 9, 30));
    expect(plan.suggestedTrainingDays, hasLength(3));
    expect(plan.progress!.weights.last.day, DateTime(2026, 9, 29));
    expect(plan.progress!.tdeePoints, hasLength(3));
  });
}
