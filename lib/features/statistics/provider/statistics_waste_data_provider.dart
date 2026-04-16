import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yamt/features/inventory/data/inventory_discard_event_repository.dart';
import 'package:yamt/features/statistics/domain/statistics_models.dart';
import 'package:yamt/features/statistics/domain/waste_metrics.dart';

/// The statistics waste data provider.
final statisticsWasteDataProvider =
    FutureProvider.family<StatisticsWasteSnapshot, StatisticsTimeframe>((
      ref,
      timeframe,
    ) async {
      final repository = ref.watch(inventoryDiscardEventRepositoryProvider);
      final events = await repository.readAll();
      final today = DateUtils.dateOnly(DateTime.now());
      final startDate = _startDateForTimeframe(
        timeframe: timeframe,
        today: today,
      );
      return buildStatisticsWasteSnapshot(
        events: events,
        startDate: startDate,
        endDate: today,
      );
    });

DateTime _startDateForTimeframe({
  required StatisticsTimeframe timeframe,
  required DateTime today,
}) {
  if (timeframe == StatisticsTimeframe.total) {
    return DateTime(2000);
  }

  final days = timeframe.dayCount ?? 7;
  return today.subtract(Duration(days: days - 1));
}
