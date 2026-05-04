import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';

void main() {
  test('section order is stable', () {
    expect(MealType.sectionOrder, <MealType>[
      MealType.breakfast,
      MealType.lunch,
      MealType.dinner,
      MealType.snack,
    ]);
  });

  test('defaultForDateTime maps hour ranges correctly', () {
    final cases = <({int hour, MealType mealType})>[
      (hour: 4, mealType: MealType.snack),
      (hour: 5, mealType: MealType.breakfast),
      (hour: 10, mealType: MealType.breakfast),
      (hour: 11, mealType: MealType.lunch),
      (hour: 15, mealType: MealType.lunch),
      (hour: 16, mealType: MealType.dinner),
      (hour: 21, mealType: MealType.dinner),
      (hour: 22, mealType: MealType.snack),
    ];

    for (final entry in cases) {
      expect(
        MealType.defaultForDateTime(DateTime(2026, 2, 1, entry.hour)),
        entry.mealType,
      );
    }
  });
}
