import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/presentation/formatters/inventory_nutrition_format.dart';

void main() {
  test('drops trailing decimals for whole numbers', () {
    expect(formatInventoryNutritionValue(10), '10');
  });

  test('keeps one decimal for fractional numbers', () {
    expect(formatInventoryNutritionValue(10.5), '10.5');
  });

  test('rounds to one decimal place', () {
    expect(formatInventoryNutritionValue(10.56), '10.6');
  });
}
