import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/application/ingredient_stock_match.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The recipe [recipeId] from [templates] with its ingredients for
/// [portions] (`null` for its own) and their Vorrat [items], or `null` when
/// the recipe is gone. It loads and fails with [templates] and [items].
///
/// An ingredient takes the item in [picks] (`null` for none), else the items
/// the recipe saved that can still supply it, else the best match. Items in
/// [hiddenItemIds] count as not in the Vorrat.
AsyncValue<RecipeView?> buildRecipeView({
  required String recipeId,
  required AsyncValue<List<PreparedMeal>> templates,
  required AsyncValue<List<InventoryItem>> items,
  required TemplateIngredientParser parser,
  required String localeCode,
  required int? portions,
  required Map<String, String?> picks,
  Set<String> hiddenItemIds = const <String>{},
}) {
  for (final async in [templates, items]) {
    if (async case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  // The previous values carry the page through a reload.
  final saved = templates.value;
  final stock = items.value?.where((item) => !hiddenItemIds.contains(item.id));
  if (saved == null || stock == null) {
    return const AsyncLoading();
  }
  final recipe = saved.firstWhereOrNull((meal) => meal.id == recipeId);
  if (recipe == null) {
    return const AsyncData(null);
  }
  // A recipe needs at least one portion to scale from.
  final basePortions = max(1, recipe.totalPortions);
  final chosen = portions ?? basePortions;
  final vorrat = stock.toList();
  return AsyncData(
    RecipeView(
      recipe: recipe,
      portions: chosen,
      lines: [
        for (final ingredient in recipe.recipeIngredients)
          _line(
            ingredient: ingredient,
            recipe: recipe,
            requirement: parser.parseRequirement(
              ingredient: ingredient,
              selectedPortions: chosen,
              basePortions: basePortions,
            ),
            items: vorrat,
            parser: parser,
            localeCode: localeCode,
            picks: picks,
          ),
      ],
    ),
  );
}

RecipeIngredientLine _line({
  required String ingredient,
  required PreparedMeal recipe,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required TemplateIngredientParser parser,
  required String localeCode,
  required Map<String, String?> picks,
}) {
  final conversion =
      recipe.recipeIngredientAmountConversions[ingredient.trim()];
  final candidates = ingredientStockCandidates(
    text: ingredient,
    requirement: requirement,
    items: items,
    localeCode: localeCode,
    amountConversion: conversion,
  );
  List<InventoryItem> pickable(Iterable<String?> ids) => [
    for (final id in ids) ?candidates.firstWhereOrNull((i) => i.id == id),
  ];
  final List<InventoryItem> stock;
  if (picks.containsKey(ingredient)) {
    stock = pickable([picks[ingredient]]);
  } else {
    final savedItems = pickable(
      recipe.recipeIngredientAssignments[ingredient] ?? const <String>[],
    );
    final best = bestIngredientStockMatch(
      text: ingredient,
      requirement: requirement,
      items: items,
      localeCode: localeCode,
      amountConversion: conversion,
    );
    stock = savedItems.isNotEmpty ? savedItems : [?best];
  }
  final shortfall = ingredientShortfall(
    requirement: requirement,
    items: stock,
    amountConversion: conversion,
  );
  String? partLabel(int amount) => switch ((requirement, shortfall)) {
    (final requirement?, final shortfall?) => parser.formatPendingIngredient(
      amount: amount,
      unit: shortfall.unit == InventoryAmountUnit.milliliter
          ? TemplateIngredientUnit.milliliter
          : TemplateIngredientUnit.gram,
      name: requirement.name,
    ),
    _ => null,
  };
  return RecipeIngredientLine(
    ingredient: ingredient,
    row: FreeCookingRow(
      text: ingredient,
      requirement: requirement,
      stockItem: stock.firstOrNull,
    ),
    isIgnored: recipe.ignoredRecipeIngredients.contains(ingredient),
    candidates: candidates,
    items: stock,
    shortfall: shortfall,
    label: _label(parser, ingredient, requirement),
    stockedLabel: partLabel(ingredientStockedAmount(stock, shortfall?.unit)),
    restLabel: partLabel(shortfall?.amount ?? 0),
  );
}

/// [ingredient] as an open row of a meal names it, but pieces without a
/// measure need no unit: "1 Zwiebel".
String _label(
  TemplateIngredientParser parser,
  String ingredient,
  TemplateIngredientRequirement? requirement,
) {
  if (requirement != null &&
      requirement.unit == TemplateIngredientUnit.piece &&
      (requirement.countMeasureLabel?.trim() ?? '').isEmpty &&
      (requirement.packageCountLabel?.trim() ?? '').isEmpty) {
    return '${requirement.amount} ${requirement.name}';
  }
  return parser.pendingIngredientLabel(
    originalIngredient: ingredient,
    requirement: requirement,
  );
}
