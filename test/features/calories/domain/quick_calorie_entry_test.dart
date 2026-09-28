import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/quick_calorie_entry.dart';

void main() {
  final loggedAt = DateTime(2026, 9, 28, 13, 5);
  final now = DateTime(2026, 9, 28, 13, 6);

  CalorieEntry quick({double? protein, double? carbs, double? fat}) {
    return buildQuickCalorieEntry(
      id: 'quick-1',
      userId: 'user-1',
      name: 'Kantine',
      mealType: MealType.lunch,
      loggedAt: loggedAt,
      now: now,
      kcal: 650,
      protein: protein,
      carbs: carbs,
      fat: fat,
    );
  }

  test('the typed values are the totals of a quick entry', () {
    final entry = quick(protein: 30, carbs: 70.5, fat: 22);

    expect(entry.isQuickEntry, isTrue);
    expect(entry.name, 'Kantine');
    expect(entry.mealType, MealType.lunch);
    expect(entry.loggedAt, loggedAt);
    expect(entry.createdAt, now);
    expect(entry.updatedAt, now);
    expect(entry.totalKcal, 650);
    expect(entry.totalProtein, 30);
    expect(entry.totalCarbs, 70.5);
    expect(entry.totalFat, 22);
    expect(entry.isBundle, isFalse);
    expect(entry.canRestoreToInventory, isFalse);
    expect(entry.isValid, isTrue);
  });

  test('a quick entry counts as 100 g of itself', () {
    final entry = quick(protein: 30, carbs: 70.5, fat: 22);

    expect(entry.consumedAmount, 100);
    expect(entry.consumedUnit, ConsumedUnit.grams);
    expect(entry.per100Kcal, entry.totalKcal);
    expect(entry.per100Protein, entry.totalProtein);
    expect(entry.per100Carbs, entry.totalCarbs);
    expect(entry.per100Fat, entry.totalFat);
    expect(entry.recalculateTotals(updatedAt: now).totalKcal, 650);
  });

  test('macros that were not typed count as 0 g', () {
    final entry = quick(carbs: 12);

    expect(entry.totalProtein, 0);
    expect(entry.totalCarbs, 12);
    expect(entry.totalFat, 0);
    expect(entry.isValid, isTrue);
  });

  test('the quick entry mark survives JSON and copies', () {
    final entry = quick(protein: 30);

    expect(CalorieEntry.fromJson(entry.toJson()).isQuickEntry, isTrue);
    expect(entry.copyWith(mealType: MealType.dinner).isQuickEntry, isTrue);
    expect(
      CalorieEntry.create(
        id: 'food-1',
        userId: 'user-1',
        name: 'Skyr',
        mealType: MealType.breakfast,
        consumedAmount: 150,
        consumedUnit: ConsumedUnit.grams,
        per100Kcal: 62,
        per100Protein: 11,
        per100Carbs: 4,
        per100Fat: 0.2,
        loggedAt: loggedAt,
        createdAt: now,
        updatedAt: now,
      ).isQuickEntry,
      isFalse,
    );
  });

  test('an entry without the quick entry mark does not parse', () {
    final json = quick().toJson()..remove('is_quick_entry');

    expect(() => CalorieEntry.fromJson(json), throwsA(isA<TypeError>()));
  });
}
