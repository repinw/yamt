import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/diary/application/diary_day_dashboard_data.dart';
import 'package:yamt/features/diary/domain/diary_plan_day.dart';

/// The plans of today, or of a tomorrow whose day before is closed: they do
/// not count on their own, so the head offers to count them ("Nach Plan").
class DiaryOpenPlans {
  /// Creates the open plans.
  const new({
    required this.kcal,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.counted,
  });

  /// The open plans of [data], or null when its day has none to offer: no
  /// plans, plans that count anyway, a past day whose plans are overdue, a
  /// pause day, or a future day that is still a plan itself. [counted] is
  /// whether the user counts them.
  static DiaryOpenPlans? of(
    DiaryDayDashboardData data, {
    required DateTime today,
    required bool counted,
  }) {
    final plans = data.plannedEntries;
    final day = normalizeDiaryDay(data.selectedDay);
    final overview = data.weekOverview;
    final isPauseDay = overview.days.any(
      (entry) => isSameDiaryDay(entry.date, day) && entry.isPauseDay,
    );
    if (plans.isEmpty ||
        data.countsPlans ||
        day.isBefore(normalizeDiaryDay(today)) ||
        isPauseDay ||
        diaryDayIsPlanned(
          day: day,
          today: today,
          isPreviousDayClosed: overview.isPreviousDayClosed,
          previousDayCarryoverKcal: overview.previousDayCarryoverKcal,
        )) {
      return null;
    }
    var kcal = 0.0;
    var protein = 0.0;
    var carbs = 0.0;
    var fat = 0.0;
    for (final plan in plans) {
      kcal += plan.totalKcal;
      protein += plan.totalProtein;
      carbs += plan.totalCarbs;
      fat += plan.totalFat;
    }
    return DiaryOpenPlans(
      kcal: kcal,
      protein: protein,
      carbs: carbs,
      fat: fat,
      counted: counted,
    );
  }

  /// Planned kcal.
  final double kcal;

  /// Planned protein in grams.
  final double protein;

  /// Planned carbs in grams.
  final double carbs;

  /// Planned fat in grams.
  final double fat;

  /// Whether the user counts the plans, so what is left is shown after them.
  final bool counted;
}
