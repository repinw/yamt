import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/food_estimate.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/product_search_hub/domain/recipe_guess_item.dart';

const _estimate = FoodEstimate(
  name: 'Flour',
  portionGrams: 50,
  kcalLean: 170,
  kcalRich: 190,
  per100: GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.unverified,
    per100Kcal: 350,
  ),
  ingredients: [],
);

final _base = InventoryItem.create(
  id: 'item',
  name: 'Placeholder',
  entryDate: DateTime(2026, 11, 12),
  storeName: 'Store',
  quantity: 1,
);

({InventoryItem item, int amount}) _guess(
  InventoryAmountUnit unit,
  int need, {
  int? pieceWeight,
}) => recipeGuessItem(
  baseItem: _base,
  estimate: _estimate,
  description: 'flour',
  unit: unit,
  need: need,
  pieceWeight: pieceWeight,
);

void main() {
  test('the item is marked estimated and carries the estimate', () {
    final guessed = _guess(InventoryAmountUnit.gram, 250);

    expect(guessed.item.aiEstimated, isTrue);
    expect(guessed.item.name, 'Flour');
    expect(guessed.item.nutrition?.per100Kcal, 350);
    expect(guessed.item.productSnapshot.aiEstimate?.description, 'flour');
  });

  test('grams: exactly the need', () {
    final guessed = _guess(InventoryAmountUnit.gram, 250);

    expect(guessed.amount, 250);
    expect(guessed.item.amountUnit, InventoryAmountUnit.gram);
    expect(guessed.item.initialAmount, 250);
    expect(guessed.item.currentAmount, 250);
  });

  test('milliliters: exactly the need in ml', () {
    final guessed = _guess(InventoryAmountUnit.milliliter, 200);

    expect(guessed.amount, 200);
    expect(guessed.item.amountUnit, InventoryAmountUnit.milliliter);
    expect(guessed.item.currentAmount, 200);
  });

  test('pieces: the need in thousandths, weighing the given piece weight', () {
    final guessed = _guess(InventoryAmountUnit.piece, 3, pieceWeight: 60);

    expect(guessed.amount, 3 * inventoryPieceAmountScale);
    expect(guessed.item.amountUnit, InventoryAmountUnit.piece);
    expect(guessed.item.amountScale, inventoryPieceAmountScale);
    expect(guessed.item.currentAmount, 3 * inventoryPieceAmountScale);
    expect(guessed.item.servingQuantity, 60);
    expect(guessed.item.servingQuantityUnit, 'g');
  });

  test('pieces without a piece weight weigh the estimated portion', () {
    final guessed = _guess(InventoryAmountUnit.piece, 2);

    expect(guessed.item.servingQuantity, 50);
  });

  _descriptionTests();
}

void _descriptionTests() {
  group('recipeGuessDescription', () {
    test('adds the addition in brackets of the line', () {
      expect(
        recipeGuessDescription(
          'Frischkäse',
          '100 g Frischkäse (Doppelrahmstufe)',
        ),
        'Frischkäse (Doppelrahmstufe)',
      );
    });

    test('trims the addition', () {
      expect(
        recipeGuessDescription('Parmesan', '30 g Parmesan ( gerieben )'),
        'Parmesan (gerieben)',
      );
    });

    test('stays the food without a line or without brackets', () {
      expect(recipeGuessDescription('Mehl', null), 'Mehl');
      expect(recipeGuessDescription('Mehl', '200 g Mehl'), 'Mehl');
    });

    test('stays the food for empty brackets', () {
      expect(recipeGuessDescription('Mehl', '200 g Mehl ()'), 'Mehl');
      expect(recipeGuessDescription('Mehl', '200 g Mehl (  )'), 'Mehl');
    });

    test('stays the food when the addition names an amount', () {
      expect(
        recipeGuessDescription('Tomaten', '1 Dose Tomaten (à 400 g)'),
        'Tomaten',
      );
    });

    test('stays the food when it has brackets of its own', () {
      expect(
        recipeGuessDescription('Frischkäse (fettarm)', 'Frischkäse (Natur)'),
        'Frischkäse (fettarm)',
      );
    });
  });
}
