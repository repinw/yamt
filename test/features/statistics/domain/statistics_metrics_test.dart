import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/calorie_goal_settings.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/statistics/domain/statistics_metrics.dart';

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

PreparedMeal _preparedMeal({
  required String id,
  required String name,
  required DateTime createdAt,
  required int totalPortions,
  required int remainingPortions,
  required double totalPrice,
}) {
  final sourceItem = _inventoryItem(
    id: '${id}_item',
    name: '$name ingredient',
    entryDate: createdAt,
    storeName: 'REWE',
    quantity: totalPrice.round(),
    initialQuantity: totalPrice.round(),
    unitPrice: 1,
  );

  return PreparedMeal(
    id: id,
    name: name,
    totalPortions: totalPortions,
    remainingPortions: remainingPortions,
    totalKcal: 900,
    totalProtein: 50,
    totalCarbs: 80,
    totalFat: 25,
    createdAt: createdAt,
    updatedAt: createdAt,
    components: [
      PreparedMealComponent(
        inventoryItemId: sourceItem.id,
        name: sourceItem.name,
        brand: sourceItem.brand,
        imageUrl: sourceItem.imageUrl,
        usedAmount: totalPrice.round(),
        usedUnit: InventoryAmountUnit.piece,
        totalKcal: 900,
        totalProtein: 50,
        totalCarbs: 80,
        totalFat: 25,
        sourceItemSnapshot: sourceItem,
      ),
    ],
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
  test('calculateRemainingInventoryValue respects amount progress ratio', () {
    final item = _inventoryItem(
      id: 'milk',
      name: 'Milk',
      entryDate: DateTime(2026, 3, 20),
      storeName: 'REWE',
      quantity: 1,
      initialQuantity: 1,
      unitPrice: 4,
      initialAmount: 1000,
      currentAmount: 250,
      amountUnit: InventoryAmountUnit.milliliter,
    );

    final value = calculateRemainingInventoryValue(item);

    expect(value, 1);
  });

  test('buildStatisticsSpendingSnapshot aggregates current values', () {
    final snapshot = buildStatisticsSpendingSnapshot(
      items: [
        _inventoryItem(
          id: 'rice',
          name: 'Rice',
          entryDate: DateTime(2026, 4, 1),
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
          entryDate: DateTime(2026, 4, 1),
          storeName: 'Lidl',
          quantity: 1,
          initialQuantity: 1,
          unitPrice: 3,
          receiptDate: DateTime(2026, 3, 27),
          receiptId: 'receipt-2',
        ),
      ],
      meals: [
        _preparedMeal(
          id: 'meal-1',
          name: 'Chili',
          createdAt: DateTime(2026, 3, 20),
          totalPortions: 4,
          remainingPortions: 2,
          totalPrice: 10,
        ),
      ],
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 3, 31),
    );

    expect(snapshot.totalValue, 12);
    expect(snapshot.inventoryValue, 7);
    expect(snapshot.preparedMealValue, 5);
    expect(snapshot.topStores.first.storeName, 'REWE');
    expect(snapshot.expensiveEntries.first.title, 'Chili');
    expect(snapshot.dailySpendValues, hasLength(2));
    expect(snapshot.dailySpendValues.first.date, DateTime(2026, 3, 21));
    expect(snapshot.dailySpendValues.last.date, DateTime(2026, 3, 27));
    expect(snapshot.dailySpendValues.first.value, 4);
    expect(snapshot.dailySpendValues.last.value, 3);
  });

  test('resolveSpendingWindowStartDate keeps sparse receipt dates visible '
      'for week view', () {
    final startDate = resolveSpendingWindowStartDate(
      spendingDates: [DateTime(2026, 3, 21), DateTime(2026, 3, 27)],
      maxVisibleDays: 7,
      fallbackDate: DateTime(2026, 4, 1),
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
}
