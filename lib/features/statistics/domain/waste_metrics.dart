import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';

class StatisticsWasteSnapshot {
  const StatisticsWasteSnapshot({
    required this.totalEvents,
    required this.totalDiscardedValue,
    required this.currencyCode,
    required this.topReason,
    required this.topReasonCount,
    required this.topItemName,
    required this.topItemCount,
  });

  final int totalEvents;
  final double totalDiscardedValue;
  final String? currencyCode;
  final InventoryDiscardReason? topReason;
  final int topReasonCount;
  final String? topItemName;
  final int topItemCount;

  bool get hasData => totalEvents > 0;
}

StatisticsWasteSnapshot buildStatisticsWasteSnapshot({
  required List<InventoryDiscardEvent> events,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final filteredEvents = events.where((event) {
    final date = _normalizeDay(event.discardedAt);
    return !date.isBefore(_normalizeDay(startDate)) &&
        !date.isAfter(_normalizeDay(endDate));
  }).toList(growable: false);

  final totalDiscardedValue = filteredEvents.fold<double>(
    0,
    (sum, event) => sum + event.discardedValue,
  );
  final currencyCode = resolveSharedCurrencyCode(
    filteredEvents.map((event) => event.currencyCode),
  );

  final reasonCounts = <InventoryDiscardReason, int>{};
  final itemCounts = <String, int>{};
  for (final event in filteredEvents) {
    reasonCounts[event.reason] = (reasonCounts[event.reason] ?? 0) + 1;
    itemCounts[event.name] = (itemCounts[event.name] ?? 0) + 1;
  }

  final topReason = _topEntry(reasonCounts.entries);
  final topItem = _topEntry(itemCounts.entries);

  return StatisticsWasteSnapshot(
    totalEvents: filteredEvents.length,
    totalDiscardedValue: totalDiscardedValue,
    currencyCode: currencyCode,
    topReason: topReason?.key,
    topReasonCount: topReason?.value ?? 0,
    topItemName: topItem?.key,
    topItemCount: topItem?.value ?? 0,
  );
}

MapEntry<TKey, int>? _topEntry<TKey>(Iterable<MapEntry<TKey, int>> entries) {
  final iterator = entries.iterator;
  if (!iterator.moveNext()) {
    return null;
  }

  var currentTop = iterator.current;
  while (iterator.moveNext()) {
    final next = iterator.current;
    if (next.value > currentTop.value) {
      currentTop = next;
    }
  }
  return currentTop;
}

DateTime _normalizeDay(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
