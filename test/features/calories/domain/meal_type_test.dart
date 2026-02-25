import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/calories/domain/meal_type.dart';

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
    expect(
      MealType.defaultForDateTime(DateTime(2026, 2, 1, 6)),
      MealType.breakfast,
    );
    expect(
      MealType.defaultForDateTime(DateTime(2026, 2, 1, 12)),
      MealType.lunch,
    );
    expect(
      MealType.defaultForDateTime(DateTime(2026, 2, 1, 18)),
      MealType.dinner,
    );
    expect(
      MealType.defaultForDateTime(DateTime(2026, 2, 1, 2)),
      MealType.snack,
    );
  });
}
