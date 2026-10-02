import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/product_missing_values.dart';

const _complete = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 67,
  per100Fat: 0.3,
  per100SaturatedFat: 0.2,
  per100Carbs: 4,
  per100Sugar: 4,
  per100Protein: 12,
  per100Salt: 0.1,
);

InventoryItem _item({
  String? weight,
  double? servingQuantity,
  String? servingQuantityUnit,
  GlobalFoodNutrition? nutrition = _complete,
}) {
  return InventoryItem.create(
    id: 'item',
    name: 'Speisequark',
    entryDate: DateTime.utc(2026, 10, 2),
    storeName: 'Store',
    quantity: 1,
    weight: weight,
    servingQuantity: servingQuantity,
    servingQuantityUnit: servingQuantityUnit,
    nutrition: nutrition,
  );
}

void main() {
  group('missingNutritionValues', () {
    test('is empty for the seven values of the label', () {
      expect(missingNutritionValues(_complete), isEmpty);
    });

    test('lists the missing values in label order', () {
      expect(
        missingNutritionValues(
          _complete.copyWith(per100Salt: null, per100Sugar: null),
        ),
        [ProductMissingValue.sugar, ProductMissingValue.salt],
      );
    });

    test('lists all seven without nutrition', () {
      expect(missingNutritionValues(null), hasLength(7));
    });
  });

  group('missingPackageSize', () {
    ProductMissingValue? check(
      String? size, {
      double? servingQuantity,
      String? servingQuantityUnit,
    }) => missingPackageSize(
      packageSize: size,
      servingQuantity: servingQuantity,
      servingQuantityUnit: servingQuantityUnit,
    );

    test('accepts grams and milliliters', () {
      expect(check('500 g'), isNull);
      expect(check('1 l'), isNull);
      expect(check('6 x 0,33 l'), isNull);
    });

    test('names a missing size', () {
      expect(check(null), ProductMissingValue.packageSize);
      expect(check(''), ProductMissingValue.packageSize);
      expect(check('Packung'), ProductMissingValue.packageSize);
    });

    test('asks for grams per piece for pieces without a serving', () {
      expect(check('1 Stück'), ProductMissingValue.pieceWeight);
      expect(check('10 Stk'), ProductMissingValue.pieceWeight);
      expect(
        check('10 Stk', servingQuantity: 1, servingQuantityUnit: 'pc'),
        ProductMissingValue.pieceWeight,
      );
    });

    test('accepts pieces with a serving in grams', () {
      expect(
        check('10 Stück', servingQuantity: 60, servingQuantityUnit: 'g'),
        isNull,
      );
    });
  });

  group('missingItemValues', () {
    test('checks the package size only when asked', () {
      final item = _item(nutrition: _complete.copyWith(per100Salt: null));

      expect(missingItemValues(item, checkPackageSize: false), [
        ProductMissingValue.salt,
      ]);
      expect(missingItemValues(item, checkPackageSize: true), [
        ProductMissingValue.packageSize,
        ProductMissingValue.salt,
      ]);
    });

    test('is empty for a complete item', () {
      expect(
        missingItemValues(_item(weight: '500 g'), checkPackageSize: true),
        isEmpty,
      );
    });
  });
}
