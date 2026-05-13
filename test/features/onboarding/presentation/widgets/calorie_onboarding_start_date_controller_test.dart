import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';
import 'package:yamt/features/onboarding/presentation/widgets/onboarding/'
    'calorie_onboarding_start_date_controller.dart';

void main() {
  group('CalorieOnboardingStartDateController', () {
    test('tracks start-date choices and save parameters', () {
      final controller = CalorieOnboardingStartDateController(
        now: DateTime(2026, 5, 13, 10),
      );

      expect(controller.futureGoalStartDate, DateTime(2026, 5, 14));
      expect(controller.hasValidChoice, isFalse);

      controller.updateStartNow(startNow: true);
      expect(controller.startsToday, isTrue);
      expect(controller.hasValidChoice, isFalse);

      controller.updateTodayTracking(CalorieGoalOnboardingTodayTracking.exact);
      expect(controller.hasValidChoice, isTrue);
      expect(controller.countGoalStartDayForLearning(), isTrue);
      expect(controller.catchUpEstimateForSave(), isNull);

      controller
        ..updateTodayTracking(CalorieGoalOnboardingTodayTracking.estimate)
        ..updateCatchUpEstimate(CalorieGoalOnboardingCatchUpEstimate.high);
      expect(controller.countGoalStartDayForLearning(), isFalse);
      expect(
        controller.catchUpEstimateForSave(),
        CalorieGoalOnboardingCatchUpEstimate.high,
      );

      controller.updateFutureGoalStartDate(DateTime(2026, 5, 20, 18));
      expect(controller.startsToday, isFalse);
      expect(controller.todayTrackingChoice, isNull);
      expect(controller.futureGoalStartDate, DateTime(2026, 5, 20));
      expect(controller.countGoalStartDayForLearning(), isNull);
      expect(controller.catchUpEstimateForSave(), isNull);
    });
  });
}
