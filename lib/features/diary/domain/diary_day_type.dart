import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';

/// Activity type of a single diary day.
enum DiaryDayType {
  /// Scheduled or manually marked training day.
  training,

  /// Regular rest day.
  rest,

  /// Neutral pause day (vacation, illness).
  pause,
}

/// Day type of a diary day together with the data its picker displays.
class DiaryDayTypeStatus {
  /// Creates a day type status.
  const DiaryDayTypeStatus({
    required this.type,
    required this.trainingDayKcalOffset,
  });

  /// Resolves the status of [day] from calorie goal [settings].
  factory DiaryDayTypeStatus.fromSettings(
    CalorieGoalSettings settings,
    DateTime day,
  ) {
    return DiaryDayTypeStatus(
      type: settings.isPauseDay(day)
          ? DiaryDayType.pause
          : settings.isTrainingDay(day)
          ? DiaryDayType.training
          : DiaryDayType.rest,
      trainingDayKcalOffset: settings.trainingDayKcalOffset,
    );
  }

  /// Current day type.
  final DiaryDayType type;

  /// Extra kcal granted on training days.
  final double trainingDayKcalOffset;
}
