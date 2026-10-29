import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';

/// Activity type of a single diary day.
enum DiaryDayType {
  /// Scheduled or manually marked training day.
  training,

  /// Normal day, the baseline when it is neither training nor pause.
  normal,

  /// Neutral pause day (vacation, illness).
  pause,
}

/// Day type of a diary day.
class DiaryDayTypeStatus {
  /// Creates a day type status.
  const new({required this.type});

  /// Resolves the status of [day] from calorie goal [settings].
  factory fromSettings(CalorieGoalSettings settings, DateTime day) {
    return DiaryDayTypeStatus(
      type: settings.isPauseDay(day)
          ? DiaryDayType.pause
          : settings.isTrainingDay(day)
          ? DiaryDayType.training
          : DiaryDayType.normal,
    );
  }

  /// Current day type.
  final DiaryDayType type;
}
