import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_discard_event.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

void main() {
  test('fromJson throws for an invalid discarded_at value', () {
    expect(
      () => InventoryDiscardEvent.fromJson(<String, dynamic>{
        'id': 'event-1',
        'source_type': 'inventoryItem',
        'source_id': 'item-1',
        'name': 'Milk',
        'reason': 'expired',
        'discarded_at': 'not-a-date',
        'discarded_amount': 1,
        'discarded_value': 1.5,
        'currency_code': 'EUR',
      }),
      throwsA(isA<FormatException>()),
    );
  });

  test('fromPreparedMeal keeps fractional discarded portions and value', () {
    final meal = PreparedMeal(
      id: 'meal-1',
      name: 'Soup',
      totalPortions: 4,
      remainingPortions: 2,
      totalKcal: 400,
      totalProtein: 20,
      totalCarbs: 40,
      totalFat: 10,
      createdAt: DateTime(2026, 3, 27),
      updatedAt: DateTime(2026, 3, 27),
      components: <PreparedMealComponent>[
        PreparedMealComponent(
          inventoryItemId: 'item-1',
          name: 'Beans',
          brand: null,
          imageUrl: null,
          usedAmount: 4,
          usedUnit: InventoryAmountUnit.piece,
          totalKcal: 400,
          totalProtein: 20,
          totalCarbs: 40,
          totalFat: 10,
          sourceItemSnapshot: InventoryItem.create(
            id: 'item-1',
            name: 'Beans',
            entryDate: DateTime(2026, 3, 27),
            storeName: 'Store',
            quantity: 4,
            initialQuantity: 4,
            unitPrice: 2,
          ),
        ),
      ],
    );

    final event = InventoryDiscardEvent.fromPreparedMeal(
      id: 'discard-1',
      meal: meal,
      discardedPortions: 0.5,
      reason: InventoryDiscardReason.expired,
    );

    expect(event.discardedAmount, 0.5);
    expect(event.discardedValue, closeTo(1, 0.0001));
    expect(event.toJson()['discarded_amount'], 0.5);
  });
}
