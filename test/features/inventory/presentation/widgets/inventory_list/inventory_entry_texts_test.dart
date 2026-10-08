import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
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
