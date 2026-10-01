import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/calories/application/calorie_goal_controller.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings_cycling.dart';
import 'package:yamt/features/calories/domain/calorie_run_training_plan.dart';

part 'calorie_run_training_service.g.dart';

/// One run day whose type changes.
typedef CalorieRunTrainingDayChange = ({
  DateTime day,
  bool isTraining,
  double kcalBefore,
  double kcalAfter,
});

/// Run days that keep their type but get a new calorie goal, all with the
/// same goal before and after.
typedef CalorieRunTrainingDayGroup = ({
  bool isTraining,
  int count,
  double kcalBefore,
  double kcalAfter,
});

/// What new training days change on the calorie goals of the current run.
@immutable
class CalorieRunTrainingEffect {
  /// Creates the effect of new training days.
  const new({
    required this.changes,
    required this.otherDays,
    required this.runKcalBefore,
    required this.runKcalAfter,
  });

  /// The days whose type changes, first to last.
  final List<CalorieRunTrainingDayChange> changes;

  /// The other days whose calorie goal changes, rest days first.
  final List<CalorieRunTrainingDayGroup> otherDays;

  /// Sum of the daily calorie goals of the run now.
  final double runKcalBefore;

  /// Sum of the daily calorie goals of the run after the change.
  final double runKcalAfter;
}

/// Shows and saves the training days of the current 7-day run.
class CalorieRunTrainingService {
  /// Creates the service for the current [settings].
  const new({required this.settings, required this.goalController});

  /// Current calorie goal settings, or `null` while they load.
  final CalorieGoalSettings? settings;

  /// Saves the calorie goal settings.
  final CalorieGoalController goalController;

  /// What [trainingDays] would change on the run that contains [now], or
  /// `null` while the settings load or without a goal.
  CalorieRunTrainingEffect? effectOf(
    Set<DateTime> trainingDays, {
    required DateTime now,
  }) {
    final settings = this.settings;
    if (settings == null || !settings.hasGoal) {
      return null;
    }
    final next = settings.withRunTrainingDays(now, trainingDays: trainingDays);
    final days = settings.runTrainingPlan(now).days;
    final changes = <CalorieRunTrainingDayChange>[];
    final otherDays = <(bool, double, double), int>{};
    for (final day in days) {
      final isTraining = next.isTrainingDay(day);
      final kcalBefore = settings.goalKcalForDay(day);
      final kcalAfter = next.goalKcalForDay(day);
      if (settings.isTrainingDay(day) != isTraining) {
        changes.add((
          day: day,
          isTraining: isTraining,
          kcalBefore: kcalBefore,
          kcalAfter: kcalAfter,
        ));
      } else if (kcalBefore != kcalAfter) {
        final key = (isTraining, kcalBefore, kcalAfter);
        otherDays[key] = (otherDays[key] ?? 0) + 1;
      }
    }
    return CalorieRunTrainingEffect(
      changes: changes,
      otherDays: [
        for (final MapEntry(key: (isTraining, before, after), value: count)
            in otherDays.entries.toList()..sort(
              (left, right) =>
                  left.key.$1 == right.key.$1 ? 0 : (left.key.$1 ? 1 : -1),
            ))
          (
            isTraining: isTraining,
            count: count,
            kcalBefore: before,
            kcalAfter: after,
          ),
      ],
      runKcalBefore: _sum(days.map(settings.goalKcalForDay)),
      runKcalAfter: _sum(days.map(next.goalKcalForDay)),
    );
  }

  /// Saves [trainingDays] for the run that contains [now] and reports
  /// whether they were stored.
  Future<bool> save(Set<DateTime> trainingDays, {required DateTime now}) async {
    return await goalController.updateSettings(
      (previous) =>
          previous.withRunTrainingDays(now, trainingDays: trainingDays),
    );
  }
}

double _sum(Iterable<double> values) {
  return values.fold(0, (sum, value) => sum + value);
}

/// Provides the run training service for the current calorie settings.
@riverpod
CalorieRunTrainingService calorieRunTrainingService(Ref ref) {
  return CalorieRunTrainingService(
    settings: ref.watch(calorieGoalControllerProvider).value,
    goalController: ref.watch(calorieGoalControllerProvider.notifier),
  );
}
