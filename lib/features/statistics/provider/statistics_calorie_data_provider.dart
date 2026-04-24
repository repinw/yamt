import 'dart:developer' show log;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/calories/data/calorie_log_repository.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/provider/calorie_goal_controller.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';

const _statisticsCalorieLogName = 'StatisticsCalorieDataProvider';

/// The statistics calorie data provider.
final FutureProvider<StatisticsCalorieSnapshot> Function(StatisticsTimeframe)
statisticsCalorieDataProvider =
    FutureProvider.family<StatisticsCalorieSnapshot, StatisticsTimeframe>((
      ref,
      timeframe,
    ) async {
      final repository = ref.watch(calorieLogRepositoryProvider);
      final settings =
          ref.watch(calorieGoalControllerProvider).value ??
          const CalorieGoalSettings.empty();
      final today = DateUtils.dateOnly(DateTime.now());

      try {
        final firstEntryDate = await repository.readFirstEntryDate();
        final historyStartDate = _resolveHistoryStartDate(
          settings: settings,
          firstEntryDate: firstEntryDate,
          today: today,
        );
        final startDate = _calendarStartDateForTimeframe(
          timeframe: timeframe,
          today: today,
          firstAvailableDate: historyStartDate,
        );
        final endExclusive = today.add(const Duration(days: 1));
        final entries = await repository.readEntriesInRange(
          startInclusive: startDate,
          endExclusive: endExclusive,
        );

        return buildStatisticsCalorieSnapshot(
          entries: entries,
          settings: settings,
          startDate: startDate,
          endDate: today,
          shouldIncludeDay: (day) => !settings.isGoalPracticeDay(day),
        );
      } on Object catch (error, stackTrace) {
        log(
          'Failed to build calorie statistics for ${timeframe.name}.',
          name: _statisticsCalorieLogName,
          error: error,
          stackTrace: stackTrace,
        );
        rethrow;
      }
    });

DateTime _calendarStartDateForTimeframe({
  required StatisticsTimeframe timeframe,
  required DateTime today,
  required DateTime firstAvailableDate,
}) {
  if (timeframe == StatisticsTimeframe.total) {
    final firstDay = DateUtils.dateOnly(firstAvailableDate);
    return firstDay.isAfter(today) ? today : firstDay;
  }

  final days = timeframe.dayCount ?? 7;
  return today.subtract(Duration(days: days - 1));
}

DateTime _resolveHistoryStartDate({
  required CalorieGoalSettings settings,
  required DateTime? firstEntryDate,
  required DateTime today,
}) {
  final historyDates = <DateTime>[
    if (firstEntryDate != null) DateUtils.dateOnly(firstEntryDate),
    ...settings.sortedGoalHistory.map(
      (entry) => DateUtils.dateOnly(entry.effectiveDate),
    ),
  ];
  if (historyDates.isEmpty) {
    return today.subtract(const Duration(days: 6));
  }
  historyDates.sort();
  return historyDates.first;
}
