import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/domain/stock_fill.dart';
import 'package:yamt/features/recipes/domain/cook_line_not_counted.dart';
import 'package:yamt/features/recipes/domain/cook_line_settlement.dart';
import 'package:yamt/features/recipes/domain/cook_run.dart';
import 'package:yamt/features/recipes/domain/cook_run_line.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The takes of [line] of [run] that needs [need] (see [cookLineNeed]),
/// from [items] in the cook's order.
///
/// The line decides what it takes: [need], filled from the items in order
/// (`fillInOrder`), each giving what it has: its stock less what
/// [otherReservations] (the other runs, by item id) and the other lines of
/// [run] take. An item that search, barcode or AI put into the Vorrat for the
/// line holds what the cook has at home, so it gives like any other; the food
/// just found comes first in [items]. Only items kept in the unit and scale of
/// the first item that can supply [need] fill. An item that can fill but is
/// not needed now stays with 0, so a higher need fills from it again, and at
/// least one item stays, so the line stays assigned and shows how much is
/// missing. A food the cook added for the line ([CookRunLine.addedItemIds])
/// always stays, with 0 when it cannot supply [need], so it is never dropped
/// without a word. Takes of 0 are not named, counted or written
/// (`cookNamedItems`).
///
/// A line whose takes follow what the cook weighed ([cookWeighedTake]) fills
/// that from all [items] in order, added ones too. A weight is a fact: the
/// food is in the pot. So each item gives its stock less what the other lines
/// of [run] take, whatever other runs reserve (as in `cookFinishBlocks`), and
/// what the items cannot hold goes onto the last one, where `CookStockShort`
/// asks the cook to correct it. An item not needed stays with 0, so a later
/// mention or clearing the weight can fill from it again.
List<ItemTake> cookTakesFor({
  required CookRun run,
  required CookRunLine line,
  required TemplateIngredientRequirement? need,
  required List<InventoryItem> items,
  required Map<String, int> otherReservations,
}) {
  if (items.isEmpty) return const [];
  if (cookWeighedTake(line, items) case final weighed?) {
    final filled = {
      for (final take in fillInOrder(
        needed: weighed,
        offers: [
          for (final item in items)
            (
              itemId: item.id,
              available: cookAvailableFor(run, line, item, const {}),
            ),
        ],
      ))
        take.itemId: take.amount,
    };
    final beyondStock = weighed - filled.values.sum;
    return [
      for (final item in items)
        ItemTake(
          itemId: item.id,
          amount:
              (filled[item.id] ?? 0) +
              (item.id == items.last.id ? beyondStock : 0),
        ),
    ];
  }
  final reference = items.firstWhere(
    (item) => cookTakeFor(need, item, line.conversion) != null,
    orElse: () => items.first,
  );
  final first = cookTakeFor(need, reference, line.conversion);
  bool fills(InventoryItem item) =>
      cookSameMeasure(
        cookTakeFor(need, item, line.conversion)?.unit,
        first?.unit,
      ) &&
      cookAmountScale(item) == cookAmountScale(reference);
  final filled = {
    for (final take in fillInOrder(
      needed: first?.amount ?? 0,
      offers: [
        for (final item in items)
          if (fills(item))
            (
              itemId: item.id,
              available: cookAvailableFor(run, line, item, otherReservations),
            ),
      ],
    ))
      take.itemId: take,
  };
  for (final item in items) {
    if ((fills(item) && _staysChosen(item, reference, first)) ||
        line.addedItemIds.contains(item.id)) {
      filled.putIfAbsent(item.id, () => ItemTake(itemId: item.id, amount: 0));
    }
  }
  if (filled.isEmpty) {
    filled[reference.id] = ItemTake(itemId: reference.id, amount: 0);
  }
  return [for (final item in items) ?filled[item.id]];
}

// Whether [item] may wait with 0 next to [reference], which asks [first] of
// the line. A measured need says it by the unit and scale ([cookTakesFor]). A
// line without a need counts on items kept alike. Spoons nobody can supply wait
// for a weight, so only items that can follow one wait with them.
bool _staysChosen(
  InventoryItem item,
  InventoryItem reference,
  ({int amount, InventoryAmountUnit? unit})? first,
) {
  final alike =
      cookKeptByWeight(item) == cookKeptByWeight(reference) &&
      cookSameMeasure(item.amountUnit, reference.amountUnit);
  return switch (first) {
    null => alike && cookKeptByWeight(item),
    (amount: _, unit: null) => alike,
    _ => true,
  };
}

/// What the other runs ([otherReservations], by item id) and the other
/// lines of [run] take of [item], next to [line]. Another line's take above
/// the whole stock does not count: `CookStockShort` holds that line back until
/// the cook corrects it, so its weight must not starve the lines next to it.
int cookReservedFor(
  CookRun run,
  CookRunLine line,
  InventoryItem item,
  Map<String, int> otherReservations,
) =>
    (otherReservations[item.id] ?? 0) +
    [
      for (final other in run.lines)
        if (other.id != line.id)
          if (other.settlement case LineAssigned(:final takes))
            for (final take in takes)
              if (take.itemId == item.id && take.amount <= item.availableAmount)
                take.amount,
    ].sum;

/// What [item] still has for [line], in its unit and scale: its stock less
/// [cookReservedFor], never below 0.
int cookAvailableFor(
  CookRun run,
  CookRunLine line,
  InventoryItem item,
  Map<String, int> otherReservations,
) => max(
  0,
  item.availableAmount - cookReservedFor(run, line, item, otherReservations),
);

/// What [items] still have for [line] of [run] in the unit of [need], or of
/// the first of them on a line without amount ([cookOwnAmountUnit]);
/// `null` when none of them can supply it. See [cookAvailableFor],
/// [cookLineAmountOf].
int? cookLineAvailable(
  CookRun run,
  CookRunLine line,
  TemplateIngredientRequirement? need,
  Iterable<InventoryItem> items,
  Map<String, int> otherReservations,
) {
  final asked =
      need ??
      TemplateIngredientRequirement(
        amount: 1,
        unit: cookOwnAmountUnit(items.firstOrNull),
        name: line.text,
      );
  final amounts = [
    for (final item in items)
      ?cookLineAmountOf(
        asked,
        item,
        line.conversion,
        cookAvailableFor(run, line, item, otherReservations),
      ),
  ];
  return amounts.isEmpty ? null : amounts.sum;
}

/// What the foods [line] of [run] names still have for it, as every text that
/// says what is there counts it, in the unit and scale of the first of them
/// (`item`): each one's stock less what the other runs ([otherReservations],
/// by item id) and the run's other lines take ([cookAvailableFor]), added up
/// over those kept like the first (the same scale; grams and ml count 1:1).
/// Its own takes stay in, so "5 EL Olivenöl" from a bottle of 400 ml, of
/// which another cooking takes 50 ml, has 350 ml. The foods are those the
/// line takes something of, else all it holds (`cookNamedItems`). `null` when
/// it holds none that is still in [items].
({InventoryItem item, int amount})? cookLineStockLeft(
  CookRun run,
  CookRunLine line,
  Map<String, InventoryItem> items,
  Map<String, int> otherReservations,
) {
  final held = [
    if (line.settlement case LineAssigned(:final takes))
      for (final take in takes)
        if (items[take.itemId] case final item?)
          (item: item, take: take.amount),
  ];
  final taking = held.where((each) => each.take > 0).toList();
  final named = [for (final each in taking.isEmpty ? held : taking) each.item];
  final first = named.firstOrNull;
  if (first == null) return null;
  return (
    item: first,
    amount: [
      for (final item in named)
        if (cookSameMeasure(item.amountUnit, first.amountUnit) &&
            cookAmountScale(item) == cookAmountScale(first))
          cookAvailableFor(run, line, item, otherReservations),
    ].sum,
  );
}

/// What a row names of [takes] from the Vorrat [items] by id: `first`, the
/// first item that takes something, and `count`, how many do. A take of 0 only
/// keeps its item with the line, so it is named only when no item takes
/// anything, and then just the first. `null` when none is still in [items].
({InventoryItem first, int count})? cookNamedItems(
  Iterable<ItemTake> takes,
  Map<String, InventoryItem> items,
) {
  final held = takes.where((take) => items.containsKey(take.itemId));
  final taking = held.where((take) => take.amount > 0);
  final first = taking.firstOrNull ?? held.firstOrNull;
  return first == null
      ? null
      : (first: items[first.itemId]!, count: max(1, taking.length));
}

/// Whether what [line], which needs [need], takes of [item] is only a guess
/// of its weight: a guessed spoon ([cookSpoonGuessed]), or a line in pieces,
/// a measure or without an amount ([cookLineAmountKind]) that counts and
/// takes from a food kept in grams or ml, whose weight "Noch zu wiegen" asks
/// for. Such a line takes what the guess says, at most what is there, and is
/// short only when [item] has nothing left for it.
bool cookTakeGuessed(
  CookRunLine line,
  TemplateIngredientRequirement? need,
  InventoryItem? item,
) =>
    cookSpoonGuessed(need, line.conversion) ||
    (item != null &&
        cookKeptByWeight(item) &&
        !cookLineNotCounted(line.text) &&
        cookLineAmountKind(line) == CookLineAmountKind.other);
