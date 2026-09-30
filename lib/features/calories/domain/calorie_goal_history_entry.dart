import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/date_time_json_converter.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_source.dart';
import 'package:yamt/features/calories/domain/calorie_goal_weekly_check_in_snapshot.dart';
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
    required this.source,
    this.countingStartDate,
    this.weeklyCheckInSnapshot,
    this.reachedAt,
    this.reachedWeightKg,
    this.reachedPromptHandledAt,
    this.endedAt,
    this.endedWeightKg,
  });

  /// Creates a [CalorieGoalHistoryEntry] from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$CalorieGoalHistoryEntryFromJson(json);

  /// The daily kcal goal.
  final double? dailyKcalGoal;

  /// The calculator profile.
  final CalorieCalculatorProfile? calculatorProfile;

  /// The effective date.
  @DateTimeJsonConverter()
  final DateTime effectiveDate;

  /// The changed at.
  @DateTimeJsonConverter()
  final DateTime? changedAt;

  /// The official counting start date for Burn Week and weekly check-ins.
  @DateTimeJsonConverter()
  final DateTime? countingStartDate;

  /// The source.
  final CalorieGoalSource source;

  /// The weekly check in snapshot.
  final CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot;

  /// First date on which the configured target weight was reached.
  @DateTimeJsonConverter()
  final DateTime? reachedAt;

  /// Scale weight recorded when the target was first reached.
  final double? reachedWeightKg;

  /// Date on which the user answered the goal-reached prompt.
  @DateTimeJsonConverter()
  final DateTime? reachedPromptHandledAt;

  /// Date on which this goal was explicitly replaced by a new goal.
  @DateTimeJsonConverter()
  final DateTime? endedAt;

  /// Scale weight recorded when this goal was replaced.
  final double? endedWeightKg;

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

  /// Returns a copy with the given goal, snapshot, and goal-lifecycle fields
  /// set.
  ///
  /// Only non-null arguments replace the current value.
  CalorieGoalHistoryEntry copyWith({
    double? dailyKcalGoal,
    CalorieCalculatorProfile? calculatorProfile,
    CalorieGoalWeeklyCheckInSnapshot? weeklyCheckInSnapshot,
    DateTime? reachedAt,
    double? reachedWeightKg,
    DateTime? reachedPromptHandledAt,
    DateTime? endedAt,
    double? endedWeightKg,
  }) {
    return CalorieGoalHistoryEntry(
      dailyKcalGoal: dailyKcalGoal ?? this.dailyKcalGoal,
      calculatorProfile: calculatorProfile ?? this.calculatorProfile,
      effectiveDate: effectiveDate,
      changedAt: changedAt,
      countingStartDate: countingStartDate,
      source: source,
      weeklyCheckInSnapshot:
          weeklyCheckInSnapshot ?? this.weeklyCheckInSnapshot,
      reachedAt: reachedAt ?? this.reachedAt,
      reachedWeightKg: reachedWeightKg ?? this.reachedWeightKg,
      reachedPromptHandledAt:
          reachedPromptHandledAt ?? this.reachedPromptHandledAt,
      endedAt: endedAt ?? this.endedAt,
      endedWeightKg: endedWeightKg ?? this.endedWeightKg,
    );
  }
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
