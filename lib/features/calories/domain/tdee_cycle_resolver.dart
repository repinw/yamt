import 'package:yamt/core/domain/local_day_window.dart';
import 'package:yamt/features/calories/domain/calorie_calculator_profile.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/tdee_analytics_goal_cycle.dart';

/// Helper to parse and structure goal cycles from calorie settings history.
abstract final class TdeeCycleResolver {
  /// Resolves all individual goal cycles plus the combined "all goals" cycle.
  static List<TdeeAnalyticsGoalCycle> resolveGoalCycles(
    CalorieGoalSettings settings,
  ) {
    final rawHistory = settings.sortedGoalHistory;
    final anchorEntries = rawHistory
        .where((entry) => entry.hasGoal && !entry.isWeeklyCheckIn)
        .toList(growable: false);

    if (anchorEntries.isEmpty) {
      final now = DateTime.now();
      final defaultCycle = TdeeAnalyticsGoalCycle(
        id: 'default',
        startDate: normalizeLocalDay(settings.updatedAt ?? now),
        goalMode: settings.calculatorProfile?.goalMode,
        startWeightKg: settings.calculatorProfile?.weightKg,
        targetWeightKg: settings.calculatorProfile?.targetWeightKg,
        endWeightKg: settings.calculatorProfile?.targetWeightKg,
        goalSpeedKgPerWeek: settings.calculatorProfile?.goalSpeedKgPerWeek,
      );
      return [
        defaultCycle,
        _buildAllGoalsCycle([defaultCycle]),
      ];
    }

    final cycles = <TdeeAnalyticsGoalCycle>[];

    for (var i = 0; i < anchorEntries.length; i++) {
      final entry = anchorEntries[i];
      final isLatest = i == anchorEntries.length - 1;
      final nextEntry = isLatest ? null : anchorEntries[i + 1];
      final startDate = entry.effectiveCountingStartDate;
      final endDate =
          entry.endedAt ??
          (nextEntry != null
              ? previousLocalDay(nextEntry.effectiveCountingStartDate)
              : null);

      cycles.add(
        TdeeAnalyticsGoalCycle(
          id: 'cycle_${entry.effectiveChangedAt.microsecondsSinceEpoch}_$i',
          startDate: startDate,
          endDate: endDate,
          goalMode: entry.calculatorProfile?.goalMode,
          startWeightKg: entry.calculatorProfile?.weightKg,
          targetWeightKg: entry.calculatorProfile?.targetWeightKg,
          goalSpeedKgPerWeek: entry.calculatorProfile?.goalSpeedKgPerWeek,
          reachedDate: entry.reachedAt,
          endWeightKg:
              entry.endedWeightKg ??
              entry.reachedWeightKg ??
              entry.calculatorProfile?.targetWeightKg ??
              (entry.calculatorProfile?.goalMode == CalorieGoalMode.maintain
                  ? entry.calculatorProfile?.weightKg
                  : null),
        ),
      );
    }

    final allGoalsCycle = _buildAllGoalsCycle(cycles);
    return [allGoalsCycle, ...cycles.reversed];
  }

  static TdeeAnalyticsGoalCycle _buildAllGoalsCycle(
    List<TdeeAnalyticsGoalCycle> individualCycles,
  ) {
    final earliest = individualCycles.first.startDate;
    return TdeeAnalyticsGoalCycle(
      id: 'all',
      startDate: earliest,
      isAllGoals: true,
    );
  }
}
