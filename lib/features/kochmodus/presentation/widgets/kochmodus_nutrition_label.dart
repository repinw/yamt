import 'package:material_ui/material_ui.dart';
import 'package:yamt/core/domain/nutrition_facts.dart';
import 'package:yamt/core/widgets/nutrition_facts_rows.dart';
import 'package:yamt/features/inventory/domain/eat_meal_nutrition.dart';
import 'package:yamt/features/inventory/presentation/widgets/eat_sheet/eat_label_table.dart';
import 'package:yamt/l10n/app_localizations.dart';

/// The food label of [eaten] in the Kochmodus: one column under
/// [eatenHeader], such as one portion, and with [per100Header] a column per
/// 100 g of the cooked food ([per100]), "–" until it is known. Energy or a
/// macro that a food does not list shows "–"; any other nutrient that a food
/// lacks shows the sum of the others as a minimum ("mind.").
class KochmodusNutritionLabel extends StatelessWidget {
  /// Creates the label of [eaten].
  const new({
    required this.eaten,
    required this.eatenHeader,
    this.per100Header,
    this.per100,
    super.key,
  });

  /// The nutrients of the column, such as one portion.
  final EatMealNutrition eaten;

  /// The header of that column.
  final String eatenHeader;

  /// The header of the column per 100 g; no such column without one.
  final String? per100Header;

  /// The nutrients per 100 g, `null` until the cooked food is weighed.
  final NutritionFacts? per100;

  @override
  Widget build(BuildContext context) {
    final unknown = AppLocalizations.of(context)!.eatPageMealUnknownValue;
    final withPer100 = per100Header != null;
    return EatLabelTable(
      rows: [
        for (final row in nutritionFactsRows(
          context,
          eaten: eaten.total,
          per100: per100,
          listed: eaten.listed,
          unknownEaten: unknown,
          atLeast: eaten.incomplete,
        ))
          NutritionFactsRow(
            label: row.label,
            per100: withPer100 ? row.per100 ?? unknown : null,
            eaten: row.eaten,
            accent: row.accent,
            isPart: row.isPart,
          ),
      ],
      per100Header: per100Header,
      eatenHeader: eatenHeader,
    );
  }
}
