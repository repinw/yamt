import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';

part 'pending_calorie_goal_weekly_check_in.g.dart';

const _keepValue = Object();

/// Defines pending calorie goal weekly check in.
@JsonSerializable(fieldRename: FieldRename.snake)
class PendingCalorieGoalWeeklyCheckIn {
  /// The pending calorie goal weekly check in.
  const PendingCalorieGoalWeeklyCheckIn({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.dueDate,
    this.dismissedAt,
  });

  /// Creates a [PendingCalorieGoalWeeklyCheckIn] from json.
  factory PendingCalorieGoalWeeklyCheckIn.fromJson(Map<String, dynamic> json) =>
      _$PendingCalorieGoalWeeklyCheckInFromJson(json);

  /// The window start date.
  @FlexibleDateTimeConverter()
  final DateTime windowStartDate;

  /// The window end date.
  @FlexibleDateTimeConverter()
  final DateTime windowEndDate;

  /// The due date.
  @FlexibleDateTimeConverter()
  final DateTime dueDate;

  /// The dismissed at.
  @NullableFlexibleDateTimeConverter()
  final DateTime? dismissedAt;

  /// Whether dismissed.
  bool get isDismissed => dismissedAt != null;

  /// The window key.
  String get windowKey {
    return '${diaryDayKey(windowStartDate)}:${diaryDayKey(windowEndDate)}';
  }

  /// Copy with.
  PendingCalorieGoalWeeklyCheckIn copyWith({Object? dismissedAt = _keepValue}) {
    return PendingCalorieGoalWeeklyCheckIn(
      windowStartDate: windowStartDate,
      windowEndDate: windowEndDate,
      dueDate: dueDate,
      dismissedAt: dismissedAt == _keepValue
          ? this.dismissedAt
          : dismissedAt as DateTime?,
    );
  }

  /// To json.
  Map<String, dynamic> toJson() =>
      _$PendingCalorieGoalWeeklyCheckInToJson(this);
}
