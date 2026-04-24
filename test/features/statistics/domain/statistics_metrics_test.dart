import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/statistics/domain/calorie_metrics.dart';
import 'package:yamt/features/statistics/domain/spending_metrics.dart';

InventoryItem _inventoryItem({
  required String id,
  required String name,
  required DateTime entryDate,
  required String storeName,
  required int quantity,
  int initialQuantity = 1,
  double unitPrice = 1.0,
  int initialAmount = 0,
  int currentAmount = 0,
  InventoryAmountUnit? amountUnit,
  DateTime? receiptDate,
  String? receiptId,
}) {
  return InventoryItem.create(
    id: id,
    name: name,
    entryDate: entryDate,
    storeName: storeName,
    quantity: quantity,
    initialQuantity: initialQuantity,
    unitPrice: unitPrice,
    initialAmount: initialAmount,
    currentAmount: currentAmount,
    amountUnit: amountUnit,
    receiptDate: receiptDate,
    receiptId: receiptId,
  );
}

CalorieEntry _entry(
  String id, {
  required DateTime loggedAt,
  required double totalKcal,
  required double protein,
  required double carbs,
  required double fat,
}) {
  return CalorieEntry.create(
    id: id,
    userId: 'user-1',
    name: 'Entry $id',
    mealType: MealType.breakfast,
    consumedAmount: 100,
    consumedUnit: ConsumedUnit.grams,
    per100Kcal: totalKcal,
    per100Protein: protein,
    per100Carbs: carbs,
    per100Fat: fat,
    loggedAt: loggedAt,
    createdAt: loggedAt,
    updatedAt: loggedAt,
  );
}

void main() {
  test('buildStatisticsSpendingSnapshot aggregates tracked purchases', () {
    final snapshot = buildStatisticsSpendingSnapshot(
      items: [
        _inventoryItem(
          id: 'rice',
          name: 'Rice',
          entryDate: DateTime(2026, 4),
          storeName: 'REWE',
          quantity: 2,
          initialQuantity: 2,
          unitPrice: 2,
          receiptDate: DateTime(2026, 3, 21),
          receiptId: 'receipt-1',
        ),
        _inventoryItem(
          id: 'beans',
          name: 'Beans',
          entryDate: DateTime(2026, 4),
          storeName: 'Lidl',
          quantity: 1,
          unitPrice: 3,
          receiptDate: DateTime(2026, 3, 27),
          receiptId: 'receipt-2',
        ),
      ],
      startDate: DateTime(2026, 3),
      endDate: DateTime(2026, 3, 31),
    );

    expect(snapshot.totalValue, 7);
    expect(snapshot.topStores.first.storeName, 'REWE');
    expect(snapshot.expensiveEntries.first.title, 'Rice');
    expect(snapshot.dailySpendValues, hasLength(2));
    expect(snapshot.dailySpendValues.first.date, DateTime(2026, 3, 21));
    expect(snapshot.dailySpendValues.last.date, DateTime(2026, 3, 27));
    expect(snapshot.dailySpendValues.first.value, 4);
    expect(snapshot.dailySpendValues.last.value, 3);
  });

  test('resolveVisibleSpendingStartDate keeps sparse receipt dates visible '
      'for week view', () {
    final startDate = resolveVisibleSpendingStartDate(
      spendingDates: [DateTime(2026, 3, 21), DateTime(2026, 3, 27)],
      maxVisibleDays: 7,
      fallbackDate: DateTime(2026, 4),
    );

    expect(startDate, DateTime(2026, 3, 21));
  });

  test('buildStatisticsCalorieSnapshot computes balance and averages', () {
    final settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 3, 20),
    );
    final snapshot = buildStatisticsCalorieSnapshot(
      entries: [
        _entry(
          'a',
          loggedAt: DateTime(2026, 3, 20, 8),
          totalKcal: 1800,
          protein: 120,
          carbs: 150,
          fat: 60,
        ),
        _entry(
          'b',
          loggedAt: DateTime(2026, 3, 21, 8),
          totalKcal: 2200,
          protein: 130,
          carbs: 200,
          fat: 70,
        ),
      ],
      settings: settings,
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 3, 21),
    );

    expect(snapshot.days, hasLength(2));
    expect(snapshot.totalEntries, 2);
    expect(snapshot.goalMetDayCount, 1);
    expect(snapshot.averageTrackedKcal, 2000);
    expect(snapshot.balanceRemainingKcal, 0);
    expect(
      snapshot.macroShares.fold<double>(0, (sum, share) => sum + share.share),
      closeTo(1.0, 0.0001),
    );
  });

  test('buildStatisticsCalorieSnapshot excludes practice days', () {
    final settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 3, 20),
      countingStartDate: DateTime(2026, 3, 21),
      source: CalorieGoalSource.calculator,
    );

    final snapshot = buildStatisticsCalorieSnapshot(
      entries: [
        _entry(
          'practice',
          loggedAt: DateTime(2026, 3, 20, 18),
          totalKcal: 800,
          protein: 20,
          carbs: 80,
          fat: 30,
        ),
        _entry(
          'counted',
          loggedAt: DateTime(2026, 3, 21, 8),
          totalKcal: 1800,
          protein: 120,
          carbs: 150,
          fat: 60,
        ),
      ],
      settings: settings,
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 3, 21),
      shouldIncludeDay: (day) => !settings.isGoalPracticeDay(day),
    );

    expect(snapshot.days, hasLength(1));
    expect(snapshot.days.single.date, DateTime(2026, 3, 21));
    expect(snapshot.totalEntries, 1);
    expect(snapshot.averageTrackedKcal, 1800);
    expect(snapshot.balanceRemainingKcal, 200);
  });

  test('buildStatisticsCalorieSnapshot keeps same-day quick starts', () {
    final settings = CalorieGoalSettings.single(
      dailyKcalGoal: 2000,
      calculatorProfile: null,
      effectiveDate: DateTime(2026, 3, 20, 18),
      source: CalorieGoalSource.calculator,
    );

    final snapshot = buildStatisticsCalorieSnapshot(
      entries: [
        _entry(
          'quick-start',
          loggedAt: DateTime(2026, 3, 20, 18),
          totalKcal: 800,
          protein: 20,
          carbs: 80,
          fat: 30,
        ),
      ],
      settings: settings,
      startDate: DateTime(2026, 3, 20),
      endDate: DateTime(2026, 3, 20),
      shouldIncludeDay: (day) => !settings.isGoalPracticeDay(day),
    );

    expect(snapshot.days, hasLength(1));
    expect(snapshot.totalEntries, 1);
    expect(snapshot.trackedDayCount, 1);
    expect(snapshot.averageTrackedKcal, 800);
    expect(snapshot.balanceRemainingKcal, 1200);
  });
}
