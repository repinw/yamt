import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yamt/core/domain/meal_type.dart';
import 'package:yamt/core/provider/clock_provider.dart';
import 'package:yamt/features/calories/data/planned_entry_repository.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/household/application/household_members_provider.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/inventory/application/inventory_plan_demand_provider.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/plan_reservation.dart';

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
        inventoryQuickEatMealsProvider.overrideWith(
          (ref) => Stream.value(const []),
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
    expect(demand.missingShareByPlanId, {'tomorrow': 0.5});
  });

  test('counts the plans of current members from today on', () async {
    final oats = InventoryItem.create(
      id: 'oats',
      name: 'Oats',
      entryDate: DateTime(2026, 10),
      storeName: 'Store',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );
    MemberPlanReservation other(String uid, DateTime at) =>
        (uid: uid, reservation: (stockId: 'oats', amount: 100, at: at));
    HouseholdMember member(String uid) => HouseholdMember(
      uid: uid,
      role: HouseholdRole.member,
      joinedAt: DateTime(2026),
      displayName: uid,
    );
    final container = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(() => DateTime(2026, 10, 7, 9)),
        inventoryQuickEatItemsProvider.overrideWith(
          (ref) => Stream.value([oats]),
        ),
        inventoryQuickEatMealsProvider.overrideWith(
          (ref) => Stream.value(const []),
        ),
        plannedEntryRepositoryProvider.overrideWithValue(
          FakePlannedEntryRepository(plans: const []),
        ),
        otherPlanReservationsProvider.overrideWith(
          (ref) => Stream.value([
            other('ben', DateTime(2026, 10, 8, 12)),
            other('anna', DateTime(2026, 10, 7, 12)),
            // A plan of a past day, and one of a member who left.
            other('anna', DateTime(2026, 10, 6, 12)),
            other('gone', DateTime(2026, 10, 7, 12)),
          ]),
        ),
        householdMembersProvider.overrideWith(
          (ref) => Stream.value([member('anna'), member('ben')]),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.listen(planStockHoldersProvider, (_, _) {});

    final demand = await container.read(openPlanDemandProvider.future);
    final holders = await container.read(planStockHoldersProvider.future);

    expect(demand.plannedByItemId, {'oats': 200});
    expect(holders['oats']!.map((holder) => holder.member.uid), [
      'anna',
      'ben',
    ]);
    expect(holders['oats']!.map((holder) => holder.day), [
      DateTime(2026, 10, 7),
      DateTime(2026, 10, 8),
    ]);
    expect(holders['oats']!.map((holder) => holder.daysAhead), [0, 1]);
  });
}
