import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';

import '../../calories/support/fake_planned_entry_repository.dart';

CalorieEntry _plan(String id, DateTime loggedAt) => CalorieEntry.create(
  id: id,
  userId: 'user-1',
  name: 'Oats',
  mealType: MealType.breakfast,
  consumedAmount: 100,
  consumedUnit: ConsumedUnit.grams,
  per100Kcal: 400,
  per100Protein: 10,
  per100Carbs: 60,
  per100Fat: 12,
  sourceInventoryItemId: 'oats',
  loggedAt: loggedAt,
  createdAt: loggedAt,
  updatedAt: loggedAt,
);

void main() {
  test('counts the open plans from today on, not the overdue ones', () async {
    final oats = InventoryItem.create(
      id: 'oats',
      name: 'Oats',
      entryDate: DateTime(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 150,
      amountUnit: InventoryAmountUnit.gram,
    );
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 9)),
        inventoryQuickEatItemsProvider.overrideWith(
          (ref) => Stream.value([oats]),
        ),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(
            plans: [
              _plan('overdue', DateTime(2026, 10, 6, 8)),
              _plan('today', DateTime(2026, 10, 7, 8)),
              _plan('tomorrow', DateTime(2026, 10, 8, 8)),
            ],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(openPlanDemandProvider, (_, _) {});

    final demand = await container.read(openPlanDemandProvider.future);

    expect(demand.plannedByItemId, {'oats': 150});
    expect(demand.shortPlanIds, {'tomorrow'});
  });
}
