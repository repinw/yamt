import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/core/widgets/nutrition_facts_table.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/calories/presentation/consumed_unit_l10n.dart';
import 'package:yamt/features/calories/presentation/widgets/'
    'calorie_entry_details_view/calorie_entry_details_labels.dart';
import 'package:yamt/features/calories/presentation/widgets/calories_page_keys.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Nutrition table of a diary entry: values per 100 g or ml and for the eaten
/// amount. Bundles have no values per 100, so they show only the eaten
/// column.
class CalorieEntryNutritionTable extends StatelessWidget {
  /// Creates the nutrition table.
  const new({required this.entry, super.key});

  /// Entry whose nutrition is shown.
  final CalorieEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final details = entry.nutrientDetails;
    final per100 = NutritionFacts(
      kcal: entry.per100Kcal,
      fat: entry.per100Fat,
      saturatedFat: details?.per100SaturatedFat,
      polyunsaturatedFat: details?.per100PolyunsaturatedFat,
      carbs: entry.per100Carbs,
      sugar: details?.per100Sugar,
      fiber: details?.per100Fiber,
      protein: entry.per100Protein,
      salt: details?.per100Salt,
    );
    final detailsEaten = per100.scaled(entry.consumedAmount / 100);
    final eaten = NutritionFacts(
      kcal: entry.totalKcal,
      fat: entry.totalFat,
      saturatedFat: detailsEaten.saturatedFat,
      polyunsaturatedFat: detailsEaten.polyunsaturatedFat,
      carbs: entry.totalCarbs,
      sugar: detailsEaten.sugar,
      fiber: detailsEaten.fiber,
      protein: entry.totalProtein,
      salt: detailsEaten.salt,
    );

    return NutritionFactsTable(
      key: CalorieEntryDetailKeys.nutritionStrip,
      eaten: eaten,
      eatenHeader: calorieEntryConsumedAmountLabel(l10n, entry),
      per100: entry.isBundle ? null : per100,
      per100Header: l10n.caloriesEntryPer100Label(
        entry.consumedUnit.localizedName(l10n),
      ),
    );
  }
}
