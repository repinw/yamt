import 'package:meta/meta.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/diary/domain/diary_day_type.dart';

/// Everything an export holds for its days: the goals, the parts of the day,
/// and one row per day with its meals, weight, and TDEE.
@immutable
class DataExportReport {
  /// Creates a report.
  const new({
    required this.from,
    required this.to,
    required this.goals,
    required this.mealSharePercents,
    required this.days,
  });

  /// First day.
  final DateTime from;

  /// Last day.
  final DateTime to;

  /// The goals that ran during the days, oldest first.
  final List<DataExportGoal> goals;

  /// Share of the day's kcal per meal of [MealType.sectionOrder], in percent.
  final List<int> mealSharePercents;

  /// One row per day from [from] to [to].
  final List<DataExportDay> days;

  /// Days with at least one entry.
  List<DataExportDay> get loggedDays =>
      days.where((day) => day.entryCount > 0).toList(growable: false);

  /// Number of entries over all days.
  int get entryCount => days.fold(0, (sum, day) => sum + day.entryCount);

  /// Number of days with a weighing.
  int get weighingCount => days.where((day) => day.weightKg != null).length;

  /// Average of [value] over the logged days; null without one.
  double? averageLogged(double Function(DataExportDay day) value) {
    final logged = loggedDays;
    if (logged.isEmpty) return null;
    return logged.fold<double>(0, (sum, day) => sum + value(day)) /
        logged.length;
  }

  /// Average of the goal [value] over the logged days that count a goal;
  /// null without one.
  double? averageGoal(double Function(DataExportDay day) value) {
    final counted = loggedDays.where((day) => day.hasGoal).toList();
    if (counted.isEmpty) return null;
    return counted.fold<double>(0, (sum, day) => sum + value(day)) /
        counted.length;
  }

  /// Average TDEE over the days that have one; null without one.
  double? get averageTdeeKcal {
    final values = [for (final day in days) ?day.tdeeKcal];
    if (values.isEmpty) return null;
    return values.fold<double>(0, (sum, value) => sum + value) / values.length;
  }

  /// Number of days of [type].
  int countOf(DiaryDayType type) =>
      days.where((day) => day.dayType == type).length;
}

/// A goal that ran during the export.
@immutable
class DataExportGoal {
  /// Creates a goal row.
  const new({
    required this.number,
    required this.startDay,
    required this.endDay,
    required this.goalMode,
    required this.startWeightKg,
    required this.targetWeightKg,
    required this.speedKgPerWeek,
    required this.baseKcal,
  });

  /// 1-based number, oldest first, as in Fortschritt.
  final int number;

  /// First day.
  final DateTime startDay;

  /// Last day; null while it runs.
  final DateTime? endDay;

  /// Lose, maintain, or gain.
  final CalorieGoalMode? goalMode;

  /// Weight at the start.
  final double? startWeightKg;

  /// Target weight.
  final double? targetWeightKg;

  /// Planned change per week.
  final double? speedKgPerWeek;

  /// Daily kcal goal before training and rest day cycling.
  final double? baseKcal;
}

/// One day of the export.
@immutable
class DataExportDay {
  /// Creates a day row.
  const new({
    required this.day,
    required this.dayType,
    required this.goalKcal,
    required this.proteinGoalGrams,
    required this.carbsGoalGrams,
    required this.fatGoalGrams,
    required this.meals,
    required this.weightKg,
    required this.trendWeightKg,
    required this.tdeeKcal,
  });

  /// The local day.
  final DateTime day;

  /// Training, normal, or pause day.
  final DiaryDayType dayType;

  /// kcal goal of the day after cycling.
  final double goalKcal;

  /// Protein goal in grams.
  final double proteinGoalGrams;

  /// Carbohydrate goal in grams.
  final double carbsGoalGrams;

  /// Fat goal in grams.
  final double fatGoalGrams;

  /// Meals with entries, in [MealType.sectionOrder].
  final List<DataExportMeal> meals;

  /// Weighing of the day.
  final double? weightKg;

  /// Trend weight of the day.
  final double? trendWeightKg;

  /// Estimated TDEE of the day.
  final double? tdeeKcal;

  /// Whether the day counts its goals; a pause day and a day before the
  /// first goal have none.
  bool get hasGoal => dayType != DiaryDayType.pause && goalKcal > 0;

  /// [goalKcal], or null on a pause day.
  double? get countedGoalKcal => hasGoal ? goalKcal : null;

  /// Number of entries.
  int get entryCount => meals.fold(0, (sum, meal) => sum + meal.foods.length);

  /// Eaten kcal.
  double get kcal => meals.fold(0, (sum, meal) => sum + meal.kcal);

  /// Eaten protein in grams.
  double get proteinGrams =>
      meals.fold(0, (sum, meal) => sum + meal.proteinGrams);

  /// Eaten carbohydrates in grams.
  double get carbsGrams => meals.fold(0, (sum, meal) => sum + meal.carbsGrams);

  /// Eaten fat in grams.
  double get fatGrams => meals.fold(0, (sum, meal) => sum + meal.fatGrams);
}

/// The entries of one meal of a day.
@immutable
class DataExportMeal {
  /// Creates a meal row.
  const new({required this.mealType, required this.foods});

  /// Breakfast, lunch, dinner, or snack.
  final MealType mealType;

  /// The eaten entries, in logging order.
  final List<CalorieEntry> foods;

  double _sum(double Function(CalorieEntry entry) value) =>
      foods.fold(0, (sum, entry) => sum + value(entry));

  /// Eaten kcal.
  double get kcal => _sum((entry) => entry.totalKcal);

  /// Eaten protein in grams.
  double get proteinGrams => _sum((entry) => entry.totalProtein);

  /// Eaten carbohydrates in grams.
  double get carbsGrams => _sum((entry) => entry.totalCarbs);

  /// Eaten fat in grams.
  double get fatGrams => _sum((entry) => entry.totalFat);
}
