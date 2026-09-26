import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/calories/domain/calorie_entry.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_sheet_l10n.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// Nutrition label of a whole meal: per 100 g or ml of the meal, and the
/// total of all foods. A total that one food does not list shows "–".
class EatMealTable extends StatelessWidget {
  /// Creates the table.
  const new({required this.meal, super.key});

  /// Key of the table.
  static const tableKey = Key('eat_meal_nutrition_table');

  /// The meal's nutrients.
  final EatMealNutrition meal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final number = NumberFormat.decimalPattern(l10n.localeName)
      ..maximumFractionDigits = 1;
    final amounts = [
      for (final MapEntry(key: unit, value: amount) in meal.amounts.entries)
        // A no-break space keeps the amount and unit on one line when the
        // header wraps under "total".
        '${number.format(amount)}\u00A0${consumedUnitSymbol(l10n, unit)}',
    ].join(' + ');
    final singleUnit = meal.amounts.length == 1
        ? meal.amounts.keys.single
        : ConsumedUnit.grams;

    return EatLabelTable(
      key: tableKey,
      rows: nutritionFactsRows(
        context,
        eaten: meal.total,
        per100: meal.per100,
        listed: meal.listed,
        unknownEaten: l10n.eatPageMealUnknownValue,
      ),
      per100Header: meal.per100 == null
          ? null
          : l10n.caloriesEntryPer100Label(consumedUnitSymbol(l10n, singleUnit)),
      eatenHeader: l10n.eatPageMealTotal(amounts),
    );
  }
}
