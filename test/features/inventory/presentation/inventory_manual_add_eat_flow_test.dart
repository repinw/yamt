import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/eat_selection.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/inventory/presentation/'
    'inventory_manual_add_eat_flow.dart';

void main() {
  test('eat request can be built from generic selection', () {
    final loggedAt = DateTime.parse('2026-04-13T20:00:00Z');

    final request = inventoryManualAddEatRequestFromSelection(
      EatSelection(
        inventoryAmount: 380,
        loggedAt: loggedAt,
        mealType: MealType.dinner,
      ),
    );

    expect(request?.inventoryAmount, 380);
    expect(request?.loggedAt, loggedAt);
    expect(request?.mealType, MealType.dinner);
  });
}
