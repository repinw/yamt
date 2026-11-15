import 'dart:math' show max, min;

import 'package:collection/collection.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/application/inventory_search_service.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/cook_line_food.dart';
import 'package:yamt/features/inventory/domain/ingredient_compound_head.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_content.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_entry.dart';
import 'package:yamt/features/inventory/presentation/models/'
    'inventory_list_view_preferences.dart';
import 'package:yamt/features/inventory/presentation/widgets/inventory_list/'
    'inventory_receipt_group.dart';
import 'package:yamt/features/kochmodus/application/cook_line_amount.dart';
import 'package:yamt/features/kochmodus/application/cook_pick_need.dart';
import 'package:yamt/features/kochmodus/application/cook_takes.dart';
import 'package:yamt/features/kochmodus/domain/cook_food_words.dart';
import 'package:yamt/features/kochmodus/domain/cook_line_weight.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_line_view.dart';
import 'package:yamt/features/kochmodus/presentation/models/kochmodus_view.dart';
import 'package:yamt/features/recipes/domain/cook_line_text.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The offers of the picker of the line [lineId] by the one rule of which
/// Vorrat items can supply a recipe line (`ingredientStockCandidates`), asked
/// for grams and for ml, which count 1:1 while cooking, so an item in the
/// other of them fits too (`cookNeedInBothMeasures`); names match in the
/// language [localeCode]. Empty when the line is gone.
///
/// The foods whose name resembles the line come first ("Passt vielleicht"),
/// also where that rule has no amount to fit: spoons, an amount it cannot read
/// and pieces on an item in grams. They count when they fit or are kept in g
/// or ml, which a weight can fill, and any of them on a line without a need,
/// but never a weak match or a food only inside a word
/// (`cookFoodOnlyInsideWord`). So is every such item that is the food the line
/// names (`cookNameIsFood` of `cookLineFood`). Every other item of the Vorrat
/// is the rest ("Alles im Vorrat"). Only a suggestion: the cook picks the food.
KochmodusPickerOffers kochmodusPickerOffers(
  KochmodusView view,
  String lineId, {
  required String localeCode,
}) {
  final line = view.lines.firstWhereOrNull((line) => line.id == lineId);
  if (line == null) return (matches: const [], rest: const []);
  final offers = kochmodusOffers(view, lineId);
  final byId = {for (final offer in offers) offer.item.id: offer};
  final conversion =
      cookSpoonWeight(line.need, line.line.conversion) ?? line.line.conversion;
  final text = cookTextForMatch(line.line.text);
  final items = [for (final offer in offers) offer.item];
  final candidates = [
    for (final need in cookNeedInBothMeasures(line.need))
      ingredientStockCandidates(
        text: text,
        requirement: need,
        items: items,
        localeCode: localeCode,
        amountConversion: conversion == null
            ? null
            : RecipeIngredientAmountConversion(
                amountPerPiece: conversion.amountPerPiece,
                unit: conversion.unit.toInventoryAmountUnit(),
              ),
      ),
  ];
  final fitting = {
    for (final found in candidates)
      for (final item in [...found.matches, ...found.others]) item.id,
  };
  final food = cookLineFood(line.line.text);
  bool canTake(InventoryItem item) =>
      line.need == null || fitting.contains(item.id) || cookKeptByWeight(item);
  final matches = {
    for (final found in candidates)
      for (final item in found.matches)
        if (!cookFoodOnlyInsideWord(text, _nameOf(item))) item.id,
    for (final match in scoreInventoryItemsForIngredient(
      ingredient: text,
      inventoryItems: items,
      localeCode: localeCode,
    ))
      if (!isWeakIngredientMatch(ingredient: text, item: match.item) &&
          !cookFoodOnlyInsideWord(text, _nameOf(match.item)) &&
          canTake(match.item))
        match.item.id,
    for (final item in items)
      if (cookNameIsFood(_nameOf(item), food) && canTake(item)) item.id,
  };
  return (
    matches: [for (final id in matches) ?byId[id]],
    rest: [
      for (final offer in offers)
        if (!matches.contains(offer.item.id)) offer,
    ],
  );
}

/// What a line that needs [need] still lacks once it takes from [picked] in
/// that order, in the unit of [need]: 0 when they cover it, and also 0 for a
/// line without an amount, which any food covers. Each offer covers the part
/// of the need that its `available` is of its `needed`, so one food covers a
/// line whose weight is asked while cooking; an offer whose unit cannot supply
/// the line covers nothing.
int kochmodusPickerStillMissing(
  List<KochmodusOffer> picked,
  TemplateIngredientRequirement? need,
) {
  if (need == null) return 0;
  // Counted in the unit of the need and multiplied before dividing, so
  // thirds that add up leave no rounding rest.
  var covered = 0.0;
  for (final offer in picked) {
    final needed = offer.needed;
    if (needed == null || needed <= 0) continue;
    covered += offer.available * need.amount / needed;
  }
  final missing = need.amount - covered;
  return missing < _missingTolerance ? 0 : (missing - _missingTolerance).ceil();
}

// Below this a missing amount is a rounding rest, not an amount.
const _missingTolerance = 1e-6;

// The text a food's name is matched in: its name and brand.
String _nameOf(InventoryItem item) => '${item.name} ${item.brand ?? ''}';

/// What the list of the picker shows of [offers]: the name matches in their
/// order (`suggested`, "Passt vielleicht"), and every other food of the Vorrat
/// in the Vorrat's order of [preferences] (`all`, "Alles im Vorrat"), under
/// receipt headers when it groups by receipt. [query] filters both by the
/// Vorrat's own match.
({List<KochmodusPickerRow> suggested, List<KochmodusPickerRow> all})
kochmodusPickerRows(
  KochmodusPickerOffers offers, {
  required InventoryListViewPreferences preferences,
  required String query,
}) {
  final below = _found(offers.rest, query).sorted(
    (a, b) => compareInventoryEntries(
      InventoryFoodEntry(a.item),
      InventoryFoodEntry(b.item),
      preferences.sortMode,
    ),
  );
  return (
    suggested: [
      for (final offer in _found(offers.matches, query))
        KochmodusPickerOfferRow(offer),
    ],
    all: [
      if (preferences.groupByReceipt)
        for (final group in groupInventoryItemsByReceipt([
          for (final offer in below) offer.item,
        ])) ...[KochmodusPickerReceiptRow(group), ..._rowsOf(group, below)]
      else
        for (final offer in below) KochmodusPickerOfferRow(offer),
    ],
  );
}

List<KochmodusOffer> _found(List<KochmodusOffer> offers, String query) {
  final byId = {for (final offer in offers) offer.item.id: offer};
  return [
    for (final item in const InventorySearchService().filterItems(
      items: [for (final offer in offers) offer.item],
      query: query,
    ))
      ?byId[item.id],
  ];
}

// The rows of the items of [group], in the order of [offers].
List<KochmodusPickerRow> _rowsOf(
  InventoryReceiptGroup group,
  List<KochmodusOffer> offers,
) {
  final ids = {for (final item in group.items) item.id};
  return [
    for (final offer in offers)
      if (ids.contains(offer.item.id)) KochmodusPickerOfferRow(offer),
  ];
}

/// The Vorrat items that have nothing left for the line [lineId]: other runs
/// or the run's other lines hold all their stock (`KochmodusOffer.held`);
/// none for a line without a need. The food search does not take them, so a
/// new pack of their product goes in instead.
Set<String> kochmodusHeldItemIds(KochmodusView view, String lineId) => {
  for (final offer in kochmodusOffers(view, lineId))
    if (offer.held) offer.item.id,
};

/// The Vorrat items the picker of the line [lineId] offers: every item
/// that is not used up, and the items the line takes, in the Vorrat's
/// order. Empty when the line is gone.
List<KochmodusOffer> kochmodusOffers(KochmodusView view, String lineId) {
  final line = view.lines.firstWhereOrNull((line) => line.id == lineId);
  if (line == null) return const [];
  final takenHere = {for (final take in line.takes) take.itemId};
  return [
    for (final item in view.items.values)
      if (!item.isFullyConsumed || takenHere.contains(item.id))
        _offer(view, line, item),
  ];
}

KochmodusOffer _offer(
  KochmodusView view,
  KochmodusLineView line,
  InventoryItem item,
) {
  // A weight is a fact: its take ignores the other runs (`cookTakesFor`).
  final weighed = cookWeighedTake(line.line, [item]);
  final others = weighed == null
      ? view.otherReservations
      : const <String, int>{};
  final reserved = cookReservedFor(view.run, line.line, item, others);
  final available = cookAvailableFor(view.run, line.line, item, others);
  final take = cookTakeFor(line.need, item, line.line.conversion)?.amount;
  // A guessed weight (`cookTakeGuessed`) lacks nothing while some is left:
  // a guessed spoon takes what is there, at most its spoons' weight,
  final guessed =
      cookSpoonGuessed(line.need, line.line.conversion) && available > 0;
  // and a line whose weight is asked while cooking, such as "1 Zwiebel" on a
  // food kept in g (`KochmodusView.toWeigh`), takes at most what is there.
  final later =
      available > 0 &&
      !line.notCounted &&
      cookKeptByWeight(item) &&
      cookLineAmountKind(line.line) == CookLineAmountKind.other;
  final needed =
      weighed ??
      (later
          ? min(take ?? available, available)
          : guessed && take != null
          ? min(take, available)
          : take);
  return (
    item: item,
    available: available,
    reserved: reserved,
    needed: needed,
    missing: needed == null ? 0 : max(0, needed - available),
    held: line.need != null && available <= 0,
  );
}
