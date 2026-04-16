import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

/// Defines statistics store value.
class StatisticsStoreValue {
  /// The statistics store value.
  const StatisticsStoreValue({
    required this.storeName,
    required this.value,
    required this.itemCount,
  });

  /// The store name.
  final String storeName;

  /// The value.
  final double value;

  /// The item count.
  final int itemCount;
}

/// Defines statistics expensive entry.
class StatisticsExpensiveEntry {
  /// The statistics expensive entry.
  const StatisticsExpensiveEntry({required this.title, required this.value});

  /// The title.
  final String title;

  /// The value.
  final double value;
}

/// Defines statistics price trend.
class StatisticsPriceTrend {
  /// The statistics price trend.
  const StatisticsPriceTrend({
    required this.title,
    required this.latestPrice,
    required this.changeRatio,
  });

  /// The title.
  final String title;

  /// The latest price.
  final double latestPrice;

  /// The change ratio.
  final double changeRatio;
}

/// Defines statistics spending day value.
class StatisticsSpendingDayValue {
  /// The statistics spending day value.
  const StatisticsSpendingDayValue({required this.date, required this.value});

  /// The date.
  final DateTime date;

  /// The value.
  final double value;
}

/// Defines statistics spending snapshot.
class StatisticsSpendingSnapshot {
  /// The statistics spending snapshot.
  const StatisticsSpendingSnapshot({
    required this.currencyCode,
    required this.totalValue,
    required this.topStores,
    required this.expensiveEntries,
    required this.priceTrends,
    required this.dailySpendValues,
  });

  /// The currency code.
  final String? currencyCode;

  /// The total value.
  final double totalValue;

  /// The top stores.
  final List<StatisticsStoreValue> topStores;

  /// The expensive entries.
  final List<StatisticsExpensiveEntry> expensiveEntries;

  /// The price trends.
  final List<StatisticsPriceTrend> priceTrends;

  /// The daily spend values.
  final List<StatisticsSpendingDayValue> dailySpendValues;
}

/// Calculate purchased inventory value.
double calculatePurchasedInventoryValue(InventoryItem item) {
  final quantity = item.effectiveInitialQuantity;
  if (quantity <= 0) {
    return 0;
  }

  final discountTotal = item.discounts.values.fold<double>(
    0,
    (sum, value) => sum + value,
  );
  return (quantity * item.unitPrice) + discountTotal;
}

/// Build statistics spending snapshot.
StatisticsSpendingSnapshot buildStatisticsSpendingSnapshot({
  required List<InventoryItem> items,
  required DateTime startDate,
  required DateTime endDate,
}) {
  final filteredItems = items
      .where(
        (item) =>
            !_isOutsideWindow(_resolvedItemDate(item), startDate, endDate),
      )
      .where((item) => !item.isReviewOnly)
      .toList(growable: false);

  final totalValue = filteredItems.fold<double>(
    0,
    (sum, item) => sum + calculatePurchasedInventoryValue(item),
  );
  final dailySpendValues = _buildDailySpendValues(filteredItems);
  final currencyCode = resolveSharedCurrencyCode(
    filteredItems.map((item) => item.currencyCode),
  );

  final storeTotals = <String, ({double value, int itemCount})>{};
  for (final item in filteredItems) {
    final value = calculatePurchasedInventoryValue(item);
    if (value <= 0) {
      continue;
    }

    final key = item.storeName.trim();
    if (key.isEmpty) {
      continue;
    }
    final current = storeTotals[key];
    if (current == null) {
      storeTotals[key] = (value: value, itemCount: 1);
      continue;
    }
    storeTotals[key] = (
      value: current.value + value,
      itemCount: current.itemCount + 1,
    );
  }

  final topStores =
      storeTotals.entries
          .map(
            (entry) => StatisticsStoreValue(
              storeName: entry.key,
              value: entry.value.value,
              itemCount: entry.value.itemCount,
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => right.value.compareTo(left.value));

  final expensiveEntries =
      filteredItems
          .map(
            (item) => StatisticsExpensiveEntry(
              title: item.name,
              value: calculatePurchasedInventoryValue(item),
            ),
          )
          .where((entry) => entry.value > 0)
          .toList(growable: false)
        ..sort((left, right) => right.value.compareTo(left.value));

  final priceTrends = _buildPriceTrends(filteredItems);

  return StatisticsSpendingSnapshot(
    currencyCode: currencyCode,
    totalValue: totalValue,
    topStores: List<StatisticsStoreValue>.unmodifiable(topStores),
    expensiveEntries: List<StatisticsExpensiveEntry>.unmodifiable(
      expensiveEntries,
    ),
    priceTrends: List<StatisticsPriceTrend>.unmodifiable(priceTrends),
    dailySpendValues: List<StatisticsSpendingDayValue>.unmodifiable(
      dailySpendValues,
    ),
  );
}

/// Resolve visible spending start date.
DateTime resolveVisibleSpendingStartDate({
  required Iterable<DateTime> spendingDates,
  required int? maxVisibleDays,
  required DateTime fallbackDate,
}) {
  final uniqueDates =
      spendingDates.map(_normalizeDay).toSet().toList(growable: false)..sort();
  if (uniqueDates.isEmpty) {
    return _normalizeDay(fallbackDate);
  }

  if (maxVisibleDays == null || maxVisibleDays <= 0) {
    return uniqueDates.first;
  }

  if (uniqueDates.length <= maxVisibleDays) {
    return uniqueDates.first;
  }

  return uniqueDates[uniqueDates.length - maxVisibleDays];
}

List<StatisticsPriceTrend> _buildPriceTrends(List<InventoryItem> items) {
  final entriesByProduct = <String, List<InventoryItem>>{};
  for (final item in items) {
    if (item.unitPrice <= 0) {
      continue;
    }

    final key = _priceTrendKey(item);
    entriesByProduct.putIfAbsent(key, () => <InventoryItem>[]).add(item);
  }

  final trends = <StatisticsPriceTrend>[];
  for (final entries in entriesByProduct.values) {
    if (entries.length < 2) {
      continue;
    }

    entries.sort(
      (left, right) =>
          _resolvedItemDate(left).compareTo(_resolvedItemDate(right)),
    );
    final first = entries.first;
    final last = entries.last;
    if (first.unitPrice <= 0 || last.unitPrice <= 0) {
      continue;
    }

    final changeRatio = first.unitPrice == 0
        ? 0.0
        : (last.unitPrice - first.unitPrice) / first.unitPrice;
    trends.add(
      StatisticsPriceTrend(
        title: last.name,
        latestPrice: last.unitPrice,
        changeRatio: changeRatio,
      ),
    );
  }

  trends.sort((left, right) {
    return right.changeRatio.abs().compareTo(left.changeRatio.abs());
  });
  return trends;
}

List<StatisticsSpendingDayValue> _buildDailySpendValues(
  List<InventoryItem> items,
) {
  final groupedValues = <DateTime, double>{};

  for (final item in items) {
    final value = calculatePurchasedInventoryValue(item);
    if (value <= 0) {
      continue;
    }

    final date = _normalizeDay(_resolvedItemDate(item));
    groupedValues[date] = (groupedValues[date] ?? 0) + value;
  }

  final values =
      groupedValues.entries
          .map(
            (entry) =>
                StatisticsSpendingDayValue(date: entry.key, value: entry.value),
          )
          .toList(growable: false)
        ..sort((left, right) => left.date.compareTo(right.date));
  return values;
}

String _priceTrendKey(InventoryItem item) {
  final globalId = item.globalFoodItemId.trim();
  if (globalId.isNotEmpty) {
    return globalId;
  }

  final normalizedName = item.name.trim().toLowerCase();
  final normalizedBrand = item.brand?.trim().toLowerCase() ?? '';
  return '$normalizedName::$normalizedBrand';
}

DateTime _resolvedItemDate(InventoryItem item) {
  return item.receiptDate ?? item.entryDate;
}

bool _isOutsideWindow(DateTime date, DateTime startDate, DateTime endDate) {
  final normalizedDate = _normalizeDay(date);
  final normalizedStart = _normalizeDay(startDate);
  final normalizedEnd = _normalizeDay(endDate);
  return normalizedDate.isBefore(normalizedStart) ||
      normalizedDate.isAfter(normalizedEnd);
}

DateTime _normalizeDay(DateTime dateTime) {
  return DateTime(dateTime.year, dateTime.month, dateTime.day);
}
