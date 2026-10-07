import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/data/'
    'global_food_serving_suggestion_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/'
    'global_food_serving_suggestion.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_sheet_controller.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_sheet_state.dart';
import 'package:yamt/features/inventory/presentation/controllers/'
    'inventory_item_eat_sheet_submission.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_item_eat_sheet_result.dart';

final _now = DateTime(2026, 5, 13, 12, 30);

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 100,
  per100Protein: 10,
);

InventoryItem _gramItem() {
  return InventoryItem.create(
    id: 'milk',
    name: 'Milk',
    entryDate: DateTime(2026, 5),
    storeName: 'Store',
    quantity: 1,
    initialAmount: 1000,
    currentAmount: 1000,
    amountUnit: InventoryAmountUnit.gram,
    globalFoodItemId: 'off-milk',
    nutrition: _nutrition,
  );
}

InventoryItem _pieceItem() {
  return InventoryItem.create(
    id: 'banana',
    name: 'Banana',
    entryDate: DateTime(2026, 5),
    storeName: 'Store',
    quantity: 3,
    initialQuantity: 3,
    nutrition: _nutrition,
  );
}

GlobalFoodServingSuggestion _globalSuggestion(double amount, String label) {
  return GlobalFoodServingSuggestion(
    id: 'egg_$label',
    itemKey: 'fingerprint_egg',
    amount: amount,
    unit: ConsumedUnit.grams,
    label: label,
    selectionCount: 1,
    uniqueUserCount: 1,
    createdAt: _now,
    updatedAt: _now,
  );
}

class _FakeSuggestionRepository
    implements GlobalFoodServingSuggestionRepository {
  GlobalFoodServingSuggestionSet suggestions =
      const GlobalFoodServingSuggestionSet.empty();
  final recorded = <({double amount, String? label})>[];

  @override
  Future<GlobalFoodServingSuggestionSet> readSuggestions({
    required String foodFingerprint,
    String? globalFoodItemId,
    int limit = 5,
  }) async {
    return suggestions;
  }

  @override
  Future<void> recordSelection({
    required String foodFingerprint,
    required double amount,
    required ConsumedUnit unit,
    required DateTime selectedAt,
    String? globalFoodItemId,
    String? label,
  }) async {
    recorded.add((amount: amount, label: label));
  }
}

({
  ProviderContainer container,
  InventoryItemEatSheetControllerProvider provider,
})
_setUp(
  InventoryItem item, {
  _FakeSuggestionRepository? repository,
  bool hasOpenStock = false,
}) {
  final container = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(() => _now),
      globalFoodServingSuggestionRepositoryProvider.overrideWithValue(
        repository ?? _FakeSuggestionRepository(),
      ),
    ],
  );
  addTearDown(container.dispose);
  final provider = inventoryItemEatSheetControllerProvider(
    item: item,
    hasOpenStock: hasOpenStock,
  );
  container.listen(provider, (_, _) {});
  return (container: container, provider: provider);
}

void main() {
  test('starts with one unit, the time from the clock, and nutrition', () {
    final (:container, :provider) = _setUp(_gramItem());

    final state = container.read(provider);

    expect(state.inventoryAmountText, '1');
    expect(state.loggedAt, _now);
    expect(state.mealType, MealType.defaultForDateTime(_now));
    expect(state.nutrition?.eaten.kcal, 1);
    expect(state.markers.single.isAll, isTrue);
    expect(state.markers.single.value, 1000);
  });

  test('the ruler spans the stock in round steps', () {
    final (:container, :provider) = _setUp(_gramItem());

    final state = container.read(provider);

    expect(state.amountMax, 1000);
    expect(state.amountStep, 25);
  });

  test('picking an amount sets the field and updates nutrition', () {
    final (:container, :provider) = _setUp(_gramItem());

    container.read(provider.notifier).pickAmount(250);

    final state = container.read(provider);
    expect(state.inventoryAmountText, '250');
    expect(state.amountValue, 250);
    expect(state.nutrition?.eaten.kcal, 250);
  });

  test('a remembered portion becomes a mark and is logged with the food', () {
    final repository = _FakeSuggestionRepository();
    final (:container, :provider) = _setUp(_gramItem(), repository: repository);
    final controller = container.read(provider.notifier)
      ..setAmountText('60')
      ..rememberPortion(' Slice ');

    final marker = container.read(provider).markers.first;
    expect(marker.value, 60);
    expect(marker.label, 'Slice');

    controller.setAmountText('120');
    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    expect(repository.recorded, isEmpty);
    final request = (outcome as InventoryItemEatSubmitted).result.request;
    expect(request.inventoryAmount, 120);
    expect(request.portionCount, 2);
    expect(request.portionBaseAmount, 60);
    expect(request.portionLabel, 'Slice');
  });

  test('an amount that is no multiple of a portion is logged plainly', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)
      ..setAmountText('60')
      ..rememberPortion('Slice')
      ..setAmountText('70');

    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    final request = (outcome as InventoryItemEatSubmitted).result.request;
    expect(request.inventoryAmount, 70);
    expect(request.portionLabel, isNull);
    expect(request.portionCount, isNull);
  });

  test('a plan day goes into the request but not into the page', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)..setAmountText('120');
    final tomorrow = _now.add(const Duration(days: 1));

    final outcome = controller.submit(
      InventoryItemEatSheetIntent.logOnly,
      asPlan: true,
      planDay: tomorrow,
    );

    final request = (outcome as InventoryItemEatSubmitted).result.request;
    expect(request.loggedAt.day, tomorrow.day);
    expect(request.isPlan, isTrue);
    // The main button keeps its label while the page closes.
    expect(container.read(provider).loggedAt, _now);
    expect(container.read(provider).isPlan, isFalse);
  });

  test('a rejected plan keeps the picked day on the page', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)..setAmountText('');
    final tomorrow = _now.add(const Duration(days: 1));

    final outcome = controller.submit(
      InventoryItemEatSheetIntent.logOnly,
      asPlan: true,
      planDay: tomorrow,
    );

    expect(outcome, isA<InventoryItemEatRejected>());
    expect(container.read(provider).loggedAt.day, tomorrow.day);
  });

  test('submits a valid amount', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)..setAmountText('120');

    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    expect(outcome, isA<InventoryItemEatSubmitted>());
    final request = (outcome as InventoryItemEatSubmitted).result.request;
    expect(request.inventoryAmount, 120);
    expect(request.loggedAt, _now);
  });

  test('rejects an amount above the stock and shows the error', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)..setAmountText('1001');

    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    expect(outcome, isA<InventoryItemEatRejected>());
    expect(
      container.read(provider).errors,
      contains(InventoryItemEatSheetError.invalidInventoryAmount),
    );
  });

  test('an open stock accepts any amount and shows no stock mark', () {
    final (:container, :provider) = _setUp(_gramItem(), hasOpenStock: true);
    final controller = container.read(provider.notifier)..setAmountText('2500');

    final state = container.read(provider);
    expect(state.usesPortionMode, isFalse);
    expect(state.amountMax, 1000);
    expect(state.markers.where((marker) => marker.isAll), isEmpty);

    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    expect(outcome, isA<InventoryItemEatSubmitted>());
    final request = (outcome as InventoryItemEatSubmitted).result.request;
    expect(request.inventoryAmount, 2500);
  });

  test('an open stock steps whole packages without a package limit', () {
    final (:container, :provider) = _setUp(_gramItem(), hasOpenStock: true);
    final controller = container.read(provider.notifier)..setAmountText('150');

    expect(container.read(provider).packageCount, 0);

    controller.stepPackages(up: true);
    expect(container.read(provider).inventoryAmountText, '1000');
    expect(container.read(provider).packageCount, 1);

    controller
      ..stepPackages(up: true)
      ..setAmountText('2150');
    expect(container.read(provider).packageCount, 2);

    controller.stepPackages(up: false);
    expect(container.read(provider).inventoryAmountText, '2000');

    controller
      ..stepPackages(up: false)
      ..stepPackages(up: false)
      ..stepPackages(up: false);
    expect(container.read(provider).inventoryAmountText, '0');
    expect(container.read(provider).amountMax, 1000);
  });

  test('a picked portion mark is counted up and down within the stock', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)
      ..setAmountText('30')
      ..rememberPortion('Slice');
    final slice = container
        .read(provider)
        .markers
        .firstWhere((marker) => marker.label == 'Slice');

    controller
      ..pickMarker(slice)
      ..stepPortions(up: true)
      ..stepPortions(up: true);

    var state = container.read(provider);
    expect(state.inventoryAmountText, '90');
    expect(state.portionCount, 3);
    expect(state.isMarkerSelected(slice), isTrue);

    controller.stepPortions(up: false);
    expect(container.read(provider).inventoryAmountText, '60');

    controller.setAmountText('1000');
    for (var i = 0; i < 3; i++) {
      controller.stepPortions(up: true);
    }
    state = container.read(provider);
    expect(state.countedPortion, isNull);
    expect(state.portionCount, isNull);
    expect(state.inventoryAmountText, '1000');
  });

  test('the counted portion never goes past the stock', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)
      ..setAmountText('400')
      ..rememberPortion('Bowl');
    final bowl = container
        .read(provider)
        .markers
        .firstWhere((marker) => marker.label == 'Bowl');

    controller
      ..pickMarker(bowl)
      ..stepPortions(up: true)
      ..stepPortions(up: true);

    expect(container.read(provider).inventoryAmountText, '800');
  });

  test('a stock item counts no packages', () {
    final (:container, :provider) = _setUp(_gramItem());

    expect(container.read(provider).packageCount, isNull);
  });

  test('a gram product without package size is eaten in grams', () {
    final item = InventoryItem.create(
      id: 'roll',
      name: 'Roll',
      entryDate: DateTime(2026, 5),
      storeName: 'Store',
      quantity: 1,
      amountUnit: InventoryAmountUnit.gram,
      nutrition: _nutrition,
    );
    final (:container, :provider) = _setUp(item, hasOpenStock: true);

    final state = container.read(provider);

    expect(state.usesPortionMode, isFalse);
    expect(state.inventoryAmountText, '100');
    expect(state.nutrition?.eaten.kcal, 100);
  });

  test('piece items start with portion inputs and need a portion', () {
    final (:container, :provider) = _setUp(_pieceItem());
    final controller = container.read(provider.notifier)..setAmountText('2');

    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    final state = container.read(provider);
    expect(outcome, isA<InventoryItemEatRejected>());
    expect(state.usesPortionMode, isTrue);
    expect(state.amountMax, 3);
    expect(state.amountStep, 1);
    expect(
      state.errors,
      contains(InventoryItemEatSheetError.invalidPortionAmount),
    );
  });

  test('picking pieces sets the count and the stock taken', () {
    final (:container, :provider) = _setUp(_pieceItem());

    container.read(provider.notifier)
      ..setPortionAmountText('80')
      ..pickAmount(2);

    final state = container.read(provider);
    expect(state.portionCountText, '2');
    expect(state.inventoryAmountText, '2');
    expect(state.nutrition?.amount, 160);
  });

  test('the piece weight unit switches between grams and milliliters', () {
    final (:container, :provider) = _setUp(_pieceItem());
    final controller = container.read(provider.notifier)..switchPortionUnit();

    expect(container.read(provider).portionUnit, ConsumedUnit.milliliters);

    controller.switchPortionUnit();

    expect(container.read(provider).portionUnit, ConsumedUnit.grams);
  });

  test('the piece weight maps the stock and is saved only with the food', () {
    final repository = _FakeSuggestionRepository();
    final (:container, :provider) = _setUp(
      _pieceItem(),
      repository: repository,
    );
    final controller = container.read(provider.notifier)
      ..setAmountText('2')
      ..setPortionAmountText('80');

    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    expect(repository.recorded, isEmpty);
    final request = (outcome as InventoryItemEatSubmitted).result.request;
    expect(request.inventoryAmount, 2);
    expect(request.calorieAmount, 160);
    expect(request.portionCount, 2);
    expect(request.portionBaseAmount, 80);
    expect(request.portionLabel, isNull);
  });

  test('a remembered piece size names the weight and is logged with it', () {
    final repository = _FakeSuggestionRepository();
    final (:container, :provider) = _setUp(
      _pieceItem(),
      repository: repository,
    );
    final controller = container.read(provider.notifier)
      ..setPortionAmountText('68')
      ..rememberPortion(' L ');

    final state = container.read(provider);
    expect(state.pieceSizes.single.label, 'L');
    expect(state.selectedPieceSize?.amount, 68);

    controller.pickAmount(2);
    final outcome = controller.submit(InventoryItemEatSheetIntent.logOnly);

    expect(repository.recorded, isEmpty);
    final request = (outcome as InventoryItemEatSubmitted).result.request;
    expect(request.calorieAmount, 136);
    expect(request.portionBaseAmount, 68);
    expect(request.portionLabel, 'L');
  });

  test(
    'learned piece sizes can be picked; a typed weight has no name',
    () async {
      final repository = _FakeSuggestionRepository()
        ..suggestions = GlobalFoodServingSuggestionSet(
          globalSuggestions: [
            _globalSuggestion(53, 'S'),
            _globalSuggestion(58, 'M'),
          ],
        );
      final (:container, :provider) = _setUp(
        _pieceItem(),
        repository: repository,
      );
      await pumpEventQueue();

      final sizes = container.read(provider).pieceSizes;
      expect(sizes.map((size) => size.label), containsAll(['S', 'M']));

      final controller = container.read(provider.notifier)
        ..pickPieceSize(sizes.firstWhere((size) => size.label == 'M'));
      var state = container.read(provider);
      expect(state.portionAmountText, '58');
      expect(state.portionLabel, 'M');
      expect(state.selectedPieceSize?.label, 'M');

      controller.setPortionAmountText('60');
      state = container.read(provider);
      expect(state.portionLabel, isNull);
      expect(state.selectedPieceSize, isNull);
    },
  );

  test('applies a learned amount the user has not changed', () async {
    final repository = _FakeSuggestionRepository()
      ..suggestions = const GlobalFoodServingSuggestionSet(
        personalSuggestion: ServingSizeSuggestion(
          amount: 135,
          unit: ConsumedUnit.grams,
        ),
      );
    final (:container, :provider) = _setUp(_gramItem(), repository: repository);

    await pumpEventQueue();

    expect(container.read(provider).inventoryAmountText, '135');
  });

  test('logs a picked day at the current time of day', () {
    final (:container, :provider) = _setUp(_gramItem());

    container.read(provider.notifier).setLoggedDay(DateTime(2026, 5, 10));

    expect(container.read(provider).loggedAt, DateTime(2026, 5, 10, 12, 30));
  });

  test('leaving a plan day goes back to today', () {
    final (:container, :provider) = _setUp(_gramItem());
    final controller = container.read(provider.notifier)
      ..setLoggedDay(DateTime(2026, 5, 15))
      ..leavePlanDay();

    expect(container.read(provider).loggedAt, _now);

    controller
      ..setLoggedDay(DateTime(2026, 5, 10))
      ..leavePlanDay();

    expect(container.read(provider).loggedAt, DateTime(2026, 5, 10, 12, 30));
  });
}
