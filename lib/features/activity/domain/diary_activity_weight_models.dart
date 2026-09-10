import 'package:yamt/features/health/domain/health_weight_sample.dart';

/// Data for the diary weight card.
class DiaryActivityWeightData {
  /// Creates diary weight data.
  const DiaryActivityWeightData({
    required this.profileWeightKg,
    required this.selectedWeightKg,
    required this.hasSelectedDayWeight,
    required this.weightTrend,
    required this.weightDays,
  });

  /// Profile weight from the calorie calculator.
  final double? profileWeightKg;

  /// Weight for the selected day, falling back to profile weight.
  final double? selectedWeightKg;

  /// Whether the selected day has a real saved weight point.
  final bool hasSelectedDayWeight;

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

/// Profile input used as the fallback weight.
class DiaryActivityWeightProfile {
  /// Creates the weight profile input.
  const DiaryActivityWeightProfile({
    required this.weightKg,
  });

  /// Profile weight in kilograms.
  final double? weightKg;
}
