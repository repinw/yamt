import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

void main() {
  test('create calculates totals from per100 and consumed amount', () {
    final entry = CalorieEntry.create(
      id: 'entry-1',
      userId: 'user-1',
      name: 'Skyr',
      mealType: MealType.breakfast,
      consumedAmount: 250,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 62,
      per100Protein: 11,
      per100Carbs: 4,
      per100Fat: 0.2,
      loggedAt: DateTime(2026, 2, 25, 9),
      createdAt: DateTime(2026, 2, 25, 9),
      updatedAt: DateTime(2026, 2, 25, 9),
    );

    expect(entry.totalKcal, closeTo(155, 0.0001));
    expect(entry.totalProtein, closeTo(27.5, 0.0001));
    expect(entry.totalCarbs, closeTo(10, 0.0001));
    expect(entry.totalFat, closeTo(0.5, 0.0001));
    expect(entry.isValid, isTrue);
  });

  test('recalculateTotals updates derived values', () {
    final base = CalorieEntry.create(
      id: 'entry-2',
      userId: 'user-1',
      name: 'Oats',
      mealType: MealType.breakfast,
      consumedAmount: 100,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 350,
      per100Protein: 12,
      per100Carbs: 55,
      per100Fat: 7,
      loggedAt: DateTime(2026, 2, 25, 9),
      createdAt: DateTime(2026, 2, 25, 9),
      updatedAt: DateTime(2026, 2, 25, 9),
    );

    final updated = base
        .copyWith(consumedAmount: 60, per100Kcal: 380)
        .recalculateTotals(updatedAt: DateTime(2026, 2, 25, 10));

    expect(updated.totalKcal, closeTo(228, 0.0001));
    expect(updated.totalProtein, closeTo(7.2, 0.0001));
    expect(updated.totalCarbs, closeTo(33, 0.0001));
    expect(updated.totalFat, closeTo(4.2, 0.0001));
    expect(updated.updatedAt, DateTime(2026, 2, 25, 10));
  });

  test('json conversion keeps persisted values stable', () {
    final original = CalorieEntry.create(
      id: 'entry-3',
      userId: 'user-1',
      name: 'Apple',
      brand: 'Bio',
      imageUrl: 'https://images.example.com/apple.jpg',
      imageBase64: base64Encode(<int>[4, 5, 6]),
      mealType: MealType.snack,
      consumedAmount: 150,
      consumedUnit: ConsumedUnit.grams,
      per100Kcal: 52,
      per100Protein: 0.3,
      per100Carbs: 14,
      per100Fat: 0.2,
      loggedAt: DateTime(2026, 2, 25, 15),
      createdAt: DateTime(2026, 2, 25, 15),
      updatedAt: DateTime(2026, 2, 25, 15),
    );

    final decoded = CalorieEntry.fromJson(original.toJson());

    expect(decoded.id, original.id);
    expect(decoded.userId, original.userId);
    expect(decoded.name, original.name);
    expect(decoded.brand, original.brand);
    expect(decoded.imageUrl, original.imageUrl);
    expect(decoded.imageBase64, original.imageBase64);
    expect(decoded.mealType, original.mealType);
    expect(decoded.consumedAmount, original.consumedAmount);
    expect(decoded.consumedUnit, original.consumedUnit);
    expect(decoded.totalKcal, closeTo(original.totalKcal, 0.0001));
  });
}
