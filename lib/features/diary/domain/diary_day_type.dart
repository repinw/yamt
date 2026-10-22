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
  const new({required this.type, required this.trainingDayKcalOffset});

  /// Resolves the status of [day] from calorie goal [settings].
  factory fromSettings(CalorieGoalSettings settings, DateTime day) {
    return DiaryDayTypeStatus(
      type: settings.isPauseDay(day)
          ? DiaryDayType.pause
          : settings.isTrainingDay(day)
          ? DiaryDayType.training
          : DiaryDayType.rest,
      trainingDayKcalOffset: settings.trainingSessionKcalForDay(day),
    );
  }

  /// Current day type.
  final DiaryDayType type;

  /// kcal a training day gets more than a rest day: one session.
  final double trainingDayKcalOffset;
}
