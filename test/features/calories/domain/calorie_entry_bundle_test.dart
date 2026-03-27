import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

void main() {
  test('bundle factory creates a read-only bundle entry snapshot', () {
    final entry = CalorieEntry.bundle(
      id: 'bundle-1',
      userId: 'user-1',
      name: 'Chili',
      imageBase64: base64Encode(<int>[1, 2, 3]),
      mealType: MealType.dinner,
      totalKcal: 420,
      totalProtein: 28,
      totalCarbs: 35,
      totalFat: 18,
      bundleSourcePreparedMealId: 'prepared-1',
      bundleConsumedPortions: 2,
      bundleTotalPortions: 4,
      bundleComponents: const [
        CalorieEntryBundleComponent(
          name: 'Beans',
          amountLabel: '150 g',
          totalKcal: 120,
          totalProtein: 8,
          totalCarbs: 18,
          totalFat: 1,
        ),
      ],
      loggedAt: DateTime.parse('2026-03-27T18:00:00Z'),
      createdAt: DateTime.parse('2026-03-27T18:00:00Z'),
      updatedAt: DateTime.parse('2026-03-27T18:00:00Z'),
    );

    final roundtrip = CalorieEntry.fromJson(entry.toJson());

    expect(roundtrip.isBundle, isTrue);
    expect(roundtrip.bundleConsumedPortions, 2);
    expect(roundtrip.bundleComponents.single.amountLabel, '150 g');
    expect(roundtrip.imageBase64, base64Encode(<int>[1, 2, 3]));
    expect(roundtrip.totalKcal, 420);
  });
}
