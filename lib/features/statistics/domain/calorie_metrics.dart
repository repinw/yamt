import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';

enum StatisticsMacroType { carbs, protein, fat }

class StatisticsCalorieDaySummary {
  const StatisticsCalorieDaySummary({
    required this.date,
    required this.entryCount,
    required this.totalKcal,
    required this.goalKcal,
  });

  final DateTime date;
  final int entryCount;
  final double totalKcal;
  final double goalKcal;

  bool get hasEntries => entryCount > 0;

  bool get isWithinGoal => hasEntries && totalKcal <= goalKcal;
}

class StatisticsMacroShare {
  const StatisticsMacroShare({
    required this.type,
    required this.grams,
    required this.share,
  });

  final StatisticsMacroType type;
  final double grams;
  final double share;
}

class StatisticsCalorieSnapshot {
  const StatisticsCalorieSnapshot({
    required this.days,
    required this.totalEntries,
    required this.balanceRemainingKcal,
    required this.trackedDayCount,
    required this.goalMetDayCount,
    required this.averageTrackedKcal,
    required this.macroShares,
  });

  final List<StatisticsCalorieDaySummary> days;
  final int totalEntries;
  final double balanceRemainingKcal;
  final int trackedDayCount;
  final int goalMetDayCount;
  final double averageTrackedKcal;
  final List<StatisticsMacroShare> macroShares;
}

StatisticsCalorieSnapshot buildStatisticsCalorieSnapshot({
  required List<CalorieEntry> entries,
  required CalorieGoalSettings settings,
  required DateTime startDate,
  required DateTime endDate,
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
