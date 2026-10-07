import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/shoppinglist/application/shopping_plan_needs.dart';
import 'package:yamt/features/shoppinglist/domain/shopping_plan_need.dart';

ShoppingPlanNeed _need(String name, DateTime day, MealType mealType) =>
    ShoppingPlanNeed(
      name: name,
      day: day,
      mealType: mealType,
      amount: 100,
      inMilliliters: false,
      isPartial: false,
    );

void main() {
  final tuesday = DateTime(2026, 10, 13, 8);
  final thursday = DateTime(2026, 10, 15, 8);

  test('groups by day and meal in plan order', () {
    final groups = groupShoppingPlanNeeds([
      _need('Milk', tuesday, MealType.breakfast),
      _need(
        'Oats',
        tuesday.add(const Duration(minutes: 5)),
        MealType.breakfast,
      ),
      _need('Rice', tuesday.add(const Duration(hours: 4)), MealType.lunch),
      _need('Skyr', thursday, MealType.breakfast),
    ], const {});

    expect(groups.map((group) => (group.day, group.mealType)), [
      (DateTime(2026, 10, 13), MealType.breakfast),
      (DateTime(2026, 10, 13), MealType.lunch),
      (DateTime(2026, 10, 15), MealType.breakfast),
    ]);
    expect(groups.first.needs.map((need) => need.name), ['Milk', 'Oats']);
  });

  test('leaves out foods already on the list', () {
    final groups = groupShoppingPlanNeeds(
      [
        _need('Milk', tuesday, MealType.breakfast),
        _need('Skyr', thursday, MealType.breakfast),
      ],
      {(normalizedName: 'milk', normalizedBrand: '')},
    );

    expect(groups.single.needs.single.name, 'Skyr');
  });

  test('mixed meals on a day form one group each, in diary order', () {
    final groups = groupShoppingPlanNeeds([
      _need('Soup', tuesday.add(const Duration(hours: 1)), MealType.lunch),
      _need('Milk', tuesday.add(const Duration(hours: 2)), MealType.breakfast),
      _need('Rice', tuesday.add(const Duration(hours: 3)), MealType.lunch),
      _need('Skyr', thursday, MealType.breakfast),
    ], const {});

    expect(groups.map((group) => (group.day.day, group.mealType)), [
      (13, MealType.breakfast),
      (13, MealType.lunch),
      (15, MealType.breakfast),
    ]);
    expect(groups[1].needs.map((need) => need.name), ['Soup', 'Rice']);
    expect(
      () => groups.first.needs.add(groups.first.needs.first),
      throwsUnsupportedError,
    );
  });
}
