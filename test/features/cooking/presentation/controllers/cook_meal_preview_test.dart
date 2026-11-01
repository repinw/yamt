import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_meal_preview.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_session_controller.dart';
import 'package:yamt/features/cooking/presentation/controllers/cook_view_builder.dart';
import 'package:yamt/features/inventory/application/prepared_meal_mutation_models.dart';
import 'package:yamt/features/inventory/data/inventory_item_repository.dart';
import 'package:yamt/features/inventory/data/prepared_meal_template_repository.dart';
import 'package:yamt/features/inventory/domain/global_food_nutrition.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';

import '../../../../helpers/fake_inventory_item_repository.dart';
import '../../../../helpers/fake_prepared_meal_template_repository.dart';

InventoryItem _mince({GlobalFoodNutrition? nutrition}) => InventoryItem.create(
  id: 'mince',
  name: 'Hackfleisch',
  entryDate: DateTime.utc(2026, 10),
  storeName: 'Store',
  quantity: 1,
  initialAmount: 800,
  currentAmount: 800,
  amountUnit: InventoryAmountUnit.gram,
  nutrition: nutrition,
);

const _nutrition = GlobalFoodNutrition(
  qualityStatus: GlobalFoodNutritionQualityStatus.verified,
  per100Kcal: 200,
  per100Protein: 10,
  per100Carbs: 20,
  per100Fat: 5,
);

final _template = PreparedMeal(
  id: 'stew',
  name: 'Eintopf',
  totalPortions: 2,
  remainingPortions: 2,
  totalKcal: 0,
  totalProtein: 0,
  totalCarbs: 0,
  totalFat: 0,
  createdAt: DateTime.utc(2026, 10, 9),
  updatedAt: DateTime.utc(2026, 10, 9),
  components: const [],
  recipeIngredients: const ['500 g Hackfleisch'],
);

const CookPortioning _weighed = (
  name: '',
  count: 2,
  inPieces: false,
  grossWeight: 1500,
);

void main() {
  Future<ProviderContainer> open(InventoryItem item) async {
    final container = ProviderContainer(
      overrides: [
        preparedMealTemplateRepositoryProvider.overrideWithValue(
          FakePreparedMealTemplateRepository(templates: [_template]),
        ),
        inventoryItemRepositoryProvider.overrideWithValue(
          FakeInventoryItemRepository([item]),
        ),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11)),
      ],
    );
    addTearDown(container.dispose);
    final view = container.listen(cookViewProvider('stew', 'de'), (_, _) {});
    addTearDown(view.close);
    for (var i = 0; i < 50 && !view.read().hasValue; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    container.read(cookSessionControllerProvider('stew').notifier).assign(
      'line-0',
      const [(itemId: 'mince', amount: 500)],
    );
    return container;
  }

  test('shows the meal nutrients with the weighed weight', () async {
    final container = await open(_mince(nutrition: _nutrition));
    final provider = cookMealPreviewProvider('stew', 'de', _weighed);
    final sub = container.listen(provider, (_, _) {});
    addTearDown(sub.close);

    final preview = sub.read();

    // 500 g at 200 kcal per 100 g.
    expect(preview.requireValue.total.kcal, 1000);
  });

  test('without a pot there is no weight to show', () async {
    final container = await open(_mince(nutrition: _nutrition));
    final sub = container.listen(
      cookMealPreviewProvider('stew', 'de', _weighed),
      (_, _) {},
    );
    addTearDown(sub.close);

    expect(sub.read().requireValue.amounts, isEmpty);

    container
        .read(cookSessionControllerProvider('stew').notifier)
        .choosePot(const CookPotUtensil(utensilId: 'pot', emptyWeight: 500));

    expect(sub.read().requireValue.amounts.values.single, 1000);
  });

  test('fails like "In Vorrat" when a food lacks nutrition', () async {
    final container = await open(_mince());
    final sub = container.listen(
      cookMealPreviewProvider('stew', 'de', _weighed),
      (_, _) {},
    );
    addTearDown(sub.close);

    final preview = sub.read();

    expect(preview, isA<AsyncError<Object?>>());
    expect(
      (preview.error! as PreparedMealBuildException).reason,
      PreparedMealCreationFailureReason.missingNutrition,
    );
  });
}
