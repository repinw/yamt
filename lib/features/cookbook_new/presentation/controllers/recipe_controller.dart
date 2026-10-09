import 'dart:developer' show log;

import 'package:collection/collection.dart';
import 'package:meta/meta.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:yamt/features/cookbook_new/application/ingredient_stock_match.dart';
import 'package:yamt/features/cookbook_new/domain/free_cooking_row.dart';
import 'package:yamt/features/cookbook_new/presentation/controllers/cookbook_controller.dart';
import 'package:yamt/features/inventory/application/inventory_quick_eat_data_providers.dart';
import 'package:yamt/features/inventory/application/prepared_meal_cooking_service.dart';
import 'package:yamt/features/inventory/domain/inventory_item.dart';
import 'package:yamt/features/inventory/domain/prepared_meal.dart';
import 'package:yamt/features/recipes/application/template_ingredient_parser.dart';

part 'recipe_controller.g.dart';

/// One ingredient of a recipe, sized for the chosen portions.
@immutable
class RecipeIngredientLine {
  /// Creates the line for the saved [ingredient].
  const new({
    required this.ingredient,
    required this.row,
    required this.isIgnored,
    required this.candidates,
  });

  /// The ingredient as the recipe saves it, for the original portions.
  final String ingredient;

  /// The ingredient for the chosen portions with the Vorrat item that
  /// supplies it.
  final FreeCookingRow row;

  /// Whether the recipe ignores the ingredient, like salt or water.
  final bool isIgnored;

  /// The Vorrat items the cook can pick for it, best match first.
  final List<InventoryItem> candidates;
}

/// A recipe as the recipe page shows it.
@immutable
class RecipeView {
  /// Creates the view of [recipe] for [portions].
  const new({
    required this.recipe,
    required this.portions,
    required this.lines,
  });

  /// The saved recipe.
  final PreparedMeal recipe;

  /// The portions to cook.
  final int portions;

  /// The ingredients for [portions].
  final List<RecipeIngredientLine> lines;

  /// The ingredients that count, without the ignored ones.
  Iterable<RecipeIngredientLine> get activeLines =>
      lines.where((line) => !line.isIgnored);

  /// How many of [activeLines] the Vorrat supplies.
  int get inStockCount =>
      activeLines.where((line) => line.row.isInStock).length;

  /// The Vorrat items to use up, by the saved ingredient.
  Map<String, List<String>> get assignments => {
    for (final line in activeLines)
      if (line.row.stockItem case final item?) line.ingredient: [item.id],
  };
}

/// What the cook changed on the recipe page.
@immutable
class RecipeDraft {
  /// Creates the draft.
  const new({
    this.portions,
    this.picks = const <String, String?>{},
    this.isCooking = false,
  });

  /// The chosen portions, or `null` for the recipe's own.
  final int? portions;

  /// The Vorrat item picked per saved ingredient; `null` means "not from the
  /// Vorrat".
  final Map<String, String?> picks;

  /// Whether "Kochen" is saving the meal.
  final bool isCooking;

  /// Returns a copy with the given values.
  RecipeDraft copyWith({
    int? portions,
    Map<String, String?>? picks,
    bool? isCooking,
  }) => RecipeDraft(
    portions: portions ?? this.portions,
    picks: picks ?? this.picks,
    isCooking: isCooking ?? this.isCooking,
  );
}

/// Holds the portions and Vorrat picks of the recipe [recipeId] and cooks it.
@riverpod
class RecipeController extends _$RecipeController {
  @override
  RecipeDraft build(String recipeId) => const RecipeDraft();

  /// Cooks [portions] portions.
  void setPortions(int portions) {
    if (portions >= 1) {
      state = state.copyWith(portions: portions);
    }
  }

  /// Takes [ingredient] from the Vorrat item [itemId], or not from the
  /// Vorrat when it is `null`.
  void pick(String ingredient, String? itemId) {
    state = state.copyWith(picks: {...state.picks, ingredient: itemId});
  }

  /// Puts the meal of [view] in the pot. Returns its id, or `null` when
  /// saving failed.
  Future<String?> cook(RecipeView view) async {
    if (state.isCooking) {
      return null;
    }
    final link = ref.keepAlive();
    state = state.copyWith(isCooking: true);
    try {
      final result = await ref
          .read(preparedMealCookingServiceProvider)
          .cookRecipe(
            recipe: view.recipe,
            portions: view.portions,
            assignments: view.assignments,
          );
      return result.isSuccess ? result.preparedMealId : null;
    } on Object catch (error, stackTrace) {
      log(
        'Failed to cook the recipe.',
        name: 'RecipeController',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      if (ref.mounted) {
        state = state.copyWith(isCooking: false);
      }
      link.close();
    }
  }
}

/// The recipe [recipeId] with its ingredients for the chosen portions and
/// their Vorrat items, or `null` when the recipe is gone. It loads and fails
/// with the recipes and the Vorrat.
///
/// An ingredient takes the item the cook picked, else the first one the
/// recipe saved that can still supply it, else the best match.
@riverpod
AsyncValue<RecipeView?> recipeView(
  Ref ref,
  String recipeId,
  String localeCode,
) {
  final draft = ref.watch(recipeControllerProvider(recipeId));
  final parser = ref.watch(templateIngredientParserProvider);
  final templatesAsync = ref.watch(cookbookTemplatesProvider);
  final itemsAsync = ref.watch(inventoryQuickEatItemsProvider);
  for (final async in [templatesAsync, itemsAsync]) {
    if (async case AsyncError(:final error, :final stackTrace)) {
      return AsyncError(error, stackTrace);
    }
  }
  // The previous values carry the page through a reload.
  final templates = templatesAsync.value;
  final items = itemsAsync.value;
  if (templates == null || items == null) {
    return const AsyncLoading();
  }
  final recipe = templates.firstWhereOrNull((meal) => meal.id == recipeId);
  if (recipe == null) {
    return const AsyncData(null);
  }
  final portions = draft.portions ?? recipe.totalPortions;
  RecipeIngredientLine line(String ingredient) {
    final requirement = parser.parseRequirement(
      ingredient: ingredient,
      selectedPortions: portions,
      basePortions: recipe.totalPortions,
    );
    final conversion =
        recipe.recipeIngredientAmountConversions[ingredient.trim()];
    final candidates = ingredientStockCandidates(
      text: ingredient,
      requirement: requirement,
      items: items,
      localeCode: localeCode,
      amountConversion: conversion,
    );
    InventoryItem? candidate(String? id) =>
        candidates.firstWhereOrNull((item) => item.id == id);
    final InventoryItem? stockItem;
    if (draft.picks.containsKey(ingredient)) {
      stockItem = candidate(draft.picks[ingredient]);
    } else {
      stockItem =
          recipe.recipeIngredientAssignments[ingredient]
              ?.map(candidate)
              .nonNulls
              .firstOrNull ??
          bestIngredientStockMatch(
            text: ingredient,
            requirement: requirement,
            items: items,
            localeCode: localeCode,
            amountConversion: conversion,
          );
    }
    return RecipeIngredientLine(
      ingredient: ingredient,
      row: FreeCookingRow(
        text: ingredient,
        requirement: requirement,
        stockItem: stockItem,
      ),
      isIgnored: recipe.ignoredRecipeIngredients.contains(ingredient),
      candidates: candidates,
    );
  }

  return AsyncData(
    RecipeView(
      recipe: recipe,
      portions: portions,
      lines: [
        for (final ingredient in recipe.recipeIngredients) line(ingredient),
      ],
    ),
  );
}
