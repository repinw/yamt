import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The best Vorrat match for [requirement] of the ingredient [text], or
/// `null` when no item fits: the first of the `matches` of
/// [ingredientStockCandidates].
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
  final scored = _scored(text, items, localeCode);
  return scored
      .firstWhereOrNull(
        (match) =>
            _standsIn(match.score, scored) &&
            _itemFits(match.item, requirement, amountConversion),
      )
      ?.item;
}

/// The Vorrat items that can supply [requirement] of the ingredient [text]:
/// the `matches` that match its name best of all items, and the `others`,
/// first the weaker name matches, best first, then the rest in a fitting
/// unit by name. Only the matches supply the line by default, so a weaker
/// match never stands in for a better one kept in another unit: no other
/// rice for "100 g Testreis" when Testreis is kept in pieces, and no
/// "Milchreis" for "300 ml Milch" (#785).
///
/// An ingredient that names no amount, such as "Salz", fits any item of its
/// name ([ingredientNamesNoAmount]), and only its name matches count. A
/// recipe's saved [amountConversion] lets pieces come from an item kept in
/// grams or milliliters.
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
  final scored = _scored(text, items, localeCode);
  final matches = <InventoryItem>[];
  final weaker = <InventoryItem>[];
  for (final (:item, :score) in scored) {
    if (_itemFits(item, requirement, amountConversion)) {
      (_standsIn(score, scored) ? matches : weaker).add(item);
    }
  }
  if (requirement == null) {
    return (matches: matches, others: weaker);
  }
  final named = {for (final (:item, score: _) in scored) item.id};
  final rest =
      [
        for (final item in items)
          if (!item.isFullyConsumed &&
              !named.contains(item.id) &&
              _itemFits(item, requirement, amountConversion))
            item,
      ]..sort(
        (left, right) =>
            left.name.toLowerCase().compareTo(right.name.toLowerCase()),
      );
  return (matches: matches, others: [...weaker, ...rest]);
}

/// The items that supply the ingredient [text] of [recipe] when nobody picks
/// one: its saved items among [candidates] ([ingredientStockCandidates]), in
/// saved order, else the best match. The recipe page, the Kochbuch cards and
/// plans all pick this way.
List<InventoryItem> ingredientStockPick({
  required PreparedMeal recipe,
  required String text,
  required ({List<InventoryItem> matches, List<InventoryItem> others})
  candidates,
}) {
  final (:matches, :others) = candidates;
  final byId = {
    for (final item in [...matches, ...others]) item.id: item,
  };
  final saved = [
    for (final id
        in recipe.recipeIngredientAssignments[text] ?? const <String>[])
      ?byId[id],
  ];
  return saved.isNotEmpty ? saved : [?matches.firstOrNull];
}

/// How much of [requirement] the [items] cannot supply, in the unit the
/// Vorrat counts it in, or `null` when they supply all of it or the
/// ingredient has no amount. [amountConversion] works as in
/// [ingredientStockCandidates].
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

// The items not used up that match [text], best first. Every item gets a
// name score, not only the fitting ones, so a better match in another unit
// keeps a weaker one from standing in.
List<({InventoryItem item, int score})> _scored(
  String text,
  List<InventoryItem> items,
  String? localeCode,
) => scoreInventoryItemsForIngredient(
  ingredient: text,
  inventoryItems: items,
  localeCode: localeCode,
);

// Whether a name match of [score] matches as well as the best of [scored],
// so it may supply a line. Compound words make "Milchreis" score more than
// half of "Milch" (#785), so no weaker match counts.
bool _standsIn(int score, List<({InventoryItem item, int score})> scored) =>
    score == scored.first.score;

// Whether [item] is kept in a unit that can supply [requirement], with the
// recipe's saved [amountConversion] for pieces, whatever it still holds.
// Without a [requirement] there is no amount to supply, so any item fits;
// callers check [ingredientNamesNoAmount] first.
bool _itemFits(
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
