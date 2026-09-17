import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'calorie_goal_history_entry.g.dart';

/// Defines calorie goal history entry.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieGoalHistoryEntry {
  /// The calorie goal history entry.
  const new({
    required this.dailyKcalGoal,
    required this.calculatorProfile,
    required this.effectiveDate,
    required this.changedAt,
    this.expectedActivityKcal,
    this.countingStartDate,
    this.source = CalorieGoalSource.manual,
    this.weeklyCheckInSnapshot,
  });

  /// Creates a [CalorieGoalHistoryEntry] from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$CalorieGoalHistoryEntryFromJson(json);

  /// The daily kcal goal.
  @NullableFlexibleDoubleConverter()
  final double? dailyKcalGoal;

  /// The calculator profile.
  final CalorieCalculatorProfile? calculatorProfile;

  /// Expected daily activity kcal for this goal snapshot.
  @NullableFlexibleDoubleConverter()
  final double? expectedActivityKcal;

  /// The effective date.
  @FlexibleDateTimeConverter()
  final DateTime effectiveDate;

  /// The changed at.
  @NullableFlexibleDateTimeConverter()
  final DateTime? changedAt;

  /// The official counting start date for Burn Week and weekly check-ins.
  @NullableFlexibleDateTimeConverter()
  final DateTime? countingStartDate;

  @JsonKey(
    defaultValue: CalorieGoalSource.manual,
    unknownEnumValue: CalorieGoalSource.manual,
  )
  /// The source.
  final CalorieGoalSource source;

  /// The weekly check in snapshot.
  final CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot;

  /// Whether goal is set.
  bool get hasGoal => dailyKcalGoal != null;

  /// The effective changed at.
  DateTime get effectiveChangedAt => changedAt ?? effectiveDate;

  /// The effective counting start date.
  DateTime get effectiveCountingStartDate {
    return resolveNormalizedCountingStartDate(
      effectiveDate: effectiveDate,
      countingStartDate: countingStartDate,
    );
  }

  /// Whether weekly check in.
  bool get isWeeklyCheckIn => source == CalorieGoalSource.weeklyCheckIn;

  /// Whether learned tdee is present and valid.
  bool get hasLearnedTdee => learnedTdeeSnapshot != null;

  /// The learned TDEE snapshot if its inputs are still valid and not rejected.
  CalorieGoalWeeklyCheckInSnapshot? get learnedTdeeSnapshot {
    final snapshot = weeklyCheckInSnapshot;
    if (snapshot == null || snapshot.isInputDirty || snapshot.isRejected) {
      return null;
    }
    return snapshot;
  }

  /// To json.
  Map<String, dynamic> toJson() => _$CalorieGoalHistoryEntryToJson(this);
}

/// Normalizes counting start date against effective date.
DateTime resolveNormalizedCountingStartDate({
  required DateTime effectiveDate,
  DateTime? countingStartDate,
}) {
  final normalizedEffectiveDate = normalizeDiaryDay(effectiveDate);
  final normalizedCountingStartDate = normalizeDiaryDay(
    countingStartDate ?? effectiveDate,
  );
  if (normalizedCountingStartDate.isBefore(normalizedEffectiveDate)) {
    return normalizedEffectiveDate;
  }
  return normalizedCountingStartDate;
}
