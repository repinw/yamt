import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// Whether [need] counts in the unit [item] is kept in: grams on grams, ml on
/// ml, pieces on an item kept in pieces or counted whole. Never spoons, which
/// no item is kept in, and never a line without an amount.
bool cookNeedInItemUnit(
  TemplateIngredientRequirement? need,
  InventoryItem item,
) => switch (need) {
  null => false,
  TemplateIngredientRequirement(unit: TemplateIngredientUnit.gram) =>
    cookKeptByWeight(item) && item.amountUnit == InventoryAmountUnit.gram,
  TemplateIngredientRequirement(unit: TemplateIngredientUnit.milliliter) =>
    cookKeptByWeight(item) && item.amountUnit == InventoryAmountUnit.milliliter,
  TemplateIngredientRequirement(
    unit: TemplateIngredientUnit.piece,
    :final allowsDirectPieceInventoryMatch,
  ) =>
    allowsDirectPieceInventoryMatch && !cookKeptByWeight(item),
};

/// Whether the cook is asked how much of [item] he takes ("Wie viel nimmst
/// du?") once he picked it as the one food of [line], which needs [need]
/// ([rough] for only the recipe's rough weight), while [item] has [there] for
/// the line in its unit and scale (`cookAvailableFor`): when [need] counts in
/// the unit [item] is kept in ([cookNeedInItemUnit]), [item] holds more than
/// the line needs and at most as much would be left as the line takes. So
/// 400 g of 500 g asks; 200 g of 1 kg, 400 g of 400 g, 300 g of 200 g and 3
/// of 10 eggs do not. Nor does a weighed line, whose take follows the weight,
/// or a rest of a part of a piece, which no amount of the line can say.
///
/// `needed` is what the line takes of [item] by its amount, the recipe's or
/// the cook's own, in the item's unit and scale ("400 g · wie im Rezept",
/// "450 g"); `all` is the line's amount, in its own unit, that takes all of
/// [there] ("Alles · 500 g"). `null` when nothing is asked.
({int needed, int all})? cookTakeAsk({
  required CookRunLine line,
  required TemplateIngredientRequirement? need,
  required bool rough,
  required InventoryItem item,
  required int there,
}) {
  if (rough || line.weighed != null || !cookNeedInItemUnit(need, item)) {
    return null;
  }
  final needed = cookTakeFor(need, item, line.conversion)?.amount;
  if (needed == null || needed <= 0 || there <= needed) return null;
  if (there - needed > needed) return null;
  final scale = need?.unit == TemplateIngredientUnit.piece
      ? cookAmountScale(item)
      : 1;
  if (there % scale != 0) return null;
  return (needed: needed, all: there ~/ scale);
}
