import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rows.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_rules.dart';

final _now = DateTime.utc(2026, 10, 10);

PreparedMealComponent _component(
  String itemId,
  String name, {
  int usedAmount = 200,
  InventoryAmountUnit unit = InventoryAmountUnit.gram,
  int amountScale = 1,
  String? row,
}) {
  final item = InventoryItem.create(
    id: itemId,
    name: name,
    entryDate: _now,
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: unit,
    amountScale: amountScale,
  );
  return PreparedMealComponent(
    inventoryItemId: itemId,
    name: name,
    brand: null,
    imageUrl: null,
    usedAmount: usedAmount,
    usedUnit: unit,
    totalKcal: 100,
    totalProtein: 1,
    totalCarbs: 2,
    totalFat: 3,
    sourceItemSnapshot: item,
    pendingRecipeIngredient: row,
  );
}

PreparedMeal _meal({
  List<PreparedMealComponent> components = const [],
  List<String> open = const [],
  List<String> ignored = const [],
}) {
  return PreparedMeal(
    id: 'pan',
    name: 'Reispfanne',
    totalPortions: 2,
    remainingPortions: 2,
    totalKcal: 0,
    totalProtein: 0,
    totalCarbs: 0,
    totalFat: 0,
    createdAt: _now,
    updatedAt: _now,
    components: components,
    pendingRecipeIngredients: open,
    ignoredPendingRecipeIngredients: ignored,
  );
}

void main() {
  group('ignored rows', () {
    test('an ignored row stays on the meal and opens again', () {
      final meal = _meal(open: const ['200 g Reis', 'Salz']);

      final ignored = meal.withRowIgnored('Salz')!;
      expect(ignored.pendingRecipeIngredients, ['200 g Reis']);
      expect(ignored.ignoredPendingRecipeIngredients, ['Salz']);

      final opened = ignored.withRowOpened('Salz')!;
      expect(opened, meal);
    });

    test('ignored rows do not keep the meal from being eaten', () {
      final meal = _meal(open: const ['Salz']).withRowIgnored('Salz')!;

      expect(meal.hasPendingRecipeIngredients, isFalse);
      expect(meal.allows(PreparedMealAction.eat), isTrue);
    });

    test('only an open row can be ignored, only an ignored one opened', () {
      final meal = _meal(open: const ['Salz'], ignored: const ['Pfeffer']);

      expect(meal.withRowIgnored('Pfeffer'), isNull);
      expect(meal.withRowOpened('Salz'), isNull);
    });

    test('filling part of an ignored row keeps the rest ignored', () {
      final meal = _meal(ignored: const ['500 g Reis', 'Salz']);

      final filled = meal.withoutRow('500 g Reis', rest: '200 g Reis')!;

      expect(filled.ignoredPendingRecipeIngredients, ['200 g Reis', 'Salz']);
      expect(filled.pendingRecipeIngredients, isEmpty);
    });
  });

  group('edited rows', () {
    test('a food left out of an edit opens its row again', () {
      final meal = _meal(
        components: [
          _component('rice', 'Basmati', row: '200 g Reis'),
          _component('salt', 'Salz', usedAmount: 5),
        ],
        open: const ['1 Zwiebel'],
      );

      final edited = meal.withEditedRows(
        keptItemIds: const {'salt'},
        deletedRows: const [],
      );

      expect(edited.pendingRecipeIngredients, ['1 Zwiebel', '200 g Reis']);
    });

    test('deleted rows leave the meal, open or ignored', () {
      final meal = _meal(
        components: [_component('rice', 'Basmati', row: '200 g Reis')],
        open: const ['1 Zwiebel'],
        ignored: const ['Salz'],
      );

      final edited = meal.withEditedRows(
        keptItemIds: const {},
        deletedRows: const ['1 Zwiebel', 'Salz'],
      );

      expect(edited.pendingRecipeIngredients, ['200 g Reis']);
      expect(edited.ignoredPendingRecipeIngredients, isEmpty);
    });
  });

  group('open row of a food', () {
    test('is the row the food fills', () {
      expect(
        _component('rice', 'Basmati', row: '200 g Reis').openRow,
        '200 g Reis',
      );
    });

    test('is the amount and name of a food that fills no row', () {
      expect(_component('rice', 'Basmati').openRow, '200 g Basmati');
      expect(
        _component(
          'eggs',
          'Eier',
          usedAmount: 1500,
          unit: InventoryAmountUnit.piece,
          amountScale: inventoryPieceAmountScale,
        ).openRow,
        '1.5 pc Eier',
      );
    });
  });

  group('stored rows', () {
    test('an ignored row and the row of a food survive a save', () {
      final meal = _meal(
        components: [_component('rice', 'Basmati', row: '200 g Reis')],
        ignored: const ['Salz'],
      );

      final json = meal.toJson();

      expect(json['ignored_pending_recipe_ingredients'], ['Salz']);
      expect(PreparedMeal.fromJson(json), meal);
    });

    test('a meal without ignored rows or linked foods stores neither', () {
      final json = _meal(components: [_component('rice', 'Basmati')]).toJson();

      expect(json.containsKey('ignored_pending_recipe_ingredients'), isFalse);
      final component = (json['components'] as List).single as Map;
      expect(component.containsKey('pending_recipe_ingredient'), isFalse);
    });

    test('a meal saved before ignored rows stayed reads without them', () {
      final json = _meal(open: const ['Salz']).toJson()
        ..remove('ignored_pending_recipe_ingredients');

      final meal = PreparedMeal.fromJson(json);

      expect(meal.ignoredPendingRecipeIngredients, isEmpty);
      expect(meal.pendingRecipeIngredients, ['Salz']);
    });
  });
}
