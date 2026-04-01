import 'package:yamt/core/utils/currency_format.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

enum StatisticsCostSourceType { inventory, preparedMeals, eatingOut, spices }

enum StatisticsMacroType { carbs, protein, fat }

class StatisticsStoreValue {
  const StatisticsStoreValue({
    required this.storeName,
    required this.value,
    required this.itemCount,
  });

  final String storeName;
  final double value;
  final int itemCount;
}

class StatisticsExpensiveEntry {
  const StatisticsExpensiveEntry({
    required this.title,
    required this.subtitle,
    required this.value,
  });

  final String title;
  final String subtitle;
  final double value;
}

class StatisticsPriceTrend {
  const StatisticsPriceTrend({
    required this.title,
    required this.subtitle,
    required this.previousPrice,
    required this.latestPrice,
    required this.changeRatio,
    required this.firstSeenAt,
    required this.lastSeenAt,
  });

  final String title;
  final String subtitle;
  final double previousPrice;
  final double latestPrice;
  final double changeRatio;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
}

class StatisticsCostSourceValue {
  const StatisticsCostSourceValue({required this.type, required this.value});

  final StatisticsCostSourceType type;
  final double value;
}

class StatisticsSpendingDayValue {
  const StatisticsSpendingDayValue({
    required this.date,
    required this.value,
    required this.receiptCount,
  });

  final DateTime date;
  final double value;
  final int receiptCount;
}

class StatisticsSpendingSnapshot {
  const StatisticsSpendingSnapshot({
    required this.currencyCode,
    required this.totalValue,
    required this.inventoryValue,
    required this.preparedMealValue,
    required this.filteredItemCount,
    required this.filteredMealCount,
    required this.receiptCount,
    required this.topStores,
    required this.expensiveEntries,
    required this.priceTrends,
    required this.costSources,
    required this.dailySpendValues,
  });

  final String? currencyCode;
  final double totalValue;
  final double inventoryValue;
  final double preparedMealValue;
  final int filteredItemCount;
  final int filteredMealCount;
  final int receiptCount;
  final List<StatisticsStoreValue> topStores;
  final List<StatisticsExpensiveEntry> expensiveEntries;
  final List<StatisticsPriceTrend> priceTrends;
  final List<StatisticsCostSourceValue> costSources;
  final List<StatisticsSpendingDayValue> dailySpendValues;
}

class StatisticsCalorieDaySummary {
  const StatisticsCalorieDaySummary({
    required this.date,
    required this.entryCount,
    required this.totalKcal,
    required this.goalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  final DateTime date;
  final int entryCount;
  final double totalKcal;
  final double goalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  bool get hasEntries => entryCount > 0;

  bool get isWithinGoal => hasEntries && totalKcal <= goalKcal;

  bool get isOverGoal => hasEntries && totalKcal > goalKcal;
}

class StatisticsMacroShare {
  const StatisticsMacroShare({
    required this.type,
    required this.grams,
    required this.kcal,
    required this.share,
  });

  final StatisticsMacroType type;
  final double grams;
  final double kcal;
  final double share;
}

class StatisticsCalorieSnapshot {
  const StatisticsCalorieSnapshot({
    required this.startDate,
    required this.endDate,
    required this.balanceStartDate,
    required this.days,
    required this.totalEntries,
    required this.totalKcal,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.periodGoalKcal,
    required this.balanceGoalKcal,
    required this.balanceConsumedKcal,
    required this.balanceRemainingKcal,
    required this.trackedDayCount,
    required this.goalMetDayCount,
    required this.averageTrackedKcal,
    required this.macroShares,
  });

  final DateTime startDate;
  final DateTime endDate;
  final DateTime balanceStartDate;
  final List<StatisticsCalorieDaySummary> days;
  final int totalEntries;
  final double totalKcal;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double periodGoalKcal;
  final double balanceGoalKcal;
  final double balanceConsumedKcal;
  final double balanceRemainingKcal;
  final int trackedDayCount;
  final int goalMetDayCount;
  final double averageTrackedKcal;
  final List<StatisticsMacroShare> macroShares;
}

double calculateRemainingInventoryValue(InventoryItem item) {
  final unitPrice = item.unitPrice;
  if (unitPrice <= 0) {
    return 0;
  }

  if (item.usesAmountProgress) {
    final initialAmount = item.initialAmount;
    if (initialAmount <= 0) {
      return 0;
    }
    final maxCurrentAmount = item.currentAmount.clamp(0, initialAmount);
    final ratio = maxCurrentAmount / initialAmount;
    return item.effectiveInitialQuantity * unitPrice * ratio;
  }

  final maxQuantity = item.quantity.clamp(0, item.effectiveInitialQuantity);
  return maxQuantity * unitPrice;
}

double calculateRemainingPreparedMealValue(PreparedMeal meal) {
  final safeRatio = meal.remainingRatio.clamp(0.0, 1.0);
  return meal.totalPrice * safeRatio;
}

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

StatisticsSpendingSnapshot buildStatisticsSpendingSnapshot({
  required List<InventoryItem> items,
  required List<PreparedMeal> meals,
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
  final filteredMeals = meals
      .where((meal) => !_isOutsideWindow(meal.createdAt, startDate, endDate))
      .toList(growable: false);

  final inventoryValue = filteredItems.fold<double>(
    0,
    (sum, item) => sum + calculateRemainingInventoryValue(item),
  );
  final preparedMealValue = filteredMeals.fold<double>(
    0,
    (sum, meal) => sum + calculateRemainingPreparedMealValue(meal),
  );
  final dailySpendValues = _buildDailySpendValues(filteredItems);
  final currencyCode = resolveSharedCurrencyCode(<String?>[
    ...filteredItems.map((item) => item.currencyCode),
    ...filteredMeals.map((meal) => meal.currencyCode),
  ]);

  final storeTotals = <String, ({double value, int itemCount})>{};
  for (final item in filteredItems) {
    final value = calculateRemainingInventoryValue(item);
    if (value <= 0) {
      continue;
    }

    final key = item.storeName.trim().isEmpty ? 'Unbekannt' : item.storeName;
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

  final expensiveEntries = <StatisticsExpensiveEntry>[
    ...filteredItems.map(
      (item) => StatisticsExpensiveEntry(
        title: item.name,
        subtitle: item.storeName.trim(),
        value: calculateRemainingInventoryValue(item),
      ),
    ),
    ...filteredMeals.map(
      (meal) => StatisticsExpensiveEntry(
        title: meal.name,
        subtitle: '${meal.remainingPortions}/${meal.totalPortions}',
        value: calculateRemainingPreparedMealValue(meal),
      ),
    ),
  ]..removeWhere((entry) => entry.value <= 0);
  expensiveEntries.sort((left, right) => right.value.compareTo(left.value));

  final priceTrends = _buildPriceTrends(filteredItems);
  final receiptCount = filteredItems
      .map((item) => item.receiptId?.trim())
      .whereType<String>()
      .where((value) => value.isNotEmpty)
      .toSet()
      .length;
  final costSources = <StatisticsCostSourceValue>[
    StatisticsCostSourceValue(
      type: StatisticsCostSourceType.inventory,
      value: inventoryValue,
    ),
    StatisticsCostSourceValue(
      type: StatisticsCostSourceType.preparedMeals,
      value: preparedMealValue,
    ),
    const StatisticsCostSourceValue(
      type: StatisticsCostSourceType.eatingOut,
      value: 0,
    ),
    const StatisticsCostSourceValue(
      type: StatisticsCostSourceType.spices,
      value: 0,
    ),
  ];

  return StatisticsSpendingSnapshot(
    currencyCode: currencyCode,
    totalValue: inventoryValue + preparedMealValue,
    inventoryValue: inventoryValue,
    preparedMealValue: preparedMealValue,
    filteredItemCount: filteredItems.length,
    filteredMealCount: filteredMeals.length,
    receiptCount: receiptCount,
    topStores: List<StatisticsStoreValue>.unmodifiable(topStores),
    expensiveEntries: List<StatisticsExpensiveEntry>.unmodifiable(
      expensiveEntries,
    ),
    priceTrends: List<StatisticsPriceTrend>.unmodifiable(priceTrends),
    costSources: List<StatisticsCostSourceValue>.unmodifiable(costSources),
    dailySpendValues: List<StatisticsSpendingDayValue>.unmodifiable(
      dailySpendValues,
    ),
  );
}

DateTime resolveSpendingWindowStartDate({
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
  var cursor = normalizedStart;
  while (!cursor.isAfter(safeEnd)) {
    final dayEntries = entriesByDay[_dayKey(cursor)] ?? const <CalorieEntry>[];
    final totalKcal = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalKcal,
    );
    final totalProtein = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalProtein,
    );
    final totalCarbs = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalCarbs,
    );
    final totalFat = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.totalFat,
    );
    days.add(
      StatisticsCalorieDaySummary(
        date: cursor,
        entryCount: dayEntries.length,
        totalKcal: totalKcal,
        goalKcal: settings.goalKcalForDay(cursor),
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
      ),
    );
    cursor = cursor.add(const Duration(days: 1));
  }

  final balanceStartDate = settings.balanceStartForWindow(
    days.map((day) => day.date),
  );
  final balanceDays = days.where(
    (day) => !_normalizeDay(day.date).isBefore(_normalizeDay(balanceStartDate)),
  );

  final totalEntries = days.fold<int>(0, (sum, day) => sum + day.entryCount);
  final totalKcal = days.fold<double>(0, (sum, day) => sum + day.totalKcal);
  final totalProtein = days.fold<double>(
    0,
    (sum, day) => sum + day.totalProtein,
  );
  final totalCarbs = days.fold<double>(0, (sum, day) => sum + day.totalCarbs);
  final totalFat = days.fold<double>(0, (sum, day) => sum + day.totalFat);
  final trackedDayCount = days.where((day) => day.hasEntries).length;
  final goalMetDayCount = days.where((day) => day.isWithinGoal).length;
  final periodGoalKcal = days.fold<double>(0, (sum, day) => sum + day.goalKcal);
  final balanceGoalKcal = balanceDays.fold<double>(
    0,
    (sum, day) => sum + day.goalKcal,
  );
  final balanceConsumedKcal = balanceDays.fold<double>(
    0,
    (sum, day) => sum + day.totalKcal,
  );
  final averageTrackedKcal = trackedDayCount == 0
      ? 0.0
      : totalKcal / trackedDayCount.toDouble();

  return StatisticsCalorieSnapshot(
    startDate: normalizedStart,
    endDate: safeEnd,
    balanceStartDate: balanceStartDate,
    days: List<StatisticsCalorieDaySummary>.unmodifiable(days),
    totalEntries: totalEntries,
    totalKcal: totalKcal,
    totalProtein: totalProtein,
    totalCarbs: totalCarbs,
    totalFat: totalFat,
    periodGoalKcal: periodGoalKcal,
    balanceGoalKcal: balanceGoalKcal,
    balanceConsumedKcal: balanceConsumedKcal,
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
        subtitle: last.storeName.trim(),
        previousPrice: first.unitPrice,
        latestPrice: last.unitPrice,
        changeRatio: changeRatio,
        firstSeenAt: _resolvedItemDate(first),
        lastSeenAt: _resolvedItemDate(last),
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
  final groupedValues =
      <DateTime, ({double value, Set<String> receiptIds, int fallbackCount})>{};

  for (final item in items) {
    final value = calculatePurchasedInventoryValue(item);
    if (value <= 0) {
      continue;
    }

    final date = _normalizeDay(_resolvedItemDate(item));
    final current = groupedValues[date];
    final receiptId = item.receiptId?.trim();
    final receiptIds = <String>{
      if (current != null) ...current.receiptIds,
      if (receiptId != null && receiptId.isNotEmpty) receiptId,
    };
    final fallbackCount =
        (current?.fallbackCount ?? 0) +
        ((receiptId == null || receiptId.isEmpty) ? 1 : 0);
    groupedValues[date] = (
      value: (current?.value ?? 0) + value,
      receiptIds: receiptIds,
      fallbackCount: fallbackCount,
    );
  }

  final values =
      groupedValues.entries
          .map(
            (entry) => StatisticsSpendingDayValue(
              date: entry.key,
              value: entry.value.value,
              receiptCount: entry.value.receiptIds.isNotEmpty
                  ? entry.value.receiptIds.length
                  : entry.value.fallbackCount,
            ),
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
      kcal: carbKcal,
      share: share(carbKcal),
    ),
    StatisticsMacroShare(
      type: StatisticsMacroType.protein,
      grams: protein,
      kcal: proteinKcal,
      share: share(proteinKcal),
    ),
    StatisticsMacroShare(
      type: StatisticsMacroType.fat,
      grams: fat,
      kcal: fatKcal,
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
