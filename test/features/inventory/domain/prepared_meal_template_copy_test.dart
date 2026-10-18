import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_template_copy.dart';

void main() {
  test('a template has every portion left and was never eaten', () {
    final meal = PreparedMeal(
      id: 'chili',
      name: ' Chili ',
      totalPortions: 4,
      remainingPortions: 1,
      totalKcal: 2000,
      totalProtein: 100,
      totalCarbs: 200,
      totalFat: 80,
      createdAt: DateTime(2026, 10, 7),
      updatedAt: DateTime(2026, 10, 7),
      lastEatenAt: DateTime(2026, 10, 8),
      components: const <PreparedMealComponent>[],
    );
    final now = DateTime(2026, 10, 9);

    final template = meal.asTemplate(id: 'template-1', now: now);

    expect(template.id, 'template-1');
    expect(template.name, 'Chili');
    expect(template.remainingPortions, 4);
    expect(template.lastEatenAt, isNull);
    expect(template.createdAt, now);
  });
}
