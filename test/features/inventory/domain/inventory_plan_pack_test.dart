import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_plan_pack.dart';

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 400,
  per100Protein: 10,
  per100Carbs: 60,
  per100Fat: 12,
);

final _day = DateTime(2026, 10, 6, 8);

final _plan = CalorieEntry.create(
  id: 'plan',
  userId: 'user-1',
  name: 'Oats',
  brand: 'Kölln',
  mealType: MealType.breakfast,
  consumedAmount: 60,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: 400,
  per100Protein: 10,
  per100Carbs: 60,
  per100Fat: 12,
  sourceInventoryItemId: 'gone',
  sourceInventoryAmountToRestore: 60,
  loggedAt: _day,
  createdAt: _day,
  updatedAt: _day,
);

InventoryItem _pack(
  String id, {
  String name = 'Oats',
  int currentAmount = 500,
  DateTime? entryDate,
}) => InventoryItem.create(
  id: id,
  name: name,
  brand: 'Kölln',
  nutrition: _nutrition,
  entryDate: entryDate ?? DateTime(2026, 9),
  storeName: 'Rewe',
  quantity: 1,
  initialAmount: 500,
  currentAmount: currentAmount,
  amountUnit: InventoryAmountUnit.gram,
);

/// The same food, counted in pieces, with [pieceGrams] per piece when
/// known. A pack without [amountUnit] has no size and counts whole packs.
InventoryItem _piecePack({
  String id = 'pieces',
  double? pieceGrams,
  InventoryAmountUnit? amountUnit = InventoryAmountUnit.piece,
}) => InventoryItem.create(
  id: id,
  name: 'Oats',
  brand: 'Kölln',
  nutrition: _nutrition,
  entryDate: DateTime(2026, 9),
  storeName: 'Rewe',
  quantity: 6,
  amountUnit: amountUnit,
  servingQuantity: pieceGrams,
  servingQuantityUnit: pieceGrams == null ? null : 'g',
);

void main() {
  test('takes an opened pack of the food before a full one', () {
    final opened = _pack('opened', currentAmount: 200);

    expect(
      pickInventoryItemForPlan(_plan, [
        _pack('older', entryDate: DateTime(2026, 8)),
        opened,
      ]),
      opened,
    );
  });

  test('takes the oldest of the full packs', () {
    final older = _pack('older', entryDate: DateTime(2026, 8));

    expect(pickInventoryItemForPlan(_plan, [_pack('newer'), older]), older);
  });

  test('skips other foods, empty packs, and packs in another unit', () {
    expect(
      pickInventoryItemForPlan(_plan, [
        _pack('rice', name: 'Rice'),
        _pack('empty', currentAmount: 0),
        _piecePack(),
      ]),
      isNull,
    );
  });

  group('inventoryAmountForPlan', () {
    test('takes the planned amount from the planned pack', () {
      expect(
        inventoryAmountForPlan(_plan, _pack('gone', currentAmount: 10)),
        60,
      );
    });

    test('takes the eaten grams from another gram pack', () {
      expect(
        inventoryAmountForPlan(
          _plan.copyWith(sourceInventoryAmountToRestore: 25),
          _pack('other'),
        ),
        60,
      );
    });

    test('converts the eaten grams into pieces by the piece weight', () {
      final plan = _plan.copyWith(
        sourceInventoryItemId: 'eggs',
        sourceInventoryAmountToRestore: null,
        consumedAmount: 120,
      );

      expect(
        inventoryAmountForPlan(plan, _piecePack(id: 'eggs', pieceGrams: 60)),
        2,
      );
      expect(inventoryAmountForPlan(plan, _piecePack(id: 'eggs')), isNull);
    });

    test('a pack without a size takes no stock by its serving', () {
      final plan = _plan.copyWith(
        sourceInventoryItemId: 'eggs',
        sourceInventoryAmountToRestore: null,
        consumedAmount: 120,
      );

      expect(
        inventoryAmountForPlan(
          plan,
          _piecePack(id: 'eggs', pieceGrams: 60, amountUnit: null),
        ),
        isNull,
      );
    });

    test('a same named piece pack with a piece weight is the food', () {
      expect(
        pickInventoryItemForPlan(
          _plan.copyWith(sourceInventoryItemId: 'gone-too'),
          [_piecePack(pieceGrams: 30)],
        )?.id,
        'pieces',
      );
    });
  });
}
