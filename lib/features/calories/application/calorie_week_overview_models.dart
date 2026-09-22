import 'package:json_annotation/json_annotation.dart';

part 'calorie_week_overview_models.g.dart';

/// Defines calorie week consumption day snapshot.
class CalorieWeekConsumptionDaySnapshot {
  /// The calorie week consumption day snapshot.
  const new({
    required this.date,
    required this.totalKcal,
    required this.entryCount,
  });

  /// The date.
  final DateTime date;

  /// The total kcal.
  final double totalKcal;

  /// The entry count.
  final int entryCount;
}

/// Defines calorie week consumption snapshot.
class CalorieWeekConsumptionSnapshot {
  /// The calorie week consumption snapshot.
  const new({required this.days, required this.totalConsumedKcal});

  /// The days.
  final List<CalorieWeekConsumptionDaySnapshot> days;

  /// The total consumed kcal.
  final double totalConsumedKcal;
}

/// Aggregate data for one visible day in the diary week strip.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieWeekDayOverview {
  /// The calorie week day overview.
  const new({
    required this.date,
    required this.totalKcal,
    required this.goalKcal,
    required this.entryCount,
    double? baseGoalKcal,
    this.activityBonusKcal = 0,
    this.todayActiveKcal = 0,
    this.expectedActivityKcal = 0,
    this.isActivityTrackingActive = false,
    this.isPauseDay = false,
  }) : baseGoalKcal = baseGoalKcal ?? goalKcal;

  /// Creates data from persisted JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$CalorieWeekDayOverviewFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$CalorieWeekDayOverviewToJson(this);

  /// The date.
  final DateTime date;

  /// The total kcal.
  final double totalKcal;

  /// The goal kcal.
  final double goalKcal;

  /// The saved base goal kcal before daily activity adjustment.
  final double baseGoalKcal;

  /// Eatable activity kcal counted toward the day.
  final double activityBonusKcal;

  /// Active energy tracked on this day.
  final int todayActiveKcal;

  /// Expected baseline active calories for this day.
  final double expectedActivityKcal;

  /// Whether activity tracking is active for this day.
  final bool isActivityTrackingActive;

  /// The entry count.
  final int entryCount;

  /// Whether this day is marked as a pause day.
  final bool isPauseDay;

  /// Whether entries exist on this day.
  bool get hasEntries => entryCount > 0;

  /// Kcal counted by Burn Week/carryover math.
  double get countedTotalKcal => isPauseDay ? goalKcal : totalKcal;

  /// Base-goal kcal counted by Burn Week carryover math.
  double get countedBaseTotalKcal => isPauseDay ? baseGoalKcal : totalKcal;

  /// Whether within goal.
  bool get isWithinGoal => isPauseDay || (hasEntries && totalKcal <= goalKcal);

  /// Whether over goal.
  bool get isOverGoal => !isPauseDay && hasEntries && totalKcal > goalKcal;
}

/// Overview for the rolling 7-day diary strip ending at the visible window end.
@JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
class CalorieWeekOverview {
  /// The calorie week overview.
  const new({
    required this.days,
    required this.totalConsumedKcal,
    required this.totalGoalKcal,
    required this.remainingKcal,
    required this.balanceStartDate,
    required this.carryoverBeforeTodayKcal,
    required this.todayFlexibleGoalKcal,
    required this.goalStartsInFuture,
    required this.nextGoalStartDate,
    required this.futureGoalKcal,
  });

  /// Creates data from persisted JSON.
  factory fromJson(Map<String, dynamic> json) =>
      _$CalorieWeekOverviewFromJson(json);

  /// Converts data to persisted JSON.
  Map<String, dynamic> toJson() => _$CalorieWeekOverviewToJson(this);

  /// The days.
  final List<CalorieWeekDayOverview> days;

  /// The total consumed kcal.
  final double totalConsumedKcal;

  /// The total goal kcal.
  final double totalGoalKcal;

  /// The remaining kcal.
  final double remainingKcal;

  /// The balance start date.
  final DateTime balanceStartDate;

  /// The carryover before today kcal.
  final double carryoverBeforeTodayKcal;

  /// The today flexible goal kcal.
  final double todayFlexibleGoalKcal;

  /// Whether official Burn Week and weekly check-in counting starts later.
  final bool goalStartsInFuture;

  /// The next official counting start date.
  final DateTime? nextGoalStartDate;

  /// The active goal kcal shown before official counting starts.
  final double? futureGoalKcal;
}
