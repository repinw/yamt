import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/kochmodus/application/cook_finish_check.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_line_parse.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/recipes/application/ingredient_exact_quantity.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/cook_line_measure.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';

/// [line] of [run] as the page shows it, with the Vorrat [items] by id, why
/// "In Vorrat" waits ([blocks]), the pot [potId] it goes into, and what the
/// household's other runs take ([otherReservations]).
KochmodusLineView kochmodusLineView(
  CookRun run,
  CookRunLine line,
  TemplateIngredientParser parser,
  Map<String, InventoryItem> items,
  List<CookFinishBlock> blocks,
  String? potId,
  Map<String, int> otherReservations,
) {
  final parsed = parseKochmodusLine(parser, run, line);
  final lineTakes = switch (line.settlement) {
    LineAssigned(:final takes) => takes,
    _ => const <ItemTake>[],
  };
  final takes = <KochmodusTake>[
    for (final take in lineTakes)
      (itemId: take.itemId, item: items[take.itemId], amount: take.amount),
  ];
  final takenItems = takes.map((take) => take.item).nonNulls;
  final named = cookNamedItems(lineTakes, items);
  final first = named?.first;
  final need = cookLineNeed(run, line, parsed, firstItem: first);
  final shown = cookNeedShownFor(need, first, line.conversion);
  final weighed = cookWeighedTake(line, takenItems);
  final stockLeft = cookLineStockLeft(run, line, items, otherReservations);
  final takesNothing = blocks.any(
    (block) => block is CookLineWithoutTake && block.lineId == line.id,
  );
  // A guessed weight (a spoon, or pieces from a food kept in grams) that
  // takes nothing ([cookLineTakesNothing]) while its food has some for it was
  // assigned before such lines took their guess. The page follows its stored
  // takes: it waits for a weight until the cook acts, as [shortBy] and
  // [kochmodusGuessedTakeOnly] read it.
  final waitsForWeight =
      takesNothing &&
      cookTakeGuessed(line, need, first) &&
      (stockLeft?.amount ?? 0) > 0;
  ({int amount, InventoryAmountUnit? unit})? supplies(InventoryItem item) =>
      waitsForWeight ? null : cookTakeFor(need, item, line.conversion);
  final firstSupplies = first == null ? null : supplies(first);
  final fromItem = first == null
      ? null
      : weighed != null
      ? (amount: weighed, unit: first.amountUnit)
      : firstSupplies;
  final canFollowWeight = cookLineCanFollowWeight(line, items);
  final rough = cookNeedIsRough(line, parsed);
  final weighsInstead =
      canFollowWeight &&
      first != null &&
      (weighed != null || firstSupplies == null);
  final available = cookLineAvailable(
    run,
    line,
    need,
    takenItems,
    otherReservations,
  );
  final entryMissing = blocks.any(
    (block) => block is CookEntryMissing && block.lineId == line.id,
  );
  final hasPart = shown?.exactQuantity != null && cookNeedHasPart(parsed);
  final guessed = cookTakeGuessed(line, need, first);
  final counts =
      line.settlement is LineAssigned &&
      !weighsInstead &&
      !rough &&
      !(hasPart && !guessed) &&
      !entryMissing;
  return KochmodusLineView(
    line: line,
    // A rough weight adds nothing to a text with its own measure.
    text: cookLineLabel(
      line,
      rough && cookTextStartsWithMeasure(line.text) ? null : shown,
    ),
    parsed: parsed,
    need: need,
    roughNeed: rough,
    shown: shown,
    amountUnit: need?.unit ?? cookOwnAmountUnit(first),
    takes: takes,
    needFromItem: fromItem,
    taken: first == null || fromItem == null
        ? 0
        : takes
              .where(
                (take) =>
                    weighed != null ? take.item != null : _addsUp(take, first),
              )
              .fold(0, (sum, take) => sum + take.amount),
    onlyAvailable: [
      for (final block in blocks)
        if (block
            case CookStockShort(:final lineId, :final itemId, :final available)
            when lineId == line.id)
          if (items[itemId] case final item?)
            (item: item, available: available),
    ].firstOrNull,
    availableForLine: available,
    stockLeft: stockLeft,
    entryMissing: entryMissing,
    nutritionMissing: blocks.any(
      (block) => block is CookNutritionMissing && block.lineId == line.id,
    ),
    takesNothing: takesNothing,
    canFollowWeight: canFollowWeight,
    weighsInstead: weighsInstead,
    weight: cookLineWeightOf(line, items),
    potId: potId,
    pictureItem: first,
    itemCount: named?.count ?? 0,
    restOnList: run.lineOf(cookRestLineId(line.id))?.settlement is LineShopping,
    uncounted: need == null
        ? null
        : [
            for (final take in lineTakes)
              if (take.amount <= 0 && line.addedItemIds.contains(take.itemId))
                if (items[take.itemId] case final item?
                    when supplies(item) == null)
                  item,
          ].firstOrNull,
    shortBy: switch ((need?.amount, available)) {
      (final needed?, final there?)
          when counts &&
              there < needed &&
              !(guessed && stockLeft?.amount != 0) =>
        needed - there,
      _ => null,
    },
    recipeHasPart: hasPart,
  );
}

/// Whether the one food [line] takes bears a name the line says already
/// ("Zucchini" on "375 g Zucchini", "Knoblauch" on "5 Zehen Knoblauch",
/// `cookLineFood`), case and spacing aside, so a second line with that name
/// adds nothing.
bool kochmodusNamesItsFood(KochmodusLineView line) {
  final name = line.pictureItem?.name;
  if (name == null || line.itemCount != 1) return false;
  final plain = _plainName(name);
  return plain == _plainName(line.need?.name ?? line.line.text) ||
      plain == _plainName(cookLineFood(line.line.text));
}

/// What a line with a guessed weight (`cookTakeGuessed`: a guessed spoon, or
/// pieces from a food kept in grams) whose stored take is above what is left
/// can take instead, for "Nur 8 g nehmen": its item and what that still has
/// ([KochmodusLineView.onlyAvailable]), as when another cooking took stock
/// since. `null` for any other line, while the line follows a weight, and with
/// nothing left, where the line is short ([KochmodusLineView.shortBy]).
({InventoryItem item, int available})? kochmodusGuessedTakeOnly(
  KochmodusLineView line,
) => switch (line.onlyAvailable) {
  final only?
      when only.available > 0 &&
          !line.weighsInstead &&
          cookTakeGuessed(line.line, line.need, only.item) =>
    only,
  _ => null,
};

// [name] without case and spacing.
String _plainName(String name) =>
    name.toLowerCase().replaceAll(RegExp(r'\s+'), '');

// Whether what [take] holds adds up with what the item [first] holds: the same
// measure, where grams and ml count 1:1, in the same scale.
bool _addsUp(KochmodusTake take, InventoryItem first) {
  final item = take.item;
  return item != null &&
      cookSameMeasure(item.amountUnit, first.amountUnit) &&
      cookAmountScale(item) == cookAmountScale(first);
}
