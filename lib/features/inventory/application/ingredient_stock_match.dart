import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The best Vorrat match for [requirement] of the ingredient [text], or
/// `null` when no item fits. An ingredient that names no amount, such as
/// "Salz", fits any item of its name ([ingredientNamesNoAmount]). A recipe's
/// saved [amountConversion] lets pieces come from an item kept in grams or
/// milliliters.
InventoryItem? bestIngredientStockMatch({
  required String text,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required String? localeCode,
  RecipeIngredientAmountConversion? amountConversion,
}) {
  if (requirement == null && !ingredientNamesNoAmount(text)) {
    return null;
  }
  return _matches(text, [
    for (final item in items)
      if (ingredientItemFits(item, requirement, amountConversion)) item,
  ], localeCode).firstOrNull;
}

/// The Vorrat items that can supply [requirement] of the ingredient [text]:
/// the `matches` by name, best first, so the first is
/// [bestIngredientStockMatch], and the `others` in a fitting unit by name.
/// A line that names no amount has no unit to fit, so only its name matches
/// count.
/// [amountConversion] works as in [bestIngredientStockMatch].
({List<InventoryItem> matches, List<InventoryItem> others})
ingredientStockCandidates({
  required String text,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required String? localeCode,
  RecipeIngredientAmountConversion? amountConversion,
}) {
  if (requirement == null && !ingredientNamesNoAmount(text)) {
    return (matches: const <InventoryItem>[], others: const <InventoryItem>[]);
  }
  // The unit check is cheap, the name score is not, so it goes first.
  final fitting = [
    for (final item in items)
      if (!item.isFullyConsumed &&
          ingredientItemFits(item, requirement, amountConversion))
        item,
  ];
  final matches = _matches(text, fitting, localeCode);
  if (requirement == null) {
    return (matches: matches, others: const <InventoryItem>[]);
  }
  final matchIds = {for (final item in matches) item.id};
  final others = fitting.where((item) => !matchIds.contains(item.id)).toList()
    ..sort(
      (left, right) =>
          left.name.toLowerCase().compareTo(right.name.toLowerCase()),
    );
  return (matches: matches, others: others);
}

/// How much of [requirement] the [items] cannot supply, in the unit the
/// Vorrat counts it in, or `null` when they supply all of it or the
/// ingredient has no amount. [amountConversion] works as in
/// [bestIngredientStockMatch].
({int amount, InventoryAmountUnit unit})? ingredientShortfall({
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  RecipeIngredientAmountConversion? amountConversion,
}) {
  if (requirement == null) {
    return null;
  }
  final effective = resolveEffectiveRequirementForItems(
    requirement: requirement,
    assignedItems: items,
    amountConversion: amountConversion,
  );
  // ponytail: pieces count as supplied; add per-piece math when recipes
  // need more pieces than the Vorrat holds.
  if (effective == null || effective.unit == InventoryAmountUnit.piece) {
    return null;
  }
  final missing =
      effective.amount - ingredientStockedAmount(items, effective.unit);
  return missing > 0 ? (amount: missing, unit: effective.unit) : null;
}

/// What [items] hold in [unit], or 0 without a unit.
int ingredientStockedAmount(
  List<InventoryItem> items,
  InventoryAmountUnit? unit,
) => unit == null
    ? 0
    : items
          .where((item) => item.amountUnit == unit)
          .fold(0, (sum, item) => sum + item.availableAmount);

List<InventoryItem> _matches(
  String text,
  List<InventoryItem> items,
  String? localeCode,
) => matchInventoryItemsForIngredient(
  ingredient: text,
  inventoryItems: items,
  localeCode: localeCode,
);

/// Whether the recipe line [text] names no amount at all, like "Salz". A
/// Vorrat item of its name stands for it and gives nothing. "1 cup Milch",
/// "½ Zwiebel", "eine Dose Tomaten" or "etwas Mehl" name an amount the
/// parser cannot read, so they stay open rows.
bool ingredientNamesNoAmount(String text) => !_amountHint.hasMatch(text);

// A digit or fraction, or a word that starts like a number, a vague amount
// or a measure ("Saft einer Zitrone"), anywhere in the line. It errs towards
// an amount, which only keeps a line open as before.
final _amountHint = RegExp(
  r'[\d¼½¾\u2150-\u215E]|\b(?:(?:ein|zwei|drei|vier|fünf|sechs|sieben|'
  'acht|neun|zehn|elf|zwölf|zwanzig|dreißig|hundert|halb|viertel|dutzend|'
  'anderthalb|einige|mehrere|etwas|paar|wenig|viel|bisschen|handvoll|prise|'
  'messerspitze|schuss|spritzer|packung|päckchen|dose|bund|becher|glas|'
  'gläser|flasche|tasse|stück|scheibe|zehe|kopf|knolle|stange|zweig|blatt|'
  'liter|gramm|kilo|pfund|seven|eight|nine|eleven|twelve|twenty|half|'
  'quarter|dozen|some|several|few|little|handful|pinch|dash|splash|pack|'
  r'bunch|cup|tablespoon|teaspoon|clove|slice|piece|bottle|pound|ounce)\w*|'
  '(?:a|an|one|two|three|four|five|six|ten|can|tin|jar|tl|el|msp|pck|stk|'
  r'tbsp|tsp|lb|oz)\b)',
  caseSensitive: false,
);

/// Whether [item] is kept in a unit that can supply [requirement], with the
/// recipe's saved [amountConversion] for pieces, whatever it still holds.
/// Without a [requirement] there is no amount to supply, so any item fits;
/// callers check [ingredientNamesNoAmount] first.
bool ingredientItemFits(
  InventoryItem item,
  TemplateIngredientRequirement? requirement,
  RecipeIngredientAmountConversion? amountConversion,
) =>
    requirement == null ||
    resolveEffectiveRequirementForItems(
          requirement: requirement,
          assignedItems: [item],
          amountConversion: amountConversion,
        ) !=
        null;
