import 'package:json_annotation/json_annotation.dart';
import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calories_json_converters.dart';

part 'pending_calorie_goal_weekly_check_in.g.dart';

// Temporary compatibility, added in 3.4.1: the JSON defaults, unknown enum
// fallbacks, and flexible converters in this file go from 3.7.0 on, once a
// migration has re-saved the stored data in the strict shape.

const _keepValue = Object();

/// Defines pending calorie goal weekly check in.
@JsonSerializable(fieldRename: FieldRename.snake)
class PendingCalorieGoalWeeklyCheckIn {
  /// The pending calorie goal weekly check in.
  const new({
    required this.windowStartDate,
    required this.windowEndDate,
    required this.dueDate,
    this.dismissedAt,
  });

  /// Creates a [PendingCalorieGoalWeeklyCheckIn] from json.
  factory fromJson(Map<String, dynamic> json) =>
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
    return '${localDayKey(windowStartDate)}:${localDayKey(windowEndDate)}';
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
