import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'calorie_goal_weekly_check_in_snapshot.g.dart';

const _keepValue = Object();

/// Defines calorie goal weekly check in snapshot.
@JsonSerializable(fieldRename: FieldRename.snake)
class CalorieGoalWeeklyCheckInSnapshot {
  /// The calorie goal weekly check in snapshot.
  const new({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.trendWeightChangePerDay,
    required this.lowConfidence,
    this.measuredTdeeKcal = 0,
    this.calculatedTdeeKcal = 0,
    this.baseGoalKcal = 0,
    this.inputHash,
    this.invalidatedAt,
    this.isRejected = false,
  });

  /// Creates a [CalorieGoalWeeklyCheckInSnapshot] from json.
  factory fromJson(Map<String, dynamic> json) =>
      _$CalorieGoalWeeklyCheckInSnapshotFromJson(json);

  /// The window start date.
  @FlexibleDateTimeConverter()
  final DateTime windowStartDate;

  /// The window end date.
  @FlexibleDateTimeConverter()
  final DateTime windowEndDate;

  /// The trend weight change per day.
  @FlexibleDoubleConverter()
  final double trendWeightChangePerDay;

  /// The measured TDEE kcal from intake and weight trend.
  @FlexibleDoubleConverter()
  final double measuredTdeeKcal;

  /// The smoothed learned TDEE kcal.
  @FlexibleDoubleConverter()
  final double calculatedTdeeKcal;

  /// The base daily goal after target mode and movement cap.
  @FlexibleDoubleConverter()
  final double baseGoalKcal;

  /// The low confidence.
  final bool lowConfidence;

  /// Stable hash of diary inputs used for this snapshot.
  @JsonKey(includeIfNull: false)
  final String? inputHash;

  /// When the snapshot was marked dirty by a later diary edit.
  @JsonKey(includeIfNull: false)
  @NullableFlexibleDateTimeConverter()
  final DateTime? invalidatedAt;

  /// Whether the user rejected this weekly check-in update to keep the
  /// previous TDEE.
  @JsonKey(defaultValue: false)
  final bool isRejected;

  /// Whether inputs changed after this snapshot was saved.
  bool get isInputDirty => invalidatedAt != null;

  /// Whether this snapshot can seed later weekly calculations directly.
  bool get isInputTrusted => inputHash != null && !isInputDirty;

  /// Copy with.
  CalorieGoalWeeklyCheckInSnapshot copyWith({
    Object? inputHash = _keepValue,
    Object? invalidatedAt = _keepValue,
    Object? isRejected = _keepValue,
  }) {
    return CalorieGoalWeeklyCheckInSnapshot(
      windowStartDate: windowStartDate,
      windowEndDate: windowEndDate,
      trendWeightChangePerDay: trendWeightChangePerDay,
      measuredTdeeKcal: measuredTdeeKcal,
      calculatedTdeeKcal: calculatedTdeeKcal,
      baseGoalKcal: baseGoalKcal,
      lowConfidence: lowConfidence,
      inputHash: inputHash == _keepValue
          ? this.inputHash
          : inputHash as String?,
      invalidatedAt: invalidatedAt == _keepValue
          ? this.invalidatedAt
          : invalidatedAt as DateTime?,
      isRejected: isRejected == _keepValue
          ? this.isRejected
          : (isRejected as bool?) ?? false,
    );
  }

  /// To json.
  Map<String, dynamic> toJson() =>
      _$CalorieGoalWeeklyCheckInSnapshotToJson(this);
}
