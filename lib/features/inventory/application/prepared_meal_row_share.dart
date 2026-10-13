import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The row that a food fills when it covers [covered] of the row [row],
/// which needs [needed] [unit] of [name]: [row] itself when the food covers
/// all of it, else the food's share, such as "300 g Reis". The share opens
/// again when the food leaves the meal, so the open rows add up to the row
/// again. Null when the food covers no whole unit of the row.
String? filledRowShare({
  required String row,
  required int covered,
  required int needed,
  required TemplateIngredientUnit unit,
  required String name,
  required TemplateIngredientParser parser,
}) {
  if (covered < 1) {
    return null;
  }
  if (covered >= needed) {
    return row;
  }
  return parser.formatPendingIngredient(
    amount: covered,
    unit: unit,
    name: name,
  );
}
