import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cooking/domain/cook_recipe.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_finish_controller.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/cooked_meal_repository.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../../../helpers/fake_inventory_item_repository.dart';

InventoryItem _mince(int amount) => InventoryItem.create(
  id: 'mince',
  name: 'Hackfleisch',
  entryDate: DateTime.utc(2026, 10),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 800,
  currentAmount: amount,
  amountUnit: InventoryAmountUnit.gram,
  nutrition: const GlobalFoodNutrition(
    qualityStatus: GlobalFoodNutritionQualityStatus.verified,
    per100Kcal: 100,
    per100Protein: 10,
    per100Carbs: 20,
    per100Fat: 5,
  ),
);

const _recipe = CookRecipe(
  id: 'stew',
  name: 'Eintopf',
  portions: 2,
  lines: [(id: 'l1', text: '500 g Hackfleisch')],
);

final CookSession _session = const CookSession().withLine(
  'l1',
  const LineAssigned([(itemId: 'mince', amount: 500)]),
);

const CookPortioning _portioning = (
  name: '',
  count: 2,
  inPieces: false,
  grossWeight: null,
);

void main() {
  late _RecordingMeals meals;

  ProviderContainer containerWith(int stock) {
    meals = _RecordingMeals();
    final container = ProviderContainer(
      overrides: [
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository([_mince(stock)]),
        ),
        cookedMealRepositoryProvider.overrideWithValue(meals),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('finish writes the meal and ends idle with a value', () async {
    final container = containerWith(800);
    final states = <AsyncValue<void>>[];
    container.listen(
      cookFinishControllerProvider('stew'),
      (_, next) => states.add(next),
    );

    final error = await container
        .read(cookFinishControllerProvider('stew').notifier)
        .finish(recipe: _recipe, session: _session, portioning: _portioning);

    expect(error, isNull);
    expect(states.first, isA<AsyncLoading<void>>());
    expect(states.last, isA<AsyncData<void>>());
    expect(meals.written.single.name, 'Eintopf');
  });

  test('finish returns false and keeps the error in the state', () async {
    final container = containerWith(100)
      ..listen(cookFinishControllerProvider('stew'), (_, _) {});

    final error = await container
        .read(cookFinishControllerProvider('stew').notifier)
        .finish(recipe: _recipe, session: _session, portioning: _portioning);

    expect(error, isNotNull);
    final state = container.read(cookFinishControllerProvider('stew'));
    expect(state.hasError, isTrue);
    expect(state.error, isA<PreparedMealBuildException>());
    expect(meals.written, isEmpty);
  });

  test('finish still reports the result when nobody listens', () async {
    final container = containerWith(800);

    final error = await container
        .read(cookFinishControllerProvider('stew').notifier)
        .finish(recipe: _recipe, session: _session, portioning: _portioning);

    expect(error, isNull);
    expect(meals.written, hasLength(1));
  });
}

class _RecordingMeals implements CookedMealRepository {
  final written = <PreparedMeal>[];

  @override
  Future<void> addCookedMeal({
    required PreparedMeal meal,
    required List<CookedStockChange> changes,
    required DateTime happenedAt,
  }) async {
    await Future<void>.delayed(Duration.zero);
    written.add(meal);
  }
}
