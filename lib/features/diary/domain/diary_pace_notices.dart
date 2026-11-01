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

/// A notification that the pace marker moved a meal's whole part of the
/// day ahead of the kcal eaten: `freeKcal` are free again for `meal` at
/// `at`.
typedef DiaryPaceNotice = ({MealType meal, DateTime at, int freeKcal});

/// The notices of [pace]'s day, at most one per meal: a meal's notice comes
/// at the first minute of its time, before it is eaten by, at which the
/// pace marker lies the meal's part of the day ahead of the kcal eaten.
/// Meals without a part get none, and none come after the last meal is
/// eaten by, so the night stays quiet.
List<DiaryPaceNotice> diaryPaceNotices(DiaryPaceDay pace) {
  final times = pace.times;
  final edges = [times.start, ...times.ends];
  final parts = pace.shares.splitKcal(pace.targetKcal);
  final notices = <DiaryPaceNotice>[];
  var dueBefore = 0;
  for (final (i, meal) in MealType.sectionOrder.indexed) {
    final percent = pace.shares.percents[i];
    final from = edges[i];
    final to = edges[i + 1];
    final dueFrom = pace.targetKcal * dueBefore / 100;
    dueBefore += percent;
    final dueTo = pace.targetKcal * dueBefore / 100;
    final need = pace.eatenKcal + parts[i];
    // At the minute a meal is eaten by, the next meal's time begins.
    if (parts[i] <= 0 || to <= from || need >= dueTo) continue;
    final minute = need <= dueFrom
        ? from
        : from + ((need - dueFrom) / (dueTo - dueFrom) * (to - from)).ceil();
    if (minute >= to) continue;
    notices.add((
      meal: meal,
      at: DateTime(
        pace.day.year,
        pace.day.month,
        pace.day.day,
        minute ~/ 60,
        minute % 60,
      ),
      freeKcal: parts[i],
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
