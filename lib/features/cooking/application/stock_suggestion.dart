import 'dart:math';

import 'package:collection/collection.dart';
import 'package:yamt/features/cooking/domain/cook_session.dart';
import 'package:yamt/features/cooking/domain/stock_fill.dart';
import 'package:yamt/features/inventory/application/ingredient_inventory_matcher.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/application/recipe_ingredient_assignment_support.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/inventory_item_consumption.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// What the Vorrat offers one line of a cooking.
typedef LineStock = ({
  /// The items whose name fits: the best name matches first, then the
  /// weaker ones.
  List<InventoryItem> candidates,

  /// The other items the line could take, by name; a line whose amount the
  /// parser cannot read could take any item.
  List<InventoryItem> more,

  /// The suggested takes, empty when nothing in the Vorrat fits.
  List<ItemTake> suggestion,
});

/// The one rule for which Vorrat items a recipe line should take. It only
/// suggests; the cook decides in the line's clarification.
///
/// The pool is the items the [recipe] saved for the line, else the best
/// name matches (`ingredientStockCandidates`). From the pool an item that
/// supplies the line alone comes first, opened packs and older ones first;
/// when none does, opened and older ones are combined until the amount is
/// filled. What other lines of [session] take is not offered again.
LineStock suggest({
  required String lineId,
  required String text,
  required TemplateIngredientRequirement? requirement,
  required PreparedMeal recipe,
  required List<InventoryItem> items,
  required CookSession session,
  required String? localeCode,
}) {
  final conversion = recipe.recipeIngredientAmountConversions[text];
  final (:matches, :others) = ingredientStockCandidates(
    text: text,
    requirement: requirement,
    items: items,
    localeCode: localeCode,
    amountConversion: conversion,
  );
  final named = {
    for (final (:item, score: _) in scoreInventoryItemsForIngredient(
      ingredient: text,
      inventoryItems: items,
      localeCode: localeCode,
    ))
      item.id,
  };
  final candidates = [
    ...matches,
    for (final item in others)
      if (named.contains(item.id)) item,
  ];
  final more = requirement == null && matches.isEmpty && others.isEmpty
      ? (items.where((item) => !item.isFullyConsumed).toList()
          ..sort((left, right) => left.name.compareTo(right.name)))
      : [
          for (final item in others)
            if (!named.contains(item.id)) item,
        ];
  final saved = [
    for (final id
        in recipe.recipeIngredientAssignments[text] ?? const <String>[])
      ?candidates.firstWhereOrNull((item) => item.id == id),
  ];
  int available(InventoryItem item) =>
      item.availableAmount - session.takenFrom(item.id, exceptLineId: lineId);
  final pool = (saved.isNotEmpty ? saved : matches)
      .where((item) => available(item) > 0)
      .sorted(_openedThenOldest);
  if (pool.isEmpty) {
    return (candidates: candidates, more: more, suggestion: const []);
  }
  final need = neededFrom(requirement, pool.first, conversion);
  final scale = cookAmountScale(pool.first);
  final alone = pool.firstWhereOrNull((item) {
    final needed = neededFrom(requirement, item, conversion);
    return needed != null && available(item) >= needed.amount;
  });
  if (alone != null) {
    final needed = neededFrom(requirement, alone, conversion)!;
    return (
      candidates: candidates,
      more: more,
      suggestion: [(itemId: alone.id, amount: needed.amount)],
    );
  }
  return (
    candidates: candidates,
    more: more,
    suggestion: fillInOrder(
      needed: need?.amount ?? 0,
      offers: [
        for (final item in pool)
          if (neededFrom(requirement, item, conversion)?.unit == need?.unit &&
              cookAmountScale(item) == scale)
            (itemId: item.id, available: available(item)),
      ],
    ),
  );
}

/// How much of [requirement] [item] must give, in the unit and scale it is
/// kept in, or `null` when its unit cannot supply it. A line without amount
/// needs 0.
({int amount, InventoryAmountUnit? unit})? neededFrom(
  TemplateIngredientRequirement? requirement,
  InventoryItem item,
  RecipeIngredientAmountConversion? conversion,
) {
  if (requirement == null) {
    return (amount: 0, unit: null);
  }
  final effective = resolveEffectiveRequirementForItems(
    requirement: requirement,
    assignedItems: [item],
    amountConversion: conversion,
  );
  if (effective == null) return null;
  // Pieces are kept in the item's scale, a thousand per piece for a pack.
  final scale = effective.unit == InventoryAmountUnit.piece
      ? cookAmountScale(item)
      : 1;
  return (amount: effective.amount * scale, unit: effective.unit);
}

/// The scale [item] counts its amounts in: packs tracked by amount keep
/// a thousand per piece, items counted whole keep 1.
int cookAmountScale(InventoryItem item) =>
    item.usesAmountProgress ? max(1, item.amountScale) : 1;

// Opened packs first, then the oldest.
int _openedThenOldest(InventoryItem left, InventoryItem right) {
  if (left.isConsumed != right.isConsumed) {
    return left.isConsumed ? -1 : 1;
  }
  return left.entryDate.compareTo(right.entryDate);
}
