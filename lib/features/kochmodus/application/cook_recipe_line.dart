import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The line a Kochbuch recipe saved from [run] keeps for [line]: what this
/// cooking used, such as "300 g Reis". That is the cook's amount scaled to
/// the run's portions ([cookLineNeed]) or, for a text without amount, what
/// the line took from [items]. What the cook weighed goes first when the
/// takes follow it ([cookWeighedTake]). The line's own text when it already
/// says so or when it neither has an amount above 0 nor took anything.
String cookRecipeLineText(
  CookRun run,
  CookRunLine line,
  Map<String, InventoryItem> items,
) {
  final parsed = parseKochmodusLine(
    const TemplateIngredientParser(),
    run,
    line,
  );
  final takes = switch (line.settlement) {
    LineAssigned(:final takes) => takes,
    _ => const <ItemTake>[],
  };
  final first = cookNamedItems(takes, items)?.first;
  final takenItems = [for (final take in takes) ?items[take.itemId]];
  if ((cookWeighedTake(line, takenItems), first?.amountUnit) case (
    final grams?,
    final unit?,
  )) {
    return preparedMealFoodRow(
      grams.toDouble(),
      unit,
      parsed?.name ?? line.text.trim(),
    );
  }
  final need = cookLineNeed(run, line, parsed, firstItem: first);
  // An amount of 0 is no amount: the line keeps its text or what it took.
  if (need != null && need.amount > 0) {
    if (parsed != null &&
        need.amount == parsed.amount &&
        need.unit == parsed.unit) {
      return line.text;
    }
    final label = need.countMeasureLabel?.trim() ?? '';
    return need.unit == TemplateIngredientUnit.piece && label.isNotEmpty
        ? '${need.amount} $label ${need.name}'
        : preparedMealFoodRow(
            need.amount.toDouble(),
            need.unit.toInventoryAmountUnit(),
            need.name,
          );
  }
  final taken = _takenOf(line, items);
  return taken == null
      ? line.text
      : preparedMealFoodRow(taken.amount, taken.unit, line.text.trim());
}

// What [line] takes from [items] in the unit of its first take, shown as
// the item counts it; `null` when it takes nothing.
({double amount, InventoryAmountUnit unit})? _takenOf(
  CookRunLine line,
  Map<String, InventoryItem> items,
) {
  if (line.settlement case LineAssigned(:final takes)) {
    InventoryAmountUnit? unit;
    var amount = 0.0;
    for (final take in takes) {
      final item = items[take.itemId];
      final itemUnit = item?.amountUnit;
      if (item == null || itemUnit == null || take.amount <= 0) continue;
      unit ??= itemUnit;
      if (itemUnit != unit) continue;
      amount += itemUnit == InventoryAmountUnit.piece
          ? take.amount / cookAmountScale(item)
          : take.amount;
    }
    if (unit != null) return (amount: amount, unit: unit);
  }
  return null;
}
