import 'package:flutter/material.dart';
import 'package:yamt/features/onboarding/domain/calorie_goal_onboarding_start.dart';

/// State controller for the onboarding goal-start date choice.
class CalorieOnboardingStartDateController extends ChangeNotifier {
  /// Creates start-date controller.
  CalorieOnboardingStartDateController({DateTime? now})
    : _futureGoalStartDate = DateUtils.dateOnly(
        (now ?? DateTime.now()).add(const Duration(days: 1)),
      );

  bool? _startNowChoice;
  CalorieGoalOnboardingTodayTracking? _todayTrackingChoice;
  CalorieGoalOnboardingCatchUpEstimate _catchUpEstimate =
      CalorieGoalOnboardingCatchUpEstimate.normal;
  DateTime _futureGoalStartDate;

  /// Whether user chose start today.
  bool? get startNowChoice => _startNowChoice;

  /// Whether goal starts today.
  bool get startsToday => _startNowChoice == true;

  /// Today's tracking choice.
  CalorieGoalOnboardingTodayTracking? get todayTrackingChoice =>
      _todayTrackingChoice;

  /// Catch-up estimate choice.
  CalorieGoalOnboardingCatchUpEstimate get catchUpEstimate => _catchUpEstimate;

  /// Future goal start date.
  DateTime get futureGoalStartDate => _futureGoalStartDate;

  /// Whether current start-date choice is valid.
  bool get hasValidChoice {
    return switch (_startNowChoice) {
      true => _todayTrackingChoice != null,
      false => true,
      null => false,
    };
  }

  /// Select whether goal starts today.
  void updateStartNow({required bool startNow}) {
    _startNowChoice = startNow;
    if (!startNow) {
      _todayTrackingChoice = null;
    }
    notifyListeners();
  }

  /// Select today's tracking mode.
  void updateTodayTracking(CalorieGoalOnboardingTodayTracking value) {
    _todayTrackingChoice = value;
    notifyListeners();
  }

  /// Select catch-up estimate.
  void updateCatchUpEstimate(CalorieGoalOnboardingCatchUpEstimate value) {
    _catchUpEstimate = value;
    notifyListeners();
  }

  /// Select a future goal start date.
  void updateFutureGoalStartDate(DateTime pickedDate) {
    _startNowChoice = false;
    _todayTrackingChoice = null;
    _futureGoalStartDate = DateUtils.dateOnly(pickedDate);
    notifyListeners();
  }

  /// Resolve goal start date.
  DateTime goalStartDate(DateTime now) {
    return startsToday ? now : _futureGoalStartDate;
  }

  /// Resolve whether goal start day should count for learning.
  bool? countGoalStartDayForLearning() {
    if (!startsToday) {
      return null;
    }
    return _todayTrackingChoice == CalorieGoalOnboardingTodayTracking.exact;
  }

  /// Resolve catch-up estimate for save.
  CalorieGoalOnboardingCatchUpEstimate? catchUpEstimateForSave() {
    if (!startsToday ||
        _todayTrackingChoice != CalorieGoalOnboardingTodayTracking.estimate) {
      return null;
    }
    return _catchUpEstimate;
  }
}
