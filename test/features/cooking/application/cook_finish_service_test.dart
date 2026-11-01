import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/features/cooking/application/cook_finish_service.dart';
import 'package:yamt/features/cooking/domain/cook_recipe.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../../helpers/fake_inventory_item_repository.dart';

final _now = DateTime.utc(2026, 11, 1, 12);

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 100,
  per100Protein: 10,
  per100Carbs: 20,
  per100Fat: 5,
);

InventoryItem _grams(
  String id,
  String name,
  int amount, {
  GlobalFoodNutrition? nutrition = _nutrition,
}) => InventoryItem.create(
  id: id,
  name: name,
  entryDate: DateTime.utc(2026, 10),
  storeName: 'Store',
  quantity: 1,
  initialAmount: amount,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.gram,
  nutrition: nutrition,
);

const _recipe = CookRecipe(
  id: 'stew',
  name: 'Eintopf',
  portions: 2,
  lines: [
    (id: 'l1', text: '500 g Hackfleisch'),
    (id: 'l2', text: '100 g Hackfleisch'),
    (id: 'l3', text: '200 g Karotten'),
    (id: 'l4', text: 'Salz'),
    (id: 'l5', text: '1 Lorbeerblatt'),
  ],
  imageAssetId: 'photo',
  imageUrl: 'https://example.com/stew.jpg',
);

CookSession _session({CookPot? pot}) {
  var session = const CookSession()
      .withLine('l1', const LineAssigned([(itemId: 'mince', amount: 500)]))
      .withLine('l2', const LineAssigned([(itemId: 'mince', amount: 100)]))
      .withLine('l3', const LineAssigned([(itemId: 'carrots', amount: 200)]))
      .withLine('l4', const LineAssigned([(itemId: 'salt', amount: 0)]))
      .withLine('l5', const LineOmitted());
  if (pot != null) session = session.withPot(pot);
  return session;
}

List<InventoryItem> _items() => [
  _grams('mince', 'Hackfleisch', 800),
  _grams('carrots', 'Karotten', 1000),
  _grams('salt', 'Salz', 500),
  _grams('rice', 'Reis', 900),
];

const CookPortioning _portioning = (
  name: '',
  count: 4,
  inPieces: false,
  grossWeight: null,
);

PreparedMealBuildResult _build({
  List<InventoryItem>? items,
  CookSession? session,
  CookPortioning portioning = _portioning,
}) => buildCookedMeal(
  items: items ?? _items(),
  recipe: _recipe,
  session: session ?? _session(),
  portioning: portioning,
  id: 'meal-1',
  now: _now,
);

void main() {
  group('buildCookedMeal', () {
    test('sums the takes of one item over its lines into one food', () {
      final built = _build();

      final mince = built.preparedMeal.components.singleWhere(
        (component) => component.inventoryItemId == 'mince',
      );
      expect(mince.usedAmount, 600);
      expect(built.preparedMeal.components.map((c) => c.inventoryItemId), [
        'mince',
        'carrots',
      ]);
    });

    test('takes the stock of the items, and only theirs', () {
      final built = _build();
      final byId = {for (final item in built.nextItems) item.id: item};

      expect(byId['mince']!.currentAmount, 200);
      expect(byId['carrots']!.currentAmount, 800);
      expect(byId['salt']!.currentAmount, 500);
      expect(byId['rice']!.currentAmount, 900);
    });

    test('a line that takes nothing adds no food', () {
      final built = _build();

      expect(
        built.preparedMeal.components.where((c) => c.inventoryItemId == 'salt'),
        isEmpty,
      );
    });

    test('names the meal like the recipe unless the cook renamed it', () {
      expect(_build().preparedMeal.name, 'Eintopf');
      expect(
        _build(
          portioning: (
            name: '  ',
            count: 4,
            inPieces: false,
            grossWeight: null,
          ),
        ).preparedMeal.name,
        'Eintopf',
      );
      expect(
        _build(
          portioning: (
            name: ' Reste ',
            count: 4,
            inPieces: false,
            grossWeight: null,
          ),
        ).preparedMeal.name,
        'Reste',
      );
    });

    test('carries the portions, the photo and the id', () {
      final meal = _build().preparedMeal;

      expect(meal.id, 'meal-1');
      expect(meal.totalPortions, 4);
      expect(meal.remainingPortions, 4);
      expect(meal.imageUrl, 'https://example.com/stew.jpg');
      expect(meal.imageAssetId, 'photo');
    });

    test('the pot weight leaves the net weight of the meal', () {
      final meal = _build(
        session: _session(
          pot: const CookPotUtensil(utensilId: 'pot', emptyWeight: 900),
        ),
        portioning: (name: '', count: 4, inPieces: false, grossWeight: 2400),
      ).preparedMeal;

      expect(meal.potTareWeight, 900);
      expect(meal.finalNetWeight, 1500);
      expect(meal.isServedInPieces, isFalse);
    });

    test('without a pot there is no net weight', () {
      final meal = _build(
        session: _session(pot: const CookPotNone()),
        portioning: (name: '', count: 4, inPieces: false, grossWeight: 2400),
      ).preparedMeal;

      expect(meal.potTareWeight, isNull);
      expect(meal.finalNetWeight, isNull);
    });

    test('a pot without a weighing gives no net weight', () {
      final meal = _build(
        session: _session(
          pot: const CookPotUtensil(utensilId: 'pot', emptyWeight: 900),
        ),
      ).preparedMeal;

      expect(meal.potTareWeight, isNull);
      expect(meal.finalNetWeight, isNull);
    });

    test('pieces mark the meal as served in pieces', () {
      final meal = _build(
        portioning: (name: '', count: 6, inPieces: true, grossWeight: null),
      ).preparedMeal;

      expect(meal.isServedInPieces, isTrue);
      expect(meal.totalPortions, 6);
    });

    test('an item without nutrition fails with missingNutrition', () {
      expect(
        () => _build(
          items: [
            _grams('mince', 'Hackfleisch', 800, nutrition: null),
            _grams('carrots', 'Karotten', 1000),
            _grams('salt', 'Salz', 500),
          ],
        ),
        throwsA(
          isA<PreparedMealBuildException>().having(
            (error) => error.reason,
            'reason',
            PreparedMealCreationFailureReason.missingNutrition,
          ),
        ),
      );
    });

    test('an item that holds too little fails with insufficientAmount', () {
      expect(
        () => _build(
          items: [
            _grams('mince', 'Hackfleisch', 550),
            _grams('carrots', 'Karotten', 1000),
            _grams('salt', 'Salz', 500),
          ],
        ),
        throwsA(
          isA<PreparedMealBuildException>().having(
            (error) => error.reason,
            'reason',
            PreparedMealCreationFailureReason.insufficientAmount,
          ),
        ),
      );
    });

    test('a meal of nothing fails with invalidInput', () {
      final nothing = const CookSession()
          .withLine('l1', const LineOmitted())
          .withLine('l4', const LineAssigned([(itemId: 'salt', amount: 0)]));

      expect(
        () => _build(session: nothing),
        throwsA(
          isA<PreparedMealBuildException>().having(
            (error) => error.reason,
            'reason',
            PreparedMealCreationFailureReason.invalidInput,
          ),
        ),
      );
    });

    test('an item that is gone fails with itemUnavailable', () {
      expect(
        () => _build(items: [_grams('carrots', 'Karotten', 1000)]),
        throwsA(
          isA<PreparedMealBuildException>().having(
            (error) => error.reason,
            'reason',
            PreparedMealCreationFailureReason.itemUnavailable,
          ),
        ),
      );
    });
  });

  group('CookFinishService', () {
    late FakeInventoryItemRepository inventory;
    late _FakeCookedMealRepository meals;
    late CookFinishService service;

    setUp(() {
      inventory = FakeInventoryItemRepository(_items());
      meals = _FakeCookedMealRepository();
      service = CookFinishService(
        inventory: inventory,
        meals: meals,
        clock: () => _now,
      );
    });

    test('writes the meal with the changed items only', () async {
      final meal = await service.finish(
        recipe: _recipe,
        session: _session(),
        portioning: _portioning,
      );

      expect(meals.written, hasLength(1));
      final write = meals.written.single;
      expect(write.meal, meal);
      expect(write.happenedAt, _now);
      expect(write.changes.map((change) => change.after.id), [
        'mince',
        'carrots',
      ]);
      final mince = write.changes.first;
      expect(mince.before.currentAmount, 800);
      expect(mince.after.currentAmount, 200);
    });

    test('writes nothing when the Vorrat no longer holds enough', () async {
      inventory.items = [
        _grams('mince', 'Hackfleisch', 100),
        _grams('carrots', 'Karotten', 1000),
        _grams('salt', 'Salz', 500),
      ];

      await expectLater(
        service.finish(
          recipe: _recipe,
          session: _session(),
          portioning: _portioning,
        ),
        throwsA(isA<PreparedMealBuildException>()),
      );
      expect(meals.written, isEmpty);
    });

    test('rethrows a failed write', () async {
      meals.failure = Exception('write failed');

      await expectLater(
        service.finish(
          recipe: _recipe,
          session: _session(),
          portioning: _portioning,
        ),
        throwsException,
      );
    });
  });
}

typedef _Write = ({
  PreparedMeal meal,
  List<CookedStockChange> changes,
  DateTime happenedAt,
});

class _FakeCookedMealRepository implements CookedMealRepository {
  final written = <_Write>[];
  Exception? failure;

  @override
  Future<void> addCookedMeal({
    required PreparedMeal meal,
    required List<CookedStockChange> changes,
    required DateTime happenedAt,
  }) async {
    final failure = this.failure;
    if (failure case final error?) throw error;
    written.add((meal: meal, changes: changes, happenedAt: happenedAt));
  }
}
