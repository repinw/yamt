import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

/// Decides whether a calendar day should be included in calorie statistics.
typedef StatisticsCalorieDayFilter = bool Function(DateTime day);

/// Defines statistics macro type.
enum StatisticsMacroType {
  /// Carbs.
  carbs,

  /// Protein.
  protein,

  /// Fat.
  fat,
}

/// Defines statistics calorie day summary.
class StatisticsCalorieDaySummary {
  /// The statistics calorie day summary.
  const StatisticsCalorieDaySummary({
    required this.date,
    required this.entryCount,
    required this.totalKcal,
    required this.goalKcal,
  });

  /// The date.
  final DateTime date;

  /// The entry count.
  final int entryCount;

  /// The total kcal.
  final double totalKcal;

  /// The goal kcal.
  final double goalKcal;

  /// Whether entries.
  bool get hasEntries => entryCount > 0;

  /// Whether within goal.
  bool get isWithinGoal => hasEntries && totalKcal <= goalKcal;
}

/// Defines statistics macro share.
class StatisticsMacroShare {
  /// The statistics macro share.
  const StatisticsMacroShare({
    required this.type,
    required this.grams,
    required this.share,
  });

  /// The type.
  final StatisticsMacroType type;

  /// The grams.
  final double grams;

  /// The share.
  final double share;
}

/// Defines statistics calorie snapshot.
class StatisticsCalorieSnapshot {
  /// The statistics calorie snapshot.
  const StatisticsCalorieSnapshot({
    required this.days,
    required this.totalEntries,
    required this.balanceRemainingKcal,
    required this.trackedDayCount,
    required this.goalMetDayCount,
    required this.averageTrackedKcal,
    required this.macroShares,
  });

  /// The days.
  final List<StatisticsCalorieDaySummary> days;

  /// The total entries.
  final int totalEntries;

  /// The balance remaining kcal.
  final double balanceRemainingKcal;

  /// The tracked day count.
  final int trackedDayCount;

  /// The goal met day count.
  final int goalMetDayCount;

  /// The average tracked kcal.
  final double averageTrackedKcal;

  /// The macro shares.
  final List<StatisticsMacroShare> macroShares;
}

/// Build statistics calorie snapshot.
///
/// [shouldIncludeDay] can remove consequence-free practice days from all
/// aggregates while keeping the underlying diary entries untouched.
StatisticsCalorieSnapshot buildStatisticsCalorieSnapshot({
  required List<CalorieEntry> entries,
  required CalorieGoalSettings settings,
  required DateTime startDate,
  required DateTime endDate,
  StatisticsCalorieDayFilter? shouldIncludeDay,
}) {
  final normalizedStart = _normalizeDay(startDate);
  final normalizedEnd = _normalizeDay(endDate);
  final safeEnd = normalizedEnd.isBefore(normalizedStart)
      ? normalizedStart
      : normalizedEnd;
  final entriesByDay = <String, List<CalorieEntry>>{};
  for (final entry in entries) {
    final key = _dayKey(entry.loggedAt);
    entriesByDay.putIfAbsent(key, () => <CalorieEntry>[]).add(entry);
  }

  final days = <StatisticsCalorieDaySummary>[];
  var totalEntries = 0;
  var totalKcal = 0.0;
  var totalProtein = 0.0;
  var totalCarbs = 0.0;
  var totalFat = 0.0;

  var cursor = normalizedStart;
  while (!cursor.isAfter(safeEnd)) {
    if (shouldIncludeDay != null && !shouldIncludeDay(cursor)) {
      cursor = cursor.add(const Duration(days: 1));
      continue;
    }
    final dayEntries = entriesByDay[_dayKey(cursor)] ?? const <CalorieEntry>[];
    final totalDayKcal = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    totalEntries += dayEntries.length;
    totalKcal += totalDayKcal;
    totalProtein += dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalProtein,
    );
    totalCarbs += dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalCarbs,
    );
    totalFat += dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalFat,
    );
    days.add(
      StatisticsCalorieDaySummary(
        date: cursor,
        entryCount: dayEntries.length,
        totalKcal: totalDayKcal,
        goalKcal: settings.goalKcalForDay(cursor),
      ),
    );
    cursor = cursor.add(const Duration(days: 1));
  }

  final balanceStartDate = settings.balanceStartForWindow(
    days.map((day) => day.date),
  );
  final normalizedBalanceStart = _normalizeDay(balanceStartDate);
  final trackedDayCount = days.where((day) => day.hasEntries).length;
  final goalMetDayCount = days.where((day) => day.isWithinGoal).length;
  final balanceGoalKcal = days.fold<double>(0, (sum, day) {
    if (_normalizeDay(day.date).isBefore(normalizedBalanceStart)) {
      return sum;
    }
    return sum + day.goalKcal;
  });
  final balanceConsumedKcal = days.fold<double>(0, (sum, day) {
    if (_normalizeDay(day.date).isBefore(normalizedBalanceStart)) {
      return sum;
    }
    return sum + day.totalKcal;
  });
  final averageTrackedKcal = trackedDayCount == 0
      ? 0.0
      : totalKcal / trackedDayCount.toDouble();

  return StatisticsCalorieSnapshot(
    days: List<StatisticsCalorieDaySummary>.unmodifiable(days),
    totalEntries: totalEntries,
    balanceRemainingKcal: balanceGoalKcal - balanceConsumedKcal,
    trackedDayCount: trackedDayCount,
    goalMetDayCount: goalMetDayCount,
    averageTrackedKcal: averageTrackedKcal,
    macroShares: _buildMacroShares(
      carbs: totalCarbs,
      protein: totalProtein,
      fat: totalFat,
    ),
  );
}

List<StatisticsMacroShare> _buildMacroShares({
  required double carbs,
  required double protein,
  required double fat,
}) {
  final carbKcal = carbs * 4;
  final proteinKcal = protein * 4;
  final fatKcal = fat * 9;
  final totalMacroKcal = carbKcal + proteinKcal + fatKcal;

  double share(double value) {
    if (totalMacroKcal <= 0) {
      return 0;
    }
    return value / totalMacroKcal;
  }

  return <StatisticsMacroShare>[
    StatisticsMacroShare(
      type: StatisticsMacroType.carbs,
      grams: carbs,
      share: share(carbKcal),
    ),
    StatisticsMacroShare(
      type: StatisticsMacroType.protein,
      grams: protein,
      share: share(proteinKcal),
    ),
    StatisticsMacroShare(
      type: StatisticsMacroType.fat,
      grams: fat,
      share: share(fatKcal),
    ),
  ];
}

DateTime _normalizeDay(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}

String _dayKey(DateTime dateTime) {
  final day = _normalizeDay(dateTime);
  return '${day.year}-${day.month}-${day.day}';
}
