import 'dart:math' show max;

import 'package:collection/collection.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/vorlage_as_recipe.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_edits.dart';
import 'package:yamt/features/cookbook_new/presentation/models/recipe_view.dart';
import 'package:yamt/features/inventory/application/ingredient_stock_match.dart';
import 'package:yamt/features/inventory/application/template_ingredient_unit_mapper.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/inventory/domain/prepared_meal_component.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';
import 'package:yamt/features/recipes/domain/template_ingredient_requirement.dart';

/// The recipe [recipeId] from [templates] with its ingredients for
/// [portions] (`null` for its own) and their Vorrat [items], or `null` when
/// the recipe is gone. It loads and fails with [templates] and [items].
///
/// The recipe takes the cook's [edits] for this cooking. An ingredient takes
/// the item in [picks] by its line key (`null` for none), else the items
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
  RecipeEdits edits = const RecipeEdits(),
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
  final stored = saved.firstWhereOrNull((meal) => meal.id == recipeId);
  if (stored == null) {
    return const AsyncData(null);
  }
  final isVorlage = stored.recipeIngredients.isEmpty;
  final (:recipe, :keys) = _applyEdits(
    isVorlage ? vorlageAsRecipe(stored, parser) : stored,
    edits,
  );
  // A Vorlage food is sized from its own amount, as cooking takes it.
  final vorlageFoodByLine = {
    if (isVorlage)
      for (final (:line, :food) in vorlageFoods(stored, parser)) line: food,
  };
  // A recipe needs at least one portion to scale from.
  final basePortions = max(1, recipe.totalPortions);
  final chosen = portions ?? basePortions;
  final vorrat = stock.toList();
  TemplateIngredientRequirement? parse(String? text) => text == null
      ? null
      : parser.parseRequirement(
          ingredient: text,
          selectedPortions: chosen,
          basePortions: basePortions,
        );
  RecipeChange change(String? original, String? text) {
    final from = parse(original);
    final to = parse(text);
    return (
      food: to?.name ?? from?.name ?? text ?? original ?? '',
      from: from,
      to: to,
      added: original == null,
      removed: text == null,
    );
  }

  return AsyncData(
    RecipeView(
      recipe: recipe,
      saved: stored,
      changes: [
        for (final MapEntry(:key, :value) in edits.changed.entries)
          change(key, value),
        for (final text in edits.added.values) change(null, text),
      ],
      portions: chosen,
      lines: [
        for (final (index, ingredient) in recipe.recipeIngredients.indexed)
          _line(
            key: keys[index].key,
            isAdded: keys[index].isAdded,
            ingredient: ingredient,
            recipe: recipe,
            vorlageAmount: switch (vorlageFoodByLine[ingredient]) {
              final food? => food.amount * chosen / basePortions,
              null => null,
            },
            requirement: switch (vorlageFoodByLine[ingredient]) {
              final food? => TemplateIngredientRequirement(
                // Matching counts whole pieces; the label keeps the part.
                amount: max(1, (food.amount * chosen / basePortions).round()),
                unit: food.unit.toTemplateIngredientUnit(),
                name: food.name,
              ),
              null => parser.parseRequirement(
                ingredient: ingredient,
                selectedPortions: chosen,
                basePortions: basePortions,
              ),
            },
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
  required String key,
  required bool isAdded,
  required String ingredient,
  required PreparedMeal recipe,
  required TemplateIngredientRequirement? requirement,
  required List<InventoryItem> items,
  required TemplateIngredientParser parser,
  required String localeCode,
  required Map<String, String?> picks,
  double? vorlageAmount,
}) {
  final conversion =
      recipe.recipeIngredientAmountConversions[ingredient.trim()];
  final found = ingredientStockCandidates(
    text: ingredient,
    requirement: requirement,
    items: items,
    localeCode: localeCode,
    amountConversion: conversion,
  );
  final candidates = [...found.matches, ...found.others];
  final stock = picks.containsKey(key)
      ? [?candidates.firstWhereOrNull((item) => item.id == picks[key])]
      : ingredientStockPick(
          recipe: recipe,
          text: ingredient,
          candidates: found,
        );
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
    key: key,
    isAdded: isAdded,
    ingredient: ingredient,
    row: FreeCookingRow(
      text: ingredient,
      requirement: requirement,
      stockItems: [?stock.firstOrNull],
    ),
    // An added ingredient is cooked even when its text is an ignored one.
    isIgnored: !isAdded && recipe.ignoredRecipeIngredients.contains(ingredient),
    candidates: candidates,
    items: stock,
    shortfall: shortfall,
    label: switch ((vorlageAmount, requirement)) {
      // Grams and milliliters cook whole, parts of a piece stay.
      (final amount?, final requirement?) => preparedMealFoodRow(
        requirement.unit == TemplateIngredientUnit.piece
            ? amount
            : amount.roundToDouble(),
        requirement.inventoryUnit,
        requirement.name,
      ),
      _ => _label(parser, ingredient, requirement),
    },
    stockedLabel: partLabel(ingredientStockedAmount(stock, shortfall?.unit)),
    restLabel: partLabel(shortfall?.amount ?? 0),
  );
}

/// [ingredient] as an open row of a meal names it, written by
/// [_ingredientText].
String _label(
  TemplateIngredientParser parser,
  String ingredient,
  TemplateIngredientRequirement? requirement,
) => requirement == null
    ? ingredient.trim()
    : _ingredientText(parser, requirement);

/// [requirement] as an ingredient text, like an open row of a meal names it,
/// but pieces without a measure need no unit: "1 Zwiebel".
String _ingredientText(
  TemplateIngredientParser parser,
  TemplateIngredientRequirement requirement,
) {
  if (requirement.unit == TemplateIngredientUnit.piece &&
      (requirement.countMeasureLabel?.trim() ?? '').isEmpty &&
      (requirement.packageCountLabel?.trim() ?? '').isEmpty) {
    return '${requirement.amount} ${requirement.name}';
  }
  return parser.formatPendingIngredient(
    amount: requirement.amount,
    unit: requirement.unit,
    name: requirement.name,
    countMeasureLabel: requirement.countMeasureLabel,
    packageCountLabel: requirement.packageCountLabel,
  );
}

/// [recipe] with [edits]: changed ingredients get their new text, left out
/// ones go, and added ones follow. The Vorrat items, amount conversions,
/// and ignores move to the new texts. Also returns the line key per
/// ingredient: the saved ingredient, or the key of an added one.
({PreparedMeal recipe, List<({String key, bool isAdded})> keys}) _applyEdits(
  PreparedMeal recipe,
  RecipeEdits edits,
) {
  if (edits.isEmpty) {
    return (
      recipe: recipe,
      keys: [
        for (final ingredient in recipe.recipeIngredients)
          (key: ingredient, isAdded: false),
      ],
    );
  }
  String? edited(String ingredient) => edits.changed.containsKey(ingredient)
      ? edits.changed[ingredient]
      : ingredient;
  final kept = [
    for (final ingredient in recipe.recipeIngredients)
      if (edited(ingredient) != null) ingredient,
  ];
  final conversions = recipe.recipeIngredientAmountConversions;
  return (
    recipe: recipe.copyWith(
      recipeIngredients: [
        for (final ingredient in kept) edited(ingredient)!,
        ...edits.added.values,
      ],
      recipeIngredientAssignments: {
        for (final MapEntry(:key, :value)
            in recipe.recipeIngredientAssignments.entries)
          ?edited(key): value,
      },
      recipeIngredientAmountConversions: {
        for (final ingredient in kept)
          edited(ingredient)!.trim(): ?conversions[ingredient.trim()],
      },
      ignoredRecipeIngredients: [
        for (final ingredient in recipe.ignoredRecipeIngredients)
          ?edited(ingredient),
      ],
    ),
    keys: [
      for (final ingredient in kept) (key: ingredient, isAdded: false),
      for (final key in edits.added.keys) (key: key, isAdded: true),
    ],
  );
}
