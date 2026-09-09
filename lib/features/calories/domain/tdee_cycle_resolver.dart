import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/diary_day_window.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';

/// Helper to parse and structure goal cycles from calorie settings history.
abstract final class TdeeCycleResolver {
  /// Resolves all individual goal cycles plus the combined "all goals" cycle.
  static List<TdeeAnalyticsGoalCycle> resolveGoalCycles(
    CalorieGoalSettings settings, {
    String locale = 'de',
  }) {
    final rawHistory = settings.sortedGoalHistory;
    final anchorEntries = rawHistory
        .where((entry) => entry.hasGoal && !entry.isWeeklyCheckIn)
        .toList(growable: false);

    if (anchorEntries.isEmpty) {
      final now = DateTime.now();
      final defaultCycle = TdeeAnalyticsGoalCycle(
        id: 'default',
        title: 'Aktuelles Ziel',
        startDate: normalizeDiaryDay(settings.updatedAt ?? now),
        goalMode: settings.calculatorProfile?.goalMode,
        startWeightKg: settings.calculatorProfile?.weightKg,
        targetWeightKg: settings.calculatorProfile?.targetWeightKg,
        goalSpeedKgPerWeek: settings.calculatorProfile?.goalSpeedKgPerWeek,
        initialGoalKcal: settings.dailyKcalGoal,
      );
      return [defaultCycle, _buildAllGoalsCycle([defaultCycle])];
    }

    final cycles = <TdeeAnalyticsGoalCycle>[];

    for (var i = 0; i < anchorEntries.length; i++) {
      final entry = anchorEntries[i];
      final isLatest = i == anchorEntries.length - 1;
      final nextEntry = isLatest ? null : anchorEntries[i + 1];
      final startDate = entry.effectiveCountingStartDate;
      final endDate = nextEntry != null
          ? previousDiaryDay(nextEntry.effectiveCountingStartDate)
          : null;

      final title = _formatCycleTitle(
        mode: entry.calculatorProfile?.goalMode,
        startDate: startDate,
        isLatest: isLatest,
      );

      cycles.add(
        TdeeAnalyticsGoalCycle(
          id: 'cycle_${startDate.millisecondsSinceEpoch}',
          title: title,
          startDate: startDate,
          endDate: endDate,
          goalMode: entry.calculatorProfile?.goalMode,
          startWeightKg: entry.calculatorProfile?.weightKg,
          targetWeightKg: entry.calculatorProfile?.targetWeightKg,
          goalSpeedKgPerWeek: entry.calculatorProfile?.goalSpeedKgPerWeek,
          initialGoalKcal: entry.dailyKcalGoal,
        ),
      );
    }

    final allGoalsCycle = _buildAllGoalsCycle(cycles);
    return [allGoalsCycle, ...cycles.reversed];
  }

  static String _formatCycleTitle({
    required CalorieGoalMode? mode,
    required DateTime startDate,
    required bool isLatest,
  }) {
    final modeLabel = switch (mode) {
      CalorieGoalMode.lose => 'Abnehmen',
      CalorieGoalMode.gain => 'Zunehmen',
      CalorieGoalMode.maintain => 'Halten',
      null => 'Ziel',
    };
    final dayStr = startDate.day.toString().padLeft(2, '0');
    final monthStr = startDate.month.toString().padLeft(2, '0');
    final dateFormatted = '$dayStr.$monthStr.${startDate.year}';
    final prefix = isLatest ? 'Aktuell: $modeLabel' : modeLabel;
    return '$prefix ($dateFormatted)';
  }

  static TdeeAnalyticsGoalCycle _buildAllGoalsCycle(
    List<TdeeAnalyticsGoalCycle> individualCycles,
  ) {
    final earliest = individualCycles.first.startDate;
    return TdeeAnalyticsGoalCycle(
      id: 'all',
      title: 'Alle Ziele (Gesamt)',
      startDate: earliest,
      isAllGoals: true,
    );
  }
}
