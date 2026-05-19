import 'package:yamt/features/health/domain/health_connection_models.dart';
import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// Data for the diary activity and weight cards.
class DiaryActivityWeightData {
  /// Creates diary activity and weight data.
  const DiaryActivityWeightData({
    required this.healthAccessState,
    required this.activityKcal,
    required this.activeMinutes,
    required this.profileWeightKg,
    required this.selectedWeightKg,
    required this.hasSelectedDayWeight,
    required this.activityTrend,
    required this.weightTrend,
    required this.weightDays,
  });

  /// Health access state for activity tracking.
  final HealthDataAccessState healthAccessState;

  /// Whether Health data is ready for Activity detail panels.
  bool get hasReadyHealthAccess =>
      healthAccessState == HealthDataAccessState.ready;

  /// Whether the user still needs Health setup.
  bool get needsHealthConnection =>
      healthAccessState != HealthDataAccessState.ready;

  /// Burned kcal for the selected day.
  final int? activityKcal;

  /// Active workout minutes for the selected day.
  final int? activeMinutes;

  /// Profile weight from the calorie calculator.
  final double? profileWeightKg;

  /// Weight for the selected day, falling back to profile weight.
  final double? selectedWeightKg;

  /// Whether the selected day has a real saved weight point.
  final bool hasSelectedDayWeight;

  /// Seven day burned kcal trend.
  final List<double?> activityTrend;

  /// Seven day weight trend.
  final List<double?> weightTrend;

  /// Seven day weight entries.
  final List<DiaryWeightDayData> weightDays;
}

/// One day of weight data for the selected diary window.
class DiaryWeightDayData {
  /// Creates one weight day.
  const DiaryWeightDayData({
    required this.day,
    required this.weightKg,
    required this.hasManualWeight,
    required this.hasAppOwnedHealthWeight,
    required this.healthSample,
  });

  /// The diary day.
  final DateTime day;

  /// The weight for the day.
  final double? weightKg;

  /// Whether the app owns this day as a manual fallback entry.
  final bool hasManualWeight;

  /// Whether this day has a Health Connect entry from this app.
  final bool hasAppOwnedHealthWeight;

  /// Health sample for the day, when available.
  final HealthWeightSample? healthSample;

  /// Whether this weight can be removed by this app.
  bool get canDeleteWeight => hasManualWeight || hasAppOwnedHealthWeight;
}

/// Profile inputs needed for activity and weight estimates.
class DiaryActivityWeightProfile {
  /// Creates activity and weight profile inputs.
  const DiaryActivityWeightProfile({
    required this.weightKg,
    required this.heightCm,
  });

  /// Profile weight in kilograms.
  final double? weightKg;

  /// Profile height in centimeters.
  final double? heightCm;
}
