import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/recipes/application/ingredient_exact_quantity.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_text.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What the text of [line] says for this cooking (`cookLineNeed` turns it into
/// what the cooking needs): a recipe line for the run's portions of its base
/// portions, a line the cook typed or said as written, whatever the portions.
/// See [readCookLineText]. Every place that reads a line of a run reads it
/// through here.
TemplateIngredientRequirement? parseKochmodusLine(
  TemplateIngredientParser parser,
  CookRun run,
  CookRunLine line,
) {
  final recipe = line.origin == CookLineOrigin.recipe;
  return readCookLineText(
    parser,
    line.text,
    selectedPortions: recipe ? run.portions : 1,
    basePortions: recipe ? run.basePortions : 1,
  );
}

/// What [text] says for [selectedPortions] of [basePortions] portions, read
/// by [parseIngredientExactly] from its normal form (`normalizeCookLineText`):
/// the amount rounded for labels and whole units, at least 1, with the exact
/// quantity of a line in pieces or spoons, and no count of packs. A scoop out
/// of a pack (`cookTextScoop`) reads like a spoon: it shows and scales, and
/// only a piece weight says what it takes. `null` when it names no amount that
/// can be read, and for a pinch (`cookTextIsPinch`).
TemplateIngredientRequirement? readCookLineText(
  TemplateIngredientParser parser,
  String text, {
  int selectedPortions = 1,
  int basePortions = 1,
}) {
  if (cookTextIsPinch(text)) return null;
  final read = parseIngredientExactly(
    parser,
    text,
    selectedPortions: selectedPortions,
    basePortions: basePortions,
  );
  // The parser takes a measure it does not know for a part of the food.
  final scoop = read == null || read.countMeasureLabel != null
      ? null
      : cookTextScoop(read.name);
  if (read == null || scoop == null) return read;
  return TemplateIngredientRequirement(
    amount: read.amount,
    unit: read.unit,
    name: scoop.food,
    countMeasureLabel: scoop.measure,
    allowsDirectPieceInventoryMatch: false,
    exactQuantity: read.exactQuantity,
  );
}

/// [line] as the page and the shopping list show it for [need]: "500 g Hack",
/// "2 Zwiebeln", "1/2 Zitrone", "1,5 EL Öl". Its own text without [need].
String cookLineLabel(CookRunLine line, TemplateIngredientRequirement? need) =>
    switch (need) {
      null => line.text.trim(),
      TemplateIngredientRequirement(unit: TemplateIngredientUnit.piece) => [
        ingredientQuantityText(need),
        if (need.countMeasureLabel?.trim() case final measure?
            when measure.isNotEmpty)
          measure,
        need.name,
      ].join(' '),
      _ => '${need.amount} ${need.unit.code} ${need.name}',
    };

/// [text], a line as the page shows it ([cookLineLabel]), split into its
/// amount and its food (`cookLineFoodName`): "1000 ml" and "Milch", "1/2" and
/// "Zitrone", "1 Prise" and "Salz", "100 g" and "Frischkäse (Doppelrahm)".
/// No amount for a line that names none ("Salz") or whose food comes first
/// ("Butter 100 g").
({String? amount, String food}) cookLineTextParts(String text) {
  final line = text.trim();
  final at = line.indexOf(cookLineFoodName(line));
  if (at <= 0) return (amount: null, food: line);
  return (amount: line.substring(0, at).trim(), food: line.substring(at));
}
