import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/diary/domain/diary_meal_shares.dart';
import 'package:yamt/features/diary/domain/diary_meal_times.dart';

/// The macro of the day with the most left of its target.
enum DiaryPaceMacro {
  /// Protein.
  protein,

  /// Carbohydrates.
  carbs,

  /// Fat.
  fat,
}

/// What today's pace notification needs: the day's kcal target, the kcal
/// eaten so far, the parts of the day, and the macro to point at.
typedef DiaryPaceDay = ({
  DateTime day,
  double targetKcal,
  double eatenKcal,
  DiaryMealTimes times,
  DiaryMealShares shares,
  DiaryPaceMacro? macro,
});

/// A notification that `freeKcal` are free at `at`, the start of the part of
/// the day of `meal`.
typedef DiaryPaceNotice = ({MealType meal, DateTime at, int freeKcal});

/// The notices of [pace]'s day: one at the start of breakfast, lunch and
/// dinner, never one for the snack. A notice names what is due by the end of
/// its part of the day minus everything eaten today, rounded half up. A part
/// without length or without a share, and a notice that rounds to 0 or less,
/// get none. The time of day does not filter: the caller decides what is
/// still to come.
List<DiaryPaceNotice> diaryPaceNotices(DiaryPaceDay pace) {
  final times = pace.times;
  final edges = [times.start, ...times.ends];
  final notices = <DiaryPaceNotice>[];
  var duePercent = 0;
  for (final (i, meal) in MealType.sectionOrder.indexed) {
    if (meal == MealType.snack) break;
    final percent = pace.shares.percents[i];
    duePercent += percent;
    if (percent <= 0 || edges[i + 1] <= edges[i]) continue;
    final freeKcal = (pace.targetKcal * duePercent / 100 - pace.eatenKcal)
        .round();
    if (freeKcal <= 0) continue;
    final minute = edges[i];
    notices.add((
      meal: meal,
      at: DateTime(
        pace.day.year,
        pace.day.month,
        pace.day.day,
        minute ~/ 60,
        minute % 60,
      ),
      freeKcal: freeKcal,
    ));
  }
  return notices;
}

/// The macro with the largest share of its target left; null when none
/// has anything left.
DiaryPaceMacro? diaryPaceMacro({
  required ({double protein, double carbs, double fat}) eaten,
  required ({double protein, double carbs, double fat}) targets,
}) {
  double left(double eaten, double target) =>
      target <= 0 ? 0 : (target - eaten) / target;
  final shares = {
    DiaryPaceMacro.protein: left(eaten.protein, targets.protein),
    DiaryPaceMacro.carbs: left(eaten.carbs, targets.carbs),
    DiaryPaceMacro.fat: left(eaten.fat, targets.fat),
  };
  final best = shares.entries.reduce((a, b) => b.value > a.value ? b : a);
  return best.value > 0 ? best.key : null;
}
