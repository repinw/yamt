import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yamt/features/household/domain/household_member.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_pot_weighing.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/widgets/'
    'inventory_list/inventory_entry_texts.dart';
import 'package:yamt/l10n/app_localizations.dart';

PreparedMeal _meal({bool? servedInPieces}) {
  final now = DateTime.utc(2026, 10, 8);
  return PreparedMeal(
    id: 'wraps',
    name: 'Wraps',
    totalPortions: 6,
    remainingPortions: 4,
    totalKcal: 1200,
    totalProtein: 60,
    totalCarbs: 120,
    totalFat: 40,
    createdAt: now,
    updatedAt: now,
    components: const <PreparedMealComponent>[],
    recipeIngredients: const ['6 Tortillas'],
    servedInPieces: servedInPieces,
  );
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('de'));

  setUpAll(() => initializeDateFormatting('de'));

  test('a food that other members plan with names them and the day', () {
    HouseholdMember member(String name) => HouseholdMember(
      uid: name,
      role: HouseholdRole.member,
      joinedAt: DateTime(2026),
      displayName: name,
    );
    final skyr = InventoryItem.create(
      id: 'skyr',
      name: 'Skyr',
      entryDate: DateTime(2026, 10),
      storeName: 'Rewe',
      quantity: 1,
      initialAmount: 500,
      currentAmount: 500,
      amountUnit: InventoryAmountUnit.gram,
    );

    final texts = InventoryEntryTexts.of(
      InventoryFoodEntry(skyr),
      l10n,
      planned: 300,
      plannedBy: [
        (member: member('Anna'), day: DateTime(2026, 10, 21), daysAhead: 1),
        (member: member('Ben'), day: DateTime(2026, 10, 23), daysAhead: 3),
      ],
    );

    expect(texts.ofFull, l10n.inventoryRowPlannedBy('300', 'Anna Mi, Ben Fr'));

    // The same weekday a week later names its date.
    final later = InventoryEntryTexts.of(
      InventoryFoodEntry(skyr),
      l10n,
      planned: 300,
      plannedBy: [
        (member: member('Anna'), day: DateTime(2026, 10, 21), daysAhead: 1),
        (member: member('Anna'), day: DateTime(2026, 10, 28), daysAhead: 8),
      ],
    );

    expect(
      later.ofFull,
      l10n.inventoryRowPlannedBy('300', 'Anna Mi, Anna Mi., 28.10.'),
    );
  });

  test('a meal in pieces counts its pieces', () {
    final texts = InventoryEntryTexts.of(
      InventoryMealEntry(_meal(servedInPieces: true)),
      l10n,
    );

    expect(texts.unit, 'Stk');
    expect(texts.info, 'Aus Rezept · 4 von 6 Stück');
  });

  test('a weighed pot shows the grams it held then, scaled', () {
    final meal = _meal().copyWith(
      finalNetWeight: 1200,
      potTareWeight: 1180,
      potWeighing: PreparedMealPotWeighing(
        netWeight: 900,
        weighedAt: DateTime.utc(2026, 10, 8),
        remainingPortions: 6,
      ),
    );

    final texts = InventoryEntryTexts.of(InventoryMealEntry(meal), l10n);

    // 4 of the 6 portions weighed at 900 g are left.
    expect(texts.amount, '600');
  });

  test('a meal without a serving unit counts portions', () {
    final texts = InventoryEntryTexts.of(InventoryMealEntry(_meal()), l10n);

    expect(texts.unit, 'Port.');
    expect(texts.info, 'Aus Rezept · 4 von 6 Portionen');
  });
}
