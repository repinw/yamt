import 'dart:math' show max;

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/domain/recipe_ingredient_row.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/recipes/application/cook_run_providers.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_not_counted.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

part 'recipe_line_states.g.dart';

/// What the cook run takes for one line when the cook changed its amount:
/// `amount` for the run's portions, in `unit` on a line whose text names
/// none.
typedef RecipeLineOwnAmount = ({int amount, TemplateIngredientUnit? unit});

/// Where one ingredient line of a recipe stands in its cook run.
sealed class RecipeLineState {
  const new(this.text, {this.own});

  /// The ingredient as the cook run took it from the recipe. The saved line
  /// at the same index can differ after an edit from another device.
  final String text;

  /// What the run takes when the cook changed the amount ("Nur 300 ml");
  /// `null` for the recipe's amount.
  final RecipeLineOwnAmount? own;
}

/// The line takes Vorrat food, which has [stock] left for this cooking
/// ("bereit"); with [rest], what it lacks waits on the shopping list ("300 ml
/// da · 200 ml im Einkauf").
final class RecipeLineAssigned extends RecipeLineState {
  /// Creates the state of the line [text] with what the Vorrat food holds.
  const new(super.text, this.stock, {super.own, this.rest});

  /// How much the Vorrat food has left for this cooking, such as 750 g, or
  /// `null` while its items are not loaded or gone.
  final ({int amount, InventoryAmountUnit unit})? stock;

  /// What the cook run's line for the rest ([cookRestLineId]) puts on the
  /// shopping list, such as 200 ml; `null` when nothing waits there.
  final ({int amount, InventoryAmountUnit unit})? rest;
}

/// The line waits on the shopping list ("im Einkauf").
final class RecipeLineShopping extends RecipeLineState {
  /// Creates the state of the line [text].
  const new(super.text, {super.own});
}

/// The line has no answer yet ("offen").
final class RecipeLineOpen extends RecipeLineState {
  /// Creates the state of the line [text].
  const new(super.text);
}

/// The line is left out of this cooking: by the cook ("weggelassen"), or,
/// with [notCounted], because it does not count in the nutrition, like a
/// pinch of salt or water, which the cook still adds ("zählt nicht mit").
final class RecipeLineIgnored extends RecipeLineState {
  /// Creates the state of the line [text].
  const new(super.text, {this.notCounted = false});

  /// Whether the line does not count in the nutrition by its text
  /// (`cookLineNotCounted`).
  final bool notCounted;
}

/// The state of each ingredient line of the recipe [recipeId] by its index
/// in the saved ingredients when the cook run started, or `null` without a
/// cook run. Lines the cook run added itself do not count.
@riverpod
Map<int, RecipeLineState>? recipeLineStates(Ref ref, String recipeId) {
  final run = ref.watch(recipeCookRunProvider(recipeId)).value;
  if (run == null) {
    return null;
  }
  final items = {
    for (final item
        in ref.watch(inventoryQuickEatItemsProvider).value ??
            const <InventoryItem>[])
      item.id: item,
  };
  final reserved =
      ref.watch(cookRunReservationsProvider).value ?? const <String, int>{};
  return {
    for (final line in run.lines)
      if (line.origin == CookLineOrigin.recipe)
        ?_recipeLineIndex(line.id): _lineState(
          line,
          run.portions,
          items,
          reserved,
          rest: switch (run.lineOf(cookRestLineId(line.id))) {
            CookRunLine(settlement: LineShopping(), :final text) =>
              const TemplateIngredientParser().parseRequirement(
                ingredient: text,
                selectedPortions: 1,
                basePortions: 1,
              ),
            _ => null,
          },
        ),
  };
}

// [rest] is what the line's rest line puts on the shopping list. The
// stock is what is left for this cooking, as "Was hast du da?" counts it:
// the items' stock less what all cook runs together take of them
// ([reserved]), except the line's own takes.
RecipeLineState _lineState(
  CookRunLine line,
  int portions,
  Map<String, InventoryItem> items,
  Map<String, int> reserved, {
  required TemplateIngredientRequirement? rest,
}) => switch (line.settlement) {
  // A take of 0 only keeps its item with the line while another one takes.
  LineAssigned(:final takes) => RecipeLineAssigned(
    line.text,
    RecipeIngredientRow(
      text: line.text,
      stockItems: [
        for (final take in takes)
          if (take.amount > 0 || takes.every((other) => other.amount <= 0))
            ?items[take.itemId],
      ],
    ).stockLeft({
      for (final take in takes)
        // Until the reservations are read, only the line's own take is known.
        take.itemId: max(
          0,
          (reserved[take.itemId] ?? take.amount) - take.amount,
        ),
    }),
    own: _ownAmount(line, portions),
    rest: rest == null
        ? null
        : (amount: rest.amount, unit: rest.unit.toInventoryAmountUnit()),
  ),
  LineShopping() => RecipeLineShopping(
    line.text,
    own: _ownAmount(line, portions),
  ),
  LineIgnored() => RecipeLineIgnored(
    line.text,
    notCounted: cookLineNotCounted(line.text),
  ),
  LineOpen() => RecipeLineOpen(line.text),
};

// The cook's amount of a recipe line, scaled from the portions it was set
// for to the run's [portions], as cooking reads it; never below 1.
RecipeLineOwnAmount? _ownAmount(CookRunLine line, int portions) {
  final (amount, from) = (line.amount, line.amountPortions);
  if (amount == null || from == null) return null;
  final scaled = (amount * portions / max(1, from)).round();
  return (amount: amount > 0 ? max(1, scaled) : 0, unit: line.amountUnit);
}

// A cook run names the recipe's lines "line-<index>".
int? _recipeLineIndex(String lineId) =>
    lineId.startsWith('line-') ? int.tryParse(lineId.substring(5)) : null;

/// How many lines of [states] are ready, on the shopping list (also those
/// whose rest waits there), left out by the cook, and open. A line that does
/// not count in the nutrition counts nowhere.
({int ready, int shopping, int ignored, int open}) recipeLineCounts(
  Map<int, RecipeLineState> states,
) {
  var ready = 0;
  var shopping = 0;
  var ignored = 0;
  var open = 0;
  for (final state in states.values) {
    switch (state) {
      case RecipeLineAssigned(rest: _?):
        shopping++;
      case RecipeLineAssigned():
        ready++;
      case RecipeLineShopping():
        shopping++;
      case RecipeLineIgnored(notCounted: true):
        break;
      case RecipeLineIgnored():
        ignored++;
      case RecipeLineOpen():
        open++;
    }
  }
  return (ready: ready, shopping: shopping, ignored: ignored, open: open);
}
