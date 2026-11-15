import 'dart:math';

import 'package:yamt/features/inventory/application/recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_line_text.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What [line] of [run] needs for this cooking. [parsed] is what its text says
/// ([parseKochmodusLine]); the cook's [CookRunLine.amount] replaces its amount
/// in the same unit: on a recipe line scaled from its
/// [CookRunLine.amountPortions] to the run's portions, on a line the cook typed
/// or said as it is. A cook's amount above 0 never rounds below 1. A line whose
/// text names no amount counts the cook's amount in the unit it was typed in
/// ([CookRunLine.amountUnit]), else in that of [firstItem], the line's first
/// item ([cookOwnAmountUnit]); without the cook's amount it needs the recipe's
/// rough weight ([CookRunLine.roughWeight], [cookNeedIsRough]) scaled to the
/// portions. `null` when none of them names an amount.
TemplateIngredientRequirement? cookLineNeed(
  CookRun run,
  CookRunLine line,
  TemplateIngredientRequirement? parsed, {
  InventoryItem? firstItem,
}) {
  final (amount, portions) = (line.amount, line.amountPortions);
  if (amount == null || portions == null) {
    final rough = line.roughWeight;
    if (parsed != null || rough == null) return parsed;
    final scaled = rough.amount * run.portions / max(1, run.basePortions);
    return TemplateIngredientRequirement(
      amount: max(1, scaled.round()),
      unit: rough.unit,
      name: line.text.trim(),
    );
  }
  final exact = line.origin == CookLineOrigin.recipe
      ? amount * run.portions / portions
      : amount.toDouble();
  final unit = parsed?.unit ?? line.amountUnit ?? cookOwnAmountUnit(firstItem);
  return TemplateIngredientRequirement(
    amount: amount > 0 ? max(1, exact.round()) : 0,
    unit: unit,
    name: parsed?.name ?? line.text,
    countMeasureLabel: parsed?.countMeasureLabel,
    allowsDirectPieceInventoryMatch:
        parsed?.allowsDirectPieceInventoryMatch ?? true,
    exactQuantity: unit == TemplateIngredientUnit.piece && amount > 0
        ? exact
        : null,
  );
}

/// The unit the cook's amount counts in on a line whose text names none: that
/// of its first item [item], pieces for an item counted in pieces or whole
/// packs, and grams without an item.
TemplateIngredientUnit cookOwnAmountUnit(InventoryItem? item) {
  if (item == null) return TemplateIngredientUnit.gram;
  return _weightUnitOf(item)?.toTemplateIngredientUnit() ??
      TemplateIngredientUnit.piece;
}

/// [need] as a row says it when [item] supplies it: an item counted whole
/// gives whole pieces, so the row says what it takes ("1 Zitrone" for "1/2
/// Zitrone"). [conversion] is the line's piece weight.
TemplateIngredientRequirement? cookNeedShownFor(
  TemplateIngredientRequirement? need,
  InventoryItem? item,
  CookLineConversion? conversion,
) {
  if (need == null || item == null || need.exactQuantity == null) return need;
  final takesWhole =
      cookTakeFor(need, item, conversion)?.unit == InventoryAmountUnit.piece &&
      cookAmountScale(item) == 1;
  return takesWhole
      ? TemplateIngredientRequirement(
          amount: need.amount,
          unit: need.unit,
          name: need.name,
          countMeasureLabel: need.countMeasureLabel,
          allowsDirectPieceInventoryMatch: need.allowsDirectPieceInventoryMatch,
        )
      : need;
}

/// What the takes of [line] from [items] follow: what the cook weighed, when
/// every one of [items] is kept in grams or ml, which count 1:1. `null` when
/// nothing is weighed or an item is counted in pieces or whole packs: the
/// weight is then only a record and the takes follow [cookLineNeed], so a
/// Zwiebel weighed at 180 g still takes 1 piece.
int? cookWeighedTake(CookRunLine line, Iterable<InventoryItem> items) {
  final grams = line.weighed;
  if (grams == null || grams < 1 || items.isEmpty) return null;
  return items.every(cookKeptByWeight) ? grams : null;
}

/// Whether the takes of [line] can follow a weight: it is assigned, one of
/// its items is still in [items] and kept in grams or ml, and every item it
/// takes from is. "1 EL Senf" on a whole pack or "200 g Reis" on an item
/// counted in pieces cannot, so weighing does not help them. A take of 0 takes
/// nothing, so its item does not count.
bool cookLineCanFollowWeight(
  CookRunLine line,
  Map<String, InventoryItem> items,
) => switch (line.settlement) {
  LineAssigned(:final takes) =>
    takes.any((take) => _keptByWeight(items[take.itemId])) &&
        takes.every(
          (take) => take.amount <= 0 || _keptByWeight(items[take.itemId]),
        ),
  _ => false,
};

/// Whether [item] is kept in grams or ml, so its take can follow a weight.
bool cookKeptByWeight(InventoryItem item) => _weightUnitOf(item) != null;

bool _keptByWeight(InventoryItem? item) =>
    item != null && cookKeptByWeight(item);

// The unit of [item] when it is kept in grams or ml, else `null`.
InventoryAmountUnit? _weightUnitOf(InventoryItem item) =>
    item.usesAmountProgress && item.amountUnit != InventoryAmountUnit.piece
    ? item.amountUnit
    : null;

// [need] in the unit [kept] when it asks for the other of grams and ml.
TemplateIngredientRequirement _inKeptUnit(
  TemplateIngredientRequirement need,
  InventoryAmountUnit? kept,
) {
  if (kept == null || need.unit == TemplateIngredientUnit.piece) return need;
  return TemplateIngredientRequirement(
    amount: need.amount,
    unit: kept.toTemplateIngredientUnit(),
    name: need.name,
    countMeasureLabel: need.countMeasureLabel,
    packageCountLabel: need.packageCountLabel,
    allowsDirectPieceInventoryMatch: need.allowsDirectPieceInventoryMatch,
  );
}

/// [need] and, when it asks for grams or ml, the same amount in the other of
/// them, which count 1:1 while cooking; its own unit first.
List<TemplateIngredientRequirement?> cookNeedInBothMeasures(
  TemplateIngredientRequirement? need,
) {
  if (need == null || need.unit == TemplateIngredientUnit.piece) return [need];
  final other = need.unit == TemplateIngredientUnit.gram
      ? InventoryAmountUnit.milliliter
      : InventoryAmountUnit.gram;
  return [need, _inKeptUnit(need, other)];
}

/// Whether amounts in [a] and [b] add up: the same unit, or grams and ml,
/// which count 1:1 while cooking.
bool cookSameMeasure(InventoryAmountUnit? a, InventoryAmountUnit? b) =>
    a == b ||
    (a != null &&
        b != null &&
        a != InventoryAmountUnit.piece &&
        b != InventoryAmountUnit.piece);

/// Whether [line] of [run] names an amount but takes nothing, such as
/// "1 Möhre" from an item kept in grams without a piece weight, "2 Tassen Reis"
/// from a pack (`cookTextScoop`), or "2 cups Mehl" whose amount cannot be read.
/// It would leave the meal, the stock and the kcal without a word, so it waits
/// until the cook weighs it ([cookLineCanFollowWeight]), picks another food or
/// removes it. A line without a counted amount takes nothing on purpose
/// ("Salz", "etwas Öl", "1 Prise Salz", see `cookTextStartsWithCount`), also
/// when the recipe's rough weight gives it a need ([cookNeedIsRough]), and so
/// does the cook's own amount of 0.
bool cookLineTakesNothing(CookRun run, CookRunLine line) {
  if (line.settlement case LineAssigned(:final takes)) {
    if (takes.any((take) => take.amount > 0)) return false;
    final parsed = parseKochmodusLine(
      const TemplateIngredientParser(),
      run,
      line,
    );
    final need = cookLineNeed(run, line, parsed);
    return need == null || cookNeedIsRough(line, parsed)
        ? cookTextStartsWithCount(line.text)
        : need.amount > 0;
  }
  return false;
}

/// Whether [line], whose text says [parsed], needs only the recipe's rough
/// weight ([CookRunLine.roughWeight]): its text names no amount and the cook
/// set none. The page shows that need as "≈".
bool cookNeedIsRough(CookRunLine line, TemplateIngredientRequirement? parsed) =>
    parsed == null && line.amount == null && line.roughWeight != null;

/// What [item] must give for [need], in the unit and scale it is kept in, or
/// `null` when its unit cannot supply it. Grams and ml count 1:1. A line in
/// spoons takes the spoon's weight ([cookSpoonWeight]), else [conversion] is
/// the line's piece weight. A line without amount needs 0. A part of a piece
/// ([TemplateIngredientRequirement.exactQuantity]) takes that part of a piece
/// kept in a scale above 1 or of a piece weight, at least 1 of an item counted
/// whole. Grams or ml of one kept in parts of pieces go by its piece weight.
({int amount, InventoryAmountUnit? unit})? cookTakeFor(
  TemplateIngredientRequirement? need,
  InventoryItem item,
  CookLineConversion? conversion,
) {
  if (need == null) return (amount: 0, unit: null);
  final kept = _weightUnitOf(item);
  final weight = cookSpoonWeight(need, conversion) ?? conversion;
  final effective = resolveEffectiveRequirementForItems(
    requirement: _inKeptUnit(need, kept),
    assignedItems: [item],
    amountConversion: weight == null
        ? null
        : RecipeIngredientAmountConversion(
            amountPerPiece: weight.amountPerPiece,
            unit: kept ?? weight.unit.toInventoryAmountUnit(),
          ),
  );
  if (effective == null) {
    final perPiece = cookPieceWeightOf(item);
    return perPiece == null || need.unit == TemplateIngredientUnit.piece
        ? null
        : (
            amount: (need.amount / perPiece * cookAmountScale(item)).round(),
            unit: InventoryAmountUnit.piece,
          );
  }
  // Pieces are kept in the item's scale, a thousand per piece for a pack.
  final scale = effective.unit == InventoryAmountUnit.piece
      ? cookAmountScale(item)
      : 1;
  final exact = need.exactQuantity;
  final whole = effective.unit == InventoryAmountUnit.piece && scale == 1;
  if (exact == null || whole || need.amount < 1) {
    return (amount: effective.amount * scale, unit: effective.unit);
  }
  final perPiece = effective.amount * scale / need.amount;
  return (amount: max(1, (exact * perPiece).round()), unit: effective.unit);
}

/// [available] of [item], kept in its unit and scale, in the unit of [need],
/// rounded down; the reverse of [cookTakeFor]. A line without amount counts
/// in grams. `null` when the item's unit cannot supply the line.
int? cookLineAmountOf(
  TemplateIngredientRequirement? need,
  InventoryItem item,
  CookLineConversion? conversion,
  int available,
) {
  final perPiece = cookPieceWeightOf(item);
  if (perPiece != null && need?.unit != TemplateIngredientUnit.piece) {
    return (available / cookAmountScale(item) * perPiece).floor();
  }
  final perUnit = cookTakeFor(
    TemplateIngredientRequirement(
      amount: 1,
      unit: need?.unit ?? TemplateIngredientUnit.gram,
      name: need?.name ?? item.name,
      allowsDirectPieceInventoryMatch:
          need?.allowsDirectPieceInventoryMatch ?? true,
    ),
    item,
    cookSpoonWeight(need, conversion) ?? conversion,
  )?.amount;
  return perUnit == null ? null : available ~/ perUnit;
}

/// The scale [item] counts its amounts in: packs tracked by amount keep
/// a thousand per piece, items counted whole keep 1.
int cookAmountScale(InventoryItem item) =>
    item.usesAmountProgress ? max(1, item.amountScale) : 1;
